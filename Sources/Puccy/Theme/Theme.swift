import SwiftUI

// MARK: - Puccy Design System
// Colour palette: Deep crimson-pink on near-black backgrounds

enum PuccyTheme {

    // ── Palette ──────────────────────────────────────────────────────────
    static let primary     = Color(hex: "#E8294A")   // vivid crimson-pink
    static let secondary   = Color(hex: "#FF5070")   // lighter rose
    static let accent      = Color(hex: "#FF2D55")   // iOS-system-red-ish
    static let gradient    = LinearGradient(
        colors: [Color(hex: "#E8294A"), Color(hex: "#C0143C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let softGradient = LinearGradient(
        colors: [Color(hex: "#FF5070").opacity(0.15), Color.clear],
        startPoint: .top,
        endPoint: .bottom
    )

    // ── Backgrounds ───────────────────────────────────────────────────────
    static let background  = Color(hex: "#0C0A0F")   // almost-black purple-tinted
    static let card        = Color(hex: "#1A1520")   // card surface
    static let cardBorder  = Color(hex: "#E8294A").opacity(0.18)
    static let surface     = Color(hex: "#221830")   // elevated surface

    // ── Text ─────────────────────────────────────────────────────────────
    static let textPrimary   = Color.white
    static let textSecondary = Color(hex: "#A899B8")
    static let textMuted     = Color(hex: "#6B5F7A")

    // ── Status ────────────────────────────────────────────────────────────
    static let success = Color(hex: "#30D158")
    static let warning = Color(hex: "#FFD60A")
    static let danger  = Color(hex: "#FF453A")
    static let info    = Color(hex: "#64D2FF")

    // ── Typography ────────────────────────────────────────────────────────
    static func titleFont(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func bodyFont(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    static func monoFont(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
    static func labelFont(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

// MARK: - Color hex init
extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - View modifiers
struct PuccyCardModifier: ViewModifier {
    var elevated: Bool = false
    func body(content: Content) -> some View {
        content
            .background(elevated ? PuccyTheme.surface : PuccyTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(PuccyTheme.cardBorder, lineWidth: 1)
            )
    }
}

struct PuccyButtonModifier: ViewModifier {
    var style: ButtonStyleType = .primary
    enum ButtonStyleType { case primary, secondary, ghost }

    func body(content: Content) -> some View {
        switch style {
        case .primary:
            content
                .font(PuccyTheme.labelFont(15))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(PuccyTheme.gradient)
                .clipShape(Capsule())
        case .secondary:
            content
                .font(PuccyTheme.labelFont(15))
                .foregroundColor(PuccyTheme.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(PuccyTheme.primary.opacity(0.15))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(PuccyTheme.primary.opacity(0.4), lineWidth: 1))
        case .ghost:
            content
                .font(PuccyTheme.bodyFont(15))
                .foregroundColor(PuccyTheme.textSecondary)
        }
    }
}

extension View {
    func puccyCard(elevated: Bool = false) -> some View {
        modifier(PuccyCardModifier(elevated: elevated))
    }
    func puccyButton(_ style: PuccyButtonModifier.ButtonStyleType = .primary) -> some View {
        modifier(PuccyButtonModifier(style: style))
    }
}
