import SwiftUI

struct ExploreView: View {
    @State private var navPath = NavigationPath()
    @State private var selectedChip = "全部"

    private var hideTabBar: Bool { !navPath.isEmpty }

    private let chips = ["全部", "地理", "视频", "学习", "百科", "图库", "拼图"]

    private let horizontalPadding: CGFloat = 20
    private let sectionGap: CGFloat = 40
    private let cardGap: CGFloat = 14

    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                heroArea

                chipsRow

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: sectionGap) {
                        featuredBannerSection

                        appCardSection

                        categorySection

                        contentCardSection

                        comingSoonSection
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 48)
                }
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
                case .why:
                    WhyMainView()
                case .wallpaper:
                    WallpaperGalleryView()
                }
            }
        }
        .toolbar(hideTabBar ? .hidden : .visible, for: .tabBar)
        .animation(.easeInOut(duration: 0.2), value: hideTabBar)
    }

    // MARK: - Hero Area

    private var heroArea: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("探索")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.gradientExplore)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                Text("搜索地理、视频、百科…")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("热门")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accentJade)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.accentJade.opacity(0.1), in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(AppTheme.background)
    }

    // MARK: - Category Chips

    private var chipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(chips, id: \.self) { chip in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedChip = chip
                        }
                    } label: {
                        Text(chip)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(selectedChip == chip ? .white : AppTheme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedChip == chip
                                    ? AppTheme.accentJade
                                    : AppTheme.card,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(selectedChip == chip ? AppTheme.accentJade : AppTheme.separator, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Featured Banner

    private var featuredBannerSection: some View {
        NavigationLink(value: ExploreDestination.geography) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentJade.opacity(0.15), AppTheme.accentJade.opacity(0.05), AppTheme.card],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                            .strokeBorder(AppTheme.separator, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 12) {
                    Text("编辑推荐")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accentJade)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.accentJade.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Text("中国地理大探险")
                        .font(.system(size: 26, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("木质拼图与图鉴，点亮神州大地")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(28)

                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(AppTheme.accentJade.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "map.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(AppTheme.accentJade)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 28)
                .padding(.trailing, 24)

                Circle()
                    .fill(AppTheme.accentJade)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(24)
            }
            .frame(minHeight: 220)
            .padding(.horizontal, horizontalPadding)
        }
        .buttonStyle(ExploreBounceButtonStyle())
    }

    // MARK: - 大家都在玩（App 图标卡横滑）

    private var appCardSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "大家都在玩", showSeeAll: true)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: cardGap) {
                    appCard(
                        title: "地理大探险",
                        subtitle: "311 道关卡 · 神州漫游",
                        icon: "map.fill",
                        accent: AppTheme.accentJade,
                        isPrimary: true,
                        destination: .geography
                    )

                    appCard(
                        title: "视频乐园",
                        subtitle: "英语动画 · 科学百科",
                        icon: "play.square.fill",
                        accent: AppTheme.accentInkPurple,
                        isPrimary: false,
                        destination: .video
                    )

                    appCard(
                        title: "火柴游戏",
                        subtitle: "经典火柴 · 益智烧脑",
                        icon: "gamecontroller.fill",
                        accent: AppTheme.accentCinnabar,
                        isPrimary: true,
                        destination: .geography
                    )

                    appCard(
                        title: "学习资料",
                        subtitle: "课程笔记 · 全科覆盖",
                        icon: "book.closed.fill",
                        accent: AppTheme.accentBamboo,
                        isPrimary: false,
                        destination: .tutu
                    )
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }

    private func appCard(title: String, subtitle: String, icon: String, accent: Color, isPrimary: Bool, destination: ExploreDestination) -> some View {
        NavigationLink(value: destination) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(accent.opacity(0.10))
                        .frame(width: 68, height: 68)
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text("进入")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(isPrimary ? .white : accent)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 7)
                    .background(
                        isPrimary ? accent : accent.opacity(0.08),
                        in: Capsule()
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(width: 300)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
        }
        .buttonStyle(ExploreBounceButtonStyle())
    }

    // MARK: - 分类推荐（视觉方块横滑）

    private var categorySection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "分类推荐", showSeeAll: true)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: cardGap) {
                    catCard(title: "地理探索", count: "311 道题", icon: "map.fill", accent: AppTheme.accentJade, destination: .geography)
                    catCard(title: "视频学习", count: "86 个视频", icon: "play.square.fill", accent: AppTheme.accentInkPurple, destination: .video)
                    catCard(title: "诗词文学", count: "311 首", icon: "book.closed.fill", accent: AppTheme.accentBamboo, destination: .tutu)
                    catCard(title: "十万个为什么", count: "科学百科", icon: "questionmark.bubble.fill", accent: AppTheme.accentYellow, destination: .why)
                    catCard(title: "壁纸图库", count: "超清精选", icon: "photo.stack.fill", accent: AppTheme.accentIndigo, destination: .wallpaper)
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }

    private func catCard(title: String, count: String, icon: String, accent: Color, destination: ExploreDestination) -> some View {
        NavigationLink(value: destination) {
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.12), accent.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(accent.opacity(0.15))
                        .frame(width: 64, height: 64)

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(accent)
                }
                .frame(height: 110)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(count)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card)
            }
            .frame(width: 170)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
        }
        .buttonStyle(ExploreBounceButtonStyle())
    }

    // MARK: - 精选内容（大尺寸内容卡横滑）

    private var contentCardSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "精选内容", showSeeAll: true)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: cardGap) {
                    contentCard(
                        title: "中国地理大探险",
                        subtitle: "311 道关卡，走遍神州大地",
                        icon: "map.fill",
                        accent: AppTheme.accentJade,
                        tag: "热门",
                        destination: .geography
                    )

                    contentCard(
                        title: "视频乐园",
                        subtitle: "英语动画、科学百科",
                        icon: "play.square.fill",
                        accent: AppTheme.accentInkPurple,
                        tag: "推荐",
                        destination: .video
                    )

                    contentCard(
                        title: "学习资料",
                        subtitle: "课程笔记、全科覆盖",
                        icon: "book.closed.fill",
                        accent: AppTheme.accentBamboo,
                        tag: nil,
                        destination: .tutu
                    )

                    contentCard(
                        title: "十万个为什么",
                        subtitle: "科学知识 · 自然奥秘",
                        icon: "questionmark.bubble.fill",
                        accent: AppTheme.accentYellow,
                        tag: nil,
                        destination: .why
                    )
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }

    private func contentCard(title: String, subtitle: String, icon: String, accent: Color, tag: String?, destination: ExploreDestination) -> some View {
        NavigationLink(value: destination) {
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.15), accent.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(accent.opacity(0.12))
                        .frame(width: 72, height: 72)

                    Image(systemName: icon)
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(accent)
                }
                .frame(height: 160)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)

                    if let tag {
                        Text(tag)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card)
            }
            .frame(width: 220)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
        }
        .buttonStyle(ExploreBounceButtonStyle())
    }

    // MARK: - 即将开放（2列虚线卡片）

    private var comingSoonSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "即将开放", showSeeAll: false)

            HStack(spacing: cardGap) {
                soonCard(title: "奇妙科学", icon: "flask.fill", accent: AppTheme.accentJade)
                soonCard(title: "上下五千年", icon: "scroll.fill", accent: AppTheme.accentTerracotta)
            }
            .padding(.horizontal, horizontalPadding)
        }
    }

    private func soonCard(title: String, icon: String, accent: Color) -> some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accent.opacity(0.06))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(accent.opacity(0.5))
            }

            Text(title)
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))

            Text("即将开放")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                .tracking(0.4)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(AppTheme.background)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                .strokeBorder(AppTheme.separator, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        )
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, showSeeAll: Bool) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            if showSeeAll {
                Button {} label: {
                    HStack(spacing: 3) {
                        Text("查看全部")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.accentJade)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, horizontalPadding)
    }
}

enum ExploreDestination: Hashable {
    case geography
    case video
    case tutu
    case why
    case wallpaper
}

private struct ExploreBounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ExploreView()
}
