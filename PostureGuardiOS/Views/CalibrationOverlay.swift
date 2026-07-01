import SwiftUI

// MARK: - Calibration Overlay
/// Full-screen overlay that guides the user through the 3-second calibration process.
struct CalibrationOverlay: View {
    @ObservedObject var engine = PostureEngine.shared
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Calibration ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 2)
                        .frame(width: 200, height: 200)
                    
                    if engine.isCalibrating {
                        // Countdown number
                        Text("\(engine.calibrationCountdown)")
                            .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                            .foregroundColor(.white)
                    } else if engine.isCalibrated {
                        // Success
                        Image(systemName: "checkmark")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(Color(red: 0.2, green: 0.85, blue: 0.5))
                    } else {
                        // Waiting
                        Image(systemName: "person.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                // Instructions
                VStack(spacing: 12) {
                    if engine.isCalibrated {
                        Text("calib_done")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                    } else if engine.isCalibrating {
                        Text("calib_hold")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        Text("calib_calibrating")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        Text("calib_sit_straight")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        Text("calib_best_posture")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Action button
                if !engine.isCalibrating {
                    if engine.isCalibrated {
                        Button(action: onComplete) {
                            Text("calib_start")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(red: 0.2, green: 0.85, blue: 0.5))
                                .cornerRadius(26)
                        }
                        .padding(.horizontal, 48)
                    } else {
                        Button(action: { engine.startCalibration() }) {
                            Text("calib_align")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(26)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 26)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 48)
                    }
                }
                
                Spacer().frame(height: 60)
            }
        }
    }
}
