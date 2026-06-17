import SwiftUI

// MARK: - 探索 · 碧潭色 · Bento 探索岛

struct ExploreView: View {
    @State private var navPath = NavigationPath()
    @State private var selectedChip = "全部"

    private var hideTabBar: Bool { !navPath.isEmpty }

    private let chips = ["全部", "地理", "视频", "学习", "百科", "图库"]

    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                heroArea

                chipsRow

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        featuredCard

                        HStack(spacing: 12) {
                            tallCard(
                                title: "视频乐园",
                                subtitle: "英语动画、科学百科",
                                icon: "play.tv.fill",
                                accent: AppTheme.accentInkPurple,
                                badge: "热门",
                                destination: ExploreDestination.video
                            )

                            tallCard(
                                title: "学习资料",
                                subtitle: "课程笔记、全科覆盖",
                                icon: "books.vertical.fill",
                                accent: AppTheme.accentBamboo,
                                badge: nil,
                                destination: ExploreDestination.tutu
                            )
                        }

                        wideCard(
                            title: "十万个为什么",
                            subtitle: "科学知识 · 自然奥秘 · 生活百科",
                            icon: "questionmark.app.dashed",
                            accent: AppTheme.accentYellow,
                            destination: ExploreDestination.why
                        )

                        wideCard(
                            title: "壁纸图库",
                            subtitle: "超清精选 · AI 漫改 · 美女车模",
                            icon: "photo.on.rectangle.angled",
                            accent: AppTheme.accentIndigo,
                            destination: ExploreDestination.wallpaper
                        )

                        HStack(alignment: .center, spacing: 4) {
                            Text("即将开放")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .tracking(0.8)
                            Spacer()
                        }
                        .padding(.horizontal, AppTheme.paddingScreen)
                        .padding(.top, 6)

                        HStack(spacing: 12) {
                            soonCard(title: "奇妙科学", icon: "flask.fill", accent: AppTheme.accentJade)

                            soonCard(title: "上下五千年", icon: "scroll.fill", accent: AppTheme.accentTerracotta)
                        }
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.bottom, 40)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("探索 · 发现")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.gradientExplore)
                Spacer()
            }

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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.accentJade.opacity(0.1), in: Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(AppTheme.background)
    }

    // MARK: - Category Chips

    private var chipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips, id: \.self) { chip in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedChip = chip
                        }
                    } label: {
                        Text(chip)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(selectedChip == chip ? .white : AppTheme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
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
            .padding(.horizontal, AppTheme.paddingScreen)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Featured Card (2-column span)

    private var featuredCard: some View {
        NavigationLink(value: ExploreDestination.geography) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentJade.opacity(0.12), AppTheme.accentJade.opacity(0.04), AppTheme.card],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                            .strokeBorder(AppTheme.separator, lineWidth: 1)
                    )
                Circle()
                    .strokeBorder(AppTheme.accentJade.opacity(0.08), lineWidth: 1)
                    .frame(width: 140, height: 140)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .offset(x: 30, y: -30)

                VStack(alignment: .leading, spacing: 8) {
                    Text("编辑推荐")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accentJade)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.accentJade.opacity(0.12), in: Capsule())

                    Text("中国地理大探险")
                        .font(.system(size: 22, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("木质拼图与图鉴，点亮神州大地")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(20)

                Circle()
                    .fill(AppTheme.accentJade)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: AppTheme.accentJade.opacity(0.35), radius: 8, y: 3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(18)
            }
            .frame(minHeight: 200)
        }
        .buttonStyle(ExploreBounceButtonStyle())
    }

    // MARK: - Tall Card (1 column, tall)

    private func tallCard(title: String, subtitle: String, icon: String, accent: Color, badge: String?, destination: ExploreDestination) -> some View {
        NavigationLink(value: destination) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.08), accent.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 90)

                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(accent.opacity(0.10))
                            .frame(width: 48, height: 48)
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(accent)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 44))
                        .foregroundStyle(accent.opacity(0.06))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .offset(x: -6, y: 6)
                }
                .frame(height: 90)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(accent.opacity(0.1), in: Capsule())
                        .padding(10)
                }
            }
        }
        .buttonStyle(ExploreBounceButtonStyle())
    }

    // MARK: - Wide Card (2-column span)

    private func wideCard(title: String, subtitle: String, icon: String, accent: Color, destination: ExploreDestination) -> some View {
        NavigationLink(value: destination) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accent.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
            }
            .padding(14)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
        }
        .buttonStyle(ExploreBounceButtonStyle())
    }

    // MARK: - Coming Soon Card (dashed border)

    private func soonCard(title: String, icon: String, accent: Color) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(0.06))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
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
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(AppTheme.background)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                .strokeBorder(AppTheme.separator, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        )
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