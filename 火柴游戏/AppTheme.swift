import SwiftUI

/// 全应用统一的视觉常量，保证简洁、一致。
enum AppTheme {
    // MARK: Color
    static let background = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let accentBlue = Color(red: 0.20, green: 0.48, blue: 0.92)
    static let accentIndigo = Color(red: 0.35, green: 0.34, blue: 0.84)
    static let accentTerracotta = Color(red: 0.72, green: 0.38, blue: 0.28)
    static let accentSage = Color(red: 0.38, green: 0.58, blue: 0.45)
    static let separator = Color(.separator)

    /// 火柴棋盘：偏纸感、低饱和
    static let matchPaper = Color(red: 0.99, green: 0.985, blue: 0.975)
    static let matchPaperStroke = Color.black.opacity(0.06)
    static let matchInk = Color(red: 0.12, green: 0.14, blue: 0.18)
    static let matchControlTint = Color(red: 0.22, green: 0.28, blue: 0.38)

    // MARK: Layout
    static let cornerLarge: CGFloat = 22
    static let cornerMedium: CGFloat = 16
    static let cornerSmall: CGFloat = 12
    static let paddingScreen: CGFloat = 20
    static let cardShadowRadius: CGFloat = 12

    // MARK: Typography helpers
    static func titleHero() -> Font { .system(.title, design: .rounded).weight(.bold) }
    static func titleSection() -> Font { .system(.title3, design: .rounded).weight(.semibold) }
    static func captionMuted() -> Font { .system(.caption, design: .rounded).weight(.medium) }
}
