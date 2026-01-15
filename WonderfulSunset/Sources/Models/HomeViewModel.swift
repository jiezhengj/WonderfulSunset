import Foundation
import SwiftUI
import CoreLocation

import Combine

class HomeViewModel: ObservableObject {
    
    @Published var currentLocation: CLLocation?
    @Published var sunsetScore: Int = 0
    @Published var sunsetTime: Date?
    @Published var goldenHourTime: Date?
    @Published var blueHourTime: Date?
    @Published var 感性文案: String = ""
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    
    private let locationService = LocationService()
    private let weatherService = WeatherDataService()
    private let scoreCalculator = SunsetScoreCalculator()
    
    init() {
        // Start location updates
        locationService.startUpdatingLocation()
        
        // Observe location changes
        locationService.$currentLocation
            .sink { [weak self] location in
                if let location = location {
                    self?.currentLocation = location
                    self?.calculateSunTimes()
                    self?.fetchWeatherData()
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func calculateSunTimes() {
        guard let location = currentLocation else { return }
        
        let solar = Solar(for: Date(), coordinate: location.coordinate)
        
        // Calculate sunset time
        sunsetTime = solar.sunset
        
        // Calculate golden hour (sunset - 1 hour to sunset)
        goldenHourTime = sunsetTime?.addingTimeInterval(-3600)
        
        // Calculate blue hour (sunset + 20 minutes to sunset + 40 minutes)
        blueHourTime = sunsetTime?.addingTimeInterval(1200)
    }
    
    func fetchWeatherData() {
        guard let location = currentLocation else { return }
        
        isLoading = true
        errorMessage = nil
        
        weatherService.getHourlyForecast(for: location) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let forecast):
                    self?.calculateSunsetScore(forecast: forecast)
                case .failure(let error):
                    self?.errorMessage = "Failed to fetch weather data: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func calculateSunsetScore(forecast: [CodableForecast]) {
        guard let sunsetTime = sunsetTime else { return }
        
        // Find forecast data around sunset time
        let sunsetHour = Calendar.current.component(.hour, from: sunsetTime)
        let sunsetMinute = Calendar.current.component(.minute, from: sunsetTime)
        
        // Filter forecast for the hour containing sunset and the next hour
        let relevantForecasts = forecast.filter { forecast in
            let forecastHour = Calendar.current.component(.hour, from: forecast.date)
            return forecastHour == sunsetHour || forecastHour == sunsetHour + 1
        }
        
        guard relevantForecasts.count >= 2 else {
            errorMessage = "Insufficient weather data for calculation"
            return
        }
        
        // Calculate weighted average of weather data in a single pass
        let highCloudValues = relevantForecasts.map { $0.cloudCover }
        let midCloudValues = relevantForecasts.map { $0.cloudCover * 0.5 }
        let lowCloudValues = relevantForecasts.map { $0.cloudCover * 0.3 }
        let humidityValues = relevantForecasts.map { $0.humidity }
        let visibilityValues = relevantForecasts.map { $0.visibility }
        
        // Calculate weighted averages
        let highCloud = calculateWeightedAverage(highCloudValues, sunsetMinute: sunsetMinute)
        let midCloud = calculateWeightedAverage(midCloudValues, sunsetMinute: sunsetMinute)
        let lowCloud = calculateWeightedAverage(lowCloudValues, sunsetMinute: sunsetMinute)
        let humidity = calculateWeightedAverage(humidityValues, sunsetMinute: sunsetMinute)
        let visibility = calculateWeightedAverage(visibilityValues, sunsetMinute: sunsetMinute)
        
        // Create weather data object
        let weatherData = WeatherData(
            highCloud: highCloud,
            midCloud: midCloud,
            lowCloud: lowCloud,
            humidity: humidity,
            visibility: visibility
        )
        
        // Calculate sunset score
        let scoreResult = scoreCalculator.calculateSunsetScore(weatherData: weatherData, sunsetTime: sunsetTime)
        
        // Update UI
        sunsetScore = scoreResult.score
       感性文案 = scoreResult.感性文案
    }
    
    private func calculateWeightedAverage(_ values: [Double], sunsetMinute: Int) -> Double {
        guard values.count >= 2 else { return values.first ?? 0 }
        
        let w1 = Double(60 - sunsetMinute) / 60.0
        let w2 = Double(sunsetMinute) / 60.0
        
        return values[0] * w1 + values[1] * w2
    }
    
    func getCountdownText() -> String {
        guard let goldenHourTime = goldenHourTime else { return "Calculating..." }
        
        let now = Date()
        let timeInterval = goldenHourTime.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "黄金时刻已过"
        }
        
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        
        return String(format: "距离黄金时刻还有 %02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func getBackgroundGradient() -> LinearGradient {
        let colors: [Color]
        
        switch sunsetScore {
        case 80...100:
            colors = [Color(hex: "#FF4500"), Color(hex: "#4B0082")] // 浓缩橘到深紫
        case 50..<80:
            colors = [Color(hex: "#FFB6C1"), Color(hex: "#87CEEB")] // 浅粉到湖蓝
        default:
            colors = [Color(hex: "#708090"), Color(hex: "#2F4F4F")] // 灰蓝到深蓝
        }
        
        return LinearGradient(gradient: Gradient(colors: colors), startPoint: .top, endPoint: .bottom)
    }
}

// Helper extension for Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}