// Test compilation file for Wonderful Sunset app
// This file imports all necessary modules and verifies compilation

import Foundation
import CoreLocation
import SwiftUI
import UserNotifications

// Import all model files
@testable import WonderfulSunset

// Test that all types are accessible
func testCompilation() {
    // Test Solar struct
    let location = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
    let solar = Solar(for: Date(), coordinate: location)
    print("✅ Solar struct works:", solar.sunset ?? "No sunset time")
    
    // Test WeatherData struct
    let weatherData = WeatherData(
        highCloud: 0.5,
        midCloud: 0.3,
        lowCloud: 0.2,
        humidity: 0.6,
        visibility: 20
    )
    print("✅ WeatherData struct works")
    
    // Test SunsetScoreCalculator
    let calculator = SunsetScoreCalculator()
    let score = calculator.calculateScore(weatherData: weatherData)
    print("✅ SunsetScoreCalculator works, score:", score)
    
    // Test CalendarViewModel
    let calendarViewModel = CalendarViewModel()
    print("✅ CalendarViewModel works")
    
    print("🎉 All types compile successfully!")
}

// Run the test
testCompilation()
