import SwiftUI

struct ExploreView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 统一 TopBar
                HStack(alignment: .center) {
                    Text("探索")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentSage.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "sparkle.magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.accentSage)
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(AppTheme.background)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        NavigationLink(destination: ChinaGeographyView()) {
                            ExploreModuleCard(
                                title: "中国地理大探险",
                                subtitle: "木质拼图与图鉴，点亮神州大地",
                                icon: "map.fill",
                                colors: (AppTheme.accentMint, AppTheme.accentBlue),
                                isPlaceholder: false
                            )
                        }
                        .buttonStyle(ExploreBounceButtonStyle())
                        
                        NavigationLink(destination: VideoCategoryListView()) {
                            ExploreModuleCard(
                                title: "视频乐园",
                                subtitle: "海量英语动画、科学百科，随时播放",
                                icon: "play.tv.fill",
                                colors: (AppTheme.accentPurple, AppTheme.accentPink),
                                isPlaceholder: false
                            )
                        }
                        .buttonStyle(ExploreBounceButtonStyle())

                        NavigationLink(destination: TutuHomeView()) {
                            ExploreModuleCard(
                                title: "学习资料",
                                subtitle: "课程笔记、单元练习，全科覆盖",
                                icon: "books.vertical.fill",
                                colors: (AppTheme.accentMint, AppTheme.accentSage),
                                isPlaceholder: false
                            )
                        }
                        .buttonStyle(ExploreBounceButtonStyle())

                        ExploreModuleCard(
                            title: "奇妙科学",
                            subtitle: "即将开放...",
                            icon: "flask.fill",
                            colors: (Color.orange, AppTheme.accentYellow),
                            isPlaceholder: true
                        )
                        
                        ExploreModuleCard(
                            title: "上下五千年",
                            subtitle: "即将开放...",
                            icon: "scroll.fill",
                            colors: (AppTheme.accentTerracotta, AppTheme.accentYellow),
                            isPlaceholder: true
                        )
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
        }
    }
}

private struct ExploreModuleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: (Color, Color)
    let isPlaceholder: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.25))
                            .frame(width: 44, height: 44)
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    }
                    
                    Text(title)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                Text(subtitle)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(4)
            }
            Spacer()
            if !isPlaceholder {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [colors.0, colors.1], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: colors.0.opacity(0.35), radius: 12, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.4), lineWidth: 2)
        )
        .opacity(isPlaceholder ? 0.7 : 1.0)
    }
}

private struct ExploreBounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ExploreView()
}
