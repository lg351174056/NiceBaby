import SwiftUI

// MARK: - 统一导航栏（二级页）

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
                    .background(AppTheme.card, in: Circle())
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }

            Text(title)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            Spacer()

            if let trailing { trailing }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(AppTheme.background, ignoresSafeAreaEdges: .top)
        .overlay(alignment: .bottom) {
            AppTheme.separator.frame(height: 0.5)
        }
    }
}

// MARK: - 优雅返回箭头（细箭头 + 轻白圆）

struct GracefulBackButton: View {
    var action: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            if let action {
                action()
            } else {
                dismiss()
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 74/255, green: 92/255, blue: 66/255))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.8), in: Circle())
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 统一 Toolbar 返回按钮（Modifier 版）

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
                                .font(.system(size: 17, weight: .bold, design: .serif))
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
            .enableSwipeBack()
    }
}

extension View {
    func unifiedBackButton(title: String) -> some View {
        modifier(UnifiedBackButton(title: title))
    }
}

// MARK: - 恢复侧滑返回手势

struct EnableSwipeBackModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background { SwipeBackHelper() }
    }
}

extension View {
    func enableSwipeBack() -> some View {
        modifier(EnableSwipeBackModifier())
    }
}

private struct SwipeBackHelper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SwipeBackViewController {
        SwipeBackViewController()
    }
    func updateUIViewController(_ uiViewController: SwipeBackViewController, context: Context) {}
}

final class SwipeBackViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let nav = navigationController {
            nav.interactivePopGestureRecognizer?.isEnabled = true
            nav.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

// MARK: - 环形进度组件

struct RingProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 快捷入口胶囊（墨韵风）

private struct QuickEntryCardContent: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
        }
        .frame(width: 64)
    }
}

struct QuickEntryView: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            QuickEntryCardContent(icon: icon, title: title, color: color)
        }
        .buttonStyle(.plain)
    }
}

struct QuickEntryLinkView<Destination: View>: View {
    let icon: String
    let title: String
    let color: Color
    let destination: Destination

    init(
        icon: String,
        title: String,
        color: Color,
        @ViewBuilder destination: () -> Destination
    ) {
        self.icon = icon
        self.title = title
        self.color = color
        self.destination = destination()
    }

    var body: some View {
        NavigationLink(destination: destination) {
            QuickEntryCardContent(icon: icon, title: title, color: color)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 每日成语卡片（墨韵风）

struct DailyIdiomCard: View {
    let idiom: ChineseIdiom
    let onTapMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "seal.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.accentCinnabar)
                Text("今日成语")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }

            Text(idiom.text)
                .font(.system(size: 26, weight: .heavy, design: .serif))
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
                    .foregroundStyle(AppTheme.accentCinnabar)
                }
            }
        }
        .padding(16)
        .background(
            AppTheme.card,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.separator, lineWidth: 1)
        )
        .padding(.horizontal, AppTheme.paddingScreen)
    }
}

// MARK: - 学习进度卡片（墨韵风）

struct WeeklyStatsCard: View {
    let matchSolves: Int
    let matchTotal: Int
    let poemsRead: Int
    let poemsTotal: Int
    let streakDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习进度")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 0) {
                ringItem(
                    progress: matchTotal > 0 ? Double(matchSolves) / Double(matchTotal) : 0,
                    value: "\(matchSolves)",
                    label: "火柴",
                    color: AppTheme.accentCinnabar
                )

                ringItem(
                    progress: poemsTotal > 0 ? Double(poemsRead) / Double(poemsTotal) : 0,
                    value: "\(poemsRead)",
                    label: "诗词",
                    color: AppTheme.accentBamboo
                )

                ringItem(
                    progress: min(Double(streakDays) / 30.0, 1.0),
                    value: "\(streakDays)天",
                    label: "连续",
                    color: AppTheme.accentSage
                )
            }
        }
        .padding(16)
        .background(
            AppTheme.card,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.separator, lineWidth: 1)
        )
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    private func ringItem(progress: Double, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RingProgressView(progress: progress, lineWidth: 5, size: 48, color: color)
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

// MARK: - 探索推荐卡片（墨韵风）

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
                        .fill(colors.0.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(colors.0)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .serif))
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
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
                .foregroundStyle(AppTheme.textSecondary.opacity(0.35))

            Text(title)
                .font(.system(size: 16, weight: .bold, design: .serif))
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
                        .background(AppTheme.accentCinnabar, in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Stagger 入场动画

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

// MARK: - 渐变卡片 Modifier（保留，供诗集详情等场景使用）

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
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

extension View {
    func gradientCard(colors: [Color], cornerRadius: CGFloat = 24) -> some View {
        modifier(GradientCardModifier(colors: colors, cornerRadius: cornerRadius))
    }
}
