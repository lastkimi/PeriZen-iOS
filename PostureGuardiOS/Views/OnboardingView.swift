import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 60) {
                Spacer()
                
                // Minimalist ring visualization for the onboarding
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 2)
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .stroke(Color(red: 0.0, green: 1.0, blue: 0.5), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .blur(radius: 8) // Symbolizes ambient glow
                        .opacity(0.6)
                }
                .padding(.bottom, 20)
                
                VStack(spacing: 24) {
                    Text("onboarding_title")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(4)
                    
                    Text("onboarding_body")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("onboarding_button")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                        .frame(width: 200, height: 50)
                        .background(Color.white)
                        .cornerRadius(25)
                }
                .padding(.bottom, 60)
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 1.5)) {
                    opacity = 1.0
                }
            }
        }
    }
}
