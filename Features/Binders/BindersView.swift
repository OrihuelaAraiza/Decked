//
//  BindersView.swift
//  Decked
//
//  Digital binder management view
//

import SwiftUI

struct BindersView: View {
    
    @StateObject private var viewModel = BindersViewModel()
    @State private var showingCreateBinder = false
    @State private var selectedBinder: Binder?
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DeckGradients.backgroundPrimary
                    .ignoresSafeArea()
                
                if viewModel.binders.isEmpty {
                    emptyState
                } else {
                    bindersGrid
                }
            }
            .navigationTitle("Binders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateBinder = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.deckAccent)
                    }
                }
            }
            .toolbarBackground(Color.deckBackground, for: .navigationBar)
            .sheet(isPresented: $showingCreateBinder) {
                CreateBinderView { binder in
                    Task {
                        await viewModel.createBinder(binder)
                    }
                }
            }
            .sheet(item: $selectedBinder) { binder in
                BinderDetailView(binder: binder)
            }
            .task {
                await viewModel.loadBinders()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.deckSurface)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.deckAccent)
            }
            
            VStack(spacing: 12) {
                Text("No Binders Yet")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(.deckTextPrimary)
                
                Text("Create your first binder to organize\nyour card collection")
                    .font(.system(.body, design: .default))
                    .foregroundColor(.deckTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingCreateBinder = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Binder")
                }
            }
            .buttonStyle(DeckButtonStyle())
        }
        .padding()
    }
    
    // MARK: - Binders Grid
    
    private var bindersGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.binders) { binder in
                    BinderCard(binder: binder) {
                        selectedBinder = binder
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Binder Card

struct BinderCard: View {
    
    let binder: Binder
    let onTap: () -> Void
    
    var accentColor: Color {
        Color(hex: binder.accentColorHex)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Cover
                ZStack {
                    // Binder texture
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.3),
                                    accentColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Ring binding effect
                    HStack {
                        VStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { _ in
                                Circle()
                                    .fill(Color.deckSurfaceElevated)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.leading, 8)
                        
                        Spacer()
                    }
                    
                    // Card count
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Text("\(binder.cardCount)")
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundColor(accentColor)
                            
                            Image(systemName: "square.stack.fill")
                                .font(.system(size: 18))
                                .foregroundColor(accentColor.opacity(0.7))
                        }
                        .padding()
                    }
                    
                    // Public badge
                    if binder.isPublic {
                        VStack {
                            HStack {
                                Spacer()
                                
                                Image(systemName: "globe")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.deckBackground)
                                    .padding(6)
                                    .background(accentColor)
                                    .clipShape(Circle())
                            }
                            .padding(8)
                            
                            Spacer()
                        }
                    }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(binder.name)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundColor(.deckTextPrimary)
                        .lineLimit(1)
                    
                    if let description = binder.description {
                        Text(description)
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.deckTextSecondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(12)
            .background(Color.deckSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Create Binder View

struct CreateBinderView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor = "38BDF8"
    @State private var isPublic = false
    
    let onCreate: (Binder) -> Void
    
    private let colorOptions = [
        "38BDF8", // Cyan
        "A78BFA", // Purple
        "F472B6", // Pink
        "FBBF24", // Yellow
        "4ADE80", // Green
        "F97316", // Orange
        "EF4444", // Red
        "60A5FA"  // Blue
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deckBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Name input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Binder Name")
                                .font(.system(.subheadline, design: .default, weight: .medium))
                                .foregroundColor(.deckTextSecondary)
                            
                            TextField("My Binder", text: $name)
                                .font(.system(.body, design: .default))
                                .foregroundColor(.deckTextPrimary)
                                .padding()
                                .background(Color.deckSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Description input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (Optional)")
                                .font(.system(.subheadline, design: .default, weight: .medium))
                                .foregroundColor(.deckTextSecondary)
                            
                            TextField("What's this binder for?", text: $description, axis: .vertical)
                                .font(.system(.body, design: .default))
                                .foregroundColor(.deckTextPrimary)
                                .lineLimit(3...6)
                                .padding()
                                .background(Color.deckSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Color picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color")
                                .font(.system(.subheadline, design: .default, weight: .medium))
                                .foregroundColor(.deckTextSecondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                ForEach(colorOptions, id: \.self) { color in
                                    Button {
                                        selectedColor = color
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(
                                                        Color.white,
                                                        lineWidth: selectedColor == color ? 3 : 0
                                                    )
                                            )
                                            .shadow(
                                                color: selectedColor == color ? Color(hex: color).opacity(0.5) : .clear,
                                                radius: 8
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Public toggle
                        Toggle(isOn: $isPublic) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.deckAccent)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Public Binder")
                                        .font(.system(.body, design: .default, weight: .medium))
                                        .foregroundColor(.deckTextPrimary)
                                    
                                    Text("Allow others to view this binder")
                                        .font(.system(.caption, design: .default))
                                        .foregroundColor(.deckTextSecondary)
                                }
                            }
                        }
                        .tint(.deckAccent)
                        .padding()
                        .background(Color.deckSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Spacer(minLength: 40)
                        
                        // Create button
                        Button {
                            let binder = Binder(
                                name: name,
                                description: description.isEmpty ? nil : description,
                                accentColorHex: selectedColor,
                                isPublic: isPublic
                            )
                            onCreate(binder)
                            dismiss()
                        } label: {
                            Text("Create Binder")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .foregroundColor(.deckBackground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    Group {
                                        if name.isEmpty {
                                            Color.deckSurfaceElevated
                                        } else {
                                            DeckGradients.accentGradient
                                        }
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Binder")
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
}

// MARK: - Binder Detail View

struct BinderDetailView: View {
    
    let binder: Binder
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BinderDetailViewModel
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    init(binder: Binder) {
        self.binder = binder
        self._viewModel = StateObject(wrappedValue: BinderDetailViewModel(binder: binder))
    }
    
    var accentColor: Color {
        Color(hex: binder.accentColorHex)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DeckGradients.backgroundPrimary
                    .ignoresSafeArea()
                
                if viewModel.cards.isEmpty {
                    emptyBinderState
                } else {
                    cardsGrid
                }
            }
            .navigationTitle(binder.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.deckAccent)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            // Share action
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            // Edit action
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            // Delete action
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.deckAccent)
                    }
                }
            }
            .toolbarBackground(Color.deckBackground, for: .navigationBar)
            .task {
                await viewModel.loadCards()
            }
        }
    }
    
    private var emptyBinderState: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.deckTextMuted)
            
            Text("No Cards Yet")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundColor(.deckTextPrimary)
            
            Text("Scan cards and add them\nto this binder")
                .font(.system(.body, design: .default))
                .foregroundColor(.deckTextSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var cardsGrid: some View {
        ScrollView {
            // Stats header
            HStack(spacing: 16) {
                StatBadge(
                    icon: "square.stack.fill",
                    value: "\(viewModel.cards.count)",
                    label: "Cards",
                    color: accentColor
                )
                
                if let totalValue = viewModel.totalValue {
                    StatBadge(
                        icon: "dollarsign.circle.fill",
                        value: String(format: "$%.2f", totalValue),
                        label: "Value",
                        color: .deckSuccess
                    )
                }
            }
            .padding()
            
            // Cards grid (binder style)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.cards) { card in
                    BinderCardSlot(card: card)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(.deckTextPrimary)
                
                Text(label)
                    .font(.system(.caption, design: .default))
                    .foregroundColor(.deckTextSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.deckSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Binder Card Slot

struct BinderCardSlot: View {
    let card: CollectionCard
    
    var body: some View {
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
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        // Quantity badge if > 1
                        Group {
                            if card.quantity > 1 {
                                VStack {
                                    HStack {
                                        Spacer()
                                        
                                        Text("×\(card.quantity)")
                                            .font(.system(.caption2, design: .rounded, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(Capsule())
                                    }
                                    .padding(4)
                                    
                                    Spacer()
                                }
                            }
                        }
                    )
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
        .shadow(color: card.card.rarity.color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    BindersView()
}
