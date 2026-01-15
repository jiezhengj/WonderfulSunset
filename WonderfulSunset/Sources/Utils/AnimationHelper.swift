import Foundation
import SwiftUI
import CoreMotion
import AVFoundation

#if os(iOS)
import UIKit
#endif

class AnimationHelper {
    
    static let shared = AnimationHelper()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    // MARK: - Sound Effects
    
    func playSelectionSound() {
        playSound(named: "selection_click")
    }
    
    func playSound(named soundName: String) {
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.volume = 0.2 // Very low volume for subtle effect
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Haptic Feedback
    
    func triggerSelectionFeedback() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }
    
    func triggerImpactFeedback(style: Int = 0) {
        #if os(iOS)
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle = style == 0 ? .medium : style == 1 ? .light : .heavy
        let generator = UIImpactFeedbackGenerator(style: uiStyle)
        generator.impactOccurred()
        #endif
    }
    
    func triggerNotificationFeedback(type: Int = 0) {
        #if os(iOS)
        let uiType: UINotificationFeedbackGenerator.FeedbackType = type == 0 ? .success : type == 1 ? .warning : .error
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(uiType)
        #endif
    }
    
    // MARK: - Animation Timing
    
    func getAnimationDuration(for scoreChange: Int) -> Double {
        // Longer duration for larger score changes
        return min(1.0, Double(abs(scoreChange)) * 0.02 + 0.3)
    }
    
    // MARK: - Gradient Animation
    
    func getGradientColors(for score: Int) -> [Color] {
        switch score {
        case 80...100:
            return [Color(hex: "#FF4500"), Color(hex: "#4B0082")] // 浓缩橘到深紫
        case 50..<80:
            return [Color(hex: "#FFB6C1"), Color(hex: "#87CEEB")] // 浅粉到湖蓝
        default:
            return [Color(hex: "#708090"), Color(hex: "#2F4F4F")] // 灰蓝到深蓝
        }
    }
    
    // MARK: - AR Overlay Animation
    
    func getAROverlayScale(for distance: Double) -> CGFloat {
        // Scale overlay based on distance to target
        let normalizedDistance = min(distance / 30, 1.0) // Normalize distance to 0-1
        return 1.0 - (normalizedDistance * 0.5) // Scale down as distance increases
    }
    
    func getAROverlayOpacity(for distance: Double) -> Double {
        // Fade overlay based on distance to target
        let normalizedDistance = min(distance / 30, 1.0) // Normalize distance to 0-1
        return 1.0 - (normalizedDistance * 0.8) // Fade out as distance increases
    }
}

// MARK: - View Modifiers

extension View {
    
    func withSelectionFeedback() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                AnimationHelper.shared.triggerSelectionFeedback()
                AnimationHelper.shared.playSelectionSound()
            }
        )
    }
    
    func withFluidGradient(score: Int, animate: Bool = true) -> some View {
        self.background(
            LinearGradient(
                gradient: Gradient(colors: AnimationHelper.shared.getGradientColors(for: score)),
                startPoint: .top,
                endPoint: .bottom
            )
            .animation(
                animate ? Animation.easeInOut(duration: 1.0) : nil,
                value: score
            )
        )
    }
    
    func withBreathingAnimation(duration: Double = 2.0) -> some View {
        self.animation(
            Animation.easeInOut(duration: duration)
                .repeatForever(autoreverses: true),
            value: UUID()
        )
    }
}

// MARK: - Particle System

struct ParticleSystemView: View {
    
    @State private var particles: [Particle] = []
    @State private var isAnimating: Bool = false
    
    let particleCount: Int = 50
    let duration: Double = 2.0
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: isAnimating) { newValue in
            if newValue {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        // Reset particles
        resetParticles()
        
        // Animate particles
        for i in 0..<particles.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                withAnimation(Animation.easeOut(duration: duration)) {
                    particles[i].animate()
                }
            }
        }
        
        // Stop animation after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            isAnimating = false
        }
    }
    
    private func resetParticles() {
        var newParticles: [Particle] = []
        for _ in 0..<particleCount {
            newParticles.append(Particle())
        }
        particles = newParticles
    }
}

struct Particle: Identifiable {
    let id = UUID()
    #if os(iOS)
    var x: CGFloat = UIScreen.main.bounds.width / 2
    var y: CGFloat = UIScreen.main.bounds.height / 2
    #else
    var x: CGFloat = 300
    var y: CGFloat = 400
    #endif
    var size: CGFloat = CGFloat.random(in: 5...15)
    var color: Color = Color.random()
    var opacity: Double = 1.0
    
    mutating func animate() {
        let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
        let distance = CGFloat.random(in: 50...200)
        
        x += cos(angle) * distance
        y += sin(angle) * distance
        size *= 0.5
        opacity = 0.0
    }
}

extension Color {
    static func random() -> Color {
        return Color(
            red: Double.random(in: 0.5...1.0),
            green: Double.random(in: 0.0...0.5),
            blue: Double.random(in: 0.5...1.0),
            opacity: 1.0
        )
    }
}