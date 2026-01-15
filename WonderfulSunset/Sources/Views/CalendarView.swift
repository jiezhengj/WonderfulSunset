import SwiftUI
import CoreLocation


struct CalendarView: View {
    
    @StateObject private var viewModel = CalendarViewModel()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#90EE90"), Color(hex: "#4682B4")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading {
                // Loading indicator
                VStack {
                    ProgressView("Loading forecast data...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            } else if let errorMessage = viewModel.errorMessage {
                // Error message
                VStack {
                    Text("Error")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        fetchForecasts()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
                .padding()
            } else {
                // Main content
                VStack {
                    // Title
                    Text("追霞日历")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                    
                    // Notification permission banner
                    if !viewModel.hasPermission {
                        HStack {
                            Text("启用通知，不错过任何一次晚霞机会")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            Spacer()
                            Button("允许") {
                                viewModel.requestNotificationPermission { granted in
                                    if granted {
                                        // Permission granted, no need to show banner anymore
                                    }
                                }
                            }
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                    
                    // Daily forecast cards
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.dailyForecasts) { forecast in
                                dailyForecastCard(forecast: forecast)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            fetchForecasts()
        }
    }
    
    private func fetchForecasts() {
        guard let location = appState.currentLocation else { return }
        viewModel.fetchDailyForecasts(for: location, days: 7) {
            // Completion handler
        }
    }
    
    private func dailyForecastCard(forecast: DailyForecast) -> some View {
        VStack(spacing: 12) {
            // Date and day
            HStack {
                VStack(alignment: .leading) {
                    Text(formatDate(forecast.date))
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(formatDay(forecast.date))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                
                // Sunset time
                Text(formatTime(forecast.sunsetTime))
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Score and感性文案
            HStack(alignment: .center) {
                Text("\(forecast.score)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 80)
                
                VStack(alignment: .leading) {
                    Text(getScoreDescription(forecast.score))
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    // Special phenomena
                    if forecast.afterglowProbability > 0 || forecast.tyndallProbability > 0 {
                        HStack(spacing: 10) {
                            if forecast.afterglowProbability > 0 {
                                Text("反霞: \(Int(round(forecast.afterglowProbability)))%")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            if forecast.tyndallProbability > 0 {
                                Text("丁达尔: \(Int(round(forecast.tyndallProbability)))%")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
                .flexibleFrame()
                
                // Reminder button
                Button(action: {
                    if !viewModel.hasPermission {
                        viewModel.requestNotificationPermission { granted in
                            if granted {
                                viewModel.toggleReminder(for: forecast)
                            }
                        }
                    } else {
                        viewModel.toggleReminder(for: forecast)
                    }
                }) {
                    Image(systemName: forecast.isReminderSet ? "bell.fill" : "bell")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(forecast.isReminderSet ? Color(hex: "#FFD700") : .white)
                        .padding(12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: date)
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func getScoreDescription(_ score: Int) -> String {
        switch score {
        case 80...100:
            return "大概率出现火烧云，建议准备好相机"
        case 50..<80:
            return "云层适中，或许会有温柔的粉色邂逅"
        default:
            return "天空稍显沉闷，适合在室内静候下一次惊喜"
        }
    }
}

// Helper extension for flexible frame
extension View {
    func flexibleFrame() -> some View {
        self.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .environmentObject(AppState())
    }
}