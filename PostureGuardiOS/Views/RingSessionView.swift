import SwiftUI

enum JoinMode {
    case publicRoom
    case privateRoom
}

enum PrivateAction {
    case create
    case join
}

// MARK: - Ring Session View
/// Multiplayer mode view. Connects to WebSocket and shows companions.
struct RingSessionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var room = RoomManager.shared
    @ObservedObject var engine = PostureEngine.shared
    @ObservedObject var session = SessionState.shared
    
    // Configuration
    private let serverURL: String = "ws://47.98.124.125:8888"
    
    @State private var joinMode: JoinMode = .publicRoom
    @State private var privateAction: PrivateAction = .create
    @State private var privatePin: String = ""
    @State private var createdPin: String = ""
    
    @State private var isConnecting: Bool = false
    @State private var showSummary: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if !room.isConnected {
                buildLobby()
            } else {
                buildSession()
            }
        }
        .onAppear {
            UIScreen.main.brightness = 0.5
        }
        .onDisappear {
            room.leaveRoom()
            UIScreen.main.brightness = 0.5
            if session.phase != .finished && session.phase != .idle {
                session.resetSession()
            }
        }
        .onChange(of: engine.postureState) { newState in
            room.updateMyState(newState)
        }
        .onChange(of: session.phase) { newPhase in
            if newPhase == .running {
                UIScreen.main.brightness = 0.15
            } else if newPhase == .finished {
                room.leaveRoom()
                UIScreen.main.brightness = 0.5
                showSummary = true
            }
        }
        // Update room regularly to sync elapsed times
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            if room.isConnected && engine.postureState == .focusing {
                room.updateMyState(.focusing)
            }
            // Locally update other companions if they are focusing for a smooth UI experience
            for i in 0..<room.companions.count {
                if room.companions[i].postureState == .focusing {
                    room.companions[i].elapsedFocusSeconds += 1
                }
            }
        }
        .fullScreenCover(isPresented: $showSummary, onDismiss: {
            presentationMode.wrappedValue.dismiss()
        }) {
            SessionSummaryView()
        }
    }
    
    // MARK: - Lobby UI
    @ViewBuilder
    private func buildLobby() -> some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("ring_lobby_title")
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                Button(action: { joinMode = .publicRoom }) {
                    Text("ring_public_room")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(joinMode == .publicRoom ? .black : .white)
                        .frame(width: 120, height: 44)
                        .background(joinMode == .publicRoom ? Color.white : Color.white.opacity(0.1))
                        .cornerRadius(22)
                }
                
                Button(action: { joinMode = .privateRoom }) {
                    Text("ring_private_room")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(joinMode == .privateRoom ? .black : .white)
                        .frame(width: 120, height: 44)
                        .background(joinMode == .privateRoom ? Color.white : Color.white.opacity(0.1))
                        .cornerRadius(22)
                }
            }
            
            if joinMode == .privateRoom {
                // Create or Join toggle
                Picker("ring_private_room_action", selection: $privateAction) {
                    Text("ring_create_room").tag(PrivateAction.create)
                    Text("ring_join_room").tag(PrivateAction.join)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 260)
                .colorScheme(.dark)
                
                if privateAction == .join {
                    SecureField("ring_join_hint", text: $privatePin)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 260, height: 60)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                } else {
                    Text("ring_create_hint")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(height: 60)
                }
            }
            
            Button(action: {
                isConnecting = true
                var code = "public"
                if joinMode == .privateRoom {
                    if privateAction == .create {
                        createdPin = String(format: "%04d", Int.random(in: 0...9999))
                        code = createdPin
                    } else {
                        code = privatePin
                    }
                }
                room.connect(to: serverURL, roomCode: code)
                session.startSession(mode: .ring, minutes: 1440, infinite: true, roomCode: code)
            }) {
                Text(isConnecting ? "ring_connecting" : "ring_connect")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(width: 260, height: 50)
                    .background(Color(red: 0.0, green: 1.0, blue: 0.5))
                    .cornerRadius(25)
            }
            .disabled(joinMode == .privateRoom && privateAction == .join && privatePin.count < 1)
            .opacity((joinMode == .privateRoom && privateAction == .join && privatePin.count < 1) ? 0.5 : 1.0)
            
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("ring_back")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Session UI
    @ViewBuilder
    private func buildSession() -> some View {
        ZStack {
            VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if room.roomCode == "public" {
                        Text("ring_public_room")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        Text("\(Text("ring_private_room")) \(room.roomCode)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Text(String(format: NSLocalizedString("ring_room_count", comment: ""), room.companions.count + 1))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 60)
            
            Spacer()
            
            // The Breathing Ring with Embedded Timer (Count UP)
            ZStack {
                BreathingRingView(postureState: engine.postureState, ringSize: 260)
                    .overlay(
                        VStack(spacing: 8) {
                            if session.phase == .running || session.phase == .paused {
                                let elapsed = session.elapsedFocusSeconds
                                let hours = elapsed / 3600
                                let minutes = (elapsed % 3600) / 60
                                let seconds = elapsed % 60
                                
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
                
                // Orbiting Companions
                ForEach(Array(room.companions.enumerated()), id: \.element.id) { index, companion in
                    let totalCompanions = room.companions.count
                    let angle = (2 * .pi / Double(totalCompanions)) * Double(index)
                    let radius: CGFloat = 180.0
                    let xOffset = radius * CGFloat(cos(angle))
                    let yOffset = radius * CGFloat(sin(angle))
                    
                    VStack(spacing: 4) {
                        CompanionDot(state: companion.postureState)
                        let cmins = companion.elapsedFocusSeconds / 60
                        Text("\(cmins)m")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .offset(x: xOffset, y: yOffset)
                }
            }
            
            Spacer()
            
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
        
        // Calibration Overlay
        if session.phase == .calibrating {
            CalibrationOverlay {
                session.onCalibrationComplete()
            }
            
            VStack {
                HStack {
                    Button(action: {
                        session.resetSession()
                        room.leaveRoom()
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
    }
    
    // MARK: - Dynamic Text Logic
    private var statusText: LocalizedStringKey {
        switch engine.postureState {
        case .focusing:
            return "status_focusing"
        case .wobble:
            return "status_wobble"
        case .away, .out:
            return "status_away"
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

struct CompanionDot: View {
    let state: PostureState
    
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 14, height: 14)
            .shadow(color: color.opacity(0.8), radius: 8)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear { startAnimation() }
            .onChange(of: state) { _ in startAnimation() }
    }
    
    private var color: Color {
        switch state {
        case .focusing: return Color(red: 0.0, green: 1.0, blue: 0.5)
        case .wobble:   return Color(red: 1.0, green: 0.3, blue: 0.0)
        default:        return Color(white: 0.3)
        }
    }
    
    private func startAnimation() {
        withAnimation(.none) {
            scale = 1.0
            opacity = 0.6
        }
        
        switch state {
        case .focusing:
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                scale = 1.2
                opacity = 1.0
            }
        case .wobble:
            withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                opacity = 0.2
            }
        default:
            break
        }
    }
}
