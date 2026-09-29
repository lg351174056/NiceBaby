import SwiftUI

/// 设计系统 · 蓝天草地田园风（Field Style）
/// 田园系 token 为全 App 主导风格（见 field* 前缀），墨韵系 accent 色仅保留给个别页面的强调点缀。
enum AppTheme {
    // MARK: — 田园系（蓝天草地 · 全 App 主导风格）
    // 以下 token 对应各页面散落的硬编码色值，新代码优先使用。

    /// 蓝天草地背景 · 天空蓝（顶部）
    static let fieldSky = Color(red: 190/255, green: 227/255, blue: 245/255)
    /// 蓝天草地背景 · 过渡青
    static let fieldSkyMid = Color(red: 220/255, green: 242/255, blue: 220/255)
    /// 蓝天草地背景 · 草地绿（底部）
    static let fieldGrass = Color(red: 207/255, green: 235/255, blue: 196/255)

    /// 薄荷绿 · 主强调色（按钮/进度/徽章）
    static let fieldMint = Color(red: 76/255, green: 175/255, blue: 125/255)
    /// 深墨绿 · 主文字
    static let fieldInk = Color(red: 61/255, green: 74/255, blue: 54/255)
    /// 灰绿 · 次要文字
    static let fieldMoss = Color(red: 138/255, green: 154/255, blue: 122/255)
    /// 橄榄绿 · 边框/描边
    static let fieldOlive = Color(red: 110/255, green: 140/255, blue: 90/255)
    /// 绿阴影
    static let fieldGrassShadow = Color(red: 60/255, green: 90/255, blue: 50/255)
    /// 浅灰绿 · 弱化文字
    static let fieldMossLight = Color(red: 160/255, green: 176/255, blue: 152/255)
    /// 深橄榄 · 标签/徽章文字
    static let fieldOliveDeep = Color(red: 74/255, green: 92/255, blue: 66/255)

    /// 太阳光晕外圈（呼吸动画用）
    static let fieldSunGlowA = Color(red: 255/255, green: 214/255, blue: 110/255)
    /// 太阳光晕内圈
    static let fieldSunGlowB = Color(red: 255/255, green: 201/255, blue: 61/255)
    /// 太阳核心高光
    static let fieldSunCoreA = Color(red: 255/255, green: 246/255, blue: 205/255)
    /// 太阳核心主体
    static let fieldSunCoreB = Color(red: 255/255, green: 214/255, blue: 100/255)
    /// 太阳核心暗部
    static let fieldSunCoreC = Color(red: 247/255, green: 188/255, blue: 55/255)

    /// 金币金棕
    static let fieldGold = Color(red: 176/255, green: 138/255, blue: 62/255)

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

    // MARK: — Layout
    static let cornerLarge: CGFloat = 20
    static let cornerMedium: CGFloat = 16
    static let cornerSmall: CGFloat = 12
    static let paddingScreen: CGFloat = 20

    // MARK: — Typography（宋体标题 + 圆体正文）
    static func titleSection() -> Font { .system(size: 22, weight: .heavy, design: .serif) }
    static func captionMuted() -> Font { .system(size: 14, weight: .semibold, design: .rounded) }

    // MARK: — 水墨卡片阴影（轻单影，替代黏土双重阴影）
    static let inkShadow = Color(red: 30/255, green: 28/255, blue: 24/255).opacity(0.06)
}