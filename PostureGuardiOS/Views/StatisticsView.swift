import SwiftUI

// MARK: - Statistics View
struct StatisticsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var logs: [SessionLog] = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("stats_title")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left")
                        .opacity(0)
                }
                .padding()
                
                // Summary Cards
                HStack(spacing: 16) {
                    summaryCard(title: NSLocalizedString("stats_total", comment: ""), value: "\(totalFocusMinutes)m")
                    summaryCard(title: NSLocalizedString("stats_avg", comment: ""), value: "\(averageRatio)%")
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // History List
                if logs.isEmpty {
                    Spacer()
                    Text("stats_no_data")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: 14))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(logs.reversed()) { log in
                                NavigationLink(destination: SessionDetailView(log: log)) {
                                    logRow(log)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            logs = SessionLog.fetchAll()
        }
    }
    
    // MARK: - Computed Stats
    private var totalFocusMinutes: Int {
        let totalSeconds = logs.reduce(0) { $0 + $1.focusDuration }
        return Int(totalSeconds / 60)
    }
    
    private var averageRatio: Int {
        guard !logs.isEmpty else { return 0 }
        let totalRatio = logs.reduce(0.0) { $0 + $1.goodPostureRatio }
        return Int((totalRatio / Double(logs.count)) * 100)
    }
    
    // MARK: - Subviews
    private func summaryCard(title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func logRow(_ log: SessionLog) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        let dateString = formatter.string(from: log.date)
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(log.mode == SessionMode.zen.rawValue ? "home_zen_mode" : "home_ring_mode")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                
                HStack(spacing: 8) {
                    Text(String(format: NSLocalizedString("stats_wobble_min", comment: ""), Int(log.wobbleDuration/60)))
                        .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.0))
                    Text(String(format: NSLocalizedString("stats_away_min", comment: ""), Int(log.awayDuration/60)))
                        .foregroundColor(.white.opacity(0.5))
                }
                .font(.system(size: 10))
                .padding(.top, 4)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: NSLocalizedString("stats_minutes", comment: ""), Int(log.focusDuration / 60)))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                
                Text("\(NSLocalizedString("summary_ratio", comment: "")): \(Int(log.goodPostureRatio * 100))%")
                    .font(.system(size: 12))
                    .foregroundColor(log.goodPostureRatio > 0.8 ? Color(red: 0.0, green: 1.0, blue: 0.5) : Color(red: 1.0, green: 0.3, blue: 0.0))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}
