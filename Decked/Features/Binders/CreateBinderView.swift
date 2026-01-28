//
//  CreateBinderView.swift
//  Decked
//
//  View for creating a new binder
//

import SwiftUI
import CoreData

struct CreateBinderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var binderName = ""
    @State private var isCreating = false
    
    let onCreate: (BinderEntity) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(DeckGradients.accentGradient)
                        .frame(width: 80, height: 80)
                        .shadow(color: .deckAccentGlow, radius: 15)
                    
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.deckBackground)
                }
                .padding(.top, 32)
                
                // Title
                VStack(spacing: 8) {
                    Text("Create New Binder")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(.deckTextPrimary)
                    
                    Text("Organize your cards into collections")
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(.deckTextSecondary)
                }
                
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Binder Name")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(.deckTextSecondary)
                    
                    TextField("e.g. My Favorites, Rare Cards", text: $binderName)
                        .font(.system(.body, design: .rounded))
                        .padding(16)
                        .background(Color.deckSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.deckSurfaceElevated, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Create button
                PrimaryButton(
                    "Create Binder",
                    icon: "folder.badge.plus",
                    style: .primary,
                    isLoading: isCreating
                ) {
                    createBinder()
                }
                .disabled(binderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(binderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color.deckBackground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.deckTextSecondary)
                }
            }
        }
    }
    
    private func createBinder() {
        let trimmedName = binderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        isCreating = true
        
        let binder = BinderEntity(context: viewContext)
        binder.id = UUID()
        binder.title = trimmedName
        binder.createdAt = Date()
        
        do {
            try viewContext.save()
            print("✅ Created binder: \(trimmedName)")
            onCreate(binder)
            dismiss()
        } catch {
            print("❌ Failed to create binder: \(error)")
            isCreating = false
        }
    }
}

#Preview {
    CreateBinderView { _ in }
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
