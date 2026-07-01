import Foundation

struct SessionLog: Codable, Identifiable {
    var id: UUID
    var date: Date
    var focusDuration: Double      // Actual elapsed time in seconds
    var goodPostureDuration: Double // Seconds of good posture
    var wobbleDuration: Double     // Seconds of wobbling
    var awayDuration: Double       // Seconds of being away
    
    var wobbleCount: Int           // Times wobbled
    var awayCount: Int             // Times away/out
    
    var mode: String               // session.mode.rawValue
    var roomCode: String?          // Room code if multiplayer
    
    // Computed property for legacy compat or UI use
    var goodPostureRatio: Double {
        let total = focusDuration + wobbleDuration + awayDuration
        guard total > 0 else { return 1.0 }
        return goodPostureDuration / total
    }
    
    init(focusDuration: Double, goodPostureDuration: Double, wobbleDuration: Double, awayDuration: Double, wobbleCount: Int = 0, awayCount: Int = 0, mode: String, roomCode: String? = nil) {
        self.id = UUID()
        self.date = Date()
        self.focusDuration = focusDuration
        self.goodPostureDuration = goodPostureDuration
        self.wobbleDuration = wobbleDuration
        self.awayDuration = awayDuration
        self.wobbleCount = wobbleCount
        self.awayCount = awayCount
        self.mode = mode
        self.roomCode = roomCode
    }
    
    // MARK: - UserDefaults Storage
    private static let storageKey = "com.thering.sessionLogs.v2"
    
    static func save(_ log: SessionLog) {
        var logs = fetchAll()
        logs.append(log)
        if let encoded = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    static func fetchAll() -> [SessionLog] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let logs = try? JSONDecoder().decode([SessionLog].self, from: data) else {
            return []
        }
        return logs
    }
}
