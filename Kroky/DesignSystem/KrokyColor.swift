import SwiftUI

/// The Kroky color system. Use these semantic names instead of literal colors in views.
enum KrokyColor {
    // MARK: - Brand

    static let petal = Color(hex: 0xF6BEDD)
    static let rose = Color(hex: 0xFDB6C9)
    static let peach = Color(hex: 0xFEC0AC)
    static let deepRose = Color(hex: 0xD78CA4)
    static let deepRoseText = Color(hex: 0xB85F81)

    // MARK: - Neutral

    static let charcoal = Color(hex: 0x30272D)
    static let porcelain = Color(hex: 0xFDF9FA)
    static let white = Color.white
    static let petalTint = Color(hex: 0xFBF0F5)
    static let warmGray = Color(hex: 0x867E84)
    static let mutedGray = Color(hex: 0xB0A8AD)

    // MARK: - Semantic

    static let danger = Color(hex: 0xC0524E)
    static let success = Color(hex: 0x4E7A4D)
    static let info = Color(hex: 0x6FA8DC)
    static let border = charcoal.opacity(0.08)
    static let hairline = charcoal.opacity(0.05)
    static let dim = charcoal.opacity(0.30)
    static let glass = charcoal.opacity(0.82)

    enum Metric {
        static let calories = KrokyColor.deepRoseText
        static let workout = Color(hex: 0xC2724E)
        static let water = Color(hex: 0x3E8BA8)
        static let mood = Color(hex: 0x7A5AA8)
    }

    enum Gradient {
        static let signature = LinearGradient(
            colors: [KrokyColor.petal, KrokyColor.rose, KrokyColor.peach],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }
}

/// Color treatments for the six Rosy app states from the component library.
enum KrokyRosyState: String, CaseIterable, Identifiable {
    case peak
    case steady
    case stalled
    case maintenance
    case gainRisk
    case noData

    var id: Self { self }

    var label: String {
        switch self {
        case .peak: "Prime weight loss"
        case .steady: "On-track weight loss"
        case .stalled: "Paused weight loss"
        case .maintenance: "Weight maintenance"
        case .gainRisk: "Weight gain risk"
        case .noData: "No logs today"
        }
    }

    var icon: KrokyIcon {
        switch self {
        case .peak: .star
        case .steady: .thumbUp
        case .stalled: .hourglass
        case .maintenance: .balance
        case .gainRisk: .stressed
        case .noData: .bedtime
        }
    }

    var accent: Color {
        switch self {
        case .peak: Color(hex: 0xE85F93)
        case .steady: Color(hex: 0xF0699A)
        case .stalled: Color(hex: 0xA9679B)
        case .maintenance: Color(hex: 0xC25A5A)
        case .gainRisk: Color(hex: 0x97303A)
        case .noData: Color(hex: 0xB9AEB7)
        }
    }

    var background: RadialGradient {
        RadialGradient(
            colors: backgroundColors,
            center: UnitPoint(x: 0.88, y: 0.84),
            startRadius: 0,
            endRadius: 360
        )
    }

    var disc: LinearGradient {
        LinearGradient(
            colors: discColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var preferredForeground: Color {
        self == .noData ? KrokyColor.charcoal : KrokyColor.white
    }

    private var backgroundColors: [Color] {
        switch self {
        case .peak: [Color(hex: 0xFFEAF2), Color(hex: 0xFCBAD3), Color(hex: 0xF294B4)]
        case .steady: [Color(hex: 0xFFF2F6), Color(hex: 0xFDCFDC), Color(hex: 0xF8A8BE)]
        case .stalled: [Color(hex: 0xF8EEF6), Color(hex: 0xE7C4DE), Color(hex: 0xC795B9)]
        case .maintenance: [Color(hex: 0xFBEFEF), Color(hex: 0xF3C4C4), Color(hex: 0xE09595)]
        case .gainRisk: [Color(hex: 0xF4DCDE), Color(hex: 0xD9959B), Color(hex: 0xB8505A)]
        case .noData: [Color(hex: 0xF8F4F7), Color(hex: 0xEEE6EC), Color(hex: 0xDDD3DB)]
        }
    }

    private var discColors: [Color] {
        switch self {
        case .peak: [Color(hex: 0xFEEDF4), Color(hex: 0xFBD9E7), Color(hex: 0xF7C3D6)]
        case .steady: [Color(hex: 0xFFF2F6), Color(hex: 0xFEE1E9), Color(hex: 0xFBD0DC)]
        case .stalled: [Color(hex: 0xF9F0F7), Color(hex: 0xF0DBEB), Color(hex: 0xE4C4DA)]
        case .maintenance: [Color(hex: 0xFCF2F2), Color(hex: 0xF8DFDF), Color(hex: 0xF0C9C9)]
        case .gainRisk: [Color(hex: 0xF7E5E7), Color(hex: 0xECC6CA), Color(hex: 0xDFA5AB)]
        case .noData: [Color(hex: 0xFAF7F9), Color(hex: 0xF2ECF0), Color(hex: 0xE9E1E7)]
        }
    }
}

private extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
