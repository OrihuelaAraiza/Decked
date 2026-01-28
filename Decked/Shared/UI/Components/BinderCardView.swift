//
//  BinderCardView.swift
//  Decked
//
//  Card view component for binder grid
//

import SwiftUI

struct BinderCardView: View {
    let binder: BinderEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Preview or placeholder
                if let previewURL = binder.previewImageURL {
                    CardThumbnailView(
                        imageURL: previewURL,
                        size: .large
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    emptyBinderPlaceholder
                }
                
                // Binder info
                VStack(alignment: .leading, spacing: 4) {
                    Text(binder.title)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundColor(.deckTextPrimary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label("\(binder.cardCount)", systemImage: "rectangle.stack")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.deckTextSecondary)
                        
                        if binder.totalValue > 0 {
                            Text(String(format: "$%.2f", binder.totalValue))
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundColor(.deckSuccess)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .background(Color.deckSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.deckSurfaceElevated.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private var emptyBinderPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.deckSurfaceElevated,
                        Color.deckSurface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 140 * 1.4)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.system(size: 36))
                        .foregroundColor(.deckTextMuted)
                    
                    Text("Empty")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.deckTextMuted)
                }
            )
            .padding(.horizontal, 12)
            .padding(.top, 12)
    }
}
