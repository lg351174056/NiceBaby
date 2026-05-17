import SwiftUI

/// 全应用统一的视觉常量，保证简洁、一致。黏土玩具风 (Claymorphism)
enum AppTheme {
    // MARK: Color
    static let background = Color(red: 238/255.0, green: 242/255.0, blue: 255/255.0) // #EEF2FF 婴儿蓝
    static let card = Color.white
    static let textPrimary = Color(red: 49/255.0, green: 46/255.0, blue: 129/255.0) // #312E81 深靛蓝
    static let textSecondary = Color(red: 49/255.0, green: 46/255.0, blue: 129/255.0).opacity(0.65)
    
    static let accentBlue = Color(red: 79/255.0, green: 70/255.0, blue: 229/255.0) // #4F46E5 活力靛蓝
    static let accentIndigo = Color(red: 129/255.0, green: 140/255.0, blue: 248/255.0) // #818CF8 柔和靛蓝
    static let accentTerracotta = Color(red: 245/255.0, green: 158/255.0, blue: 11/255.0) // 亮橙/琥珀色
    static let accentSage = Color(red: 34/255.0, green: 197/255.0, blue: 94/255.0) // #22C55E 进度绿
    
    // 探索页专用糖果色
    static let accentYellow = Color(red: 250/255.0, green: 204/255.0, blue: 21/255.0) // #FACC15 向日葵黄
    static let accentMint = Color(red: 16/255.0, green: 185/255.0, blue: 129/255.0) // #10B981 薄荷绿
    static let accentPurple = Color(red: 139/255.0, green: 92/255.0, blue: 246/255.0) // #8B5CF6 深邃紫
    static let accentPink = Color(red: 244/255.0, green: 63/255.0, blue: 94/255.0) // #F43F5E 西瓜红

    static let separator = Color(red: 49/255.0, green: 46/255.0, blue: 129/255.0).opacity(0.1)

    /// 火柴棋盘：偏纸感、低饱和
    static let matchPaper = Color(red: 0.99, green: 0.985, blue: 0.975)
    static let matchPaperStroke = Color.black.opacity(0.06)
    static let matchInk = Color(red: 49/255.0, green: 46/255.0, blue: 129/255.0)
    static let matchControlTint = Color(red: 79/255.0, green: 70/255.0, blue: 229/255.0)

    // MARK: Layout
    static let cornerLarge: CGFloat = 24 // 增加圆角
    static let cornerMedium: CGFloat = 18 // 增加圆角
    static let cornerSmall: CGFloat = 14
    static let paddingScreen: CGFloat = 20
    static let cardShadowRadius: CGFloat = 12

    // MARK: Typography helpers
    // 全部替换为加粗、大字号的圆体字
    static func titleHero() -> Font { .system(size: 32, weight: .heavy, design: .rounded) }
    static func titleSection() -> Font { .system(size: 22, weight: .bold, design: .rounded) }
    static func captionMuted() -> Font { .system(size: 14, weight: .semibold, design: .rounded) }
}
