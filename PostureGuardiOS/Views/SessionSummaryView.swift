import SwiftUI

// MARK: - Session Summary View
struct SessionSummaryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var session = SessionState.shared
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 4) {
                    Text("summary_end")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(.white)
                    
                    if let room = session.roomCode {
                        if room == "public" {
                            Text("ring_public_room")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        } else {
                            Text("\(Text("ring_private_room")) \(room)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    } else {
                        Text("mode_single")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Ring visualization
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(session.goodPostureRatio))
                        .stroke(
                            Color(red: 0.0, green: 1.0, blue: 0.5),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.5), value: session.goodPostureRatio)
                    
                    VStack {
                        Text("\(Int(session.goodPostureSeconds / 60))")
                            .font(.system(size: 48, weight: .ultraLight, design: .rounded))
                            .foregroundColor(.white)
                        Text("summary_minutes")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.vertical, 40)
                
                // Detailed Stats
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Text("\(Int(session.goodPostureRatio * 100))%")
                            .font(.system(size: 20, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.5))
                        Text("summary_ratio")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    VStack(spacing: 8) {
                        Text(String(format: NSLocalizedString("common_times", comment: ""), session.wobbleCount))
                            .font(.system(size: 20, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.0))
                        Text("summary_wobbles")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    VStack(spacing: 8) {
                        Text(String(format: NSLocalizedString("common_times", comment: ""), session.awayCount))
                            .font(.system(size: 20, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        Text("summary_aways")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // Save log
                    let log = SessionLog(
                        focusDuration: Double(session.elapsedFocusSeconds),
                        goodPostureDuration: Double(session.goodPostureSeconds),
                        wobbleDuration: Double(session.wobbleSeconds),
                        awayDuration: Double(session.awaySeconds),
                        wobbleCount: session.wobbleCount,
                        awayCount: session.awayCount,
                        mode: session.mode.rawValue,
                        roomCode: session.roomCode
                    )
                    SessionLog.save(log)
                    
                    session.resetSession()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("home_return")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(25)
                }
                .padding(.bottom, 60)
            }
        }
    }
}
