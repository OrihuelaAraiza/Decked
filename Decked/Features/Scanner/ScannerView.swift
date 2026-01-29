//
//  ScannerView.swift
//  Decked
//
//  Main camera scanning view for card detection
//

import SwiftUI
import AVFoundation

struct ScannerView: View {
    
    @StateObject private var viewModel = ScannerViewModel()
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            ZStack {
                // Background
                Color.deckBackground
                    .ignoresSafeArea()
                
                // Camera preview
                CameraPreviewView(previewLayer: viewModel.previewLayer)
                    .ignoresSafeArea()
                
                // Scan overlay
                scanOverlay
                
                // Bottom controls
                VStack {
                    Spacer()
                    
                    // Status and detected info
                    statusPanel
                    
                    // Control buttons
                    controlButtons
                        .padding(.bottom, 30)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("decked")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(.deckAccent)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showDebugOverlay.toggle()
                    } label: {
                        Image(systemName: viewModel.showDebugOverlay ? "text.viewfinder" : "viewfinder")
                            .foregroundColor(.deckTextSecondary)
                    }
                }
            }
            .task {
                await viewModel.startScanning()
            }
            .onDisappear {
                viewModel.stopScanning()
            }
            .onChange(of: viewModel.navigationPath) { path in
                if path.isEmpty {
                    viewModel.resumeScanningAfterResults()
                }
            }
            .navigationDestination(for: ScannerRoute.self) { route in
                switch route {
                case .results(let matches):
                    ResultsListView(matches: matches)
                case .detail(let match):
                    CardDetailView(match: match)
                case .noResults(let hint, let attemptedQueries, let warning):
                    NoResultsView(
                        hint: hint,
                        attemptedQueries: attemptedQueries,
                        warning: warning,
                        autoConfirmSingleMatch: viewModel.autoConfirmSingleMatch,
                        onShowResults: { matches in
                            viewModel.navigationPath.append(.results(matches))
                        },
                        onShowDetail: { match in
                            viewModel.navigationPath.append(.detail(match))
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Scan Overlay
    
    private var scanOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                // Darkened corners
                scanFrame(in: geometry)
                
                // Center frame
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        viewModel.hasDetectedCard ? Color.deckSuccess : Color.deckAccent.opacity(0.6),
                        lineWidth: viewModel.hasDetectedCard ? 3 : 2
                    )
                    .frame(
                        width: geometry.size.width * 0.75,
                        height: geometry.size.width * 0.75 * 1.4 // Card aspect ratio
                    )
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * 0.4
                    )
                    .animation(.easeInOut(duration: 0.2), value: viewModel.hasDetectedCard)
                
                // Corner brackets
                cornerBrackets(in: geometry)
                
                // Debug overlay
                if viewModel.showDebugOverlay {
                    debugOverlay(in: geometry)
                }
                
                // Scanning animation
                if viewModel.scannerState == .scanning || viewModel.scannerState == .processing {
                    scanningIndicator(in: geometry)
                }
            }
        }
    }
    
    private func scanFrame(in geometry: GeometryProxy) -> some View {
        let frameWidth = geometry.size.width * 0.75
        let frameHeight = frameWidth * 1.4
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height * 0.4
        
        return Path { path in
            // Full screen
            path.addRect(CGRect(origin: .zero, size: geometry.size))
            
            // Cut out center
            let cutout = CGRect(
                x: centerX - frameWidth / 2,
                y: centerY - frameHeight / 2,
                width: frameWidth,
                height: frameHeight
            )
            path.addRoundedRect(in: cutout, cornerSize: CGSize(width: 16, height: 16))
        }
        .fill(Color.black.opacity(0.5), style: FillStyle(eoFill: true))
    }
    
    private func cornerBrackets(in geometry: GeometryProxy) -> some View {
        let frameWidth = geometry.size.width * 0.75
        let frameHeight = frameWidth * 1.4
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height * 0.4
        let bracketSize: CGFloat = 30
        let bracketWeight: CGFloat = 4
        
        let color = viewModel.hasDetectedCard ? Color.deckSuccess : Color.deckAccent
        
        return ZStack {
            // Top-left
            CornerBracket()
                .stroke(color, lineWidth: bracketWeight)
                .frame(width: bracketSize, height: bracketSize)
                .position(
                    x: centerX - frameWidth / 2 + bracketSize / 2,
                    y: centerY - frameHeight / 2 + bracketSize / 2
                )
            
            // Top-right
            CornerBracket()
                .stroke(color, lineWidth: bracketWeight)
                .frame(width: bracketSize, height: bracketSize)
                .rotationEffect(.degrees(90))
                .position(
                    x: centerX + frameWidth / 2 - bracketSize / 2,
                    y: centerY - frameHeight / 2 + bracketSize / 2
                )
            
            // Bottom-left
            CornerBracket()
                .stroke(color, lineWidth: bracketWeight)
                .frame(width: bracketSize, height: bracketSize)
                .rotationEffect(.degrees(-90))
                .position(
                    x: centerX - frameWidth / 2 + bracketSize / 2,
                    y: centerY + frameHeight / 2 - bracketSize / 2
                )
            
            // Bottom-right
            CornerBracket()
                .stroke(color, lineWidth: bracketWeight)
                .frame(width: bracketSize, height: bracketSize)
                .rotationEffect(.degrees(180))
                .position(
                    x: centerX + frameWidth / 2 - bracketSize / 2,
                    y: centerY + frameHeight / 2 - bracketSize / 2
                )
        }
    }
    
    private func debugOverlay(in geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("OCR Debug")
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .foregroundColor(.deckAccent)
            
            ForEach(viewModel.recognizedTextLines.prefix(10), id: \.self) { line in
                Text(line)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.deckTextSecondary)
            }
            
            Divider()
                .background(Color.deckSurfaceElevated)
            
            Text(viewModel.parsedHintDescription)
                .font(.system(.caption2, design: .monospaced, weight: .medium))
                .foregroundColor(.deckSuccess)
        }
        .padding(12)
        .background(Color.deckBackground.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: geometry.size.width * 0.9)
        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.82)
    }
    
    private func scanningIndicator(in geometry: GeometryProxy) -> some View {
        let frameWidth = geometry.size.width * 0.75
        let frameHeight = frameWidth * 1.4
        let centerY = geometry.size.height * 0.4
        
        return ScanningLine()
            .stroke(
                LinearGradient(
                    colors: [.clear, .deckAccent, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
            .frame(width: frameWidth - 20, height: frameHeight - 20)
            .position(x: geometry.size.width / 2, y: centerY)
    }
    
    // MARK: - Status Panel
    
    private var statusPanel: some View {
        VStack(spacing: 12) {
            // Status badge
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(viewModel.statusText)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundColor(.deckTextPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.deckSurface.opacity(0.9))
            .clipShape(Capsule())
            
            // Detected card preview
            if let topMatch = viewModel.topMatch {
                DetectedCardPreview(match: topMatch) {
                    viewModel.pushResults()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.topMatch?.id)
    }
    
    private var statusColor: Color {
        switch viewModel.scannerState {
        case .idle:
            return .deckTextMuted
        case .scanning:
            return .deckAccent
        case .processing:
            return .deckWarning
        case .cardDetected:
            return .deckSuccess
        case .showingResults:
            return .deckSuccess
        case .noResults:
            return .deckWarning
        case .error:
            return .deckError
        }
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(spacing: 40) {
            // Clear button
            Button {
                viewModel.clearResults()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.deckTextSecondary)
                    .frame(width: 50, height: 50)
                    .background(Color.deckSurface)
                    .clipShape(Circle())
            }
            
            // Pause/Resume button
            Button {
                viewModel.togglePause()
            } label: {
                Image(systemName: viewModel.scannerState == .scanning ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.deckBackground)
                    .frame(width: 70, height: 70)
                    .background(
                        DeckGradients.accentGradient
                    )
                    .clipShape(Circle())
                    .shadow(color: .deckAccentGlow, radius: 15)
            }
            
            // Manual search
            Button {
                Task {
                    await viewModel.searchWithCurrentHint()
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.deckTextSecondary)
                    .frame(width: 50, height: 50)
                    .background(Color.deckSurface)
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Corner Bracket Shape

struct CornerBracket: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        return path
    }
}

// MARK: - Scanning Line Animation

struct ScanningLine: Shape {
    @State private var offset: CGFloat = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - Detected Card Preview

struct DetectedCardPreview: View {
    let match: CardMatch
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Card image
                AsyncImage(url: match.card.imageURL) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.deckSurfaceElevated)
                            .overlay(
                                ProgressView()
                                    .tint(.deckAccent)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.deckSurfaceElevated)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.deckTextMuted)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Card info
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.card.name)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundColor(.deckTextPrimary)
                    
                    Text("\(match.card.setName) · #\(match.card.number)")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.deckTextSecondary)
                    
                    HStack(spacing: 8) {
                        RarityBadge(rarity: match.card.rarity)
                        
                        Text("\(match.confidencePercentage)% match")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.deckTextMuted)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.deckTextMuted)
            }
            .padding(16)
            .background(Color.deckSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rarity Badge

struct RarityBadge: View {
    let rarity: CardRarity
    
    var body: some View {
        Text(rarity.shortName)
            .font(.system(.caption2, design: .rounded, weight: .bold))
            .foregroundColor(.deckBackground)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(rarity.color)
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    ScannerView()
}
