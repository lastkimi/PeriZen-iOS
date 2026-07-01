import SwiftUI

// MARK: - Zen Session View
/// Single player Zen mode view. Handles calibration overlay and main focus UI.
struct ZenSessionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var session = SessionState.shared
    @ObservedObject var engine = PostureEngine.shared
    
    @State private var showSummary = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Main Focus UI
            VStack {
                Spacer()
                
                // The Breathing Ring with Embedded Timer
                BreathingRingView(postureState: engine.postureState, ringSize: 260)
                    .overlay(
                        VStack(spacing: 8) {
                            if session.phase == .running || session.phase == .paused {
                                let hours = session.timeRemaining / 3600
                                let minutes = (session.timeRemaining % 3600) / 60
                                let seconds = session.timeRemaining % 60
                                
                                if hours > 0 {
                                    Text(String(format: "%02d:%02d:%02d", hours, minutes, seconds))
                                        .font(.system(size: 32, weight: .light, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                } else {
                                    Text(String(format: "%02d:%02d", minutes, seconds))
                                        .font(.system(size: 36, weight: .light, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Text(statusText)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(statusColor)
                            }
                        }
                    )
                    .padding(.bottom, 40)
                
                Spacer()
                
                // Exit Button
                if session.phase == .running || session.phase == .paused {
                    Button(action: {
                        HapticManager.shared.severeWarning()
                        session.endSession()
                    }) {
                        Text("session_end_button")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 120, height: 44)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(22)
                    }
                    .padding(.bottom, 40)
                }
            }
            
            // Calibration Overlay
            if session.phase == .calibrating {
                CalibrationOverlay {
                    session.onCalibrationComplete()
                }
                
                VStack {
                    HStack {
                        Button(action: {
                            session.resetSession()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(.white)
                                .padding()
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.leading, 10)
            }
        }
        .onAppear {
            // Start at normal brightness for calibration
            UIScreen.main.brightness = 0.5
        }
        .onDisappear {
            // Restore brightness when leaving completely
            UIScreen.main.brightness = 0.5
            if session.phase != .finished && session.phase != .idle {
                session.resetSession()
            }
        }
        .onChange(of: session.phase) { newPhase in
            if newPhase == .running {
                // Dim screen only after calibration is done
                UIScreen.main.brightness = 0.15
            } else if newPhase == .finished {
                // Restore brightness for summary
                UIScreen.main.brightness = 0.5
                showSummary = true
            }
        }
        // Dismiss self when summary is dismissed to prevent getting stuck
        .fullScreenCover(isPresented: $showSummary, onDismiss: {
            presentationMode.wrappedValue.dismiss()
        }) {
            SessionSummaryView()
        }
    }
    
    // MARK: - Dynamic Text Logic
    private var statusText: LocalizedStringKey {
        switch engine.postureState {
        case .focusing:
            return "status_zen_focusing"
        case .wobble:
            return "status_zen_wobble"
        case .away, .out:
            return "status_zen_away"
        }
    }
    
    private var statusColor: Color {
        switch engine.postureState {
        case .focusing:
            return .white.opacity(0.8)
        case .wobble:
            return Color(red: 1.0, green: 0.4, blue: 0.2) // brighter red/orange
        case .away, .out:
            return .white // pure white for maximum visibility
        }
    }
}
