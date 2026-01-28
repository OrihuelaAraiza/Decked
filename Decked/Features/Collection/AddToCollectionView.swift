//
//  AddToCollectionView.swift
//  Decked
//
//  Form for adding a card to the collection with Core Data
//

import SwiftUI
import CoreData

struct AddToCollectionView: View {
    
    let card: Card
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: AddToCollectionViewModel
    
    init(card: Card) {
        self.card = card
        // Will be updated by environment
        let context = PersistenceController.shared.viewContext
        self._viewModel = StateObject(wrappedValue: AddToCollectionViewModel(card: card, viewContext: context))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deckBackground.ignoresSafeArea()
                
                if viewModel.didSave {
                    successView
                } else {
                    formContent
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(viewModel.didSave ? "Done" : "Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.deckAccent)
                }
            }
            .sheet(isPresented: $viewModel.showingCreateBinder) {
                CreateBinderView { _ in
                    Task {
                        await viewModel.loadBinders()
                    }
                }
                .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    // MARK: - Form Content
    
    private var formContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Card preview
                cardPreview
                
                // Form
                VStack(spacing: 20) {
                    // Binder selection (first!)
                    binderSection
                    
                    // Card details
                    languageSection
                    conditionSection
                    foilSection
                    quantitySection
                    priceSection
                }
                .padding(.horizontal)
                
                // Error message
                if let error = viewModel.error {
                    Text(error)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.deckError)
                        .padding()
                }
                
                // Add button
                PrimaryButton(
                    "Add to Binder",
                    icon: "folder.badge.plus",
                    style: .primary,
                    isLoading: viewModel.isSaving
                ) {
                    Task {
                        await viewModel.addToCollection()
                    }
                }
                .disabled(!viewModel.canSave)
                .opacity(viewModel.canSave ? 1.0 : 0.5)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Card Preview
    
    private var cardPreview: some View {
        VStack(spacing: 16) {
            CardThumbnailView(
                imageURL: card.imageLargeURL ?? card.imageURL,
                size: .large
            )
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
            
            VStack(spacing: 8) {
                Text(card.name)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(.deckTextPrimary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    Text(card.setName)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.deckTextSecondary)
                    
                    Text("•")
                        .foregroundColor(.deckTextMuted)
                    
                    Text("#\(card.number)")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(.deckAccent)
                }
                
                RarityBadge(rarity: card.rarity)
            }
        }
        .padding(.top, 24)
    }
    
    // MARK: - Binder Section
    
    private var binderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Binder", systemImage: "folder")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(.deckTextPrimary)
            
            if viewModel.binders.isEmpty {
                // No binders yet
                Button {
                    viewModel.showingCreateBinder = true
                } label: {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Create Your First Binder")
                        Spacer()
                    }
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(.deckAccent)
                    .padding()
                    .background(Color.deckSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                // Binder picker
                Menu {
                    ForEach(viewModel.binders) { binder in
                        Button {
                            viewModel.selectedBinder = binder
                        } label: {
                            HStack {
                                Text(binder.title)
                                if viewModel.selectedBinder?.id == binder.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        viewModel.showingCreateBinder = true
                    } label: {
                        Label("Create New Binder", systemImage: "plus")
                    }
                } label: {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.deckAccent)
                        
                        Text(viewModel.selectedBinder?.title ?? "Select a binder")
                            .foregroundColor(viewModel.selectedBinder != nil ? .deckTextPrimary : .deckTextMuted)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.deckTextSecondary)
                    }
                    .padding()
                    .background(Color.deckSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(Color.deckSurface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Language Section
    
    private var languageSection: some View {
        FormSectionView(title: "Language", icon: "globe") {
            Picker("Language", selection: $viewModel.selectedLanguage) {
                ForEach(CardLanguage.allCases, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - Condition Section
    
    private var conditionSection: some View {
        FormSectionView(title: "Condition", icon: "star.fill") {
            Picker("Condition", selection: $viewModel.selectedCondition) {
                ForEach(CardCondition.allCases, id: \.self) { condition in
                    Text(condition.shortCode).tag(condition)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - Foil Section
    
    private var foilSection: some View {
        FormSectionView(title: "Finish", icon: "sparkles") {
            Toggle("Foil / Holographic", isOn: $viewModel.isFoil)
                .tint(.deckAccent)
        }
    }
    
    // MARK: - Quantity Section
    
    private var quantitySection: some View {
        FormSectionView(title: "Quantity", icon: "number") {
            Stepper("\(viewModel.quantity)", value: $viewModel.quantity, in: 1...99)
                .font(.system(.body, design: .rounded, weight: .medium))
        }
    }
    
    // MARK: - Price Section
    
    private var priceSection: some View {
        FormSectionView(title: "Price", icon: "dollarsign.circle") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("$")
                        .foregroundColor(.deckTextSecondary)
                    
                    TextField("0.00", text: $viewModel.pricePaid)
                        .keyboardType(.decimalPad)
                        .font(.system(.body, design: .rounded))
                }
                .padding()
                .background(Color.deckSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if let marketPrice = card.marketPrice {
                    HStack {
                        Text("Market Price:")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.deckTextSecondary)
                        
                        Text(String(format: "$%.2f", marketPrice))
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(.deckSuccess)
                    }
                }
            }
        }
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(DeckGradients.successGradient)
                    .frame(width: 100, height: 100)
                    .shadow(color: .deckSuccess.opacity(0.3), radius: 20)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Card Added!")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.deckTextPrimary)
                
                Text("Added to \(viewModel.selectedBinder?.title ?? "binder")")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.deckTextSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Form Section View

struct FormSectionView<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(.deckTextPrimary)
            
            content
        }
        .padding()
        .background(Color.deckSurface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    AddToCollectionView(card: Card(
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
    ))
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
