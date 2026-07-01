import Foundation

// MARK: - WebSocket Room Manager (V1.2)
class RoomManager: ObservableObject {
    static let shared = RoomManager()
    
    @Published var isConnected: Bool = false
    @Published var roomCode: String = ""
    @Published var companions: [Companion] = []
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    private let userId = UUID().uuidString
    
    // For V1.2 MVP, allow setting a custom URL (defaulting to a generic local host for now)
    private var serverURL: URL?
    
    private init() {}
    
    // MARK: - Companion Model
    struct Companion: Identifiable, Codable {
        let id: String
        var name: String
        var state: String // "focusing", "wobble", "away", "out"
        var elapsedFocusSeconds: Int
        
        var postureState: PostureState {
            return PostureState(rawValue: state) ?? .focusing
        }
    }
    
    // MARK: - Payload Model
    struct Payload: Codable {
        let type: String    // "join", "update", "leave", "sync"
        let roomId: String
        let userId: String
        let userName: String
        let state: String
        let elapsedFocusSeconds: Int
    }
    
    // MARK: - Connection Methods
    func connect(to urlString: String, roomCode: String) {
        guard let url = URL(string: urlString) else { return }
        self.serverURL = url
        self.roomCode = roomCode
        
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        
        receiveMessage()
        
        // Send join event
        sendPayload(type: "join", state: PostureEngine.shared.postureState.rawValue)
    }
    
    func leaveRoom() {
        sendPayload(type: "leave", state: "out")
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        companions = []
        roomCode = ""
    }
    
    func updateMyState(_ state: PostureState) {
        guard isConnected else { return }
        sendPayload(type: "update", state: state.rawValue)
    }
    
    // MARK: - WebSocket I/O
    private func sendPayload(type: String, state: String) {
        let elapsed = SessionState.shared.elapsedFocusSeconds
        let payload = Payload(type: type, roomId: roomCode, userId: userId, userName: "我", state: state, elapsedFocusSeconds: elapsed)
        guard let data = try? JSONEncoder().encode(payload),
              let jsonString = String(data: data, encoding: .utf8) else { return }
        
        webSocketTask?.send(.string(jsonString)) { error in
            if let error = error {
                print("WebSocket sending error: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleIncomingJSON(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleIncomingJSON(text)
                    }
                @unknown default:
                    break
                }
                // Continue listening
                self.receiveMessage()
                
            case .failure(let error):
                print("WebSocket receiving error: \(error)")
                DispatchQueue.main.async {
                    self.isConnected = false
                }
            }
        }
    }
    
    private func handleIncomingJSON(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return }
        
        // Ignore own messages reflected by server
        if payload.userId == self.userId { return }
        
        DispatchQueue.main.async {
            switch payload.type {
            case "sync", "update", "join":
                if let index = self.companions.firstIndex(where: { $0.id == payload.userId }) {
                    self.companions[index].state = payload.state
                    self.companions[index].elapsedFocusSeconds = payload.elapsedFocusSeconds
                } else {
                    let newCompanion = Companion(id: payload.userId, name: payload.userName, state: payload.state, elapsedFocusSeconds: payload.elapsedFocusSeconds)
                    self.companions.append(newCompanion)
                }
                
                // If it's a join, send a sync back so the new user knows we exist
                if payload.type == "join" {
                    self.sendPayload(type: "sync", state: PostureEngine.shared.postureState.rawValue)
                }
                
            case "leave":
                self.companions.removeAll { $0.id == payload.userId }
            default:
                break
            }
        }
    }
}
