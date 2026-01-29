//
//  ResultsListView.swift
//  Decked
//
//  Displays card search/identification results
//

import SwiftUI

struct ResultsListView: View {
    
    let matches: [CardMatch]
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMatch: CardMatch?
    
    var body: some View {
        ZStack {
            // Background
            Color.deckBackground
                .ignoresSafeArea()
            
            if matches.isEmpty {
                emptyState
            } else {
                resultsList
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.deckAccent)
            }
        }
        .toolbarBackground(Color.deckBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(item: $selectedMatch) { match in
            CardDetailView(match: match)
        }
    }
    
    // MARK: - Results List
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Header
                HStack {
                    Text("\(matches.count) matches found")
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(.deckTextSecondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Results
                ForEach(matches) { match in
                    ResultCardRow(match: match) {
                        selectedMatch = match
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.deckTextMuted)
            
            Text("No matches found")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundColor(.deckTextPrimary)
            
            Text("Try scanning the card again\nor adjust the position")
                .font(.system(.body, design: .default))
                .foregroundColor(.deckTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Result Card Row

struct ResultCardRow: View {
    
    let match: CardMatch
    let onSelect: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Card image
                cardImage
                
                // Card details
                cardDetails
                
                Spacer()
                
                // Right side
                VStack(alignment: .trailing, spacing: 8) {
                    // Confidence
                    confidenceBadge
                    
                    // Price if available
                    if let price = match.card.marketPrice {
                        Text(String(format: "$%.2f", price))
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundColor(.deckAccent)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.deckAccent)
                }
            }
            .padding(16)
            .background(Color.deckSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        match.card.rarity.color.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    // MARK: - Card Image
    
    private var cardImage: some View {
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
                    .overlay(
                        DeckGradients.cardShine
                    )
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
        .frame(width: 80, height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: match.card.rarity.color.opacity(0.3), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Card Details
    
    private var cardDetails: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Name
            Text(match.card.name)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(.deckTextPrimary)
                .lineLimit(2)
            
            // Set and number
            Text("\(match.card.setName)")
                .font(.system(.subheadline, design: .default))
                .foregroundColor(.deckTextSecondary)
            
            Text("#\(match.card.number)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.deckTextMuted)
            
            // Rarity
            HStack(spacing: 8) {
                RarityBadge(rarity: match.card.rarity)
                
                if match.card.hp != nil {
                    Text("\(match.card.hp!) HP")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.deckTextSecondary)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Confidence Badge
    
    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: confidenceIcon)
                .font(.system(size: 10, weight: .bold))
            
            Text("\(match.confidencePercentage)%")
                .font(.system(.caption2, design: .rounded, weight: .bold))
        }
        .foregroundColor(confidenceColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(confidenceColor.opacity(0.15))
        .clipShape(Capsule())
    }
    
    private var confidenceIcon: String {
        if match.confidence >= 0.8 {
            return "checkmark.circle.fill"
        } else if match.confidence >= 0.5 {
            return "questionmark.circle.fill"
        } else {
            return "exclamationmark.circle.fill"
        }
    }
    
    private var confidenceColor: Color {
        if match.confidence >= 0.8 {
            return .deckSuccess
        } else if match.confidence >= 0.5 {
            return .deckWarning
        } else {
            return .deckTextMuted
        }
    }
}

// MARK: - Preview

#Preview {
    ResultsListView(
        matches: [
            CardMatch(
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
                    artist: nil,
                    supertype: nil,
                    subtypes: nil,
                    hp: nil,
                    types: nil,
                    nationalPokedexNumber: nil,
                    marketPrice: 150.0,
                    lowPrice: nil,
                    highPrice: nil,
                    setSeries: nil,
                    setReleaseDate: nil,
                    setTotalCards: nil
                ),
                confidence: 0.92,
                matchedFields: ["name", "number"]
            ),
            CardMatch(
                id: "base1-58",
                card: Card(
                    id: "base1-58",
                    name: "Pikachu",
                    setId: "base1",
                    setName: "Base Set",
                    number: "58",
                    rarity: .common,
                    imageURL: URL(string: "https://images.pokemontcg.io/base1/58.png"),
                    imageURLHighRes: URL(string: "https://images.pokemontcg.io/base1/58_hires.png"),
                    artist: nil,
                    supertype: nil,
                    subtypes: nil,
                    hp: nil,
                    types: nil,
                    nationalPokedexNumber: nil,
                    marketPrice: 25.0,
                    lowPrice: nil,
                    highPrice: nil,
                    setSeries: nil,
                    setReleaseDate: nil,
                    setTotalCards: nil
                ),
                confidence: 0.78,
                matchedFields: ["name"]
            )
        ]
    )
}
