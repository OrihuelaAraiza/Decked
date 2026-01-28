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
    var previewLayer: AVCaptureVideoPreviewLayer? { get }
    var isRunning: Bool { get }
    var framePublisher: AnyPublisher<UIImage, Never> { get }
    
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
    private let processingQueue = DispatchQueue(label: "com.decked.camera.processing")
    
    private let frameSubject = PassthroughSubject<UIImage, Never>()
    private let lock = NSLock()
    
    private var _lastCaptureTime: Date = .distantPast
    private var _isPaused = false
    
    private var lastCaptureTime: Date {
        get { lock.withLock { _lastCaptureTime } }
        set { lock.withLock { _lastCaptureTime = newValue } }
    }
    
    private var isPaused: Bool {
        get { lock.withLock { _isPaused } }
        set { lock.withLock { _isPaused = newValue } }
    }
    
    /// Minimum interval between frame captures (throttle)
    var captureInterval: TimeInterval = 0.75
    
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    
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
    @MainActor
    func startSession() async throws {
        // Check authorization
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                throw CameraError.accessDenied
            }
        case .denied, .restricted:
            throw CameraError.accessDenied
        case .authorized:
            break
        @unknown default:
            throw CameraError.unknown
        }
        
        // Configure session
        try configureSession()
        
        // Start running
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                self?.captureSession.startRunning()
                continuation.resume()
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
    
    func pauseCapture() {
        isPaused = true
    }
    
    func resumeCapture() {
        isPaused = false
    }
    
    // MARK: - Private Methods
    private func configureSession() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // Set session preset for high quality
        captureSession.sessionPreset = .hd1920x1080
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.deviceNotFound
        }
        
        // Configure device for optimal card scanning
        try videoDevice.lockForConfiguration()
        
        if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
            videoDevice.focusMode = .continuousAutoFocus
        }
        
        if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
            videoDevice.exposureMode = .continuousAutoExposure
        }
        
        videoDevice.unlockForConfiguration()
        
        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        
        guard captureSession.canAddInput(videoInput) else {
            throw CameraError.configurationFailed
        }
        captureSession.addInput(videoInput)
        
        // Configure video output
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        guard captureSession.canAddOutput(videoOutput) else {
            throw CameraError.configurationFailed
        }
        captureSession.addOutput(videoOutput)
        
        // Configure video connection
        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90 // Portrait orientation
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
        }
        
        // Create preview layer
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        self.previewLayer = layer
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
        guard now.timeIntervalSince(lastCaptureTime) >= captureInterval else { return }
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
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        if let previewLayer = previewLayer {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            previewLayer?.frame = uiView.bounds
        }
    }
}
