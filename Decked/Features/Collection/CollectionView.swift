//
//  CollectionView.swift
//  Decked
//
//  Overview of user's card collection
//

import SwiftUI

struct CollectionView: View {
    
    @StateObject private var viewModel = CollectionViewModel()
    @State private var selectedCard: CollectionCard?
    @State private var searchText = ""
    @State private var selectedFilter: CollectionFilter = .all
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DeckGradients.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Stats header
                    statsHeader
                    
                    // Filter tabs
                    filterTabs
                    
                    // Content
                    if viewModel.cards.isEmpty {
                        emptyState
                    } else {
                        cardsGrid
                    }
                }
            }
            .navigationTitle("Collection")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search cards..."
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.sortOption = .dateAdded
                        } label: {
                            Label("Date Added", systemImage: viewModel.sortOption == .dateAdded ? "checkmark" : "")
                        }
                        
                        Button {
                            viewModel.sortOption = .name
                        } label: {
                            Label("Name", systemImage: viewModel.sortOption == .name ? "checkmark" : "")
                        }
                        
                        Button {
                            viewModel.sortOption = .value
                        } label: {
                            Label("Value", systemImage: viewModel.sortOption == .value ? "checkmark" : "")
                        }
                        
                        Button {
                            viewModel.sortOption = .rarity
                        } label: {
                            Label("Rarity", systemImage: viewModel.sortOption == .rarity ? "checkmark" : "")
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .foregroundColor(.deckAccent)
                    }
                }
            }
            .toolbarBackground(Color.deckBackground, for: .navigationBar)
            .sheet(item: $selectedCard) { card in
                CardDetailView(card: card)
            }
            .task {
                await viewModel.loadCollection()
            }
            .onChange(of: searchText) { _, newValue in
                viewModel.searchText = newValue
            }
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CollectionStatCard(
                    icon: "square.stack.3d.up.fill",
                    value: "\(viewModel.totalCards)",
                    label: "Cards",
                    color: .deckAccent
                )
                
                CollectionStatCard(
                    icon: "dollarsign.circle.fill",
                    value: viewModel.formattedTotalValue,
                    label: "Value",
                    color: .deckSuccess
                )
                
                CollectionStatCard(
                    icon: "star.fill",
                    value: "\(viewModel.uniqueCards)",
                    label: "Unique",
                    color: .raritySAR
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Filter Tabs
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CollectionFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        viewModel.filter = filter
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }
    
    // MARK: - Cards Grid
    
    private var cardsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.filteredCards) { card in
                    CollectionCardCell(card: card) {
                        selectedCard = card
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.deckSurface)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "square.stack.3d.up.slash")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.deckTextMuted)
            }
            
            VStack(spacing: 12) {
                Text("No Cards Yet")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(.deckTextPrimary)
                
                Text("Start scanning cards to build\nyour collection")
                    .font(.system(.body, design: .default))
                    .foregroundColor(.deckTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Collection Stat Card

struct CollectionStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(.deckTextPrimary)
            
            Text(label)
                .font(.system(.caption, design: .default))
                .foregroundColor(.deckTextSecondary)
        }
        .frame(width: 100)
        .padding()
        .background(Color.deckSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundColor(isSelected ? .deckBackground : .deckTextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.deckAccent : Color.deckSurface)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Collection Card Cell

struct CollectionCardCell: View {
    let card: CollectionCard
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Card image
                AsyncImage(url: card.card.imageURL) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.deckSurface)
                            .aspectRatio(0.714, contentMode: .fit)
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
                            .fill(Color.deckSurface)
                            .aspectRatio(0.714, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.deckTextMuted)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .aspectRatio(0.714, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Badges overlay
                HStack(spacing: 4) {
                    // Quantity
                    if card.quantity > 1 {
                        Text("×\(card.quantity)")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    // Condition
                    Text(card.condition.shortName)
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(conditionColor.opacity(0.8))
                        .clipShape(Capsule())
                }
                .padding(6)
                .offset(y: -30)
            }
        }
        .buttonStyle(.plain)
        .shadow(color: card.card.rarity.color.opacity(0.3), radius: 6, x: 0, y: 3)
    }
    
    var conditionColor: Color {
        switch card.condition {
        case .nearMint: return .conditionNM
        case .lightlyPlayed: return .conditionLP
        case .moderatelyPlayed: return .conditionMP
        case .heavilyPlayed: return .conditionHP
        case .damaged: return .deckError
        }
    }
}

// MARK: - Card Detail View

struct CardDetailView: View {
    
    let card: CollectionCard
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deckBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Large card image
                        AsyncImage(url: card.card.imageURLHighRes ?? card.card.imageURL) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.deckSurface)
                                    .aspectRatio(0.714, contentMode: .fit)
                                    .overlay(ProgressView().tint(.deckAccent))
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            case .failure:
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.deckSurface)
                                    .aspectRatio(0.714, contentMode: .fit)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: 280)
                        .shadow(color: card.card.rarity.color.opacity(0.5), radius: 20)
                        
                        // Card info
                        VStack(spacing: 16) {
                            Text(card.card.name)
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundColor(.deckTextPrimary)
                            
                            Text("\(card.card.setName) · #\(card.card.number)")
                                .font(.system(.subheadline))
                                .foregroundColor(.deckTextSecondary)
                            
                            HStack(spacing: 12) {
                                RarityBadge(rarity: card.card.rarity)
                                
                                Text(card.language.flag)
                                
                                Text(card.condition.shortName)
                                    .font(.system(.caption, design: .rounded, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.conditionNM)
                                    .clipShape(Capsule())
                                
                                if card.isFoil {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.raritySAR)
                                }
                            }
                        }
                        
                        // Details section
                        VStack(spacing: 12) {
                            DetailRow(label: "Quantity", value: "×\(card.quantity)")
                            
                            if let pricePaid = card.pricePaid {
                                DetailRow(label: "Price Paid", value: "$\(pricePaid, default: "%.2f")")
                            }
                            
                            if let marketPrice = card.card.marketPrice {
                                DetailRow(label: "Market Price", value: "$\(marketPrice, default: "%.2f")")
                            }
                            
                            if let estimatedValue = card.estimatedValue {
                                DetailRow(label: "Estimated Value", value: "$\(estimatedValue, default: "%.2f")")
                            }
                            
                            DetailRow(
                                label: "Added",
                                value: card.dateAdded.formatted(date: .abbreviated, time: .omitted)
                            )
                        }
                        .padding()
                        .background(Color.deckSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Card Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.deckAccent)
                }
            }
            .toolbarBackground(Color.deckBackground, for: .navigationBar)
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(.body))
                .foregroundColor(.deckTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundColor(.deckTextPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    CollectionView()
}
