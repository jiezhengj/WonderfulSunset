import SwiftUI
import CoreLocation
import Combine

class AppState: ObservableObject {
    @Published var currentLocation: CLLocation? = CLLocation(latitude: 39.9042, longitude: 116.4074) // Default: Beijing
    @Published var sunsetTime: Date? = Date()
    @Published var goldenHourTime: Date? = Date().addingTimeInterval(-3600)
    @Published var blueHourTime: Date? = Date().addingTimeInterval(1200)
    @Published var sunsetScore: Int = 0
}

struct ContentView: View {
    
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home - Forecast
            HomeView()
                .environmentObject(appState)
                .tag(0)
            
            // Deep Dive
            DeepDiveView(
                location: appState.currentLocation ?? CLLocation(latitude: 39.9042, longitude: 116.4074),
                sunsetTime: appState.sunsetTime ?? Date()
            )
            .environmentObject(appState)
            .tag(1)
            
            // Calendar
            CalendarView()
                .environmentObject(appState)
                .tag(2)
            
            // Lab & Feedback
            FeedbackView(predictedScore: appState.sunsetScore)
                .environmentObject(appState)
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}