//
//  PrimaryButton.swift
//  Decked
//
//  Reusable primary button component
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let isLoading: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(style.foregroundColor)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(style.background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: style.shadowColor, radius: style.shadowRadius)
        }
        .disabled(isLoading)
    }
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case ghost
        
        var background: AnyView {
            switch self {
            case .primary:
                return AnyView(DeckGradients.accentGradient)
            case .secondary:
                return AnyView(Color.deckSurface)
            case .destructive:
                return AnyView(Color.deckError)
            case .ghost:
                return AnyView(Color.clear)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary:
                return .deckBackground
            case .secondary:
                return .deckTextPrimary
            case .destructive:
                return .white
            case .ghost:
                return .deckAccent
            }
        }
        
        var shadowColor: Color {
            switch self {
            case .primary:
                return .deckAccentGlow.opacity(0.3)
            case .secondary:
                return .black.opacity(0.1)
            case .destructive:
                return .deckError.opacity(0.3)
            case .ghost:
                return .clear
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .primary:
                return 8
            case .secondary:
                return 4
            case .destructive:
                return 6
            case .ghost:
                return 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("Add to Binder", icon: "folder.badge.plus", style: .primary) {}
        
        PrimaryButton("Create New Binder", icon: "plus", style: .secondary) {}
        
        PrimaryButton("Delete Card", icon: "trash", style: .destructive) {}
        
        PrimaryButton("Loading...", style: .primary, isLoading: true) {}
    }
    .padding()
    .background(Color.deckBackground)
}
