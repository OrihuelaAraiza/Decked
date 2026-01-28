//
//  ScannerViewModel.swift
//  Decked
//
//  ViewModel for continuous card scanning
//

import Foundation
import Combine
import UIKit
import AVFoundation

@MainActor
final class ScannerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var scannerState: ScannerState = .idle
    @Published private(set) var lastScanResult: ScanResult?
    @Published private(set) var detectedMatches: [CardMatch] = []
    @Published private(set) var isProcessing = false
    @Published var showDebugOverlay = false
    @Published var recognizedTextLines: [String] = []
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - Services
    
    let cameraService: CameraService
    private let ocrService: OCRService
    private let cardParser: CardTextParser
    private let apiClient: CardAPIClient
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var isScanning = false
    
    var statusText: String {
        scannerState.statusText
    }
    
    var hasDetectedCard: Bool {
        if case .cardDetected = scannerState {
            return true
        }
        return false
    }
    
    // MARK: - Initialization
    
    init(
        cameraService: CameraService? = nil,
        ocrService: OCRService = OCRService(),
        cardParser: CardTextParser = CardTextParser(),
        apiClient: CardAPIClient = CardAPIClient()
    ) {
        self.cameraService = cameraService ?? CameraService()
        self.ocrService = ocrService
        self.cardParser = cardParser
        self.apiClient = apiClient
        
        setupFrameProcessing()
    }
    
    // MARK: - Public Methods
    
    func startScanning() async {
        guard !isScanning else { return }
        
        do {
            print("🎬 ScannerViewModel: Starting scanning...")
            scannerState = .scanning
            try await cameraService.startSession()
            
            // Wait a bit and get preview layer
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            previewLayer = cameraService.getPreviewLayer()
            
            if previewLayer != nil {
                print("✅ ScannerViewModel: Preview layer obtained")
                isScanning = true
            } else {
                print("⚠️ ScannerViewModel: Preview layer is nil")
                isScanning = true // Still mark as scanning
            }
        } catch {
            print("❌ ScannerViewModel: Error starting scanning: \(error)")
            scannerState = .error(error.localizedDescription)
        }
    }
    
    func stopScanning() {
        cameraService.stopSession()
        isScanning = false
        scannerState = .idle
    }
    
    func pauseScanning() {
        cameraService.pauseCapture()
        scannerState = .idle
    }
    
    func resumeScanning() {
        cameraService.resumeCapture()
        scannerState = .scanning
    }
    
    func togglePause() {
        if scannerState == .scanning {
            pauseScanning()
        } else if scannerState == .idle {
            resumeScanning()
        }
    }
    
    func clearResults() {
        lastScanResult = nil
        detectedMatches = []
        recognizedTextLines = []
        if scannerState != .scanning {
            scannerState = .idle
        }
    }
    
    /// Manually trigger search with current hint
    func searchWithCurrentHint() async {
        guard let hint = lastScanResult?.parsedHint, hint.hasStrongHint else { return }
        
        do {
            isProcessing = true
            let matches = try await apiClient.searchCards(hint: hint)
            detectedMatches = matches
        } catch {
            print("Search error: \(error)")
        }
        isProcessing = false
    }
    
    // MARK: - Private Methods
    
    private func setupFrameProcessing() {
        cameraService.framePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                Task { @MainActor [weak self] in
                    await self?.processFrame(image)
                }
            }
            .store(in: &cancellables)
    }
    
    private func processFrame(_ image: UIImage) async {
        guard !isProcessing else { return }
        
        isProcessing = true
        scannerState = .processing
        
        let startTime = Date()
        
        do {
            // Perform OCR
            let recognizedTexts = try await ocrService.recognizeText(from: image)
            
            // Update debug overlay
            recognizedTextLines = recognizedTexts.map { $0.text }
            
            // Parse the results
            let parsedHint = cardParser.parse(recognizedTexts)
            
            let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)
            
            let scanResult = ScanResult(
                recognizedTexts: recognizedTexts,
                parsedHint: parsedHint,
                processingTimeMs: processingTime
            )
            
            lastScanResult = scanResult
            
            // If we have a strong hint, search for matches
            if parsedHint.hasStrongHint {
                scannerState = .cardDetected(parsedHint)
                
                let matches = try await apiClient.searchCards(hint: parsedHint)
                detectedMatches = matches
            } else {
                scannerState = .scanning
            }
            
        } catch {
            print("Frame processing error: \(error)")
            scannerState = .scanning
        }
        
        isProcessing = false
    }
}

// MARK: - Scanner View State
extension ScannerViewModel {
    
    var shouldShowResults: Bool {
        !detectedMatches.isEmpty
    }
    
    var topMatch: CardMatch? {
        detectedMatches.first
    }
    
    var parsedHintDescription: String {
        lastScanResult?.parsedHint.debugDescription ?? "No data"
    }
}
