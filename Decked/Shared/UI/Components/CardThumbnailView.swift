//
//  CardThumbnailView.swift
//  Decked
//
//  Reusable card thumbnail component
//

import SwiftUI

struct CardThumbnailView: View {
    let imageURL: URL?
    let showQuantity: Bool
    let quantity: Int
    let size: CardThumbnailSize
    
    init(
        imageURL: URL?,
        showQuantity: Bool = false,
        quantity: Int = 1,
        size: CardThumbnailSize = .medium
    ) {
        self.imageURL = imageURL
        self.showQuantity = showQuantity
        self.quantity = quantity
        self.size = size
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Card image
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    placeholder
                        .overlay(
                            ProgressView()
                                .tint(.deckAccent)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholder
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: size.placeholderIconSize))
                                .foregroundColor(.deckTextMuted)
                        )
                @unknown default:
                    placeholder
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .strokeBorder(Color.deckSurfaceElevated.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            // Quantity badge
            if showQuantity && quantity > 1 {
                Text("\(quantity)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundColor(.deckBackground)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.deckAccent)
                            .shadow(color: .deckAccentGlow.opacity(0.5), radius: 3)
                    )
                    .offset(x: -4, y: 4)
            }
        }
    }
    
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.deckSurfaceElevated,
                        Color.deckSurface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Card Thumbnail Size

enum CardThumbnailSize {
    case small
    case medium
    case large
    case extraLarge
    
    var width: CGFloat {
        switch self {
        case .small: return 60
        case .medium: return 100
        case .large: return 140
        case .extraLarge: return 200
        }
    }
    
    var height: CGFloat {
        width * 1.4 // Standard card aspect ratio
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 12
        case .extraLarge: return 16
        }
    }
    
    var placeholderIconSize: CGFloat {
        switch self {
        case .small: return 20
        case .medium: return 28
        case .large: return 36
        case .extraLarge: return 48
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CardThumbnailView(
            imageURL: URL(string: "https://images.pokemontcg.io/base1/4.png"),
            showQuantity: true,
            quantity: 3,
            size: .small
        )
        
        CardThumbnailView(
            imageURL: URL(string: "https://images.pokemontcg.io/base1/4.png"),
            showQuantity: true,
            quantity: 5,
            size: .medium
        )
        
        CardThumbnailView(
            imageURL: nil,
            size: .large
        )
    }
    .padding()
    .background(Color.deckBackground)
}
