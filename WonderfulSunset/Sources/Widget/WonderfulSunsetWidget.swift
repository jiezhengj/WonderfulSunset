import SwiftUI
import WidgetKit
import CoreLocation

// Widget configuration
struct WonderfulSunsetWidget: Widget {
    let kind: String = "WonderfulSunsetWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SunsetTimelineProvider()) { entry in
            SunsetWidgetView(entry: entry)
        }
        .configurationDisplayName("Wonderful Sunset")
        .description("Track sunset scores and golden hour times")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Timeline provider
struct SunsetTimelineProvider: TimelineProvider {
    
    typealias Entry = SunsetWidgetEntry
    
    func placeholder(in context: Context) -> SunsetWidgetEntry {
        SunsetWidgetEntry(
            date: Date(),
            sunsetScore: 75,
            goldenHourTime: Date().addingTimeInterval(3600),
            sunsetTime: Date().addingTimeInterval(7200),
            blueHourTime: Date().addingTimeInterval(8400),
            location: CLLocation(latitude: 39.9042, longitude: 116.4074)
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SunsetWidgetEntry) -> Void) {
        // Get current location or use default
        let location = LocationService.shared.getCurrentLocation()
        
        // Calculate sun times
        let solar = Solar(for: Date(), coordinate: location.coordinate)
        
        let entry = SunsetWidgetEntry(
            date: Date(),
            sunsetScore: 75,
            goldenHourTime: solar.sunset?.addingTimeInterval(-3600) ?? Date(),
            sunsetTime: solar.sunset ?? Date(),
            blueHourTime: solar.sunset?.addingTimeInterval(1200) ?? Date(),
            location: location
        )
        
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SunsetWidgetEntry>) -> Void) {
        // Get current location or use default
        let location = LocationService.shared.getCurrentLocation()
        
        // Calculate sun times
        let solar = Solar(for: Date(), coordinate: location.coordinate)
        
        // Create current entry
        let currentEntry = SunsetWidgetEntry(
            date: Date(),
            sunsetScore: 75,
            goldenHourTime: solar.sunset?.addingTimeInterval(-3600) ?? Date(),
            sunsetTime: solar.sunset ?? Date(),
            blueHourTime: solar.sunset?.addingTimeInterval(1200) ?? Date(),
            location: location
        )
        
        // Create timeline entries for the next 24 hours
        var entries: [SunsetWidgetEntry] = [currentEntry]
        
        // Add entries for every 4 hours
        for hourOffset in 1...6 {
            let date = Date().addingTimeInterval(TimeInterval(hourOffset * 4 * 3600))
            let solar = Solar(for: date, coordinate: location.coordinate)
            
            let entry = SunsetWidgetEntry(
                date: date,
                sunsetScore: 75,
                goldenHourTime: solar.sunset?.addingTimeInterval(-3600) ?? date,
                sunsetTime: solar.sunset ?? date,
                blueHourTime: solar.sunset?.addingTimeInterval(1200) ?? date,
                location: location
            )
            
            entries.append(entry)
        }
        
        // Create timeline with refresh policy
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// Widget entry
struct SunsetWidgetEntry: TimelineEntry {
    let date: Date
    let sunsetScore: Int
    let goldenHourTime: Date
    let sunsetTime: Date
    let blueHourTime: Date
    let location: CLLocation
}

// Widget view
struct SunsetWidgetView: View {
    let entry: SunsetTimelineProvider.Entry
    
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallSunsetWidgetView(entry: entry)
        case .systemMedium:
            MediumSunsetWidgetView(entry: entry)
        default:
            SmallSunsetWidgetView(entry: entry)
        }
    }
}

// Small widget view
struct SmallSunsetWidgetView: View {
    let entry: SunsetTimelineProvider.Entry
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: AnimationHelper.shared.getGradientColors(for: entry.sunsetScore)),
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 8) {
                // Sunset score
                Text("\(entry.sunsetScore)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Golden hour countdown
                Text(getCountdownText())
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
    
    private func getCountdownText() -> String {
        let now = Date()
        let timeInterval = entry.goldenHourTime.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "Golden hour passed"
        }
        
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "Golden hour in \(hours)h \(minutes)m"
        } else {
            return "Golden hour in \(minutes)m"
        }
    }
}

// Medium widget view
struct MediumSunsetWidgetView: View {
    let entry: SunsetTimelineProvider.Entry
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: AnimationHelper.shared.getGradientColors(for: entry.sunsetScore)),
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 12) {
                // Sunset score
                Text("\(entry.sunsetScore)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Golden hour countdown
                Text(getCountdownText())
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                // Timeline
                HStack(spacing: 16) {
                    timePointView(title: "Golden Hour", time: entry.goldenHourTime)
                    timePointView(title: "Sunset", time: entry.sunsetTime)
                    timePointView(title: "Blue Hour", time: entry.blueHourTime)
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }
    
    private func getCountdownText() -> String {
        let now = Date()
        let timeInterval = entry.goldenHourTime.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "Golden hour passed"
        }
        
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "Golden hour in \(hours)h \(minutes)m"
        } else {
            return "Golden hour in \(minutes)m"
        }
    }
    
    private func timePointView(title: String, time: Date) -> some View {
        VStack {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.8))
            Text(formatTime(time))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// Preview provider
struct SunsetWidget_Previews: PreviewProvider {
    static var previews: some View {
        let entry = SunsetWidgetEntry(
            date: Date(),
            sunsetScore: 75,
            goldenHourTime: Date().addingTimeInterval(3600),
            sunsetTime: Date().addingTimeInterval(7200),
            blueHourTime: Date().addingTimeInterval(8400),
            location: CLLocation(latitude: 39.9042, longitude: 116.4074)
        )
        
        Group {
            SunsetWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            SunsetWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}