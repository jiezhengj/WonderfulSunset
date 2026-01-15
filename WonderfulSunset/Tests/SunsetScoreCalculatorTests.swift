import Foundation

final class SunsetScoreCalculatorTests {
    
    var calculator: SunsetScoreCalculator!
    
    func setUp() {
        calculator = SunsetScoreCalculator()
    }
    
    func tearDown() {
        calculator = nil
    }
    
    func testCalculateScore_HighScore() {
        // Test case for high sunset score
        let weatherData = WeatherData(
            highCloud: 0.8,
            midCloud: 0.2,
            lowCloud: 0.0,
            humidity: 0.4,
            visibility: 40
        )
        
        let score = calculator.calculateScore(weatherData: weatherData)
        assert(score >= 80, "Score should be high for favorable conditions")
    }
    
    func testCalculateScore_LowScore() {
        // Test case for low sunset score
        let weatherData = WeatherData(
            highCloud: 0.0,
            midCloud: 0.0,
            lowCloud: 1.0,
            humidity: 0.9,
            visibility: 1
        )
        
        let score = calculator.calculateScore(weatherData: weatherData)
        assert(score < 30, "Score should be low for unfavorable conditions")
    }
    
    func testCalculateScore_ModerateScore() {
        // Test case for moderate sunset score
        let weatherData = WeatherData(
            highCloud: 0.5,
            midCloud: 0.3,
            lowCloud: 0.2,
            humidity: 0.6,
            visibility: 20
        )
        
        let score = calculator.calculateScore(weatherData: weatherData)
        assert(score >= 40, "Score should be moderate for average conditions")
        assert(score < 70, "Score should be moderate for average conditions")
    }
    
    func testCalculateSpecialPhenomena_Afterglow() {
        // Test case for afterglow probability
        let weatherData = WeatherData(
            highCloud: 0.6,
            midCloud: 0.0,
            lowCloud: 0.0,
            humidity: 0.3,
            visibility: 35
        )
        
        let (afterglow, _) = calculator.calculateSpecialPhenomena(weatherData: weatherData, sunsetTime: Date())
        assert(afterglow > 0, "Afterglow probability should be greater than 0 for favorable conditions")
        assert(afterglow <= 100, "Afterglow probability should be less than or equal to 100")
    }
    
    func testCalculateSpecialPhenomena_Tyndall() {
        // Test case for tyndall effect probability
        let weatherData = WeatherData(
            highCloud: 0.2,
            midCloud: 0.2,
            lowCloud: 0.2,
            humidity: 0.8,
            visibility: 15
        )
        
        let (_, tyndall) = calculator.calculateSpecialPhenomena(weatherData: weatherData, sunsetTime: Date())
        assert(tyndall > 0, "Tyndall probability should be greater than 0 for favorable conditions")
        assert(tyndall <= 100, "Tyndall probability should be less than or equal to 100")
    }
    
    func testCalculateWeightedAverage() {
        // Test weighted average calculation
        let values = [10.0, 20.0]
        let sunsetMinute = 30 // 30 minutes past the hour
        
        let average = calculator.calculateWeightedAverage(values, sunsetMinute: sunsetMinute)
        assert(average == 15.0, "Weighted average should be 15.0 for equal weights")
    }
    
    func testCalculateWeightedAverage_Weighted() {
        // Test weighted average with different weights
        let values = [10.0, 20.0]
        let sunsetMinute = 45 // 45 minutes past the hour
        
        let average = calculator.calculateWeightedAverage(values, sunsetMinute: sunsetMinute)
        assert(average == 17.5, "Weighted average should be 17.5 for 25%/75% weights")
    }
    
    func testDetectLowCloudIncrease() {
        // Test low cloud increase detection
        let startLowCloud = 0.1
        let endLowCloud = 0.3
        
        let didIncrease = calculator.detectLowCloudIncrease(startLowCloud: startLowCloud, endLowCloud: endLowCloud)
        assert(didIncrease, "Should detect low cloud increase of more than 20%")
    }
    
    func testDetectLowCloudIncrease_NoIncrease() {
        // Test low cloud no increase detection
        let startLowCloud = 0.1
        let endLowCloud = 0.2
        
        let didIncrease = calculator.detectLowCloudIncrease(startLowCloud: startLowCloud, endLowCloud: endLowCloud)
        assert(!didIncrease, "Should not detect low cloud increase of less than 20%")
    }
    
    func testGet感性文案_HighScore() {
        // Test get感性文案 for high score
        let text = calculator.get感性文案(score: 90)
        assert(text.contains("火烧云"), "文案 should mention fire clouds for high score")
    }
    
    func testGet感性文案_ModerateScore() {
        // Test get感性文案 for moderate score
        let text = calculator.get感性文案(score: 60)
        assert(text.contains("粉色"), "文案 should mention pink for moderate score")
    }
    
    func testGet感性文案_LowScore() {
        // Test get感性文案 for low score
        let text = calculator.get感性文案(score: 30)
        assert(text.contains("沉闷"), "文案 should mention dull for low score")
    }
}