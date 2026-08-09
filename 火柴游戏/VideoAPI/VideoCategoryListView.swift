import SwiftUI

struct VideoCategoryListView: View {
    @StateObject private var api = VideoAPIService.shared
    @State private var categories: [VideoCategory] = []
    @State private var isLoading = false
    @State private var showTokenInput = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            // 蓝天草地背景（书野营地竹青风）
            LinearGradient(
                colors: [
                    Color(red: 190/255, green: 227/255, blue: 245/255),
                    Color(red: 220/255, green: 242/255, blue: 220/255),
                    Color(red: 207/255, green: 235/255, blue: 196/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            gardenSun
            gardenCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            gardenCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text("视频乐园")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

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
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
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
            VStack(spacing: 14) {
                headerBanner

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(categories) { cat in
                        let index = categories.firstIndex(where: { $0.id == cat.id }) ?? 0
                        NavigationLink(destination: VideoSeriesListView(category: cat)) {
                            CategoryCard(
                                category: cat,
                                style: CategoryCardStyle.forIndex(index)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)

                Text("已展示全部频道 ✓")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
                    .padding(.top, 6)
            }
            .padding(.bottom, 30)
        }
    }

    private var headerBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 227/255, green: 242/255, blue: 234/255),
                            Color(red: 189/255, green: 232/255, blue: 211/255)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("🎬")
                    .font(.system(size: 24))
                    .modifier(Bob(delay: 0.3))
            }
            .frame(width: 52, height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.4), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("视频乐园")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Text("共 \(categories.count) 个频道，海量视频等你探索")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.12), radius: 8, y: 4)
        )
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }

    // MARK: - 背景装饰（太阳/云）

    private var gardenSun: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breathe = 1 + 0.03 * sin(t * 1.2)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 214/255, blue: 110/255).opacity(0.4),
                            Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.14),
                            .clear
                        ], center: .center, startRadius: 10, endRadius: 50)
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(breathe)
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 246/255, blue: 205/255),
                            Color(red: 255/255, green: 214/255, blue: 100/255),
                            Color(red: 247/255, green: 188/255, blue: 55/255)
                        ], center: .init(x: 0.38, y: 0.3), startRadius: 2, endRadius: 18)
                    )
                    .frame(width: 32, height: 32)
                    .scaleEffect(breathe)
                    .shadow(color: Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.8), radius: 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.trailing, 20)
            .padding(.top, 30)
        }
        .allowsHitTesting(false)
    }

    private func gardenCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate + delay
            let drift = 14 * sin(t * 0.42)
            let bob = 3 * sin(t * 0.85 + 1.2)
            ZStack {
                ZStack {
                    Capsule().fill(Color.white.opacity(0.95)).frame(width: 42, height: 15).offset(y: 4)
                    Circle().fill(Color.white.opacity(0.95)).frame(width: 25, height: 25).offset(x: -9, y: -6)
                    Circle().fill(Color.white.opacity(0.9)).frame(width: 21, height: 21).offset(x: 7, y: -4)
                    Circle().fill(Color.white.opacity(0.9)).frame(width: 15, height: 15).offset(x: 0, y: -10)
                }
                .frame(width: 52, height: 30)
                .scaleEffect(scale)
                .offset(x: drift, y: bob)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, 390 * x - 10)
            .padding(.top, 390 * y)
        }
        .allowsHitTesting(false)
    }

    private struct Bob: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(y: CGFloat(sin(t * 2.2) * 4.0))
            }
        }
    }

    // MARK: - 状态页

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(Color(red: 76/255, green: 175/255, blue: 125/255))
            Text("正在加载频道...")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(Color(red: 232/255, green: 100/255, blue: 82/255))
            Text("加载失败")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            Text("请检查网络或 Token 是否有效")
                .font(AppTheme.captionMuted())
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            Button {
                Task { await loadCategories() }
            } label: {
                Text("重新加载")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color(red: 76/255, green: 175/255, blue: 125/255))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tokenEmptyView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "key.horizontal.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
            }
            Text("请先设置 Token")
                .font(AppTheme.titleSection())
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            Text("从小程序抓包获取 Authorization\n中的 Token 即可使用")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                .multilineTextAlignment(.center)
            Button {
                showTokenInput = true
            } label: {
                Text("设置 Token")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color(red: 76/255, green: 175/255, blue: 125/255))
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

// MARK: - 分类卡片样式（书野竹青 · 墨韵色板）

struct CategoryCardStyle {
    let gradient: [Color]
    let icon: String

    static let styles: [CategoryCardStyle] = [
        .init(gradient: [Color(red: 126/255, green: 211/255, blue: 160/255), Color(red: 76/255, green: 175/255, blue: 125/255)], icon: "music.note.list"),
        .init(gradient: [Color(red: 232/255, green: 148/255, blue: 100/255), Color(red: 201/255, green: 100/255, blue: 66/255)], icon: "mouth.fill"),
        .init(gradient: [Color(red: 120/255, green: 160/255, blue: 210/255), Color(red: 74/255, green: 111/255, blue: 165/255)], icon: "tv.fill"),
        .init(gradient: [Color(red: 140/255, green: 115/255, blue: 195/255), Color(red: 92/255, green: 75/255, blue: 138/255)], icon: "arrow.up.right.circle.fill"),
        .init(gradient: [Color(red: 232/255, green: 106/255, blue: 158/255), Color(red: 186/255, green: 80/255, blue: 100/255)], icon: "star.fill"),
        .init(gradient: [Color(red: 245/255, green: 214/255, blue: 123/255), Color(red: 212/255, green: 168/255, blue: 75/255)], icon: "flask.fill"),
        .init(gradient: [Color(red: 91/255, green: 168/255, blue: 217/255), Color(red: 59/255, green: 142/255, blue: 165/255)], icon: "hare.fill"),
        .init(gradient: [Color(red: 217/255, green: 164/255, blue: 91/255), Color(red: 176/255, green: 138/255, blue: 62/255)], icon: "crown.fill"),
        .init(gradient: [Color(red: 110/255, green: 140/255, blue: 90/255), Color(red: 74/255, green: 124/255, blue: 89/255)], icon: "book.fill"),
        .init(gradient: [Color(red: 186/255, green: 80/255, blue: 100/255), Color(red: 201/255, green: 100/255, blue: 66/255)], icon: "function"),
        .init(gradient: [Color(red: 80/255, green: 180/255, blue: 160/255), Color(red: 59/255, green: 142/255, blue: 165/255)], icon: "textformat.abc"),
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
                        .foregroundStyle(.white.opacity(0.85))
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
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(red: 61/255, green: 74/255, blue: 54/255).opacity(0.25), lineWidth: 2)
        )
        .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.14), radius: 6, y: 3)
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
