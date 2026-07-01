import UIKit
import AudioToolbox

// MARK: - HapticManager
/// All feedback during focus is 100% tactile. No sound. No flash.
class HapticManager {
    static let shared = HapticManager()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        prepareAll()
    }
    
    private func prepareAll() {
        lightGenerator.prepare()
        heavyGenerator.prepare()
        rigidGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    // MARK: - Calibration
    /// Light tick during calibration countdown or dial scroll
    func tick() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
    
    /// Success notification when calibration completes
    func calibrationSuccess() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    // MARK: - Posture Warnings
    /// Wobble: light double-tap (posture deviated for 10s)
    func wobbleWarning() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.lightGenerator.impactOccurred()
            self?.lightGenerator.prepare()
        }
    }
    
    /// Severe: medium-long vibration (posture deviated for 20s, timer paused)
    func severeWarning() {
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    /// Session paused (user left the frame)
    func sessionPaused() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    // MARK: - Session Events
    /// Focus session complete
    func sessionComplete() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.notificationGenerator.notificationOccurred(.success)
            self?.notificationGenerator.prepare()
        }
    }
    
    // MARK: - Multiplayer (The Ring)
    /// "Silent Rescue" double-tap — only sent to the wobbling user
    func rescueTap() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.lightGenerator.impactOccurred()
            self?.lightGenerator.prepare()
        }
    }
}
