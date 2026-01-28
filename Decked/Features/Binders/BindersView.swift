//
//  BindersView.swift
//  Decked
//
//  Main view for managing card binders (collections)
//

import SwiftUI

struct BindersView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: BindersViewModel
    
    @State private var showingCreateBinder = false
    @State private var selectedBinder: BinderEntity?
    
    init() {
        // Initialize with temporary context, will be updated by environment
        let context = PersistenceController.shared.viewContext
        _viewModel = StateObject(wrappedValue: BindersViewModel(viewContext: context))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deckBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView(message: "Loading binders...")
                } else if !viewModel.hasBinders {
                    emptyState
                } else {
                    bindersList
                }
            }
            .navigationTitle("Binders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateBinder = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.deckAccent)
                    }
                }
            }
            .sheet(isPresented: $showingCreateBinder) {
                CreateBinderView { _ in
                    viewModel.fetchBinders()
                }
                .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: $selectedBinder) { binder in
                BinderDetailView(binder: binder)
                    .environment(\.managedObjectContext, viewContext)
            }
            .onAppear {
                viewModel.fetchBinders()
            }
        }
    }
    
    // MARK: - Binders List
    
    private var bindersList: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary cards
                summarySection
                
                // Binders grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.binders) { binder in
                        BinderCardView(binder: binder) {
                            selectedBinder = binder
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        HStack(spacing: 12) {
            // Total cards
            SummaryCard(
                icon: "rectangle.stack.fill",
                value: "\(viewModel.totalCards)",
                label: "Cards",
                gradient: DeckGradients.accentGradient
            )
            
            // Total value
            SummaryCard(
                icon: "dollarsign.circle.fill",
                value: String(format: "$%.0f", viewModel.totalValue),
                label: "Value",
                gradient: DeckGradients.successGradient
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        EmptyStateView(
            icon: "folder.badge.plus",
            title: "No Binders Yet",
            message: "Create your first binder to start organizing your card collection",
            actionTitle: "Create Binder",
            action: {
                showingCreateBinder = true
            }
        )
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let icon: String
    let value: String
    let label: String
    let gradient: LinearGradient
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.deckAccent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(.deckTextPrimary)
                
                Text(label)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.deckTextSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.deckSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.deckSurfaceElevated.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    BindersView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
