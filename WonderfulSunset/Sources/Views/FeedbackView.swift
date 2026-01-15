import SwiftUI
import CoreLocation
import UIKit

struct FeedbackView: View {
    
    @StateObject private var viewModel = FeedbackViewModel()
    @EnvironmentObject private var appState: AppState
    
    let predictedScore: Int
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#FFA07A"), Color(hex: "#FF6347")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Success particles effect
            if viewModel.showSuccess {
                HeartParticlesView()
            }
            
            if viewModel.isSubmitting {
                // Loading indicator
                VStack {
                    ProgressView("Submitting feedback...")
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
                        // Retry logic
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
                .padding()
            } else if !viewModel.hasiCloudAccount {
                // iCloud account required
                VStack {
                    Text("请登录 iCloud 以参与社区反馈")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("打开设置") {
                        // Open settings
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
                .padding()
            } else {
                // Main content
                VStack(spacing: 24) {
                    // Title
                    Text("实验室 / 反馈")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    // Feedback question
                    Text("准吗？")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Feedback options
                    HStack(spacing: 16) {
                        feedbackButton(
                            title: "绝美",
                            englishTitle: "Stunning",
                            isSelected: viewModel.selectedFeedback == "Perfect",
                            action: {
                                viewModel.selectedFeedback = "Perfect"
                                viewModel.selectedFlipReason = nil
                            }
                        )
                        
                        feedbackButton(
                            title: "名不虚传",
                            englishTitle: "Good",
                            isSelected: viewModel.selectedFeedback == "Good",
                            action: {
                                viewModel.selectedFeedback = "Good"
                                viewModel.selectedFlipReason = nil
                            }
                        )
                        
                        feedbackButton(
                            title: "并不准",
                            englishTitle: "Not Accurate",
                            isSelected: viewModel.selectedFeedback == "Flipped",
                            action: {
                                viewModel.selectedFeedback = "Flipped"
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Flip reason options
                    if viewModel.selectedFeedback == "Flipped" {
                        VStack(spacing: 12) {
                            Text("请选择原因：")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 8) {
                                ForEach(viewModel.getFlipReasons(), id: \.self) { reason in
                                    flipReasonButton(
                                        title: viewModel.getFlipReasonDescription(reason: reason),
                                        isSelected: viewModel.selectedFlipReason == reason,
                                        action: {
                                            viewModel.selectedFlipReason = reason
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    // Submit button
                    Button("提交反馈") {
                        guard let feedback = viewModel.selectedFeedback else {
                            viewModel.errorMessage = "请选择反馈类型"
                            return
                        }
                        
                        guard let location = appState.currentLocation else {
                            viewModel.errorMessage = "无法获取位置信息"
                            return
                        }
                        
                        var flipReason: String? = nil
                        if feedback == "Flipped" {
                            flipReason = viewModel.selectedFlipReason
                            guard flipReason != nil else {
                                viewModel.errorMessage = "请选择具体原因"
                                return
                            }
                        }
                        
                        viewModel.submitFeedback(
                            location: location,
                            predictedScore: predictedScore,
                            feedback: feedback,
                            flipReason: flipReason
                        ) {
                            // Completion handler
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        (viewModel.selectedFeedback != nil && 
                         (viewModel.selectedFeedback != "Flipped" || viewModel.selectedFlipReason != nil)) ? 
                        Color.white.opacity(0.3) : Color.white.opacity(0.1)
                    )
                    .cornerRadius(8)
                    .disabled(
                        viewModel.selectedFeedback == nil || 
                        (viewModel.selectedFeedback == "Flipped" && viewModel.selectedFlipReason == nil)
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func feedbackButton(title: String, englishTitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(englishTitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(16)
            .background(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
            .cornerRadius(12)
            .flexibleFrame()
        }
    }
    
    private func flipReasonButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(12)
            .background(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// Heart particles view
struct HeartParticlesView: View {
    @State private var particles: [HeartParticle] = []
    @State private var isAnimating: Bool = true
    
    private let particleCount: Int = 20
    
    init() {
        // Initialize particles
        var initialParticles: [HeartParticle] = []
        for _ in 0..<particleCount {
            initialParticles.append(HeartParticle())
        }
        particles = initialParticles
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                HeartShape()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.pink, .red]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
                    .animation(
                        Animation.easeOut(duration: 0.5)
                            .repeatForever(autoreverses: false),
                        value: particle
                    )
            }
        }
        .onAppear {
            animateParticles()
        }
    }
    
    private func animateParticles() {
        guard isAnimating else { return }
        
        // Reset particles
        for i in 0..<particles.count {
            particles[i].reset()
        }
        
        // Animate particles
        for i in 0..<particles.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation {
                    particles[i].animate()
                }
            }
        }
        
        // Repeat animation after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            animateParticles()
        }
    }
}

// Heart shape
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Start at the top center
        path.move(to: CGPoint(x: width / 2, y: height * 0.2))
        
        // Left side
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.6),
            control1: CGPoint(x: width / 4, y: height * 0.1),
            control2: CGPoint(x: 0, y: height * 0.4)
        )
        
        // Bottom
        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            control1: CGPoint(x: 0, y: height * 0.8),
            control2: CGPoint(x: width / 4, y: height)
        )
        
        // Right side
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.6),
            control1: CGPoint(x: width * 3 / 4, y: height),
            control2: CGPoint(x: width, y: height * 0.8)
        )
        
        // Back to top
        path.addCurve(
            to: CGPoint(x: width / 2, y: height * 0.2),
            control1: CGPoint(x: width, y: height * 0.4),
            control2: CGPoint(x: width * 3 / 4, y: height * 0.1)
        )
        
        return path
    }
}
// Particle model
struct HeartParticle: Identifiable, Equatable {
    let id = UUID()
    #if os(iOS)
    var x: CGFloat = UIScreen.main.bounds.width / 2
    var y: CGFloat = UIScreen.main.bounds.height / 2
    #else
    var x: CGFloat = 300
    var y: CGFloat = 400
    #endif
    var size: CGFloat = 20
    var opacity: Double = 1.0
    
    mutating func reset() {
        #if os(iOS)
        x = UIScreen.main.bounds.width / 2
        y = UIScreen.main.bounds.height / 2
        #else
        x = 300
        y = 400
        #endif
        size = CGFloat.random(in: 10...20)
        opacity = 1.0
    }
    
    mutating func animate() {
        let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
        let distance = CGFloat.random(in: 50...150)
        
        x += cos(angle) * distance
        y += sin(angle) * distance
        size *= 0.5
        opacity = 0.0
    }
}
struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView(predictedScore: 85)
            .environmentObject(AppState())
    }
}