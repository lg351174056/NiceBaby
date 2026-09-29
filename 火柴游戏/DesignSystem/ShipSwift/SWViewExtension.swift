import SwiftUI

// MARK: - Button Style (保留黏土按下回弹)

struct SWButtonStyle: ButtonStyle {
    enum Variant {
        case primary
        case secondary
    }

    @Environment(\.isEnabled) private var isEnabled

    let variant: Variant
    var showBorder: Bool = false
    var cornerRadius: CGFloat = 16

    private var backgroundColor: Color {
        switch variant {
        case .primary: AppTheme.accentCinnabar
        case .secondary: AppTheme.accentCinnabar.opacity(0.1)
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: .white
        case .secondary: AppTheme.textPrimary.opacity(0.8)
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary: AppTheme.accentCinnabar
        case .secondary: AppTheme.separator
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .foregroundStyle(foregroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        showBorder ? borderColor : .clear,
                        lineWidth: 1.5
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .opacity(isEnabled ? 1 : 0.5)
    }
}

extension ButtonStyle where Self == SWButtonStyle {
    static var swPrimary: SWButtonStyle { .init(variant: .primary) }
    static var swSecondary: SWButtonStyle { .init(variant: .secondary) }

    static func swPrimary(showBorder: Bool = true, cornerRadius: CGFloat = 12) -> SWButtonStyle {
        .init(variant: .primary, showBorder: showBorder, cornerRadius: cornerRadius)
    }

    static func swSecondary(showBorder: Bool = true, cornerRadius: CGFloat = 12) -> SWButtonStyle {
        .init(variant: .secondary, showBorder: showBorder, cornerRadius: cornerRadius)
    }
}

// MARK: - 水墨卡片 Style

extension View {
    func swCardStyle(
        strokeColor: Color = AppTheme.inkShadow,
        background: Color = AppTheme.card,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16,
        strokeWidth: CGFloat = 1.0
    ) -> some View {
        self
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: strokeWidth)
            )
            .shadow(color: AppTheme.inkShadow, radius: 6, x: 0, y: 2)
    }
}

// MARK: - 水墨 Glass Card（宣纸底 + 轻单影 + 1px 墨边线）

extension View {
    func glassCard(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 18
    ) -> some View {
        self
            .padding(padding)
            .background(
                Color.white.opacity(0.88),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
            .shadow(color: AppTheme.inkShadow, radius: 4, x: 0, y: 2)
    }

    /// 水墨轻边卡片：白底 + 1px 淡墨边 + 极轻投影
    func inkCard(
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16
    ) -> some View {
        self
            .padding(padding)
            .background(
                AppTheme.card,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
            .shadow(color: AppTheme.inkShadow, radius: 4, x: 0, y: 2)
    }

    /// 强调卡片：带强调色左边框
    func accentInkCard(
        accent: Color = AppTheme.accentCinnabar,
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16
    ) -> some View {
        self
            .padding(padding)
            .background(
                AppTheme.card,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
            .shadow(color: AppTheme.inkShadow, radius: 4, x: 0, y: 2)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(accent)
                    .frame(width: 4)
                    .padding(.vertical, 8)
            }
    }
}

// MARK: - Bouncy Press ButtonStyle

struct SWBouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SWBouncyButtonStyle {
    static var bouncy: SWBouncyButtonStyle { .init() }
}