//
//  Theme.swift
//  Decked
//
//  Premium dark theme for Pokémon TCG collectors
//

import SwiftUI

// MARK: - Color Palette
extension Color {
    // Primary backgrounds
    static let deckBackground = Color(hex: "0F172A")
    static let deckSurface = Color(hex: "1E293B")
    static let deckSurfaceElevated = Color(hex: "334155")
    
    // Accent colors
    static let deckAccent = Color(hex: "38BDF8")
    static let deckAccentSecondary = Color(hex: "22D3EE")
    static let deckAccentGlow = Color(hex: "38BDF8").opacity(0.3)
    
    // Text colors
    static let deckTextPrimary = Color(hex: "F1F5F9")
    static let deckTextSecondary = Color(hex: "94A3B8")
    static let deckTextMuted = Color(hex: "64748B")
    
    // Rarity colors (subtle glows)
    static let rarityCommon = Color(hex: "94A3B8")
    static let rarityUncommon = Color(hex: "4ADE80")
    static let rarityRare = Color(hex: "60A5FA")
    static let rarityHolo = Color(hex: "A78BFA")
    static let rarityUltra = Color(hex: "F472B6")
    static let raritySAR = Color(hex: "FBBF24")
    static let raritySecret = Color(hex: "F97316")
    
    // Status colors
    static let deckSuccess = Color(hex: "10B981")
    static let deckWarning = Color(hex: "F59E0B")
    static let deckError = Color(hex: "EF4444")
    
    // Card condition colors
    static let conditionNM = Color(hex: "10B981")
    static let conditionLP = Color(hex: "84CC16")
    static let conditionMP = Color(hex: "F59E0B")
    static let conditionHP = Color(hex: "EF4444")
}

// MARK: - Hex Color Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradients
struct DeckGradients {
    static let backgroundPrimary = LinearGradient(
        colors: [Color.deckBackground, Color(hex: "0C1222")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let surfaceGradient = LinearGradient(
        colors: [Color.deckSurface, Color.deckSurface.opacity(0.9)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [Color.deckAccent, Color.deckAccentSecondary],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let cardShine = LinearGradient(
        colors: [
            Color.white.opacity(0.0),
            Color.white.opacity(0.1),
            Color.white.opacity(0.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [
            Color.deckSuccess,
            Color.deckSuccess.opacity(0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static func rarityGlow(_ rarity: CardRarity) -> RadialGradient {
        RadialGradient(
            colors: [rarity.color.opacity(0.4), rarity.color.opacity(0.0)],
            center: .center,
            startRadius: 0,
            endRadius: 100
        )
    }
}

// MARK: - Card Rarity Extension
extension CardRarity {
    var color: Color {
        switch self {
        case .common: return .rarityCommon
        case .uncommon: return .rarityUncommon
        case .rare: return .rarityRare
        case .holo: return .rarityHolo
        case .ultraRare: return .rarityUltra
        case .secretRare: return .raritySecret
        case .specialArt: return .raritySAR
        case .illustrationRare: return .rarityUltra
        case .unknown: return .rarityCommon
        }
    }
}

// MARK: - View Modifiers
struct DeckCardStyle: ViewModifier {
    var isElevated: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(isElevated ? Color.deckSurfaceElevated : Color.deckSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.3), radius: isElevated ? 12 : 6, x: 0, y: 4)
    }
}

struct DeckButtonStyle: ButtonStyle {
    var isPrimary: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundColor(isPrimary ? .deckBackground : .deckAccent)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Group {
                    if isPrimary {
                        DeckGradients.accentGradient
                    } else {
                        Color.deckSurface
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isPrimary ? Color.clear : Color.deckAccent.opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct DeckGlowStyle: ViewModifier {
    var color: Color = .deckAccent
    var radius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
    }
}

// MARK: - View Extensions
extension View {
    func deckCard(elevated: Bool = false) -> some View {
        modifier(DeckCardStyle(isElevated: elevated))
    }
    
    func deckGlow(_ color: Color = .deckAccent, radius: CGFloat = 20) -> some View {
        modifier(DeckGlowStyle(color: color, radius: radius))
    }
}

// MARK: - Typography
struct DeckTypography {
    static func title(_ text: String) -> some View {
        Text(text)
            .font(.system(.title, design: .rounded, weight: .bold))
            .foregroundColor(.deckTextPrimary)
    }
    
    static func headline(_ text: String) -> some View {
        Text(text)
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundColor(.deckTextPrimary)
    }
    
    static func body(_ text: String) -> some View {
        Text(text)
            .font(.system(.body, design: .default))
            .foregroundColor(.deckTextSecondary)
    }
    
    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .default))
            .foregroundColor(.deckTextMuted)
    }
}

// MARK: - Theme Environment
struct DeckTheme {
    let spacing: Spacing
    let animation: AnimationConfig
    
    struct Spacing {
        let xs: CGFloat = 4
        let sm: CGFloat = 8
        let md: CGFloat = 16
        let lg: CGFloat = 24
        let xl: CGFloat = 32
        let xxl: CGFloat = 48
    }
    
    struct AnimationConfig {
        let fast = Animation.easeInOut(duration: 0.15)
        let normal = Animation.easeInOut(duration: 0.25)
        let slow = Animation.easeInOut(duration: 0.4)
        let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    }
    
    static let shared = DeckTheme(
        spacing: Spacing(),
        animation: AnimationConfig()
    )
}

// MARK: - Preview
#Preview {
    ZStack {
        DeckGradients.backgroundPrimary
            .ignoresSafeArea()
        
        VStack(spacing: 24) {
            DeckTypography.title("Decked")
            DeckTypography.headline("Premium Card Collection")
            DeckTypography.body("For serious collectors")
            
            Button("Primary Button") {}
                .buttonStyle(DeckButtonStyle())
            
            Button("Secondary Button") {}
                .buttonStyle(DeckButtonStyle(isPrimary: false))
            
            HStack(spacing: 16) {
                ForEach([CardRarity.rare, .ultraRare, .secretRare, .specialArt], id: \.self) { rarity in
                    Circle()
                        .fill(rarity.color)
                        .frame(width: 30, height: 30)
                        .deckGlow(rarity.color, radius: 10)
                }
            }
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.deckSurface)
                .frame(height: 100)
                .overlay(
                    Text("Card Preview")
                        .foregroundColor(.deckTextSecondary)
                )
                .deckCard(elevated: true)
                .padding(.horizontal)
        }
    }
}
