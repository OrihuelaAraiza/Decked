//
//  CollectionView.swift
//  Decked
//
//  Overview of user's card collection with Core Data
//

import SwiftUI
import CoreData

struct CollectionView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: CollectionViewModel
    @State private var selectedCard: OwnedCardEntity?
    @State private var selectedFilter: CollectionFilter = .all
    
    init() {
        let context = PersistenceController.shared.viewContext
        _viewModel = StateObject(wrappedValue: CollectionViewModel(viewContext: context))
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deckBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Stats header
                    statsHeader
                        .padding()
                    
                    // Filter tabs
                    filterTabs
                        .padding(.horizontal)
                    
                    // Content
                    if viewModel.isLoading {
                        LoadingView(message: "Loading collection...")
                    } else if viewModel.ownedCards.isEmpty {
                        emptyState
                    } else {
                        cardsGrid
                    }
                }
            }
            .navigationTitle("Collection")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search cards..."
            )
            .task {
                await viewModel.loadCollection()
            }
            .sheet(item: $selectedCard) { card in
                OwnedCardDetailView(ownedCard: card)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "rectangle.stack.fill",
                value: "\(viewModel.totalCards)",
                label: "Cards",
                color: .deckAccent
            )
            
            StatCard(
                icon: "square.grid.2x2.fill",
                value: "\(viewModel.uniqueCards)",
                label: "Unique",
                color: .deckSuccess
            )
            
            StatCard(
                icon: "dollarsign.circle.fill",
                value: viewModel.formattedTotalValue,
                label: "Value",
                color: .deckWarning
            )
        }
    }
    
    // MARK: - Filter Tabs
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CollectionFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.filter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.filter = filter
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Cards Grid
    
    private var cardsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.filteredCards) { card in
                    CollectionCardItem(card: card) {
                        selectedCard = card
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        EmptyStateView(
            icon: "square.stack.3d.up",
            title: "No Cards Yet",
            message: "Start scanning cards to build your collection"
        )
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(.deckTextPrimary)
            
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.deckTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.deckSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

// MARK: - Collection Card Item

struct CollectionCardItem: View {
    let card: OwnedCardEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                CardThumbnailView(
                    imageURL: card.catalogCard?.imageSmallURL.flatMap(URL.init(string:)),
                    showQuantity: true,
                    quantity: Int(card.quantity),
                    size: .medium
                )
                
                VStack(spacing: 4) {
                    Text(card.displayName)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(.deckTextPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        if card.isFoil {
                            Image(systemName: "sparkles")
                                .font(.system(size: 8))
                                .foregroundColor(.deckAccent)
                        }
                        
                        Text(card.languageEnum.code)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.deckTextMuted)
                        
                        Text(card.conditionEnum.shortCode)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(card.conditionEnum.color)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    CollectionView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
