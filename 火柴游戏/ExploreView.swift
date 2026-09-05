import SwiftUI

struct ExploreView: View {
    @EnvironmentObject private var progress: AppProgressStore
    @State private var navPath = NavigationPath()

    private var hideTabBar: Bool { !navPath.isEmpty }

    private let horizontalPadding: CGFloat = 22

    private let volumes: [ExploreVolume] = ExploreVolume.all

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                // 蓝天草地背景（固定）
                FieldBackground()

                // 太阳 + 白云 + 草地装饰
                sunDecoration
                cloudDecoration(x: 0.02, y: 0.10, scale: 1.0, delay: 0)
                cloudDecoration(x: 0.72, y: 0.16, scale: 0.75, delay: 2.5)
                grassDecoration

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroArea
                        campStats
                        scrollArea
                    }
                    .padding(.bottom, 56)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ExploreDestination.self) { dest in
                switch dest {
                case .geography:
                    ChinaGeographyView()
                case .bilibili:
                    BilibiliColumnView()
                case .tutu:
                    TutuHomeView()
                case .idiomSolitaire:
                    IdiomSolitaireView()
                case .wallpaper:
                    WallpaperGalleryView()
                case .poetry:
                    PMMainView()
                }
            }
        }
        .toolbar(hideTabBar ? .hidden : .visible, for: .tabBar)
        .animation(.easeInOut(duration: 0.2), value: hideTabBar)
    }

    // MARK: - 营地头（白昼野营）

    private var heroArea: some View {
        VStack(spacing: 0) {
            Text("FIELD EXPLORATION")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(5)
                .foregroundStyle(Color(red: 110/255, green: 138/255, blue: 90/255))

            Text("探索")
                .font(.system(size: 32, weight: .black, design: .serif))
                .tracking(5)
                .foregroundStyle(AppTheme.fieldInk)
                .padding(.top, 6)

            Text("背上小背包，向未知出发")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 122/255, green: 138/255, blue: 110/255))
                .padding(.top, 6)

            campfire
                .frame(width: 74, height: 56)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    // 营火：三层火焰（不同频率叠加）+ 光晕 + 柴堆
    private var campfire: some View {
        ZStack {
            // 光晕（呼吸 + 闪烁）
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 240/255, green: 150/255, blue: 60/255).opacity(0.26 + 0.08 * sin(t * 1.3)),
                            .clear
                        ], center: .center, startRadius: 6, endRadius: 44)
                    )
                    .frame(width: 88, height: 88)
            }

            // 三层火焰
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    // 外焰：低频大摆动
                    FlameShape()
                        .fill(
                            LinearGradient(colors: [
                                Color(red: 255/255, green: 143/255, blue: 61/255),
                                Color(red: 222/255, green: 92/255, blue: 38/255)
                            ], startPoint: .top, endPoint: .bottom)
                        )
                        .scaleEffect(x: 1 + 0.06 * sin(t * 1.9), y: 1 + 0.08 * sin(t * 2.3), anchor: .bottom)
                        .rotationEffect(.degrees(2.5 * sin(t * 1.5)))
                        .frame(width: 34, height: 42)
                        .offset(y: 8)

                    // 中焰：中频
                    FlameShape()
                        .fill(
                            LinearGradient(colors: [
                                Color(red: 255/255, green: 178/255, blue: 90/255),
                                Color(red: 246/255, green: 125/255, blue: 52/255)
                            ], startPoint: .top, endPoint: .bottom)
                        )
                        .scaleEffect(x: 1 + 0.08 * sin(t * 3.2), y: 1 + 0.1 * sin(t * 3.7), anchor: .bottom)
                        .rotationEffect(.degrees(-3 * sin(t * 2.6)))
                        .frame(width: 24, height: 32)
                        .offset(y: 8)

                    // 内焰：高频跳跃
                    FlameShape()
                        .fill(
                            RadialGradient(colors: [
                                Color(red: 255/255, green: 248/255, blue: 205/255),
                                Color(red: 255/255, green: 214/255, blue: 110/255)
                            ], center: .init(x: 0.5, y: 0.75), startRadius: 2, endRadius: 12)
                        )
                        .scaleEffect(x: 1 + 0.09 * sin(t * 4.6), y: 1 + 0.13 * sin(t * 5.2), anchor: .bottom)
                        .rotationEffect(.degrees(3.5 * sin(t * 4.1)))
                        .frame(width: 14, height: 22)
                        .offset(y: 8)
                }
            }

            // 柴堆
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 176/255, green: 138/255, blue: 94/255),
                            Color(red: 138/255, green: 106/255, blue: 62/255)
                        ], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 52, height: 6)
                    .rotationEffect(.degrees(8))
                Rectangle()
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 176/255, green: 138/255, blue: 94/255),
                            Color(red: 138/255, green: 106/255, blue: 62/255)
                        ], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 52, height: 6)
                    .rotationEffect(.degrees(-8))
            }
            .offset(y: 22)
        }
        .frame(width: 74, height: 56)
    }

    /// 火焰轮廓（底宽顶尖，双曲线内凹）
    private struct FlameShape: Shape {
        func path(in rect: CGRect) -> Path {
            let w = rect.width, h = rect.height
            var p = Path()
            p.move(to: CGPoint(x: w * 0.20, y: h))
            p.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.10),
                       control1: CGPoint(x: w * 0.10, y: h * 0.62),
                       control2: CGPoint(x: w * 0.26, y: h * 0.32))
            p.addCurve(to: CGPoint(x: w * 0.80, y: h),
                       control1: CGPoint(x: w * 0.74, y: h * 0.32),
                       control2: CGPoint(x: w * 0.90, y: h * 0.62))
            p.addCurve(to: CGPoint(x: w * 0.20, y: h),
                       control1: CGPoint(x: w * 0.56, y: h * 0.94),
                       control2: CGPoint(x: w * 0.44, y: h * 0.94))
            p.closeSubpath()
            return p
        }
    }

    // MARK: - 营地统计

    private var campStats: some View {
        HStack(spacing: 10) {
            campStat(value: "\(exploreTotal)", label: "探索点")
            campStat(value: "\(exploreBadges)", label: "收集徽章")
            campStat(value: "\(progress.streakDays)", label: "露营天")
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 10)
    }

    private var exploreTotal: Int {
        volumes.reduce(0) { $0 + $1.items.count }
    }

    private var exploreBadges: Int {
        volumes
            .flatMap { $0.items }
            .filter { $0.destination != nil && !$0.medal.isEmpty }
            .count
    }

    private func campStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 19, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 110/255, green: 138/255, blue: 62/255))
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundStyle(AppTheme.fieldMoss)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.1), radius: 6, y: 3)
        )
    }

    // MARK: - 太阳（光环旋转）

    private var sunDecoration: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let angle = (t.truncatingRemainder(dividingBy: 26) / 26) * 360
            let breathe = 1 + 0.03 * sin(t * 1.2)
            ZStack {
                // 大光晕（柔和扩散）
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 214/255, blue: 110/255).opacity(0.4),
                            Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.14),
                            .clear
                        ], center: .center, startRadius: 10, endRadius: 52)
                    )
                    .frame(width: 104, height: 104)
                    .scaleEffect(breathe)

                // 光芒射线（8 条旋转）
                ZStack {
                    ForEach(0..<8, id: \.self) { i in
                        Capsule()
                            .fill(
                                LinearGradient(colors: [
                                    Color(red: 255/255, green: 220/255, blue: 120/255).opacity(0.85),
                                    Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.05)
                                ], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: 22, height: 3.5)
                            .offset(x: 26)
                            .rotationEffect(.degrees(Double(i) * 45))
                    }
                }
                .rotationEffect(.degrees(angle))
                .frame(width: 60, height: 60)

                // 太阳本体（脉动）
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 246/255, blue: 205/255),
                            Color(red: 255/255, green: 214/255, blue: 100/255),
                            Color(red: 247/255, green: 188/255, blue: 55/255)
                        ], center: .init(x: 0.38, y: 0.3), startRadius: 2, endRadius: 18)
                    )
                    .frame(width: 34, height: 34)
                    .scaleEffect(breathe)
                    .shadow(color: Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.8), radius: 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.trailing, 22)
            .padding(.top, 52)
        }
        .allowsHitTesting(false)
    }

    // MARK: - 白云（漂移动画）

    private func cloudDecoration(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate + delay
            let drift = 16 * sin(t * 0.42)          // 水平漂移（慢）
            let bob = 3.5 * sin(t * 0.85 + 1.2)      // 垂直浮动（快一档）
            ZStack {
                // 云朵主体（多层圆，边缘柔和）
                ZStack {
                    // 底部主体
                    Capsule()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 44, height: 16)
                        .offset(y: 4)
                    // 左侧大团
                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 26, height: 26)
                        .offset(x: -9, y: -6)
                    // 右侧团
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 22, height: 22)
                        .offset(x: 7, y: -4)
                    // 顶部小团
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 16, height: 16)
                        .offset(x: 0, y: -10)
                    // 底部阴影
                    Ellipse()
                        .fill(Color(red: 160/255, green: 190/255, blue: 210/255).opacity(0.18))
                        .frame(width: 48, height: 7)
                        .offset(y: 11)
                }
                .frame(width: 54, height: 32)
                .scaleEffect(scale)
                .offset(x: drift, y: bob)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, 390 * x - 10)
            .padding(.top, 390 * y)
        }
        .allowsHitTesting(false)
    }

    // MARK: - 草地装饰

    private var grassDecoration: some View {
        Canvas { ctx, size in
            let w = size.width
            let blades: [(CGFloat, CGFloat)] = [(0.08, 0.55), (0.28, 0.42), (0.52, 0.5), (0.74, 0.4), (0.93, 0.55)]
            for (rx, h) in blades {
                var p = Path()
                let x = w * rx, y = size.height * 0.94
                p.move(to: CGPoint(x: x, y: y))
                p.addQuadCurve(to: CGPoint(x: x + 6, y: y - h * 0.9),
                               control: CGPoint(x: x + 8, y: y - h * 0.45))
                p.addQuadCurve(to: CGPoint(x: x + 2, y: y),
                               control: CGPoint(x: x + 4, y: y - h * 0.6))
                p.closeSubpath()
                ctx.fill(p, with: .color(Color(red: 90/255, green: 150/255, blue: 90/255).opacity(0.5)))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - 营地分区

    private var scrollArea: some View {
        VStack(spacing: 0) {
            ForEach(volumes) { vol in
                campSection(vol)
            }
            badgeSection
        }
        .padding(.top, 14)
    }

    private func campSection(_ vol: ExploreVolume) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 营地标题行
            HStack(spacing: 10) {
                Text(vol.icon).font(.system(size: 20))
                Text(vol.name)
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .tracking(2)
                    .foregroundStyle(AppTheme.fieldInk)
                Rectangle()
                    .fill(
                        LinearGradient(colors: [
                            AppTheme.fieldOlive.opacity(0.35),
                            .clear
                        ], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 2)
                Text("\(vol.items.count) 处探索")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 18)
            .padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(vol.items) { item in
                    campItem(item)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, 10)
                }
            }
        }
    }

    private func campItem(_ item: ExploreItem) -> some View {
        return Group {
            if let dest = item.destination {
                NavigationLink(value: dest) {
                    expeditionCard(item, locked: false)
                }
                .buttonStyle(ExploreBounceButtonStyle())
            } else {
                expeditionCard(item, locked: true)
                    .opacity(0.55)
                    .grayscale(0.4)
            }
        }
    }

    private func expeditionCard(_ item: ExploreItem, locked: Bool) -> some View {
        HStack(spacing: 14) {
            // 科考图标
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(expeditionTint(item.icon))
                Text(item.icon)
                    .font(.system(size: 22))
            }
            .frame(width: 46, height: 46)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppTheme.fieldOlive.opacity(0.35), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 14, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text(item.subtitle)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .lineLimit(1)
                if !item.meta.isEmpty {
                    Text(item.meta)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 110/255, green: 138/255, blue: 62/255))
                        .padding(.top, 2)
                }
            }

            Spacer()

            if locked {
                Text("🔒")
                    .font(.system(size: 15))
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 160/255, green: 138/255, blue: 90/255))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.12), radius: 8, y: 4)
        )
        .overlay(alignment: .topTrailing) {
            if !item.medal.isEmpty {
                Text(item.medal)
                    .font(.system(size: 15))
                    .offset(x: -8, y: -7)
            }
        }
    }

    private func expeditionTint(_ icon: String) -> Color {
        switch icon {
        case "🏔": return Color(red: 255/255, green: 238/255, blue: 216/255)
        case "🖼": return Color(red: 227/255, green: 240/255, blue: 248/255)
        case "🎬": return Color(red: 232/255, green: 245/255, blue: 224/255)
        case "📺": return Color(red: 255/255, green: 240/255, blue: 246/255)
        case "🔗": return Color(red: 245/255, green: 232/255, blue: 245/255)
        case "📜": return Color(red: 248/255, green: 240/255, blue: 216/255)
        default: return Color(red: 240/255, green: 234/255, blue: 224/255)
        }
    }

    // MARK: - 收集图鉴

    private var badgeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text("🏅").font(.system(size: 20))
                Text("收集图鉴")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .tracking(2)
                    .foregroundStyle(AppTheme.fieldInk)
                Rectangle()
                    .fill(
                        LinearGradient(colors: [
                            AppTheme.fieldOlive.opacity(0.35),
                            .clear
                        ], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 2)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 18)
            .padding(.bottom, 12)

            HStack(spacing: 8) {
                badgeCell("🏔", got: true, delay: 0)
                badgeCell("🎬", got: true, delay: 0.2)
                badgeCell("🔗", got: true, delay: 0.4)
                badgeCell("🖼", got: false, delay: 0)
                badgeCell("📜", got: false, delay: 0)
                badgeCell("🔬", got: false, delay: 0)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, 20)
        }
    }

    private func badgeCell(_ icon: String, got: Bool, delay: Double) -> some View {
        Text(icon)
            .font(.system(size: 19))
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(got ? Color(red: 255/255, green: 248/255, blue: 220/255).opacity(0.9)
                        : Color.white.opacity(0.7))
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        got ? Color(red: 110/255, green: 138/255, blue: 62/255)
                            : AppTheme.fieldOlive.opacity(0.45),
                        style: StrokeStyle(lineWidth: 2, dash: got ? [] : [4, 3])
                    )
            )
            .modifier(BadgeBob(delay: delay, enabled: got))
    }

    private struct BadgeBob: ViewModifier {
        let delay: Double
        let enabled: Bool
        @State private var bobbing = false
        func body(content: Content) -> some View {
            content
                .offset(y: bobbing ? -4 : 0)
                .animation(
                    .easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(delay),
                    value: bobbing
                )
                .onAppear { if enabled { bobbing = true } }
        }
    }

}

// MARK: - 卷数据

struct ExploreVolume: Identifiable {
    let id: String
    let numLabel: String
    let name: String
    let icon: String
    let items: [ExploreItem]

    static let all: [ExploreVolume] = [
        ExploreVolume(id: "v1", numLabel: "卷一", name: "山河营地", icon: "⛺", items: [
            ExploreItem(id: "i1", seal: "壹", title: "中国地理大探险",
                        subtitle: "311 道关卡 · 游遍神州",
                        icon: "🏔", meta: "🏅 42 关 · 🧭 8 省", medal: "🥇",
                        destination: .geography, isLast: false),
            ExploreItem(id: "i2", seal: "贰", title: "壁纸图库",
                        subtitle: "山川风物 · 收藏入屏",
                        icon: "🖼", meta: "", medal: "🥈",
                        destination: .wallpaper, isLast: true),
        ]),
        ExploreVolume(id: "v2", numLabel: "卷二", name: "声影营地", icon: "📻", items: [
            ExploreItem(id: "i8", seal: "贰", title: "B站专栏",
                        subtitle: "数学思维 · 趣味百科 · 国学语文",
                        icon: "📺", meta: "精选 · 持续更新", medal: "",
                        destination: .bilibili, isLast: true),
        ]),
        ExploreVolume(id: "v3", numLabel: "卷三", name: "学问营地", icon: "📚", items: [
            ExploreItem(id: "i4", seal: "肆", title: "成语接龙",
                        subtitle: "同字相承 · 越接越聪明",
                        icon: "🔗", meta: "", medal: "🥉",
                        destination: .idiomSolitaire, isLast: false),
            ExploreItem(id: "i5", seal: "伍", title: "诗词文学",
                        subtitle: "311 首 · 唐宋元明清",
                        icon: "📜", meta: "", medal: "",
                        destination: .poetry, isLast: true),
        ]),
        ExploreVolume(id: "v4", numLabel: "续卷", name: "迷雾之地", icon: "🌫", items: [
            ExploreItem(id: "i6", seal: "疑", title: "奇妙科学",
                        subtitle: "探索科学奥秘 · 敬请期待",
                        icon: "🔬", meta: "", medal: "",
                        destination: nil, isLast: false),
            ExploreItem(id: "i7", seal: "参", title: "上下五千年",
                        subtitle: "穿越历史长河 · 敬请期待",
                        icon: "🏯", meta: "", medal: "",
                        destination: nil, isLast: true),
        ]),
    ]
}

struct ExploreItem: Identifiable {
    let id: String
    let seal: String
    let title: String
    let subtitle: String
    let icon: String
    let meta: String
    let medal: String
    let destination: ExploreDestination?
    let isLast: Bool
}

enum ExploreDestination: Hashable {
    case geography
    case bilibili
    case tutu
    case idiomSolitaire
    case wallpaper
    case poetry
}

private struct ExploreBounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ExploreView()
}
