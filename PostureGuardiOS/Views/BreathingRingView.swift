import SwiftUI

// MARK: - Breathing Ring View (V1.2 Stacked Bloom)
/// A highly premium glowing ring utilizing stacked blurs and screen blend modes.
struct BreathingRingView: View {
    let postureState: PostureState
    let ringSize: CGFloat
    
    // Animation states
    @State private var phase: Double = 0.0
    @State private var warningFlicker: Double = 1.0
    
    // Premium Colors
    private var baseColor: Color {
        switch postureState {
        case .focusing: return Color(red: 0.0, green: 1.0, blue: 0.5) // Vivid Emerald
        case .wobble:   return Color(red: 1.0, green: 0.3, blue: 0.0) // Danger Orange/Red
        default:        return Color(white: 0.2) // Inactive Grey
        }
    }
    
    var body: some View {
        ZStack {
            // Layer 1: Huge ambient spread (Background Bloom)
            Circle()
                .fill(baseColor)
                .frame(width: ringSize, height: ringSize)
                .blur(radius: 80)
                .opacity(postureState == .focusing ? (0.15 + (sin(phase) * 0.1)) : 0.05)
            
            // Layer 2: Core Glow
            Circle()
                .strokeBorder(baseColor, lineWidth: 8)
                .frame(width: ringSize, height: ringSize)
                .blur(radius: 20)
                .opacity(postureState == .focusing ? (0.6 + (sin(phase) * 0.3)) : 0.2)
            
            // Layer 3: Intense inner ring (The solid core)
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            baseColor.opacity(1.0),
                            baseColor.opacity(0.3),
                            baseColor.opacity(1.0)
                        ]),
                        center: .center,
                        angle: .degrees(phase * 30) // Subtle rotation
                    ),
                    style: StrokeStyle(lineWidth: 3.0, lineCap: .round)
                )
                .frame(width: ringSize - 16, height: ringSize - 16)
                .opacity(postureState == .focusing ? (0.8 + (sin(phase) * 0.2)) : 0.5)
            
            // Layer 4: Warning Flicker Overlay (Only visible in wobble state)
            if postureState == .wobble {
                Circle()
                    .stroke(Color.red, lineWidth: 6)
                    .frame(width: ringSize - 16, height: ringSize - 16)
                    .blur(radius: 5)
                    .opacity(warningFlicker)
            }
        }
        .onAppear { startSineAnimation() }
        .onChange(of: postureState) { _ in startSineAnimation() }
    }
    
    private func startSineAnimation() {
        withAnimation(.none) {
            phase = 0
            warningFlicker = 1.0
        }
        
        switch postureState {
        case .focusing:
            // Smooth Sine-wave based breathing (3 seconds per full cycle)
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        case .wobble:
            // Fast nervous flicker
            withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                warningFlicker = 0.2
            }
        default:
            break
        }
    }
}
