//
//  BinderDetailView.swift
//  Decked
//
//  Detail view showing cards in a binder (album grid)
//

import SwiftUI
import CoreData

struct BinderDetailView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var binder: BinderEntity
    @State private var selectedCard: OwnedCardEntity?
    @State private var showingDeleteAlert = false
    
    private var cards: [OwnedCardEntity] {
        guard let cardsSet = binder.cards as? Set<OwnedCardEntity> else { return [] }
        return cardsSet.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deckBackground.ignoresSafeArea()
                
                if cards.isEmpty {
                    emptyState
                } else {
                    cardsGrid
                }
            }
            .navigationTitle(binder.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.deckTextSecondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Binder", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.deckTextSecondary)
                    }
                }
            }
            .sheet(item: $selectedCard) { card in
                OwnedCardDetailView(ownedCard: card)
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert("Delete Binder?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteBinder()
                }
            } message: {
                Text("This will delete the binder and all \(binder.cardCount) card(s) inside. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Cards Grid
    
    private var cardsGrid: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Binder stats
                statsSection
                
                // Cards grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 16
                ) {
                    ForEach(cards) { card in
                        CardGridItem(card: card) {
                            selectedCard = card
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatBadge(
                    icon: "rectangle.stack",
                    value: "\(binder.cardCount)",
                    label: "Cards"
                )
                
                StatBadge(
                    icon: "dollarsign.circle",
                    value: String(format: "$%.2f", binder.totalValue),
                    label: "Value"
                )
            }
            
            Text("Created \(binder.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.deckTextMuted)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        EmptyStateView(
            icon: "folder",
            title: "No Cards Yet",
            message: "Scan cards and add them to this binder to start your collection"
        )
    }
    
    // MARK: - Actions
    
    private func deleteBinder() {
        viewContext.delete(binder)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("❌ Failed to delete binder: \(error)")
        }
    }
}

// MARK: - Card Grid Item

struct CardGridItem: View {
    let card: OwnedCardEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                CardThumbnailView(
                    imageURL: card.catalogCard?.imageSmallURL.flatMap(URL.init(string:)),
                    showQuantity: true,
                    quantity: Int(card.quantity),
                    size: .medium
                )
                
                // Card badge indicators
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
                .padding(.top, 6)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.deckAccent)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundColor(.deckTextPrimary)
                
                Text(label)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.deckTextSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.deckSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.viewContext
    let binder = BinderEntity(context: context)
    binder.id = UUID()
    binder.title = "My Favorites"
    binder.createdAt = Date()
    
    return BinderDetailView(binder: binder)
        .environment(\.managedObjectContext, context)
}
