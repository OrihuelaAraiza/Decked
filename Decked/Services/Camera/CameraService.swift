//
//  CameraService.swift
//  Decked
//
//  AVFoundation camera service for continuous card scanning
//

import AVFoundation
import UIKit
import Combine
import SwiftUI

// MARK: - Camera Service Protocol
protocol CameraServiceProtocol: AnyObject {
    var isRunning: Bool { get }
    var framePublisher: AnyPublisher<UIImage, Never> { get }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer?
    func startSession() async throws
    func stopSession()
    func pauseCapture()
    func resumeCapture()
}

// MARK: - Camera Service
final class CameraService: NSObject, CameraServiceProtocol {
    
    // MARK: - Properties
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.decked.camera.session")
    
    private let frameSubject = PassthroughSubject<UIImage, Never>()
    private let lock = NSLock()
    
    // Thread-safe properties
    private var _lastCaptureTime: Date = .distantPast
    private var _isPaused = false
    private var _captureInterval: TimeInterval = 0.75
    private var _previewLayer: AVCaptureVideoPreviewLayer?
    private var _isConfigured = false
    
    private var lastCaptureTime: Date {
        get { lock.withLock { _lastCaptureTime } }
        set { lock.withLock { _lastCaptureTime = newValue } }
    }
    
    private var isPaused: Bool {
        get { lock.withLock { _isPaused } }
        set { lock.withLock { _isPaused = newValue } }
    }
    
    /// Minimum interval between frame captures (throttle)
    var captureInterval: TimeInterval {
        get { lock.withLock { _captureInterval } }
        set { lock.withLock { _captureInterval = newValue } }
    }
    
    var isRunning: Bool {
        captureSession.isRunning
    }
    
    var framePublisher: AnyPublisher<UIImage, Never> {
        frameSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        lock.withLock { _previewLayer }
    }
    
    func startSession() async throws {
        print("📸 CameraService: Starting session...")
        
        // Check authorization
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        print("📸 CameraService: Authorization status: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            print("📸 CameraService: Requesting camera access...")
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            print("📸 CameraService: Access granted: \(granted)")
            guard granted else {
                throw CameraError.accessDenied
            }
        case .denied, .restricted:
            print("📸 CameraService: Access denied or restricted")
            throw CameraError.accessDenied
        case .authorized:
            print("📸 CameraService: Already authorized")
            break
        @unknown default:
            throw CameraError.unknown
        }
        
        // Configure session if not already configured
        let needsConfiguration = lock.withLock { !_isConfigured }
        
        if needsConfiguration {
            print("📸 CameraService: Configuring session...")
            try await configureSession()
            lock.withLock { _isConfigured = true }
            print("📸 CameraService: Session configured successfully")
        }
        
        // Start running
        print("📸 CameraService: Starting capture session...")
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                    print("📸 CameraService: Capture session started")
                }
                continuation.resume()
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            print("📸 CameraService: Session stopped")
        }
    }
    
    func pauseCapture() {
        isPaused = true
        print("📸 CameraService: Capture paused")
    }
    
    func resumeCapture() {
        isPaused = false
        print("📸 CameraService: Capture resumed")
    }
    
    // MARK: - Private Methods
    private func configureSession() async throws {
        print("📸 CameraService: Beginning configuration...")
        
        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    print("❌ CameraService: Self is nil")
                    continuation.resume(throwing: CameraError.unknown)
                    return
                }
                
                do {
                    self.captureSession.beginConfiguration()
                    
                    // Set session preset for high quality
                    if self.captureSession.canSetSessionPreset(.hd1920x1080) {
                        self.captureSession.sessionPreset = .hd1920x1080
                        print("📸 CameraService: Set preset to HD 1080p")
                    } else {
                        self.captureSession.sessionPreset = .high
                        print("📸 CameraService: Set preset to high")
                    }
                    
                    // Add video input
                    guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                        print("❌ CameraService: No video device found")
                        self.captureSession.commitConfiguration()
                        continuation.resume(throwing: CameraError.deviceNotFound)
                        return
                    }
                    
                    print("📸 CameraService: Video device found: \(videoDevice.localizedName)")
                    
                    // Configure device for optimal card scanning
                    try videoDevice.lockForConfiguration()
                    
                    if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                        videoDevice.focusMode = .continuousAutoFocus
                        print("📸 CameraService: Set continuous autofocus")
                    }
                    
                    if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                        videoDevice.exposureMode = .continuousAutoExposure
                        print("📸 CameraService: Set continuous auto exposure")
                    }
                    
                    videoDevice.unlockForConfiguration()
                    
                    let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    guard self.captureSession.canAddInput(videoInput) else {
                        print("❌ CameraService: Cannot add video input")
                        self.captureSession.commitConfiguration()
                        continuation.resume(throwing: CameraError.configurationFailed)
                        return
                    }
                    
                    self.captureSession.addInput(videoInput)
                    print("📸 CameraService: Video input added")
                    
                    // Configure video output
                    self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                    self.videoOutput.alwaysDiscardsLateVideoFrames = true
                    self.videoOutput.videoSettings = [
                        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                    ]
                    
                    guard self.captureSession.canAddOutput(self.videoOutput) else {
                        print("❌ CameraService: Cannot add video output")
                        self.captureSession.commitConfiguration()
                        continuation.resume(throwing: CameraError.configurationFailed)
                        return
                    }
                    
                    self.captureSession.addOutput(self.videoOutput)
                    print("📸 CameraService: Video output added")
                    
                    // Configure video connection
                    if let connection = self.videoOutput.connection(with: .video) {
                        connection.videoRotationAngle = 90 // Portrait orientation
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                        print("📸 CameraService: Video connection configured")
                    }
                    
                    self.captureSession.commitConfiguration()
                    print("📸 CameraService: Configuration committed")
                    
                    // Create preview layer on main thread
                    DispatchQueue.main.async {
                        let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                        layer.videoGravity = .resizeAspectFill
                        self.lock.withLock {
                            self._previewLayer = layer
                        }
                        print("📸 CameraService: Preview layer created")
                        continuation.resume()
                    }
                    
                } catch {
                    print("❌ CameraService: Configuration error: \(error)")
                    self.captureSession.commitConfiguration()
                    continuation.resume(throwing: CameraError.configurationFailed)
                }
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Check if paused
        guard !isPaused else { return }
        
        // Throttle frame capture
        let now = Date()
        let interval = captureInterval
        guard now.timeIntervalSince(lastCaptureTime) >= interval else { return }
        lastCaptureTime = now
        
        // Convert to UIImage
        guard let image = imageFromSampleBuffer(sampleBuffer) else { return }
        
        // Publish frame
        frameSubject.send(image)
    }
    
    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Camera Errors
enum CameraError: LocalizedError {
    case accessDenied
    case deviceNotFound
    case configurationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Camera access denied. Please enable camera access in Settings."
        case .deviceNotFound:
            return "No camera device found."
        case .configurationFailed:
            return "Failed to configure camera."
        case .unknown:
            return "An unknown camera error occurred."
        }
    }
}

// MARK: - Camera Preview UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.backgroundColor = .black
        print("📱 CameraPreviewView: makeUIView called, previewLayer: \(previewLayer != nil ? "YES" : "NO")")
        return view
    }
    
    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        print("📱 CameraPreviewView: updateUIView called, previewLayer: \(previewLayer != nil ? "YES" : "NO")")
        
        // Remove old layer if exists
        if let oldLayer = uiView.previewLayer, oldLayer !== previewLayer {
            print("📱 CameraPreviewView: Removing old layer")
            oldLayer.removeFromSuperlayer()
            uiView.previewLayer = nil
        }
        
        // Add new layer if not already added
        if let previewLayer = previewLayer, uiView.previewLayer !== previewLayer {
            print("📱 CameraPreviewView: Adding new preview layer")
            previewLayer.frame = uiView.bounds
            uiView.layer.insertSublayer(previewLayer, at: 0)
            uiView.previewLayer = previewLayer
        }
        
        // Update frame
        if let previewLayer = uiView.previewLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = uiView.bounds
            CATransaction.commit()
        }
    }
}

// Container view to hold the preview layer
class PreviewContainerView: UIView {
    weak var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
