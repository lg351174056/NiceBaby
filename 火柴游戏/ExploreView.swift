import SwiftUI

struct ExploreView: View {
    @State private var navPath = NavigationPath()

    private var hideTabBar: Bool { !navPath.isEmpty }

    private let horizontalPadding: CGFloat = 22

    private let volumes: [ExploreVolume] = ExploreVolume.all

    var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroArea
                    scrollArea
                }
                .padding(.bottom, 56)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ExploreDestination.self) { dest in
                switch dest {
                case .geography:
                    ChinaGeographyView()
                case .video:
                    VideoCategoryListView()
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

    // MARK: - Hero

    private var heroArea: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 10) {
                Text("EXPLORE · 拾卷于山川")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(3.7)
                    .foregroundStyle(AppTheme.accentJade)

                Text("探索")
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .tracking(2.2)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("择卷而观，循序而入。神州风物，皆在尺寸之间。")
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: 30 * 14, alignment: .leading)
                    .padding(.top, 2)

                HStack(spacing: 8) {
                    sealRound("墨")
                    sealSquare("癸卯 · 探索")
                }
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 10)

            farMountain
                .frame(width: 96, height: 60)
                .opacity(0.5)
                .padding(.top, 16)
                .padding(.trailing, 20)
                .allowsHitTesting(false)
        }
    }

    private var farMountain: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let back = Path { p in
                p.move(to: .init(x: 0, y: h))
                p.addLine(to: .init(x: w * 0.20, y: h * 0.50))
                p.addLine(to: .init(x: w * 0.34, y: h * 0.73))
                p.addLine(to: .init(x: w * 0.52, y: h * 0.30))
                p.addLine(to: .init(x: w * 0.72, y: h * 0.63))
                p.addLine(to: .init(x: w, y: h * 0.20))
                p.addLine(to: .init(x: w, y: h))
                p.closeSubpath()
            }
            ctx.fill(back, with: .color(AppTheme.accentJade.opacity(0.55)))

            let front = Path { p in
                p.move(to: .init(x: 0, y: h))
                p.addLine(to: .init(x: w * 0.14, y: h * 0.63))
                p.addLine(to: .init(x: w * 0.28, y: h * 0.80))
                p.addLine(to: .init(x: w * 0.48, y: h * 0.43))
                p.addLine(to: .init(x: w * 0.70, y: h * 0.70))
                p.addLine(to: .init(x: w, y: h * 0.37))
                p.addLine(to: .init(x: w, y: h))
                p.closeSubpath()
            }
            ctx.fill(front, with: .color(AppTheme.accentJade.opacity(0.45)))
        }
    }

    private func sealRound(_ text: String) -> some View {
        ZStack {
            Circle()
                .fill(AppTheme.accentCinnabar.opacity(0.04))
            Circle()
                .strokeBorder(AppTheme.accentCinnabar, lineWidth: 1.5)
            Text(text)
                .font(.system(size: 14, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.accentCinnabar)
        }
        .frame(width: 32, height: 32)
    }

    private func sealSquare(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .serif))
            .foregroundStyle(AppTheme.accentCinnabar)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AppTheme.accentCinnabar.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(AppTheme.accentCinnabar, lineWidth: 1.5)
            )
            .rotationEffect(.degrees(2))
    }

    // MARK: - 长卷

    private var scrollArea: some View {
        VStack(spacing: 0) {
            ForEach(volumes) { vol in
                volumeSection(vol)
            }
            postscript
        }
        .padding(.top, 6)
    }

    private func volumeSection(_ vol: ExploreVolume) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(vol.numLabel)
                    .font(.system(size: 14, weight: .black, design: .serif))
                    .tracking(1.4)
                    .foregroundStyle(AppTheme.accentCinnabar)
                Text(vol.name)
                    .font(.system(size: 19, weight: .black, design: .serif))
                    .tracking(1.1)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(vol.items.count) 篇")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 22)
            .padding(.bottom, 10)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppTheme.separator)
                    .frame(height: 1)
                    .padding(.horizontal, horizontalPadding)
            }

            VStack(spacing: 0) {
                ForEach(vol.items) { item in
                    volumeItem(item)
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
    }

    private func volumeItem(_ item: ExploreItem) -> some View {
        _ = item.destination == nil
        return Group {
            if let dest = item.destination {
                NavigationLink(value: dest) {
                    itemRow(item, locked: false)
                }
                .buttonStyle(ExploreBounceButtonStyle())
            } else {
                itemRow(item, locked: true)
                    .opacity(0.55)
            }
        }
        .overlay(alignment: .bottom) {
            if !item.isLast {
                Rectangle()
                    .fill(AppTheme.separator.opacity(0.6))
                    .frame(height: 1)
                    .padding(.leading, 52)
            }
        }
    }

    private func itemRow(_ item: ExploreItem, locked: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                if locked {
                    Circle()
                        .fill(AppTheme.card)
                    Circle()
                        .strokeBorder(
                            AppTheme.textSecondary.opacity(0.4),
                            style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])
                        )
                } else {
                    Circle()
                        .fill(AppTheme.accentCinnabar)
                    Circle()
                        .strokeBorder(AppTheme.accentCinnabar, lineWidth: 1.5)
                }
                Text(item.seal)
                    .font(.system(size: 13, weight: .black, design: .serif))
                    .foregroundStyle(
                        locked
                            ? AppTheme.textSecondary.opacity(0.5)
                            : Color(red: 247/255, green: 245/255, blue: 240/255)
                    )
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .tracking(0.6)
                    .foregroundStyle(
                        locked ? AppTheme.textSecondary.opacity(0.6) : AppTheme.textPrimary
                    )
                Text(item.subtitle)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Text(locked ? "—" : "入 ▸")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(AppTheme.textSecondary.opacity(locked ? 0.4 : 0.7))
        }
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    // MARK: - 题跋

    private var postscript: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("题 跋")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(2.2)
                .foregroundStyle(AppTheme.accentJade)
            Text("古曰学海无涯。今择五卷以为端，皆可凭兴趣入门，循序而至深。")
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: 34 * 14, alignment: .leading)
                .padding(.top, 10)
            Text("即所见，亦所学 · 探索谨题")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.accentCinnabar)
                .rotationEffect(.degrees(-2))
                .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(AppTheme.accentJade.opacity(0.06))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(AppTheme.accentJade)
                .frame(width: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 30)
    }
}

// MARK: - 卷数据

struct ExploreVolume: Identifiable {
    let id: String
    let numLabel: String
    let name: String
    let items: [ExploreItem]

    static let all: [ExploreVolume] = [
        ExploreVolume(id: "v1", numLabel: "卷 一", name: "山河之卷", items: [
            ExploreItem(id: "i1", seal: "壹", title: "中国地理大探险",
                        subtitle: "311 道关卡 · 神州漫游 · 木质拼图与图鉴",
                        destination: .geography, isLast: false),
            ExploreItem(id: "i2", seal: "贰", title: "壁纸图库",
                        subtitle: "超清精选 · 山川风物入屏为伴",
                        destination: .wallpaper, isLast: true),
        ]),
        ExploreVolume(id: "v2", numLabel: "卷 二", name: "声影之卷", items: [
            ExploreItem(id: "i3", seal: "叁", title: "视频乐园",
                        subtitle: "86 个视频 · 英语动画与科学百科",
                        destination: .video, isLast: true),
        ]),
        ExploreVolume(id: "v3", numLabel: "卷 三", name: "学问之卷", items: [
            ExploreItem(id: "i4", seal: "肆", title: "成语接龙",
                        subtitle: "同字相承 · 绝杀封喉 · 益智接龙",
                        destination: .idiomSolitaire, isLast: false),
            ExploreItem(id: "i5", seal: "伍", title: "诗词文学",
                        subtitle: "311 首 · 唐宋元明清 · 课读与释义",
                        destination: .poetry, isLast: true),
        ]),
        ExploreVolume(id: "v4", numLabel: "续 卷", name: "未启之篇", items: [
            ExploreItem(id: "i6", seal: "疑", title: "奇妙科学",
                        subtitle: "未启 · 敬请期待",
                        destination: nil, isLast: false),
            ExploreItem(id: "i7", seal: "参", title: "上下五千年",
                        subtitle: "未启 · 敬请期待",
                        destination: nil, isLast: true),
        ]),
    ]
}

struct ExploreItem: Identifiable {
    let id: String
    let seal: String
    let title: String
    let subtitle: String
    let destination: ExploreDestination?
    let isLast: Bool
}

enum ExploreDestination: Hashable {
    case geography
    case video
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
