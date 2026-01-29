//
//  CardDetailView.swift
//  Decked
//
//  Shows full card info with actions after a scan match
//

import SwiftUI

struct CardDetailView: View {
    
    let match: CardMatch
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddSheet = false
    
    private var card: Card { match.card }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    infoGrid
                    priceSection
                    metaSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color.deckBackground.ignoresSafeArea())
            .navigationTitle("Card Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.deckAccent)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddToCollectionView(card: card)
            }
            .safeAreaInset(edge: .bottom) {
                actionButtons
                    .padding()
                    .background(
                        Color.deckBackground
                            .opacity(0.95)
                            .shadow(color: .black.opacity(0.15), radius: 10)
                    )
            }
        }
    }
    
    // MARK: - Sections
    
    private var header: some View {
        VStack(spacing: 16) {
            CardHeroImageView(imageURL: card.imageLargeURL ?? card.imageURL)
            .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 6)
            
            VStack(spacing: 6) {
                Text(card.name)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(.deckTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text(setNumberLine)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.deckTextSecondary)
                
                HStack(spacing: 10) {
                    RarityBadge(rarity: card.rarity)
                    
                    ConfidenceChip(percentage: match.confidencePercentage)
                }
            }
        }
        .padding(.top, 24)
    }

    private var setNumberLine: String {
        if let total = card.setTotalCards {
            return "\(card.setName) • \(card.number)/\(total)"
        }
        return "\(card.setName) • \(card.number)"
    }
    
    private var infoGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(.deckTextPrimary)
            
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    DetailRow(label: "Card ID", value: card.id)
                        .gridCellColumns(2)
                }
                GridRow {
                    InfoChip(icon: "flame", title: "Type", value: card.types?.joined(separator: ", ") ?? "—")
                    InfoChip(icon: "heart.fill", title: "HP", value: card.hp ?? "—")
                }
                GridRow {
                    InfoChip(icon: "person", title: "Artist", value: card.artist ?? "Unknown")
                    InfoChip(icon: "sparkles", title: "Supertype", value: card.supertype ?? "—")
                }
                GridRow {
                    InfoChip(icon: "calendar", title: "Released", value: card.setReleaseDate ?? "—")
                    InfoChip(icon: "number.circle", title: "Set Total", value: card.setTotalCards.map { "\($0)" } ?? "—")
                }
            }
        }
    }
    
    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(.deckTextPrimary)
            
            if let market = card.marketPrice {
                HStack(spacing: 12) {
                    PricePill(label: "Market", value: market, color: .deckSuccess)
                    
                    if let low = card.lowPrice {
                        PricePill(label: "Low", value: low, color: .deckTextSecondary)
                    }
                    
                    if let high = card.highPrice {
                        PricePill(label: "High", value: high, color: .deckAccent)
                    }
                }
            } else {
                Text("No price data available")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.deckTextSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.deckSurface.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Matched On")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(.deckTextPrimary)
            
            if match.matchedFields.isEmpty {
                Text("Detected by visual scan")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.deckTextSecondary)
            } else {
                WrapChips(items: match.matchedFields) { field in
                    Text(field.capitalized)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundColor(.deckTextPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.deckSurface)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            PrimaryButton("Add to Binder", icon: "folder.badge.plus", style: .primary) {
                showingAddSheet = true
            }
            
            PrimaryButton("Seguir escaneando", icon: "camera.viewfinder", style: .secondary) {
                dismiss()
            }
        }
    }
}

// MARK: - Supporting UI

private struct InfoChip: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.deckAccent)
                .font(.system(size: 16, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.deckTextSecondary)
                Text(value)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(.deckTextPrimary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.deckSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundColor(.deckTextSecondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundColor(.deckTextPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.deckSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct CardHeroImageView: View {
    let imageURL: URL?
    
    var body: some View {
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
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.deckTextMuted)
                    )
            @unknown default:
                placeholder
            }
        }
        .frame(width: 220, height: 308)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.deckSurfaceElevated.opacity(0.4), lineWidth: 1)
        )
    }
    
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.deckSurfaceElevated, Color.deckSurface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

private struct PricePill: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(label.uppercased())
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundColor(color)
            
            Text(String(format: "$%.2f", value))
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(.deckTextPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.deckSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ConfidenceChip: View {
    let percentage: Int
    
    private var color: Color {
        switch percentage {
        case 80...100: return .deckSuccess
        case 50..<80: return .deckWarning
        default: return .deckTextSecondary
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.shield")
            Text("\(percentage)% match")
        }
        .font(.system(.caption, design: .rounded, weight: .bold))
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

private struct WrapChips<Content: View>: View {
    let items: [String]
    let content: (String) -> Content
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self, content: content)
        }
    }
}

/// Simple wrapping flow layout for chips
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? (UIScreen.main.bounds.width - 32)
        var width: CGFloat = 0
        var height: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: proposal.height))
            if width + size.width > maxWidth {
                height += rowHeight + spacing
                width = 0
                rowHeight = 0
            }
            width += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        
        height += rowHeight
        return CGSize(width: proposal.width ?? maxWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: proposal.height))
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Preview

#Preview {
    CardDetailView(
        match: CardMatch(
            id: "base1-4",
            card: Card(
                id: "base1-4",
                name: "Charizard",
                setId: "base1",
                setName: "Base Set",
                number: "4",
                rarity: .holo,
                imageURL: URL(string: "https://images.pokemontcg.io/base1/4.png"),
                imageURLHighRes: URL(string: "https://images.pokemontcg.io/base1/4_hires.png"),
                artist: "Mitsuhiro Arita",
                supertype: "Pokémon",
                subtypes: ["Stage 2"],
                hp: "120",
                types: ["Fire"],
                nationalPokedexNumber: 6,
                marketPrice: 150.0,
                lowPrice: 90.0,
                highPrice: 250.0,
                setSeries: "Base",
                setReleaseDate: "1999-01-09",
                setTotalCards: 102
            ),
            confidence: 0.92,
            matchedFields: ["name", "number"]
        )
    )
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
