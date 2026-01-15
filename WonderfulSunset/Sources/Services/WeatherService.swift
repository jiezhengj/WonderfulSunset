import Foundation
import CoreLocation

class WeatherDataService {
    private let cacheKey = "WeatherKitHourlyForecastCache"
    private let cacheExpiryKey = "WeatherKitCacheExpiry"
    
    func getHourlyForecast(for location: CLLocation, completion: @escaping (Result<[CodableForecast], Error>) -> Void) {
        // Check if cached data is available and not expired
        if let cachedForecast = getCachedForecast() {
            completion(.success(cachedForecast))
            // In a real app, we would refresh in background
            return
        }
        
        // For testing, return mock data
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
    
    private func getCachedForecast(ignoreExpiry: Bool = false) -> [CodableForecast]? {
        // Check if cache is expired
        if !ignoreExpiry {
            let expiryTime = UserDefaults.standard.double(forKey: cacheExpiryKey)
            let currentTime = Date().timeIntervalSince1970
            // Cache expires after 60 minutes
            if currentTime - expiryTime > 3600 {
                return nil
            }
        }
        
        // Get cached data
        if let encoded = UserDefaults.standard.data(forKey: cacheKey) {
            if let decoded = try? JSONDecoder().decode([CodableForecast].self, from: encoded) {
                return decoded
            }
        }
        return nil
    }
    
    // Clear cached data
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheExpiryKey)
    }
}

// Helper struct for encoding/decoding forecast data
struct CodableForecast: Codable {
    let date: Date
    let temperature: Double
    let cloudCover: Double
    let humidity: Double
    let visibility: Double
    let condition: String
}