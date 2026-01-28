//
//  EmptyStateView.swift
//  Decked
//
//  Reusable empty state component
//

import SwiftUI

struct EmptyStateView: View {
    
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.deckSurface)
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.deckAccent)
            }
            
            // Text
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(.deckTextPrimary)
                
                Text(message)
                    .font(.system(.body, design: .default))
                    .foregroundColor(.deckTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus")
                        Text(actionTitle)
                    }
                }
                .buttonStyle(DeckButtonStyle())
            }
        }
        .padding()
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    
    static var noCards: EmptyStateView {
        EmptyStateView(
            icon: "square.stack.3d.up.slash",
            title: "No Cards Yet",
            message: "Start scanning cards to build your collection"
        )
    }
    
    static var noBinders: EmptyStateView {
        EmptyStateView(
            icon: "folder.badge.plus",
            title: "No Binders Yet",
            message: "Create your first binder to organize your card collection"
        )
    }
    
    static var noResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "Try scanning the card again or adjust the position"
        )
    }
    
    static var searchEmpty: EmptyStateView {
        EmptyStateView(
            icon: "doc.text.magnifyingglass",
            title: "No Matches",
            message: "No cards match your search criteria"
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.deckBackground
            .ignoresSafeArea()
        
        EmptyStateView.noCards
    }
}
