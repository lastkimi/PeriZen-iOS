import SwiftUI

@main
struct PostureGuardiOSApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                    .onAppear {
                        // Pre-warm taptic engines
                        _ = HapticManager.shared
                        
                        // Prevent screen dimming when the app is foregrounded
                        UIApplication.shared.isIdleTimerDisabled = true
                    }
                    .onDisappear {
                        UIApplication.shared.isIdleTimerDisabled = false
                    }
                
                if !hasSeenOnboarding {
                    OnboardingView(isPresented: Binding(
                        get: { !hasSeenOnboarding },
                        set: { hasSeenOnboarding = !$0 }
                    ))
                    .zIndex(1)
                }
            }
        }
    }
}
