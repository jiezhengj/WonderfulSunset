import Foundation
import CoreLocation

struct WeatherData {
    let highCloud: Double // 0.0-1.0
    let midCloud: Double  // 0.0-1.0
    let lowCloud: Double  // 0.0-1.0
    let humidity: Double  // 0.0-1.0
    let visibility: Double // km
}

struct SunsetScoreResult {
    let score: Int
    let afterglowProbability: Double
    let tyndallProbability: Double
    let 感性文案: String
}

class SunsetScoreCalculator {
    
    // 计算晚霞指数
    func calculateScore(weatherData: WeatherData) -> Int {
        let Ch = weatherData.highCloud
        let Cm = weatherData.midCloud
        let Cl = weatherData.lowCloud
        let H = weatherData.humidity
        let V = weatherData.visibility
        
        // 计算基础分数
        let cloudFactor = (Ch * 0.5 + Cm * 0.1) * (1 - Cl)
        let humidityFactor = (1.2 - H)
        let visibilityFactor = min(V / 20, 1.2)
        
        let rawScore = cloudFactor * humidityFactor * visibilityFactor * 100
        return Int(round(rawScore))
    }
    
    // 计算特殊现象概率
    func calculateSpecialPhenomena(weatherData: WeatherData, sunsetTime: Date) -> (afterglow: Double, tyndall: Double) {
        let Ch = weatherData.highCloud
        let Cm = weatherData.midCloud
        let Cl = weatherData.lowCloud
        let H = weatherData.humidity
        let V = weatherData.visibility
        let totalCloud = Ch + Cm + Cl
        
        // 反霞概率
        var afterglowProbability: Double = 0
        if Cl < 0.05 && V > 30 && Ch > 0.5 {
            afterglowProbability = Ch * 100
        }
        
        // 丁达尔效应概率
        var tyndallProbability: Double = 0
        if 0.3 < totalCloud && totalCloud < 0.7 && H > 0.7 {
            let cloudDeviation = abs(totalCloud - 0.55)
            tyndallProbability = (1 - cloudDeviation) * H * 100
        }
        
        return (afterglowProbability, tyndallProbability)
    }
    
    // 计算时间加权平均 (with array input)
    func calculateWeightedAverage(_ values: [Double], sunsetMinute: Int) -> Double {
        guard values.count >= 2 else { return values.first ?? 0 }
        
        let W1 = Double(60 - sunsetMinute) / 60.0
        let W2 = Double(sunsetMinute) / 60.0
        
        return values[0] * W1 + values[1] * W2
    }
    
    // 计算时间加权平均 (with individual values)
    func calculateWeightedAverage(data1: Double, data2: Double, sunsetMinute: Int) -> Double {
        let W1 = Double(60 - sunsetMinute) / 60.0
        let W2 = Double(sunsetMinute) / 60.0
        return data1 * W1 + data2 * W2
    }
    
    // 检测低云量突增
    func detectLowCloudIncrease(startLowCloud: Double, endLowCloud: Double) -> Bool {
        let delta = endLowCloud - startLowCloud
        return delta > 0.2 // 突增超过20%
    }
    
    // 获取感性文案
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
    
    // 计算综合结果
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