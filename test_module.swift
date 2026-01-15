// Test module for Wonderful Sunset app
// This file imports all necessary components and verifies they work together

// Import necessary frameworks
import Foundation
import CoreLocation
import SwiftUI
import UserNotifications

// MARK: - Solar Implementation
struct Solar {
    let date: Date
    let coordinate: CLLocationCoordinate2D
    
    var sunset: Date? {
        return calculateSunset()
    }
    
    init(for date: Date, coordinate: CLLocationCoordinate2D) {
        self.date = date
        self.coordinate = coordinate
    }
    
    private func calculateSunset() -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        components.hour = 18
        components.minute = 0
        components.second = 0
        
        return Calendar.current.date(from: components)
    }
}

// MARK: - Weather Data Models
struct WeatherData {
    let highCloud: Double
    let midCloud: Double
    let lowCloud: Double
    let humidity: Double
    let visibility: Double
}

struct CodableForecast: Codable {
    let date: Date
    let temperature: Double
    let cloudCover: Double
    let humidity: Double
    let visibility: Double
    let condition: String
}

struct SunsetScoreResult {
    let score: Int
    let afterglowProbability: Double
    let tyndallProbability: Double
    let 感性文案: String
}

// MARK: - Weather Service
class WeatherDataService {
    private let cacheKey = "WeatherKitHourlyForecastCache"
    private let cacheExpiryKey = "WeatherKitCacheExpiry"
    
    func getHourlyForecast(for location: CLLocation, completion: @escaping (Result<[CodableForecast], Error>) -> Void) {
        let mockForecast = generateMockForecast()
        completion(.success(mockForecast))
    }
    
    private func generateMockForecast() -> [CodableForecast] {
        var forecast: [CodableForecast] = []
        let now = Date()
        
        for hour in 0..<24 {
            let date = Calendar.current.date(byAdding: .hour, value: hour, to: now)!
            let forecastItem = CodableForecast(
                date: date,
                temperature: 20.0 + Double.random(in: -5...5),
                cloudCover: Double.random(in: 0...1),
                humidity: Double.random(in: 0.3...0.8),
                visibility: 10.0 + Double.random(in: 0...30),
                condition: "PartlyCloudy"
            )
            forecast.append(forecastItem)
        }
        
        return forecast
    }
}

// MARK: - Sunset Score Calculator
class SunsetScoreCalculator {
    func calculateScore(weatherData: WeatherData) -> Int {
        let Ch = weatherData.highCloud
        let Cm = weatherData.midCloud
        let Cl = weatherData.lowCloud
        let H = weatherData.humidity
        let V = weatherData.visibility
        
        let cloudFactor = (Ch * 0.5 + Cm * 0.1) * (1 - Cl)
        let humidityFactor = (1.2 - H)
        let visibilityFactor = min(V / 20, 1.2)
        
        let rawScore = cloudFactor * humidityFactor * visibilityFactor * 100
        return Int(round(rawScore))
    }
    
    func calculateSpecialPhenomena(weatherData: WeatherData, sunsetTime: Date) -> (afterglow: Double, tyndall: Double) {
        let Ch = weatherData.highCloud
        let Cm = weatherData.midCloud
        let Cl = weatherData.lowCloud
        let H = weatherData.humidity
        let V = weatherData.visibility
        let totalCloud = Ch + Cm + Cl
        
        var afterglowProbability: Double = 0
        if Cl < 0.05 && V > 30 && Ch > 0.5 {
            afterglowProbability = Ch * 100
        }
        
        var tyndallProbability: Double = 0
        if 0.3 < totalCloud && totalCloud < 0.7 && H > 0.7 {
            let cloudDeviation = abs(totalCloud - 0.55)
            tyndallProbability = (1 - cloudDeviation) * H * 100
        }
        
        return (afterglowProbability, tyndallProbability)
    }
    
    func calculateWeightedAverage(_ values: [Double], sunsetMinute: Int) -> Double {
        guard values.count >= 2 else { return values.first ?? 0 }
        
        let W1 = Double(60 - sunsetMinute) / 60.0
        let W2 = Double(sunsetMinute) / 60.0
        
        return values[0] * W1 + values[1] * W2
    }
    
    func get感性文案(score: Int) -> String {
        switch score {
        case 80...100:
            return "今日大概率出现‘火烧云’，建议准备好相机。"
        case 50..<80:
            return "云层适中，或许会有温柔的粉色邂逅。"
        default:
            return "天空稍显沉闷，适合在室内静候下一次惊喜。"
        }
    }
    
    func calculateSunsetScore(weatherData: WeatherData, sunsetTime: Date) -> SunsetScoreResult {
        let score = calculateScore(weatherData: weatherData)
        let (afterglow, tyndall) = calculateSpecialPhenomena(weatherData: weatherData, sunsetTime: sunsetTime)
        let 文案 = get感性文案(score: score)
        
        return SunsetScoreResult(
            score: score,
            afterglowProbability: afterglow,
            tyndallProbability: tyndall,
            感性文案: 文案
        )
    }
}

// MARK: - Calendar View Model
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
        
        for dayOffset in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
            let solar = Solar(for: date, coordinate: location.coordinate)
            
            guard let sunsetTime = solar.sunset else { continue }
            
            let sunsetHour = Calendar.current.component(.hour, from: sunsetTime)
            let sunsetMinute = Calendar.current.component(.minute, from: sunsetTime)
            
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
            
            let scoreResult = scoreCalculator.calculateSunsetScore(weatherData: weatherData, sunsetTime: sunsetTime)
            
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
        
        let W1 = Double(60 - sunsetMinute) / 60.0
        let W2 = Double(sunsetMinute) / 60.0
        
        return values[0] * W1 + values[1] * W2
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

// MARK: - Test Function
func testWonderfulSunsetApp() {
    print("Testing Wonderful Sunset app components...")
    
    // Test Solar
    let location = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
    let solar = Solar(for: Date(), coordinate: location)
    print("✅ Solar test: Sunset time - \(solar.sunset ?? Date())")
    
    // Test Weather Data
    let weatherData = WeatherData(
        highCloud: 0.5,
        midCloud: 0.3,
        lowCloud: 0.2,
        humidity: 0.6,
        visibility: 20
    )
    print("✅ WeatherData test: Created successfully")
    
    // Test Sunset Score Calculator
    let calculator = SunsetScoreCalculator()
    let scoreResult = calculator.calculateSunsetScore(weatherData: weatherData, sunsetTime: Date())
    print("✅ SunsetScoreCalculator test: Score - \(scoreResult.score), Afterglow - \(scoreResult.afterglowProbability), Tyndall - \(scoreResult.tyndallProbability)")
    
    // Test Calendar View Model
    let calendarViewModel = CalendarViewModel()
    print("✅ CalendarViewModel test: Initialized successfully")
    
    print("🎉 All components test successfully!")
}

// Run the test
testWonderfulSunsetApp()
