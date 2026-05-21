import SwiftUI

struct VideoCategoryListView: View {
    @StateObject private var api = VideoAPIService.shared
    @State private var categories: [VideoCategory] = []
    @State private var isLoading = false
    @State private var showTokenInput = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        Group {
            if api.token.isEmpty {
                tokenEmptyView
            } else if isLoading {
                loadingView
            } else if categories.isEmpty {
                errorView
            } else {
                categoryContent
            }
        }
        .navigationTitle("视频乐园")
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showTokenInput = true } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showTokenInput) {
            TokenInputView()
        }
        .task {
            if categories.isEmpty && !api.token.isEmpty {
                await loadCategories()
            }
        }
    }

    // MARK: - 分类内容

    private var categoryContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerBanner

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(categories) { cat in
                        let index = categories.firstIndex(where: { $0.id == cat.id }) ?? 0
                        NavigationLink(destination: VideoSeriesListView(category: cat)) {
                            CategoryCard(
                                category: cat,
                                style: CategoryCardStyle.forIndex(index)
                            )
                        }
                        .buttonStyle(CardBounceStyle())
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
            }
            .padding(.bottom, 40)
        }
        .background(AppTheme.background)
    }

    private var headerBanner: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("发现精彩内容")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("共 \(categories.count) 个频道，海量视频等你探索")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accentPurple, AppTheme.accentPink],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    Image(systemName: "play.tv.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 8)
    }

    // MARK: - 状态页

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
            Text("正在加载频道...")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.accentTerracotta)
            Text("加载失败")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text("请检查网络或 Token 是否有效")
                .font(AppTheme.captionMuted())
                .foregroundStyle(AppTheme.textSecondary)
            Button {
                Task { await loadCategories() }
            } label: {
                Text("重新加载")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(AppTheme.accentBlue)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tokenEmptyView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentPurple.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "key.horizontal.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AppTheme.accentPurple)
            }
            Text("请先设置 Token")
                .font(AppTheme.titleSection())
                .foregroundStyle(AppTheme.textPrimary)
            Text("从小程序抓包获取 Authorization\n中的 Token 即可使用")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                showTokenInput = true
            } label: {
                Text("设置 Token")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(AppTheme.accentBlue)
                    .clipShape(Capsule())
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadCategories() async {
        isLoading = true
        categories = await api.fetchCategories()
        isLoading = false
    }
}

// MARK: - 分类卡片样式

struct CategoryCardStyle {
    let gradient: [Color]
    let icon: String

    static let styles: [CategoryCardStyle] = [
        .init(gradient: [Color(hex: "667eea"), Color(hex: "764ba2")], icon: "music.note.list"),
        .init(gradient: [Color(hex: "f093fb"), Color(hex: "f5576c")], icon: "mouth.fill"),
        .init(gradient: [Color(hex: "4facfe"), Color(hex: "00f2fe")], icon: "tv.fill"),
        .init(gradient: [Color(hex: "43e97b"), Color(hex: "38f9d7")], icon: "arrow.up.right.circle.fill"),
        .init(gradient: [Color(hex: "fa709a"), Color(hex: "fee140")], icon: "star.fill"),
        .init(gradient: [Color(hex: "a18cd1"), Color(hex: "fbc2eb")], icon: "flask.fill"),
        .init(gradient: [Color(hex: "fccb90"), Color(hex: "d57eeb")], icon: "hare.fill"),
        .init(gradient: [Color(hex: "e0c3fc"), Color(hex: "8ec5fc")], icon: "crown.fill"),
        .init(gradient: [Color(hex: "f6d365"), Color(hex: "fda085")], icon: "book.fill"),
        .init(gradient: [Color(hex: "89f7fe"), Color(hex: "66a6ff")], icon: "function"),
        .init(gradient: [Color(hex: "fddb92"), Color(hex: "d1fdff")], icon: "textformat.abc"),
    ]

    static func forIndex(_ index: Int) -> CategoryCardStyle {
        styles[index % styles.count]
    }
}

private struct CategoryCard: View {
    let category: VideoCategory
    let style: CategoryCardStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.25))
                    .frame(width: 44, height: 44)
                Image(systemName: style.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 3) {
                Text(category.name)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if category.seriesCount > 0 {
                    Text("\(category.seriesCount) 个系列")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 130)
        .background(
            LinearGradient(
                colors: style.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: style.gradient[0].opacity(0.35), radius: 10, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.3), lineWidth: 1.5)
        )
    }
}

private struct CardBounceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Color hex extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}
