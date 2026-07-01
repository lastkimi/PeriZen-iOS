import SwiftUI

// MARK: - Home View
/// Minimalist black home screen with mode selection and infinite time scroll.
struct HomeView: View {
    @ObservedObject var session = SessionState.shared
    
    @State private var selectedMinutes: Int = 25
    @State private var navigateToZen: Bool = false
    @State private var navigateToRing: Bool = false
    @State private var showAbout: Bool = false
    
    // Config
    private let minMinutes = 1
    private let maxMinutes = 1440
    private let pointsPerMinute: CGFloat = 40.0 // Every 40 points dragged = 1 minute change
    
    // For continuous scroll
    @State private var dragAccumulator: CGFloat = 0.0
    @State private var dragStartMinutes: Int = 25
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // App Title & Header
                    ZStack(alignment: .topTrailing) {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Text("app_name")
                                    .font(.system(size: 32, weight: .ultraLight, design: .rounded))
                                    .foregroundColor(.white)
                                    .tracking(6)
                                Text("home_slogan")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                                    .tracking(1)
                            }
                            Spacer()
                        }
                        
                        HStack(spacing: 16) {
                            Button(action: { showAbout = true }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            
                            NavigationLink(destination: StatisticsView().navigationBarBackButtonHidden(true)) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        .padding()
                    }
                    
                    Spacer().frame(height: 60)
                    
                    // Duration Selector (Infinite vertical swipe)
                    VStack(spacing: 8) {
                        Text("\(selectedMinutes)")
                            .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                        Text("home_target_minutes")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("home_drag_hint")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.top, 4)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if dragAccumulator == 0 {
                                    // Capture the starting minute exactly once at the beginning of the drag
                                    dragStartMinutes = selectedMinutes
                                    dragAccumulator = 1 // marker to indicate we've started
                                }
                                
                                let delta = -value.translation.height
                                let minuteDelta = Int(delta / pointsPerMinute)
                                
                                let newMinutes = dragStartMinutes + minuteDelta
                                let clamped = max(minMinutes, min(maxMinutes, newMinutes))
                                
                                if clamped != selectedMinutes {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                        selectedMinutes = clamped
                                    }
                                    HapticManager.shared.tick()
                                }
                            }
                            .onEnded { _ in
                                dragAccumulator = 0
                            }
                    )
                    
                    // Swipe hint
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10))
                        Text("home_swipe_hint")
                            .font(.system(size: 11))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white.opacity(0.15))
                    .padding(.top, 12)
                    
                    Spacer()
                    
                    // Mode Buttons
                    VStack(spacing: 16) {
                        // Zen Mode (primary)
                        Button(action: {
                            session.startSession(mode: .zen, minutes: selectedMinutes)
                            navigateToZen = true
                        }) {
                            HStack {
                                Image(systemName: "leaf")
                                    .font(.system(size: 16, weight: .light))
                                Text("home_zen_mode")
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(red: 0.0, green: 1.0, blue: 0.5)) // brighter emerald green
                            .cornerRadius(26)
                        }
                        
                        // Ring Mode
                        Button(action: {
                            session.startSession(mode: .ring, minutes: selectedMinutes)
                            navigateToRing = true
                        }) {
                            HStack {
                                Image(systemName: "person.3")
                                    .font(.system(size: 16, weight: .light))
                                Text("home_ring_mode")
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(26)
                            .overlay(
                                RoundedRectangle(cornerRadius: 26)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            }
            .preferredColorScheme(.dark)
            .navigationDestination(isPresented: $navigateToZen) {
                ZenSessionView()
                    .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $navigateToRing) {
                RingSessionView()
                    .navigationBarBackButtonHidden(true)
            }
            .confirmationDialog(Text("home_about"), isPresented: $showAbout, titleVisibility: .visible) {
                Button("about_privacy") {
                    if let url = URL(string: "https://www.slmcamp.com/#/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("about_website") {
                    if let url = URL(string: "https://www.slmcamp.com/#/") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
}
