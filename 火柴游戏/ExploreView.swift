import SwiftUI

// MARK: - 探索 · 碧潭色

struct ExploreView: View {
    @State private var navPath = NavigationPath()

    private var hideTabBar: Bool { !navPath.isEmpty }

    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text("探索")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentJade.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: "sparkle.magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.accentJade)
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(AppTheme.background)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        NavigationLink(value: ExploreDestination.geography) {
                            ExploreInkCard(
                                title: "中国地理大探险",
                                subtitle: "木质拼图与图鉴，点亮神州大地",
                                icon: "map.fill",
                                accent: AppTheme.accentJade,
                                isPlaceholder: false
                            )
                        }
                        .buttonStyle(ExploreBounceButtonStyle())

                        NavigationLink(value: ExploreDestination.video) {
                            ExploreInkCard(
                                title: "视频乐园",
                                subtitle: "海量英语动画、科学百科，随时播放",
                                icon: "play.tv.fill",
                                accent: AppTheme.accentInkPurple,
                                isPlaceholder: false
                            )
                        }
                        .buttonStyle(ExploreBounceButtonStyle())

                        NavigationLink(value: ExploreDestination.tutu) {
                            ExploreInkCard(
                                title: "学习资料",
                                subtitle: "课程笔记、单元练习，全科覆盖",
                                icon: "books.vertical.fill",
                                accent: AppTheme.accentBamboo,
                                isPlaceholder: false
                            )
                        }
                        .buttonStyle(ExploreBounceButtonStyle())

                        NavigationLink(value: ExploreDestination.why) {
                            ExploreInkCard(
                                title: "十万个为什么",
                                subtitle: "科学知识、自然奥秘、生活百科",
                                icon: "questionmark.app.dashed",
                                accent: AppTheme.accentYellow,
                                isPlaceholder: false
                            )
                        }
                        .buttonStyle(ExploreBounceButtonStyle())

                        NavigationLink(value: ExploreDestination.wallpaper) {
                            ExploreInkCard(
                                title: "壁纸图库",
                                subtitle: "超清精选、AI漫改、美女车模",
                                icon: "photo.on.rectangle.angled",
                                accent: AppTheme.accentIndigo,
                                isPlaceholder: false
                            )
                        }
                        .buttonStyle(ExploreBounceButtonStyle())

                        ExploreInkCard(
                            title: "奇妙科学",
                            subtitle: "即将开放...",
                            icon: "flask.fill",
                            accent: AppTheme.accentCinnabar,
                            isPlaceholder: true
                        )

                        ExploreInkCard(
                            title: "上下五千年",
                            subtitle: "即将开放...",
                            icon: "scroll.fill",
                            accent: AppTheme.accentTerracotta,
                            isPlaceholder: true
                        )
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.top, 10)
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
}

enum ExploreDestination: Hashable {
    case geography
    case video
    case tutu
    case why
    case wallpaper
}

// MARK: - 水墨探索卡 · 单色图标 + 轻边框

private struct ExploreInkCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let isPlaceholder: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent.opacity(0.08))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(3)
            }

            Spacer()

            if !isPlaceholder {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.3))
            }
        }
        .padding(18)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: AppTheme.inkShadow, radius: 4, x: 0, y: 2)
        .opacity(isPlaceholder ? 0.65 : 1.0)
    }
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