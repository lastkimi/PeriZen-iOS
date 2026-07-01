import SwiftUI

struct SessionDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let log: SessionLog
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Custom Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("detail_title")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left")
                        .opacity(0)
                }
                .padding()
                
                let formatter = DateFormatter()
                let _ = formatter.dateFormat = "yyyy-MM-dd HH:mm"
                
                Text(formatter.string(from: log.date))
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                
                // Ring visualization
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(log.goodPostureRatio))
                        .stroke(
                            log.goodPostureRatio > 0.8 ? Color(red: 0.0, green: 1.0, blue: 0.5) : Color(red: 1.0, green: 0.3, blue: 0.0),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("\(Int(log.goodPostureDuration / 60))")
                            .font(.system(size: 48, weight: .ultraLight, design: .rounded))
                            .foregroundColor(.white)
                        Text("summary_minutes")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.vertical, 20)
                
                // Detailed Stats Grid
                VStack(spacing: 24) {
                    HStack(spacing: 40) {
                        VStack(spacing: 8) {
                            Text("\(Int(log.focusDuration / 60))m")
                                .font(.system(size: 24, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                            Text("detail_total_time")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        VStack(spacing: 8) {
                            Text("\(Int(log.goodPostureRatio * 100))%")
                                .font(.system(size: 24, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.5))
                            Text("summary_ratio")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    HStack(spacing: 40) {
                        VStack(spacing: 8) {
                            Text(String(format: NSLocalizedString("common_times", comment: ""), log.wobbleCount))
                                .font(.system(size: 24, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.0))
                            Text("summary_wobbles")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        VStack(spacing: 8) {
                            Text(String(format: NSLocalizedString("common_times", comment: ""), log.awayCount))
                                .font(.system(size: 24, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                            Text("summary_aways")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
    }
}
