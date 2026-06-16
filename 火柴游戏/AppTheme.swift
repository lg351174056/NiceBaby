import SwiftUI

/// 墨韵新风 (Ink Rhythm) 设计系统
/// 水墨留白 × 现代 iOS，五 Tab 各有独立强调色
enum AppTheme {
    // MARK: — 宣纸底色层
    static let background = Color(red: 247/255, green: 245/255, blue: 240/255) // #F7F5F0 宣纸暖白
    static let card = Color.white
    static let textPrimary = Color(red: 30/255, green: 28/255, blue: 24/255)  // #1E1C18 墨黑
    static let textSecondary = Color(red: 100/255, green: 96/255, blue: 88/255) // #646058 中灰

    // MARK: — 五 Tab 强调色（每屏最多使用 2 处）
    /// 首页 · 朱砂红
    static let accentCinnabar = Color(red: 201/255, green: 100/255, blue: 66/255)  // #C96442
    /// 诗库 · 竹青
    static let accentBamboo = Color(red: 74/255, green: 124/255, blue: 89/255)     // #4A7C59
    /// 探索 · 碧潭
    static let accentJade = Color(red: 59/255, green: 142/255, blue: 165/255)      // #3B8EA5
    /// 益智 · 墨紫
    static let accentInkPurple = Color(red: 92/255, green: 75/255, blue: 138/255)   // #5C4B8A
    /// 我的 · 靛蓝
    static let accentIndigo = Color(red: 74/255, green: 111/255, blue: 165/255)    // #4A6FA5

    // MARK: — 功能色
    static let accentSage = Color(red: 92/255, green: 156/255, blue: 102/255)      // #5C9C66 进度绿
    static let accentTerracotta = Color(red: 201/255, green: 100/255, blue: 66/255) // 同朱砂，兼容旧引用
    static let accentBlue = Color(red: 74/255, green: 111/255, blue: 165/255)     // 同靛蓝，兼容旧引用
    static let accentYellow = Color(red: 194/255, green: 162/255, blue: 72/255)    // #C2A248 琥珀金
    static let accentMint = Color(red: 59/255, green: 142/255, blue: 165/255)       // 同碧潭，兼容
    static let accentPurple = Color(red: 92/255, green: 75/255, blue: 138/255)     // 同墨紫，兼容
    static let accentPink = Color(red: 186/255, green: 80/255, blue: 100/255)       // #BA5064 绯色

    static let separator = Color(red: 30/255, green: 28/255, blue: 24/255).opacity(0.08)

    // MARK: — 火柴棋盘配色（保持不变）
    static let matchPaper = Color(red: 0.99, green: 0.985, blue: 0.975)
    static let matchPaperStroke = Color.black.opacity(0.06)
    static let matchInk = Color(red: 49/255, green: 46/255, blue: 129/255)
    static let matchControlTint = Color(red: 201/255, green: 100/255, blue: 66/255)

    // MARK: — Layout
    static let cornerXL: CGFloat = 24
    static let cornerLarge: CGFloat = 20
    static let cornerMedium: CGFloat = 16
    static let cornerSmall: CGFloat = 12
    static let cornerXS: CGFloat = 8
    static let paddingScreen: CGFloat = 20
    static let cardShadowRadius: CGFloat = 0

    // Spacing scale (8-base)
    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    static let spacing48: CGFloat = 48

    // MARK: — Typography（宋体标题 + 圆体正文）
    static func titleHero() -> Font { .system(size: 34, weight: .bold, design: .serif) }
    static func titleSection() -> Font { .system(size: 22, weight: .heavy, design: .serif) }
    static func cardTitle() -> Font { .system(size: 17, weight: .heavy, design: .serif) }
    static func bodyText() -> Font { .system(size: 15, weight: .medium, design: .rounded) }
    static func caption() -> Font { .system(size: 13, weight: .semibold, design: .rounded) }
    static func captionMuted() -> Font { .system(size: 14, weight: .semibold, design: .rounded) }
    static func micro() -> Font { .system(size: 11, weight: .medium, design: .rounded) }
    static func poemDisplay() -> Font { .system(size: 22, weight: .medium, design: .serif) }
    static func poemTitle() -> Font { .system(size: 32, weight: .heavy, design: .serif) }

    // MARK: — 水墨卡片阴影（轻单影，替代黏土双重阴影）
    static let inkShadow = Color(red: 30/255, green: 28/255, blue: 24/255).opacity(0.06)
    static let inkShadowStrong = Color(red: 30/255, green: 28/255, blue: 24/255).opacity(0.12)

    // MARK: — 首页背景渐变（墨韵暖调，替代婴儿蓝 MeshGradient）
    static let homeMeshA: [Color] = [
        Color(red: 0.97, green: 0.96, blue: 0.94),
        Color(red: 0.96, green: 0.94, blue: 0.92),
        Color(red: 0.97, green: 0.96, blue: 0.94),
        Color(red: 0.95, green: 0.94, blue: 0.91),
        Color(red: 0.97, green: 0.96, blue: 0.94),
        Color(red: 0.96, green: 0.95, blue: 0.93),
        Color(red: 0.97, green: 0.97, blue: 0.95),
        Color(red: 0.96, green: 0.94, blue: 0.92),
        Color(red: 0.97, green: 0.96, blue: 0.94)
    ]
    static let homeMeshB: [Color] = [
        Color(red: 0.97, green: 0.95, blue: 0.93),
        Color(red: 0.96, green: 0.95, blue: 0.93),
        Color(red: 0.95, green: 0.94, blue: 0.91),
        Color(red: 0.97, green: 0.95, blue: 0.92),
        Color(red: 0.96, green: 0.95, blue: 0.94),
        Color(red: 0.95, green: 0.93, blue: 0.91),
        Color(red: 0.96, green: 0.95, blue: 0.93),
        Color(red: 0.96, green: 0.94, blue: 0.92),
        Color(red: 0.95, green: 0.94, blue: 0.91)
    ]
}