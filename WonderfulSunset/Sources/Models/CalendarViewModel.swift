import Foundation
import SwiftUI
import CoreLocation
import UserNotifications
import Combine

class CalendarViewModel: ObservableObject {
    
    @Published var dailyForecasts: [DailyForecast] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasPermission: Bool = false
    
    private let weatherService = WeatherDataService()
    private let scoreCalculator = SunsetScoreCalculator()
    
    init() {
        checkNotificationPermission()
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
                    completion(false)
                } else {
                    self.hasPermission = granted
                    completion(granted)
                }
            }
        }
    }
    
    func fetchDailyForecasts(for location: CLLocation, days: Int = 7, completion: @escaping () -> Void) {
        isLoading = true
        errorMessage = nil
        
        weatherService.getHourlyForecast(for: location) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let forecast):
                    self?.calculateDailyForecasts(forecast: forecast, location: location, days: days)
                    completion()
                case .failure(let error):
                    self?.errorMessage = "Failed to fetch weather data: \(error.localizedDescription)"
                    completion()
                }
            }
        }
    }
    
    private func calculateDailyForecasts(forecast: [CodableForecast], location: CLLocation, days: Int) {
        var forecasts: [DailyForecast] = []
        
        // Calculate forecasts for the next N days
        for dayOffset in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
            let solar = Solar(for: date, coordinate: location.coordinate)
            
            guard let sunsetTime = solar.sunset else { continue }
            
            // Find forecast data around sunset time for this day
            let sunsetHour = Calendar.current.component(.hour, from: sunsetTime)
            let sunsetMinute = Calendar.current.component(.minute, from: sunsetTime)
            
            // Filter forecast for the hour containing sunset and the next hour
            let relevantForecasts = forecast.filter { forecast in
                let forecastDate = Calendar.current.dateComponents([.year, .month, .day], from: forecast.date)
                let targetDate = Calendar.current.dateComponents([.year, .month, .day], from: date)
                
                return forecastDate.year == targetDate.year &&
                       forecastDate.month == targetDate.month &&
                       forecastDate.day == targetDate.day &&
                       (Calendar.current.component(.hour, from: forecast.date) == sunsetHour ||
                        Calendar.current.component(.hour, from: forecast.date) == sunsetHour + 1)
            }
            
            guard relevantForecasts.count >= 2 else { continue }
            
            // Calculate weighted average of weather data
            let highCloud = calculateWeightedAverage(relevantForecasts.map { $0.cloudCover }, sunsetMinute: sunsetMinute)
            let midCloud = calculateWeightedAverage(relevantForecasts.map { $0.cloudCover * 0.5 }, sunsetMinute: sunsetMinute)
            let lowCloud = calculateWeightedAverage(relevantForecasts.map { $0.cloudCover * 0.3 }, sunsetMinute: sunsetMinute)
            let humidity = calculateWeightedAverage(relevantForecasts.map { $0.humidity }, sunsetMinute: sunsetMinute)
            let visibility = calculateWeightedAverage(relevantForecasts.map { $0.visibility }, sunsetMinute: sunsetMinute)
            
            let weatherData = WeatherData(
                highCloud: highCloud,
                midCloud: midCloud,
                lowCloud: lowCloud,
                humidity: humidity,
                visibility: visibility
            )
            
            // Calculate sunset score
            let scoreResult = scoreCalculator.calculateSunsetScore(weatherData: weatherData, sunsetTime: sunsetTime)
            
            // Create daily forecast
            let dailyForecast = DailyForecast(
                date: date,
                sunsetTime: sunsetTime,
                score: scoreResult.score,
                afterglowProbability: scoreResult.afterglowProbability,
                tyndallProbability: scoreResult.tyndallProbability,
                isReminderSet: false
            )
            
            forecasts.append(dailyForecast)
        }
        
        dailyForecasts = forecasts
    }
    
    private func calculateWeightedAverage(_ values: [Double], sunsetMinute: Int) -> Double {
        guard values.count >= 2 else { return values.first ?? 0 }
        
        let w1 = Double(60 - sunsetMinute) / 60.0
        let w2 = Double(sunsetMinute) / 60.0
        
        return values[0] * w1 + values[1] * w2
    }
    
    func toggleReminder(for forecast: DailyForecast) {
        // Find the forecast in the array
        if let index = dailyForecasts.firstIndex(where: { $0.date == forecast.date }) {
            var updatedForecast = dailyForecasts[index]
            updatedForecast.isReminderSet.toggle()
            dailyForecasts[index] = updatedForecast
            
            if updatedForecast.isReminderSet {
                // Set up notification for 15:00 on the forecast date
                scheduleNotification(for: updatedForecast)
            } else {
                // Remove notification
                cancelNotification(for: updatedForecast)
            }
        }
    }
    
    private func scheduleNotification(for forecast: DailyForecast) {
        guard hasPermission else {
            errorMessage = "Notification permission not granted"
            return
        }
        
        // Calculate notification time (15:00 on the forecast date)
        var components = Calendar.current.dateComponents([.year, .month, .day], from: forecast.date)
        components.hour = 15
        components.minute = 0
        
        guard Calendar.current.date(from: components) != nil else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Wonderful Sunset"
        content.body = "今日晚霞指数为 \(forecast.score)，\(forecast.score >= 80 ? "大概率出现火烧云，建议准备好相机！" : "云层适中，或许会有不错的观赏体验。")"
        content.sound = UNNotificationSound.default
        
        // Create notification trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create notification request
        let request = UNNotificationRequest(identifier: "sunset_\(forecast.date.timeIntervalSince1970)", content: content, trigger: trigger)
        
        // Add request to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to schedule notification: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func cancelNotification(for forecast: DailyForecast) {
        let identifier = "sunset_\(forecast.date.timeIntervalSince1970)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let sunsetTime: Date
    let score: Int
    let afterglowProbability: Double
    let tyndallProbability: Double
    var isReminderSet: Bool
}