import SwiftUI
import CoreLocation
import CoreMotion
import AVFoundation

struct DeepDiveView: View {
    
    @StateObject private var viewModel = DeepDiveViewModel()
    @State private var selectedCloudLayer: CloudLayer?
    @State private var showARCompass: Bool = false
    @State private var heading: Double = 0
    
    let location: CLLocation
    let sunsetTime: Date
    
    enum CloudLayer {
        case high, mid, low
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#87CEEB"), Color(hex: "#4682B4")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading {
                // Loading indicator
                VStack {
                    ProgressView("Loading cloud data...")
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
                        viewModel.fetchWeatherData(for: location, sunsetTime: sunsetTime, completion: {})
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
                .padding()
            } else if showARCompass {
                // AR Compass view
                ARCompassView(heading: $heading)
                    .overlay(
                        Button(action: {
                            showARCompass = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                                .padding()
                        }
                        .position(x: UIScreen.main.bounds.width - 30, y: 50)
                    )
            } else {
                // Main content
                ScrollView {
                    VStack(spacing: 30) {
                        // Title
                        Text("深度分析")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 40)
                        
                        // Cloud layers chart
                        VStack(spacing: 20) {
                            Text("云层分析")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 30) {
                                cloudLayerView(
                                    value: viewModel.highCloud,
                                    title: "高云",
                                    color: Color(hex: "#FFB6C1"),
                                    layer: .high,
                                    selected: selectedCloudLayer == .high
                                )
                                
                                cloudLayerView(
                                    value: viewModel.midCloud,
                                    title: "中云",
                                    color: Color(hex: "#87CEEB"),
                                    layer: .mid,
                                    selected: selectedCloudLayer == .mid
                                )
                                
                                cloudLayerView(
                                    value: viewModel.lowCloud,
                                    title: "低云",
                                    color: Color(hex: "#708090"),
                                    layer: .low,
                                    selected: selectedCloudLayer == .low
                                )
                            }
                            .padding(.horizontal, 40)
                            
                            // Cloud layer explanation
                            Text(getCloudLayerExplanation())
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .padding(.top, 10)
                        }
                        
                        // Prediction cards
                        VStack(spacing: 20) {
                            Text("特殊现象预测")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                predictionCard(
                                    title: "反霞",
                                    probability: viewModel.afterglowProbability,
                                    color: Color(hex: "#9370DB")
                                )
                                
                                predictionCard(
                                    title: "丁达尔效应",
                                    probability: viewModel.tyndallProbability,
                                    color: Color(hex: "#FFD700")
                                )
                            }
                            .padding(.horizontal, 40)
                        }
                        
                        // AR compass
                        VStack(spacing: 20) {
                            Text("观赏方位")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ZStack {
                                // Compass background
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                    .frame(width: 200, height: 200)
                                
                                // Compass directions
                                CompassDirectionsView()
                                
                                // Needle
                                CompassNeedleView(heading: heading)
                            }
                            .padding()
                            
                            Button("实景引导") {
                                showARCompass = true
                                startHeadingUpdates()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchWeatherData(for: location, sunsetTime: sunsetTime, completion: {})
        }
    }
    
    private func cloudLayerView(value: Double, title: String, color: Color, layer: CloudLayer, selected: Bool) -> some View {
        Button(action: {
            selectedCloudLayer = selected ? nil : layer
        }) {
            VStack(spacing: 10) {
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: CGFloat(value))
                        .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    // Percentage text
                    Text("\(Int(round(value * 100)))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .padding(selected ? 10 : 0)
            .background(selected ? Color.white.opacity(0.2) : Color.clear)
            .cornerRadius(12)
        }
    }
    
    private func predictionCard(title: String, probability: Double, color: Color) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text("\(Int(round(probability)))%")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            // Breathing animation background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.3))
                    .frame(height: 10)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(width: CGFloat(probability) * 1.5, height: 10)
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                        value: probability
                    )
            }
            .frame(width: 120)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func startHeadingUpdates() {
        let locationManager = CLLocationManager()
        
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
            
            locationManager.headingFilter = 1.0
            
            locationManager.delegate = nil // In a real app, you would set a delegate
        }
    }
    
    private func getCloudLayerExplanation() -> String {
        guard let selectedLayer = selectedCloudLayer else {
            return ""
        }
        
        switch selectedLayer {
        case .high:
            return "高层云是彩霞的画布，越高颜色越鲜艳。"
        case .mid:
            return "中层云可以反射和散射阳光，创造出丰富的色彩层次。"
        case .low:
            return "低层云过多会遮挡阳光，影响晚霞的观赏效果。"
        }
    }
}

// Helper views for the compass
struct CompassDirectionsView: View {
    var body: some View {
        ZStack {
            VStack {
                Text("北")
                    .foregroundColor(.white)
                Spacer()
                Text("南")
                    .foregroundColor(.white)
            }
            .frame(width: 200, height: 200)
            
            HStack {
                Text("西")
                    .foregroundColor(.white)
                Spacer()
                Text("东")
                    .foregroundColor(.white)
            }
            .frame(width: 200, height: 200)
        }
    }
}

struct CompassNeedleView: View {
    let heading: Double
    
    var body: some View {
        Image(systemName: "arrow.up")
            .resizable()
            .frame(width: 20, height: 80)
            .foregroundColor(.white)
            .rotationEffect(.degrees(-heading))
    }
}

struct ARCompassView: View {
    @Binding var heading: Double
    
    var body: some View {
        ZStack {
            // Camera preview placeholder
            Color.black
                .ignoresSafeArea()
            
            // Horizon line
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 100, height: 100)
                        
                        Text("Sun Drop Here")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .padding(.bottom, 100)
            }
            
            // Compass overlay
            VStack {
                Text("AR引导")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                
                CompassNeedleView(heading: heading)
                    .padding()
            }
        }
    }
}

struct DeepDiveView_Previews: PreviewProvider {
    static var previews: some View {
        DeepDiveView(
            location: CLLocation(latitude: 39.9042, longitude: 116.4074), // Beijing
            sunsetTime: Date()
        )
    }
}