import SwiftUI
import CoreLocation
import AVFoundation

// Import AnimationHelper
import Foundation

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var selectedTimeSegment: TimeSegment = .goldenHour
    
    enum TimeSegment {
        case goldenHour
        case sunset
        case blueHour
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: AnimationHelper.shared.getGradientColors(for: viewModel.sunsetScore)),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(Animation.easeInOut(duration: 1.0), value: viewModel.sunsetScore)
            
            if viewModel.isLoading {
                // Loading indicator
                VStack {
                    ProgressView("Calculating sunset score...")
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
                        viewModel.fetchWeatherData()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
                .padding()
            } else {
                // Main content
                VStack(spacing: 20) {
                    // Location and countdown
                    VStack {
                        Text("Current Location")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text(viewModel.getCountdownText())
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Sunset score
                    Text("\(viewModel.sunsetScore)")
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .animation(
                            Animation.easeInOut(duration: AnimationHelper.shared.getAnimationDuration(for: appState.sunsetScore - viewModel.sunsetScore)),
                            value: viewModel.sunsetScore
                        )
                    
                    //感性文案
                    Text(viewModel.感性文案)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Timeline
                    HStack(spacing: 40) {
                        timeSegmentButton(
                            title: "黄金时刻",
                            segment: .goldenHour,
                            selected: selectedTimeSegment == .goldenHour
                        )
                        
                        timeSegmentButton(
                            title: "日落时刻",
                            segment: .sunset,
                            selected: selectedTimeSegment == .sunset
                        )
                        
                        timeSegmentButton(
                            title: "魔幻时刻",
                            segment: .blueHour,
                            selected: selectedTimeSegment == .blueHour
                        )
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            // Update app state with sunset score
            appState.sunsetScore = viewModel.sunsetScore
            appState.sunsetTime = viewModel.sunsetTime
        }
        .onChange(of: viewModel.sunsetScore) { newValue in
            // Update app state when sunset score changes
            appState.sunsetScore = newValue
        }
    }
    
    private func timeSegmentButton(title: String, segment: TimeSegment, selected: Bool) -> some View {
        Button(action: {
            // Play haptic feedback and sound
            AnimationHelper.shared.triggerSelectionFeedback()
            AnimationHelper.shared.playSelectionSound()
            
            // Update selected segment
            selectedTimeSegment = segment
            
            // TODO: Update background gradient based on selected time segment score
        }) {
            Text(title)
                .font(.system(size: 16, weight: selected ? .bold : .medium))
                .foregroundColor(selected ? .white : .white.opacity(0.7))
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(selected ? Color.white.opacity(0.2) : Color.clear)
                .cornerRadius(20)
        }
        .withSelectionFeedback()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppState())
    }
}