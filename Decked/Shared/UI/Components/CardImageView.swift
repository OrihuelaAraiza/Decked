//
//  CardImageView.swift
//  Decked
//
//  Reusable card image component with loading states
//

import SwiftUI

struct CardImageView: View {
    
    let url: URL?
    var size: CardImageSize = .medium
    var showRarityGlow: Bool = true
    var rarity: CardRarity = .common
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                placeholder
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(
                        DeckGradients.cardShine
                    )
            case .failure:
                errorPlaceholder
            @unknown default:
                placeholder
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
        .shadow(
            color: showRarityGlow ? rarity.color.opacity(0.4) : Color.black.opacity(0.2),
            radius: size.shadowRadius,
            x: 0,
            y: size.shadowY
        )
    }
    
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius)
            .fill(Color.deckSurface)
            .overlay(
                ProgressView()
                    .tint(.deckAccent)
            )
    }
    
    private var errorPlaceholder: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius)
            .fill(Color.deckSurface)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: size.iconSize))
                    if size != .small {
                        Text("Unavailable")
                            .font(.caption2)
                    }
                }
                .foregroundColor(.deckTextMuted)
            )
    }
}

// MARK: - Card Image Size

enum CardImageSize {
    case small
    case medium
    case large
    case full
    
    var width: CGFloat {
        switch self {
        case .small: return 60
        case .medium: return 100
        case .large: return 160
        case .full: return 280
        }
    }
    
    var height: CGFloat {
        width * 1.4 // Standard card aspect ratio
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 10
        case .large: return 14
        case .full: return 18
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 8
        case .large: return 12
        case .full: return 20
        }
    }
    
    var shadowY: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 4
        case .large: return 6
        case .full: return 10
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 20
        case .large: return 28
        case .full: return 36
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.deckBackground
            .ignoresSafeArea()
        
        HStack(spacing: 20) {
            CardImageView(
                url: URL(string: "https://images.pokemontcg.io/sv3/215.png"),
                size: .small,
                rarity: .secretRare
            )
            
            CardImageView(
                url: URL(string: "https://images.pokemontcg.io/sv3/215.png"),
                size: .medium,
                rarity: .secretRare
            )
            
            CardImageView(
                url: URL(string: "https://images.pokemontcg.io/sv3/215.png"),
                size: .large,
                rarity: .secretRare
            )
        }
    }
}
