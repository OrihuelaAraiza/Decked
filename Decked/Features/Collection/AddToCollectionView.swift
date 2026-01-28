//
//  AddToCollectionView.swift
//  Decked
//
//  Form for adding a card to the collection
//

import SwiftUI

struct AddToCollectionView: View {
    
    let card: Card
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddToCollectionViewModel
    
    init(card: Card) {
        self.card = card
        self._viewModel = StateObject(wrappedValue: AddToCollectionViewModel(card: card))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.deckBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Card preview
                        cardPreview
                        
                        // Form sections
                        VStack(spacing: 20) {
                            languageSection
                            conditionSection
                            foilSection
                            quantitySection
                            priceSection
                            binderSection
                        }
                        .padding(.horizontal)
                        
                        // Add button
                        addButton
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Add to Collection")
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
        }
    }
    
    // MARK: - Card Preview
    
    private var cardPreview: some View {
        VStack(spacing: 16) {
            // Card image
            AsyncImage(url: card.imageURLHighRes ?? card.imageURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.deckSurface)
                        .overlay(
                            ProgressView()
                                .tint(.deckAccent)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .overlay(
                            DeckGradients.cardShine
                        )
                case .failure:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.deckSurface)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                Text("Image unavailable")
                                    .font(.caption)
                            }
                            .foregroundColor(.deckTextMuted)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: card.rarity.color.opacity(0.4), radius: 20, x: 0, y: 8)
            
            // Card info
            VStack(spacing: 8) {
                Text(card.name)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(.deckTextPrimary)
                
                Text("\(card.setName) · #\(card.number)")
                    .font(.system(.subheadline, design: .default))
                    .foregroundColor(.deckTextSecondary)
                
                HStack(spacing: 12) {
                    RarityBadge(rarity: card.rarity)
                    
                    if let price = card.marketPrice {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 12))
                            Text(String(format: "$%.2f", price))
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        }
                        .foregroundColor(.deckAccent)
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Language Section
    
    private var languageSection: some View {
        FormSection(title: "Language") {
            HStack(spacing: 12) {
                ForEach([CardLanguage.english, .spanish, .japanese], id: \.self) { language in
                    LanguageButton(
                        language: language,
                        isSelected: viewModel.selectedLanguage == language
                    ) {
                        viewModel.selectedLanguage = language
                    }
                }
            }
        }
    }
    
    // MARK: - Condition Section
    
    private var conditionSection: some View {
        FormSection(title: "Condition") {
            HStack(spacing: 8) {
                ForEach(CardCondition.allCases, id: \.self) { condition in
                    ConditionButton(
                        condition: condition,
                        isSelected: viewModel.selectedCondition == condition
                    ) {
                        viewModel.selectedCondition = condition
                    }
                }
            }
        }
    }
    
    // MARK: - Foil Section
    
    private var foilSection: some View {
        FormSection(title: "Finish") {
            HStack(spacing: 16) {
                FinishButton(
                    title: "Regular",
                    icon: "square",
                    isSelected: !viewModel.isFoil
                ) {
                    viewModel.isFoil = false
                }
                
                FinishButton(
                    title: "Foil",
                    icon: "sparkles",
                    isSelected: viewModel.isFoil
                ) {
                    viewModel.isFoil = true
                }
            }
        }
    }
    
    // MARK: - Quantity Section
    
    private var quantitySection: some View {
        FormSection(title: "Quantity") {
            HStack {
                Button {
                    if viewModel.quantity > 1 {
                        viewModel.quantity -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.deckTextPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.deckSurfaceElevated)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("\(viewModel.quantity)")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.deckTextPrimary)
                    .frame(minWidth: 60)
                
                Spacer()
                
                Button {
                    if viewModel.quantity < 99 {
                        viewModel.quantity += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.deckTextPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.deckSurfaceElevated)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Price Section
    
    private var priceSection: some View {
        FormSection(title: "Price Paid (Optional)") {
            VStack(spacing: 12) {
                HStack {
                    Text("$")
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .foregroundColor(.deckTextMuted)
                    
                    TextField("0.00", text: $viewModel.pricePaid)
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .foregroundColor(.deckTextPrimary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color.deckSurfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if let marketPrice = card.marketPrice {
                    HStack {
                        Text("Market price:")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.deckTextMuted)
                        
                        Text(String(format: "$%.2f", marketPrice))
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(.deckAccent)
                        
                        Spacer()
                        
                        Button("Use market price") {
                            viewModel.pricePaid = String(format: "%.2f", marketPrice)
                        }
                        .font(.system(.caption, design: .default, weight: .medium))
                        .foregroundColor(.deckAccent)
                    }
                }
            }
        }
    }
    
    // MARK: - Binder Section
    
    private var binderSection: some View {
        FormSection(title: "Add to Binder") {
            HStack {
                Image(systemName: "folder")
                    .font(.system(size: 18))
                    .foregroundColor(.deckAccent)
                
                Text(viewModel.selectedBinder?.name ?? "No binder selected")
                    .font(.system(.body, design: .default))
                    .foregroundColor(.deckTextPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.deckTextMuted)
            }
            .padding()
            .background(Color.deckSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Add Button
    
    private var addButton: some View {
        Button {
            Task {
                await viewModel.addToCollection()
                dismiss()
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add to Collection")
            }
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundColor(.deckBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(DeckGradients.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .deckAccentGlow, radius: 10)
        }
    }
}

// MARK: - Form Section

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(.subheadline, design: .default, weight: .medium))
                .foregroundColor(.deckTextSecondary)
            
            content()
        }
    }
}

// MARK: - Language Button

struct LanguageButton: View {
    let language: CardLanguage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(language.flag)
                    .font(.system(size: 24))
                
                Text(language.rawValue)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundColor(isSelected ? .deckAccent : .deckTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.deckAccent.opacity(0.15) : Color.deckSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.deckAccent : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Condition Button

struct ConditionButton: View {
    let condition: CardCondition
    let isSelected: Bool
    let action: () -> Void
    
    var conditionColor: Color {
        switch condition {
        case .nearMint: return .conditionNM
        case .lightlyPlayed: return .conditionLP
        case .moderatelyPlayed: return .conditionMP
        case .heavilyPlayed: return .conditionHP
        case .damaged: return .deckError
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(condition.shortName)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundColor(isSelected ? .deckBackground : conditionColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? conditionColor : conditionColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Finish Button

struct FinishButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
            }
            .foregroundColor(isSelected ? .deckAccent : .deckTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color.deckAccent.opacity(0.15) : Color.deckSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.deckAccent : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    AddToCollectionView(
        card: MockCardData.allCards.first { $0.id == "sv3-215" }!
    )
}
