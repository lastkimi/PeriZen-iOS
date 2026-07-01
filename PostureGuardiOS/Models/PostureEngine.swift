import Foundation
import AVFoundation
import Vision
import UIKit
import Combine
import CoreMotion

// MARK: - Posture State
enum PostureState: String {
    case focusing = "专注中"
    case wobble = "姿态偏离"
    case out = "已暂停"
    case away = "离席"
}

// MARK: - PostureEngine
class PostureEngine: NSObject, ObservableObject {
    static let shared = PostureEngine()
    
    // MARK: Published State
    @Published var postureState: PostureState = .focusing
    @Published var isTracking: Bool = false
    @Published var hasCameraPermission: Bool = false
    @Published var isCalibrated: Bool = false
    @Published var calibrationCountdown: Int = 3
    @Published var isCalibrating: Bool = false
    @Published var isFaceDetected: Bool = true
    
    // MARK: Metrics
    @Published var currentPitch: Double = 0.0
    @Published var currentRoll: Double = 0.0
    
    // MARK: Configuration
    let deviationThreshold: Double = 20.0  // degrees
    
    // MARK: Calibration Baselines
    private var pitchBaseline: Double = 0.0
    private var rollBaseline: Double = 0.0
    
    private var devicePitchBaseline: Double = 0.0
    private var deviceRollBaseline: Double = 0.0
    
    // MARK: CoreMotion
    private let motionManager = CMMotionManager()
    private let motionQueue = OperationQueue()
    
    // MARK: AVCapture (Vision 0.2 FPS Throttle)
    private var captureSession: AVCaptureSession?
    private let sessionQueue = DispatchQueue(label: "com.thering.session", qos: .userInitiated)
    private var lastProcessTime: Date = Date.distantPast
    private let samplingInterval: TimeInterval = 2.0  // 2 seconds for faster recovery
    
    // MARK: Wobble Tracking
    private var wobbleStartTime: Date?
    private var awayStartTime: Date?
    private var faceDetectedRecently: Bool = false
    
    // MARK: Init
    private override init() {
        super.init()
    }
    
    // MARK: - Camera Permission
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.hasCameraPermission = true }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { self.hasCameraPermission = granted }
            }
        default:
            DispatchQueue.main.async { self.hasCameraPermission = false }
        }
    }
    
    // MARK: - Start / Stop
    func startTracking() {
        guard !isTracking else { return }
        
        setupVisionCaptureSession()
        startMotionTracking()
        
        isTracking = true
        wobbleStartTime = nil
        awayStartTime = nil
    }
    
    func stopTracking() {
        isTracking = false
        
        let sessionToStop = captureSession
        captureSession = nil
        
        sessionQueue.async {
            sessionToStop?.stopRunning()
        }
        
        motionManager.stopDeviceMotionUpdates()
        
        DispatchQueue.main.async {
            self.postureState = .focusing
            self.isCalibrated = false
        }
    }
    
    // MARK: - Calibration
    func startCalibration() {
        guard !isCalibrating else { return }
        isCalibrating = true
        calibrationCountdown = 3
        
        // 3-second countdown
        func tick(_ remaining: Int) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self, self.isCalibrating else { return }
                if remaining > 1 {
                    self.calibrationCountdown = remaining - 1
                    HapticManager.shared.tick()
                    tick(remaining - 1)
                } else {
                    // Capture face baselines
                    self.pitchBaseline = self.currentPitch
                    self.rollBaseline = self.currentRoll
                    
                    // Capture device physical baselines
                    if let motion = self.motionManager.deviceMotion {
                        self.devicePitchBaseline = motion.attitude.pitch * (180.0 / .pi)
                        self.deviceRollBaseline = motion.attitude.roll * (180.0 / .pi)
                    }
                    
                    self.isCalibrated = true
                    self.isCalibrating = false
                    self.calibrationCountdown = 0
                    HapticManager.shared.calibrationSuccess()
                }
            }
        }
        
        HapticManager.shared.tick()
        tick(3)
    }
    
    // MARK: - Motion Tracking (Physical Device Checks)
    private func startMotionTracking() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 // Low frequency is enough
        motionManager.startDeviceMotionUpdates(to: motionQueue) { _, _ in
            // Keep motion queue active so we can poll deviceMotion synchronously in evaluatePosture
        }
    }
    
    // MARK: - Posture Evaluation (Face)
    private func evaluatePosture(pitch: Double, roll: Double, faceDetected: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard self.isCalibrated else { return }
            
            // 1. First check if device is picked up
            if let motion = self.motionManager.deviceMotion {
                let devicePitch = motion.attitude.pitch * (180.0 / .pi)
                let deviceRoll = motion.attitude.roll * (180.0 / .pi)
                let pitchDelta = abs(devicePitch - self.devicePitchBaseline)
                let rollDelta = abs(deviceRoll - self.deviceRollBaseline)
                
                if pitchDelta > 35.0 || rollDelta > 35.0 {
                    if self.postureState != .away {
                        self.postureState = .away
                        HapticManager.shared.sessionPaused()
                    }
                    return // Stop evaluating face until phone is placed back
                }
            }
            
            self.currentPitch = pitch
            self.currentRoll = roll
            
            let now = Date()
            
            // 2. Face not detected → away logic
            if !faceDetected {
                self.isFaceDetected = false
                self.faceDetectedRecently = false
                if self.awayStartTime == nil {
                    self.awayStartTime = now
                }
                // 4s missing face -> away
                if let start = self.awayStartTime, now.timeIntervalSince(start) >= 4.0 {
                    if self.postureState != .away {
                        self.postureState = .away
                        HapticManager.shared.sessionPaused()
                    }
                }
                return
            }
            
            // 3. Face detected → reset away timer
            self.isFaceDetected = true
            self.faceDetectedRecently = true
            self.awayStartTime = nil
            
            // If we were away, recover. (Only happens if motion is correct and face is detected)
            if self.postureState == .away {
                self.postureState = .focusing
            }
            
            // Check deviation
            let pitchDelta = abs(pitch - self.pitchBaseline)
            let rollDelta = abs(roll - self.rollBaseline)
            let isDeviated = pitchDelta >= self.deviationThreshold || rollDelta >= self.deviationThreshold
            
            if isDeviated {
                // Start or continue wobble timer
                if self.wobbleStartTime == nil {
                    self.wobbleStartTime = now
                }
                
                let wobbleDuration = now.timeIntervalSince(self.wobbleStartTime!)
                
                if wobbleDuration >= 20.0 && self.postureState != .out {
                    self.postureState = .out
                    HapticManager.shared.severeWarning()
                } else if wobbleDuration >= 10.0 && self.postureState == .focusing {
                    self.postureState = .wobble
                    HapticManager.shared.wobbleWarning()
                }
            } else {
                // Good posture → reset
                self.wobbleStartTime = nil
                if self.postureState == .wobble || self.postureState == .out {
                    self.postureState = .focusing
                }
            }
        }
    }
    
    // MARK: - Vision 2D Engine (The absolute minimum for heat control)
    private func setupVisionCaptureSession() {
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // Lowest possible preset for minimum heat
        if session.canSetSessionPreset(.cif352x288) {
            session.sessionPreset = .cif352x288
        } else {
            session.sessionPreset = .low
        }
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            session.commitConfiguration()
            return
        }
        
        // Lock to 2 FPS hardware limit
        do {
            try camera.lockForConfiguration()
            camera.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 2)
            camera.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 2)
            camera.unlockForConfiguration()
        } catch {}
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) { session.addInput(input) }
        } catch {
            session.commitConfiguration()
            return
        }
        
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        
        if session.canAddOutput(output) { session.addOutput(output) }
        
        if let connection = output.connection(with: .video) {
            if connection.isVideoOrientationSupported { connection.videoOrientation = .portrait }
            if connection.isVideoMirroringSupported { connection.isVideoMirrored = true }
        }
        
        session.commitConfiguration()
        self.captureSession = session
        
        sessionQueue.async { session.startRunning() }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension PostureEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 1 FPS hard throttle
        let now = Date()
        guard now.timeIntervalSince(lastProcessTime) >= samplingInterval else { return }
        lastProcessTime = now
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let self = self else { return }
            guard let results = request.results as? [VNFaceObservation], let face = results.first else {
                self.evaluatePosture(pitch: 0, roll: 0, faceDetected: false)
                return
            }
            
            // Estimate pitch and roll from 2D landmarks
            let pitch = Double(face.roll?.doubleValue ?? 0.0) * (180.0 / .pi)
            let yaw = Double(face.yaw?.doubleValue ?? 0.0) * (180.0 / .pi)
            
            self.evaluatePosture(pitch: yaw, roll: pitch, faceDetected: true)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .up, options: [:])
        try? handler.perform([request])
    }
}
