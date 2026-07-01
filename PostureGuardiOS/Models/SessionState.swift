import Foundation
import Combine

// MARK: - Session Mode
enum SessionMode: String {
    case zen = "禅意静修"
    case ring = "默契自习"
}

// MARK: - Session Phase
enum SessionPhase {
    case idle
    case calibrating
    case running
    case paused
    case finished
}

// MARK: - Session State Manager
class SessionState: ObservableObject {
    static let shared = SessionState()
    
    @Published var mode: SessionMode = .zen
    @Published var phase: SessionPhase = .idle
    @Published var focusDurationMinutes: Int = 25  // User-selected duration
    @Published var timeRemaining: Int = 0          // Countdown in seconds
    @Published var isInfinite: Bool = false
    @Published var roomCode: String? = nil
    
    // New detailed metrics
    @Published var goodPostureSeconds: Int = 0
    @Published var wobbleSeconds: Int = 0
    @Published var awaySeconds: Int = 0
    
    @Published var wobbleCount: Int = 0
    @Published var awayCount: Int = 0
    
    private var lastState: PostureState = .focusing
    
    private var timer: Timer?
    private let engine = PostureEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Observe posture state to auto-pause/resume
        engine.$postureState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.handlePostureChange(state)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Session Lifecycle
    func startSession(mode: SessionMode, minutes: Int, infinite: Bool = false, roomCode: String? = nil) {
        self.mode = mode
        self.isInfinite = infinite
        self.roomCode = roomCode
        self.focusDurationMinutes = minutes
        self.timeRemaining = minutes * 60
        self.goodPostureSeconds = 0
        self.wobbleSeconds = 0
        self.awaySeconds = 0
        self.wobbleCount = 0
        self.awayCount = 0
        self.lastState = .focusing
        self.phase = .calibrating
        
        engine.checkCameraPermission()
        engine.startTracking()
    }
    
    func onCalibrationComplete() {
        phase = .running
        startTimer()
    }
    
    func pauseSession() {
        phase = .paused
        timer?.invalidate()
        timer = nil
    }
    
    func resumeSession() {
        phase = .running
        startTimer()
    }
    
    func endSession() {
        timer?.invalidate()
        timer = nil
        engine.stopTracking()
        phase = .finished
    }
    
    func resetSession() {
        timer?.invalidate()
        timer = nil
        engine.stopTracking()
        phase = .idle
        timeRemaining = 0
        goodPostureSeconds = 0
        wobbleSeconds = 0
        awaySeconds = 0
        wobbleCount = 0
        awayCount = 0
        lastState = .focusing
    }
    
    // MARK: - Timer
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let postureState = self.engine.postureState
            
            // If face is not detected, instantly stop focus time from increasing (even during 4s grace period)
            if !self.engine.isFaceDetected {
                self.awaySeconds += 1
                return
            }
            
            // Record exact time distributions regardless of countdown
            switch postureState {
            case .focusing:
                self.goodPostureSeconds += 1
            case .wobble:
                self.wobbleSeconds += 1
            case .away, .out:
                self.awaySeconds += 1
            }
            
            // Auto-pause countdown when away or out
            if postureState == .away || postureState == .out {
                return  // Timer ticks but countdown/countup doesn't progress
            }
            
            if !self.isInfinite {
                if self.timeRemaining > 1 {
                    self.timeRemaining -= 1
                } else {
                    self.timeRemaining = 0
                    self.endSession()
                    HapticManager.shared.sessionComplete()
                }
            }
        }
    }
    
    // MARK: - Posture State Handling
    private func handlePostureChange(_ state: PostureState) {
        if state == .wobble && lastState != .wobble && lastState != .out {
            wobbleCount += 1
        }
        if (state == .away || state == .out) && lastState != .away && lastState != .out {
            awayCount += 1
        }
        lastState = state
    }
    
    // MARK: - Computed
    var totalSessionSeconds: Int {
        return goodPostureSeconds + wobbleSeconds + awaySeconds
    }
    
    var goodPostureRatio: Double {
        let totalTargetSeconds = Double(focusDurationMinutes * 60)
        guard totalTargetSeconds > 0 else { return 0.0 }
        let ratio = Double(goodPostureSeconds) / totalTargetSeconds
        return min(1.0, max(0.0, ratio))
    }
    
    // Actual time spent actively decrementing the timer
    var elapsedFocusSeconds: Int {
        return goodPostureSeconds + wobbleSeconds
    }
}
