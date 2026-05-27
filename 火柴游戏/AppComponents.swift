import SwiftUI

// MARK: - 统一导航栏（所有二级及以下页面使用）

struct UnifiedNavBar: View {
    let title: String
    var trailing: AnyView? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }

            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            Spacer()

            if let trailing { trailing }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.vertical, 10)
    }
}

// MARK: - 统一 Toolbar 返回按钮（轻量 Modifier，用于不改结构的页面）

struct UnifiedBackButton: ViewModifier {
    let title: String
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 30, height: 30)
                                .background(.ultraThinMaterial, in: Circle())
                            Text(title)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
    }
}

extension View {
    func unifiedBackButton(title: String) -> some View {
        modifier(UnifiedBackButton(title: title))
    }
}

// MARK: - 环形进度组件

struct RingProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = min(progress, 1.0)
            }
        }
    }
}

// MARK: - 快捷入口胶囊

struct QuickEntryView: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
            }
            .frame(width: 64)
        }
        .buttonStyle(.bouncy)
    }
}

// MARK: - 每日一词卡片

struct DailyIdiomCard: View {
    let idiom: ChineseIdiom
    let onTapMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.accentYellow)
                Text("今日成语")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }

            Text(idiom.text)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            if let explanation = idiom.explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                    .lineSpacing(3)
            }

            HStack {
                Spacer()
                Button(action: onTapMore) {
                    HStack(spacing: 4) {
                        Text("查看更多")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.accentBlue)
                }
            }
        }
        .glassCard()
        .padding(.horizontal, AppTheme.paddingScreen)
    }
}

// MARK: - 学习周报卡片

struct WeeklyStatsCard: View {
    let matchSolves: Int
    let matchTotal: Int
    let poemsRead: Int
    let poemsTotal: Int
    let streakDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习进度")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 0) {
                ringItem(
                    progress: matchTotal > 0 ? Double(matchSolves) / Double(matchTotal) : 0,
                    value: "\(matchSolves)",
                    label: "火柴",
                    color: AppTheme.accentBlue
                )

                ringItem(
                    progress: poemsTotal > 0 ? Double(poemsRead) / Double(poemsTotal) : 0,
                    value: "\(poemsRead)",
                    label: "诗词",
                    color: AppTheme.accentTerracotta
                )

                ringItem(
                    progress: min(Double(streakDays) / 30.0, 1.0),
                    value: "\(streakDays)天",
                    label: "连续",
                    color: AppTheme.accentSage
                )
            }
        }
        .glassCard()
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    private func ringItem(progress: Double, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RingProgressView(progress: progress, lineWidth: 6, size: 52, color: color)

                Text(value)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .minimumScaleFactor(0.7)
            }

            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 探索推荐卡

struct DiscoverySuggestionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let colors: (Color, Color)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [colors.0, colors.1],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        }
        .buttonStyle(.bouncy)
        .padding(.horizontal, AppTheme.paddingScreen)
    }
}

// MARK: - 空态组件

struct EmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.4))

            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AppTheme.accentBlue, in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Stagger 入场动画 Modifier
// 仅用 opacity 渐显，不用 offset，避免 ScrollView 布局抖动

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    let totalCount: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .onAppear {
                guard !appeared else { return }
                withAnimation(
                    .easeOut(duration: 0.3)
                    .delay(Double(index) * 0.06)
                ) {
                    appeared = true
                }
            }
    }
}

extension View {
    func staggerAppear(index: Int, total: Int = 10) -> some View {
        modifier(StaggeredAppearModifier(index: index, totalCount: total))
    }
}

// MARK: - 渐变卡片 Modifier

struct GradientCardModifier: ViewModifier {
    let colors: [Color]
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: colors.first?.opacity(0.3) ?? .clear, radius: 12, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
            )
    }
}

extension View {
    func gradientCard(colors: [Color], cornerRadius: CGFloat = 28) -> some View {
        modifier(GradientCardModifier(colors: colors, cornerRadius: cornerRadius))
    }
}
