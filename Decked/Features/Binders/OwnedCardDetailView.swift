//
//  OwnedCardDetailView.swift
//  Decked
//
//  Detail view for an owned card with editing capabilities
//

import SwiftUI
import CoreData

struct OwnedCardDetailView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var ownedCard: OwnedCardEntity
    
    @State private var quantity: Int
    @State private var isFoil: Bool
    @State private var selectedLanguage: CardLanguage
    @State private var selectedCondition: CardCondition
    @State private var purchasePrice: String
    @State private var showingDeleteAlert = false
    @State private var showingBinderPicker = false
    
    init(ownedCard: OwnedCardEntity) {
        self.ownedCard = ownedCard
        _quantity = State(initialValue: Int(ownedCard.quantity))
        _isFoil = State(initialValue: ownedCard.isFoil)
        _selectedLanguage = State(initialValue: ownedCard.languageEnum)
        _selectedCondition = State(initialValue: ownedCard.conditionEnum)
        _purchasePrice = State(initialValue: ownedCard.purchasePrice > 0 ? String(format: "%.2f", ownedCard.purchasePrice) : "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Card image
                    cardImageSection
                    
                    // Card info
                    cardInfoSection
                    
                    // Edit section
                    editSection
                    
                    // Actions
                    actionsSection
                }
                .padding()
            }
            .background(Color.deckBackground.ignoresSafeArea())
            .navigationTitle("Card Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundColor(.deckAccent)
                }
            }
            .alert("Delete Card?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteCard()
                }
            } message: {
                Text("This will remove this card from your collection. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Card Image Section
    
    private var cardImageSection: some View {
        CardThumbnailView(
            imageURL: ownedCard.catalogCard?.imageLargeURL.flatMap(URL.init(string:)),
            size: .extraLarge
        )
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Card Info Section
    
    private var cardInfoSection: some View {
        VStack(spacing: 12) {
            Text(ownedCard.displayName)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(.deckTextPrimary)
                .multilineTextAlignment(.center)
            
            if let catalogCard = ownedCard.catalogCard {
                HStack(spacing: 16) {
                    Label(catalogCard.setName, systemImage: "square.stack.3d.up")
                    Text("•")
                    Text("#\(catalogCard.number)")
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.deckTextSecondary)
                
                if let rarity = catalogCard.rarity {
                    RarityBadge(rarity: CardRarity(rawValue: rarity) ?? .common)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.deckSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Edit Section
    
    private var editSection: some View {
        VStack(spacing: 20) {
            // Language
            FormRow(label: "Language") {
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(CardLanguage.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Condition
            FormRow(label: "Condition") {
                Picker("Condition", selection: $selectedCondition) {
                    ForEach(CardCondition.allCases, id: \.self) { condition in
                        Text(condition.shortCode).tag(condition)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Foil toggle
            FormRow(label: "Foil") {
                Toggle("", isOn: $isFoil)
                    .tint(.deckAccent)
            }
            
            // Quantity stepper
            FormRow(label: "Quantity") {
                Stepper("\(quantity)", value: $quantity, in: 1...99)
                    .font(.system(.body, design: .rounded, weight: .medium))
            }
            
            // Purchase price
            FormRow(label: "Purchase Price") {
                HStack {
                    Text("$")
                        .foregroundColor(.deckTextSecondary)
                    TextField("0.00", text: $purchasePrice)
                        .keyboardType(.decimalPad)
                        .font(.system(.body, design: .rounded))
                }
            }
            
            // Suggested price (read-only)
            if ownedCard.suggestedPrice > 0 {
                FormRow(label: "Suggested Price") {
                    Text(String(format: "$%.2f", ownedCard.suggestedPrice))
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(.deckSuccess)
                }
            }
        }
        .padding()
        .background(Color.deckSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                "Delete Card",
                icon: "trash",
                style: .destructive
            ) {
                showingDeleteAlert = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveChanges() {
        ownedCard.quantity = Int16(quantity)
        ownedCard.isFoil = isFoil
        ownedCard.languageEnum = selectedLanguage
        ownedCard.conditionEnum = selectedCondition
        
        if let price = Double(purchasePrice) {
            ownedCard.purchasePrice = price
        } else {
            ownedCard.purchasePrice = 0
        }
        
        do {
            try viewContext.save()
            print("✅ Saved card changes")
        } catch {
            print("❌ Failed to save card changes: \(error)")
        }
    }
    
    private func deleteCard() {
        viewContext.delete(ownedCard)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("❌ Failed to delete card: \(error)")
        }
    }
}

// MARK: - Form Row

struct FormRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundColor(.deckTextSecondary)
            
            content
        }
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.viewContext
    let card = OwnedCardEntity(context: context)
    card.id = UUID()
    card.language = "EN"
    card.condition = "NM"
    card.isFoil = true
    card.quantity = 1
    card.createdAt = Date()
    
    return OwnedCardDetailView(ownedCard: card)
        .environment(\.managedObjectContext, context)
}
