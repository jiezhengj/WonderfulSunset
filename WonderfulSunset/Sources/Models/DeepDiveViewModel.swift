import Foundation
import SwiftUI
import CoreLocation
import Combine


class DeepDiveViewModel: ObservableObject {
    
    @Published var highCloud: Double = 0
    @Published var midCloud: Double = 0
    @Published var lowCloud: Double = 0
    @Published var afterglowProbability: Double = 0
    @Published var tyndallProbability: Double = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let weatherService = WeatherDataService()
    private let scoreCalculator = SunsetScoreCalculator()
    
    func fetchWeatherData(for location: CLLocation, sunsetTime: Date, completion: @escaping () -> Void) {
        isLoading = true
        errorMessage = nil
        
        weatherService.getHourlyForecast(for: location) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let forecast):
                    self?.calculateCloudData(forecast: forecast, sunsetTime: sunsetTime)
                    completion()
                case .failure(let error):
                    self?.errorMessage = "Failed to fetch weather data: \(error.localizedDescription)"
                    completion()
                }
            }
        }
    }
    
    private func calculateCloudData(forecast: [CodableForecast], sunsetTime: Date) {
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
        
        // Calculate weighted average of cloud data
        highCloud = calculateWeightedAverage(relevantForecasts.map { $0.cloudCover }, sunsetMinute: sunsetMinute)
        midCloud = calculateWeightedAverage(relevantForecasts.map { $0.cloudCover * 0.5 }, sunsetMinute: sunsetMinute)
        lowCloud = calculateWeightedAverage(relevantForecasts.map { $0.cloudCover * 0.3 }, sunsetMinute: sunsetMinute)
        
        // Calculate special phenomena probabilities
        let weatherData = WeatherData(
            highCloud: highCloud,
            midCloud: midCloud,
            lowCloud: lowCloud,
            humidity: calculateWeightedAverage(relevantForecasts.map { $0.humidity }, sunsetMinute: sunsetMinute),
            visibility: calculateWeightedAverage(relevantForecasts.map { $0.visibility }, sunsetMinute: sunsetMinute)
        )
        
        let (afterglow, tyndall) = scoreCalculator.calculateSpecialPhenomena(weatherData: weatherData, sunsetTime: sunsetTime)
        afterglowProbability = afterglow
        tyndallProbability = tyndall
    }
    
    private func calculateWeightedAverage(_ values: [Double], sunsetMinute: Int) -> Double {
        guard values.count >= 2 else { return values.first ?? 0 }
        
        let w1 = Double(60 - sunsetMinute) / 60.0
        let w2 = Double(sunsetMinute) / 60.0
        
        return values[0] * w1 + values[1] * w2
    }
}