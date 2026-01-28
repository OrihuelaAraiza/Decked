//
//  LoadingView.swift
//  Decked
//
//  Reusable loading states and animations
//

import SwiftUI

// MARK: - Loading View

struct LoadingView: View {
    
    var message: String? = nil
    var style: LoadingStyle = .default
    
    var body: some View {
        VStack(spacing: 16) {
            switch style {
            case .default:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .deckAccent))
                    .scaleEffect(1.2)
            case .cards:
                CardLoadingAnimation()
            case .scanning:
                ScanningAnimation()
            }
            
            if let message = message {
                Text(message)
                    .font(.system(.subheadline, design: .default))
                    .foregroundColor(.deckTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.deckBackground)
    }
}

enum LoadingStyle {
    case `default`
    case cards
    case scanning
}

// MARK: - Card Loading Animation

struct CardLoadingAnimation: View {
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.deckSurface,
                                Color.deckSurfaceElevated
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 70)
                    .rotationEffect(.degrees(Double(index - 1) * 15 + rotation))
                    .offset(x: CGFloat(index - 1) * 8)
                    .scaleEffect(scale)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                rotation = 10
                scale = 1.1
            }
        }
    }
}

// MARK: - Scanning Animation

struct ScanningAnimation: View {
    
    @State private var scanOffset: CGFloat = -60
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        ZStack {
            // Card outline
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.deckAccent.opacity(0.3), lineWidth: 2)
                .frame(width: 80, height: 112)
            
            // Scanning line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .deckAccent, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 60, height: 3)
                .offset(y: scanOffset)
            
            // Glow effect
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.deckAccent)
                .frame(width: 80, height: 112)
                .opacity(glowOpacity)
                .blur(radius: 20)
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                scanOffset = 60
            }
            
            withAnimation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
            ) {
                glowOpacity = 0.6
            }
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.2),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
            )
            .clipped()
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton View

struct SkeletonView: View {
    
    var width: CGFloat? = nil
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.deckSurface)
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.deckBackground
            .ignoresSafeArea()
        
        VStack(spacing: 40) {
            LoadingView(message: "Loading...", style: .default)
                .frame(height: 100)
            
            LoadingView(message: "Loading cards...", style: .cards)
                .frame(height: 150)
            
            LoadingView(message: "Scanning...", style: .scanning)
                .frame(height: 180)
            
            VStack(spacing: 12) {
                SkeletonView(height: 20)
                SkeletonView(width: 150, height: 16)
                SkeletonView(width: 100, height: 16)
            }
            .padding()
        }
    }
}
