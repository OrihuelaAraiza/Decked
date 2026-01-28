//
//  DeckedLogoView.swift
//  Decked
//
//  Premium app icon design
//

import SwiftUI

struct DeckedLogoView: View {
    
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: size * 0.2237) // 229/1024 for iOS standard
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "0A1628"),
                            Color(hex: "0F172A")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Letter D made of stacked cards
            cardStackD
                .frame(width: size * 0.65, height: size * 0.7)
        }
        .frame(width: size, height: size)
    }
    
    // MARK: - Card Stack D
    
    private var cardStackD: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.18
            let cardHeight = geometry.size.height * 0.16
            let spacing = geometry.size.height * 0.02
            
            ZStack(alignment: .leading) {
                // Vertical left spine of D (stack of cards)
                VStack(spacing: spacing) {
                    ForEach(0..<5, id: \.self) { index in
                        CardShape(index: index)
                            .frame(width: cardWidth, height: cardHeight)
                    }
                }
                .offset(x: 0)
                
                // Curved right side (arc cards)
                arcCards(cardWidth: cardWidth, cardHeight: cardHeight, geometry: geometry)
            }
        }
    }
    
    // MARK: - Arc Cards
    
    private func arcCards(cardWidth: CGFloat, cardHeight: CGFloat, geometry: GeometryProxy) -> some View {
        ZStack {
            // Top curve cards
            CardShape(index: 0, isAccent: true)
                .frame(width: cardWidth * 1.8, height: cardHeight * 0.8)
                .rotationEffect(.degrees(-10))
                .offset(
                    x: geometry.size.width * 0.25,
                    y: geometry.size.height * 0.05
                )
            
            CardShape(index: 1, isAccent: true)
                .frame(width: cardWidth * 1.6, height: cardHeight * 0.8)
                .rotationEffect(.degrees(5))
                .offset(
                    x: geometry.size.width * 0.45,
                    y: geometry.size.height * 0.15
                )
            
            // Middle curve card
            CardShape(index: 2, isAccent: true)
                .frame(width: cardWidth * 1.5, height: cardHeight * 0.8)
                .rotationEffect(.degrees(20))
                .offset(
                    x: geometry.size.width * 0.55,
                    y: geometry.size.height * 0.38
                )
            
            // Bottom curve cards
            CardShape(index: 3, isAccent: true)
                .frame(width: cardWidth * 1.6, height: cardHeight * 0.8)
                .rotationEffect(.degrees(35))
                .offset(
                    x: geometry.size.width * 0.48,
                    y: geometry.size.height * 0.62
                )
            
            CardShape(index: 4, isAccent: true)
                .frame(width: cardWidth * 1.8, height: cardHeight * 0.8)
                .rotationEffect(.degrees(50))
                .offset(
                    x: geometry.size.width * 0.28,
                    y: geometry.size.height * 0.77
                )
        }
    }
}

// MARK: - Card Shape

struct CardShape: View {
    let index: Int
    var isAccent: Bool = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(
                        isAccent ? Color(hex: "38BDF8").opacity(0.4) : Color.white.opacity(0.15),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isAccent ? Color(hex: "38BDF8").opacity(0.3) : Color.black.opacity(0.3),
                radius: isAccent ? 8 : 4,
                x: 0,
                y: 2
            )
    }
    
    private var gradientColors: [Color] {
        if isAccent {
            return [
                Color(hex: "38BDF8").opacity(0.9),
                Color(hex: "22D3EE").opacity(0.8)
            ]
        } else {
            return [
                Color(hex: "1E293B"),
                Color(hex: "0F172A")
            ]
        }
    }
}

// MARK: - Preview & Export Helper

#Preview("Logo 1024x1024") {
    DeckedLogoView(size: 1024)
}

#Preview("Logo 512x512") {
    DeckedLogoView(size: 512)
}

#Preview("Logo 180x180") {
    DeckedLogoView(size: 180)
}

// MARK: - Export Helper View

struct LogoExportView: View {
    
    @State private var isExporting = false
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Decked Logo")
                .font(.system(.title, design: .rounded, weight: .bold))
            
            DeckedLogoView(size: 300)
                .clipShape(RoundedRectangle(cornerRadius: 67))
            
            Button("Export App Icon") {
                exportIcons()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isExporting)
        }
        .padding()
    }
    
    @MainActor
    private func exportIcons() {
        isExporting = true
        
        // Generate different sizes for iOS app icon
        let sizes: [CGFloat] = [
            20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024
        ]
        
        for size in sizes {
            let renderer = ImageRenderer(content: DeckedLogoView(size: size))
            renderer.scale = 1.0
            
            if let image = renderer.uiImage {
                // Save to photo library or files
                print("Generated icon at \(size)x\(size)")
                // You can save using PHPhotoLibrary or FileManager here
            }
        }
        
        isExporting = false
    }
}

#Preview("Export Helper") {
    LogoExportView()
}
