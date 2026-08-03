import SwiftUI

// MARK: - App 主容器

struct MainTabView: View {
    @EnvironmentObject private var progress: AppProgressStore

    var body: some View {
        TabView(selection: $progress.selectedTab) {
            Tab("首页", systemImage: "house.fill", value: 0) {
                HomeView()
            }
            Tab("诗库", systemImage: "book.closed.fill", value: 1) {
                DiscoverView()
            }
            Tab("探索", systemImage: "sparkle.magnifyingglass", value: 2) {
                ExploreView()
            }
            Tab("益智", systemImage: "gamecontroller.fill", value: 3) {
                PlayView()
            }
            Tab("我的", systemImage: "person.crop.circle.fill", value: 4) {
                ProfileView()
            }
        }
        .tint(AppTheme.accentCinnabar)
        .onAppear { progress.refreshStreakOnActivity() }
    }
}

// MARK: - 诗库 · 竹青风

struct DiscoverView: View {
    @StateObject private var store = ClassicalPoetryStore.shared
    @State private var navPath = NavigationPath()

    private var hideTabBar: Bool { !navPath.isEmpty }

    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                if !store.isReady {
                    Spacer()
                    ProgressView("正在加载诗词数据...")
                        .controlSize(.large)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            // 匾额
                            libraryPlaque

                            // 今日一诗 · 案上摊开的书
                            todayPoemScroll
                                .padding(.top, 16)

                            // 学段书架
                            shelfHeader
                            gradeShelf
                                .padding(.horizontal, AppTheme.paddingScreen)

                            // 诗集藏卷
                            scrollsHeader
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                ForEach(PoetryLibraryItem.allItems) { item in
                                    NavigationLink(value: item) {
                                        CollectionCardView(item: item)
                                    }
                                    .buttonStyle(.bouncy)
                                }
                            }
                            .padding(.horizontal, AppTheme.paddingScreen)
                            .padding(.bottom, 40)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 246/255, green: 241/255, blue: 231/255),
                        Color(red: 242/255, green: 236/255, blue: 222/255)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: PMNavigationTarget.self) { _ in
                PMMainView()
            }
            .navigationDestination(for: PoetryLibraryItem.self) { item in
                PoetryCollectionListView(item: item)
            }
            .navigationDestination(for: ClassicalPoetryStore.TextbookStage.self) { stage in
                TextbookGradeListView(stage: stage)
            }
            .navigationDestination(for: PoetryCollection.self) { collection in
                PoetryPoemListView(title: collection.title, poems: collection.poems)
            }
            .navigationDestination(for: Poem.self) { poem in
                PoetryDetailView(poem: poem)
            }
        }
        .toolbar(hideTabBar ? .hidden : .visible, for: .tabBar)
    }

    // MARK: - 匾额

    private var libraryPlaque: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(red: 59/255, green: 50/255, blue: 38/255))
                    .shadow(color: Color(red: 60/255, green: 45/255, blue: 25/255).opacity(0.35), radius: 10, y: 5)
                    .frame(height: 86)
                // 两侧金色圆环挂饰
                HStack {
                    ZStack {
                        Circle().strokeBorder(Color(red: 217/255, green: 164/255, blue: 91/255), lineWidth: 2.5)
                            .frame(width: 34, height: 34)
                        Circle().strokeBorder(Color(red: 217/255, green: 164/255, blue: 91/255).opacity(0.4), lineWidth: 1)
                            .frame(width: 46, height: 46)
                    }
                    .offset(x: -14)
                    Spacer()
                    ZStack {
                        Circle().strokeBorder(Color(red: 217/255, green: 164/255, blue: 91/255), lineWidth: 2.5)
                            .frame(width: 34, height: 34)
                        Circle().strokeBorder(Color(red: 217/255, green: 164/255, blue: 91/255).opacity(0.4), lineWidth: 1)
                            .frame(width: 46, height: 46)
                    }
                    .offset(x: 14)
                }
                VStack(spacing: 4) {
                    Text("诗 库")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .tracking(10)
                        .foregroundStyle(Color(red: 240/255, green: 228/255, blue: 200/255))
                    Text("藏 书 阁 · SHI KU")
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(Color(red: 201/255, green: 184/255, blue: 138/255))
                }
            }
            .frame(maxWidth: .infinity)

            Text("阁中藏书三千卷，案头常开一卷诗")
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundStyle(Color(red: 110/255, green: 98/255, blue: 80/255))
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 8)
    }

    // MARK: - 今日一诗 · 案上摊开的书

    private var todayPoemScroll: some View {
        let poems = PoemCatalog.poems()
        let poem = poems.isEmpty ? nil : poems[PoemCatalog.dailyPoemIndex(total: poems.count)]

        return Group {
            if let poem {
                NavigationLink(value: poem) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("今日一诗")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(Color(red: 246/255, green: 241/255, blue: 231/255))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(red: 176/255, green: 58/255, blue: 46/255), in: RoundedRectangle(cornerRadius: 4, style: .continuous))

                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(poem.title)
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundStyle(Color(red: 59/255, green: 50/255, blue: 38/255))
                            Text(poem.author)
                                .font(.system(size: 11, weight: .medium, design: .serif))
                                .foregroundStyle(Color(red: 138/255, green: 122/255, blue: 96/255))
                        }
                        .padding(.top, 12)

                        Text(firstLines(of: poem))
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .foregroundStyle(Color(red: 92/255, green: 81/255, blue: 64/255))
                            .lineSpacing(8)
                            .lineLimit(2)
                            .padding(.top, 8)

                        HStack {
                            // 朱砂印章「夜」
                            Text("夜")
                                .font(.system(size: 12, weight: .bold, design: .serif))
                                .foregroundStyle(Color(red: 246/255, green: 241/255, blue: 231/255))
                                .frame(width: 26, height: 26)
                                .background(Color(red: 176/255, green: 58/255, blue: 46/255), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                                .rotationEffect(.degrees(-5))
                                .shadow(color: Color(red: 120/255, green: 40/255, blue: 30/255).opacity(0.3), radius: 3, y: 2)
                            Spacer()
                            Text("展开此卷 →")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 176/255, green: 58/255, blue: 46/255))
                        }
                        .padding(.top, 12)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                LinearGradient(colors: [
                                    Color(red: 251/255, green: 246/255, blue: 234/255),
                                    Color(red: 239/255, green: 228/255, blue: 204/255)
                                ], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .shadow(color: Color(red: 60/255, green: 45/255, blue: 25/255).opacity(0.2), radius: 12, y: 6)
                    )
                    .overlay(alignment: .leading) {
                        // 朱砂竖排线
                        Rectangle()
                            .fill(Color(red: 176/255, green: 58/255, blue: 46/255).opacity(0.35))
                            .frame(width: 2)
                            .padding(.vertical, 6)
                            .padding(.leading, 8)
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)
                }
                .buttonStyle(.bouncy)
            }
        }
    }

    private func firstLines(of poem: Poem) -> String {
        poem.contents.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .prefix(2)
            .joined(separator: "\n")
    }

    // MARK: - 学段书架

    private var shelfHeader: some View {
        HStack(spacing: 10) {
            Text("学")
                .font(.system(size: 11, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 240/255, green: 228/255, blue: 200/255))
                .frame(width: 22, height: 22)
                .background(Color(red: 59/255, green: 50/255, blue: 38/255), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .rotationEffect(.degrees(-4))
            Text("学 段 书 架")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .tracking(3)
                .foregroundStyle(Color(red: 59/255, green: 50/255, blue: 38/255))
            Rectangle()
                .fill(
                    LinearGradient(colors: [Color(red: 120/255, green: 100/255, blue: 70/255).opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing)
                )
                .frame(height: 1)
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 22)
        .padding(.bottom, 10)
    }

    private var gradeShelf: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ForEach(ClassicalPoetryStore.TextbookStage.allCases) { stage in
                    NavigationLink(value: stage) {
                        VStack(spacing: 5) {
                            Text(stage.emoji)
                                .font(.system(size: 19))
                            Text(stage.rawValue)
                                .font(.system(size: 12, weight: .bold, design: .serif))
                                .foregroundStyle(Color(red: 92/255, green: 69/255, blue: 48/255))
                            Text(stage == .primary ? "小学课文" : stage == .junior ? "初中课文" : "高中课文")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(red: 138/255, green: 106/255, blue: 58/255))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(
                                    LinearGradient(colors: [
                                        Color(red: 232/255, green: 212/255, blue: 168/255),
                                        Color(red: 212/255, green: 184/255, blue: 126/255)
                                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .shadow(color: Color(red: 40/255, green: 25/255, blue: 5/255).opacity(0.3), radius: 3, y: 3)
                        )
                        .overlay(alignment: .topTrailing) {
                            if stage == .primary {
                                Rectangle()
                                    .fill(Color(red: 176/255, green: 58/255, blue: 46/255))
                                    .frame(width: 8, height: 16)
                                    .offset(x: -5, y: -4)
                            }
                        }
                    }
                    .buttonStyle(.bouncy)
                }
            }
            .padding(10)

            Text("— 拾级而上 · 朗朗书声 —")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .tracking(4)
                .foregroundStyle(Color(red: 232/255, green: 212/255, blue: 168/255))
                .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        Color(red: 138/255, green: 106/255, blue: 62/255),
                        Color(red: 110/255, green: 82/255, blue: 48/255)
                    ], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: Color(red: 60/255, green: 45/255, blue: 25/255).opacity(0.3), radius: 10, y: 5)
        )
        .overlay(alignment: .bottom) {
            // 书架底部木框
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        Color(red: 154/255, green: 122/255, blue: 74/255),
                        Color(red: 122/255, green: 94/255, blue: 56/255)
                    ], startPoint: .top, endPoint: .bottom)
                )
                .frame(height: 8)
                .padding(.horizontal, 0)
                .offset(y: 0)
        }
        .padding(.bottom, 6)
    }

    // MARK: - 诗集藏卷

    private var scrollsHeader: some View {
        HStack(spacing: 10) {
            Text("卷")
                .font(.system(size: 11, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 240/255, green: 228/255, blue: 200/255))
                .frame(width: 22, height: 22)
                .background(Color(red: 59/255, green: 50/255, blue: 38/255), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .rotationEffect(.degrees(-4))
            Text("诗 集 藏 卷")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .tracking(3)
                .foregroundStyle(Color(red: 59/255, green: 50/255, blue: 38/255))
            Rectangle()
                .fill(
                    LinearGradient(colors: [Color(red: 120/255, green: 100/255, blue: 70/255).opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing)
                )
                .frame(height: 1)
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    // 诗词古文大全入口卡 · 竹青强调
    private var poetryEncyclopediaCard: some View {
        NavigationLink(value: PMNavigationTarget.home) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("📜")
                            .font(.system(size: 28))
                        Text("诗词古文大全")
                            .font(.system(size: 22, weight: .heavy, design: .serif))
                            .foregroundStyle(.white)
                    }
                    Text("唐诗宋词 · 古籍经典 · 名家赏析\n海量诗文，随查随读")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(4)
                }
                Spacer()
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [AppTheme.accentBamboo, Color(red: 54/255, green: 100/255, blue: 70/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.bouncy)
    }

    // 教材同步横卡 · 竹青浅底
    private var textbookCard: some View {
        NavigationLink(value: PoetryLibraryItem.textbookPlaceholder) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("📚")
                            .font(.system(size: 28))
                        Text("教材同步")
                            .font(.system(size: 22, weight: .heavy, design: .serif))
                            .foregroundStyle(.white)
                    }
                    Text("小学 · 初中 · 高中\n跟着课本学古诗")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(4)
                }
                Spacer()
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [AppTheme.accentSage, AppTheme.accentBamboo], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.bouncy)
    }
}

// MARK: - 诗词集子数据模型

struct PoetryLibraryItem: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let emoji: String
    let colors: (Color, Color)
    let filePatterns: [String]

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PoetryLibraryItem, rhs: PoetryLibraryItem) -> Bool { lhs.id == rhs.id }

    static let textbookPlaceholder = PoetryLibraryItem(
        id: "textbook", title: "教材同步", subtitle: "", emoji: "📚",
        colors: (AppTheme.accentSage, AppTheme.accentBamboo), filePatterns: []
    )

    static let allItems: [PoetryLibraryItem] = [
        PoetryLibraryItem(id: "tangshi", title: "唐诗三百首", subtitle: "唐代经典诗歌精选", emoji: "🏮",
                          colors: (AppTheme.accentCinnabar, Color(red: 168/255, green: 72/255, blue: 50/255)),
                          filePatterns: ["唐诗三百首"]),
        PoetryLibraryItem(id: "songci", title: "宋词三百首", subtitle: "宋代婉约豪放词", emoji: "🌙",
                          colors: (AppTheme.accentInkPurple, Color(red: 70/255, green: 55/255, blue: 110/255)),
                          filePatterns: ["宋词三百首"]),
        PoetryLibraryItem(id: "gushi19", title: "古诗十九首", subtitle: "汉代五言抒情经典", emoji: "🎋",
                          colors: (AppTheme.accentBamboo, AppTheme.accentSage),
                          filePatterns: ["古诗十九首"]),
        PoetryLibraryItem(id: "huajian", title: "花间集", subtitle: "婉约派的巅峰之作", emoji: "🌸",
                          colors: (AppTheme.accentPink, Color(red: 160/255, green: 60/255, blue: 80/255)),
                          filePatterns: ["花间集"]),
        PoetryLibraryItem(id: "shijing", title: "诗经·国风", subtitle: "追溯华夏诗歌源头", emoji: "🍃",
                          colors: (AppTheme.accentSage, AppTheme.accentBamboo),
                          filePatterns: ["国风"]),
        PoetryLibraryItem(id: "wyjueju", title: "五言绝句", subtitle: "字字珠玑二十字", emoji: "✨",
                          colors: (AppTheme.accentYellow, Color(red: 160/255, green: 130/255, blue: 50/255)),
                          filePatterns: ["五言绝句"]),
        PoetryLibraryItem(id: "qyjueju", title: "七言绝句", subtitle: "四句二十八字的艺术", emoji: "🎭",
                          colors: (AppTheme.accentCinnabar, AppTheme.accentYellow),
                          filePatterns: ["七言绝句"]),
        PoetryLibraryItem(id: "wylvshi", title: "五言律诗", subtitle: "格律精严意境深", emoji: "🏔️",
                          colors: (AppTheme.accentJade, AppTheme.accentBamboo),
                          filePatterns: ["五言律诗"]),
        PoetryLibraryItem(id: "qylvshi", title: "七言律诗", subtitle: "大气磅礴的格律美", emoji: "🐉",
                          colors: (AppTheme.accentCinnabar, Color(red: 128/255, green: 30/255, blue: 30/255)),
                          filePatterns: ["七言律诗"]),
        PoetryLibraryItem(id: "yuefu", title: "乐府", subtitle: "民歌与叙事的传承", emoji: "🎵",
                          colors: (AppTheme.accentJade, AppTheme.accentIndigo),
                          filePatterns: ["乐府"]),
        PoetryLibraryItem(id: "nantang", title: "南唐二主词", subtitle: "李煜李璟词作精选", emoji: "👑",
                          colors: (AppTheme.accentYellow, AppTheme.accentCinnabar),
                          filePatterns: ["南唐二主词"])
    ]
}

// MARK: - 集子卡片 · 书卷风（竖放卷轴 · 左右木轴 · 米黄底）

private struct CollectionCardView: View {
    let item: PoetryLibraryItem

    private var poemCount: Int {
        let matched = ClassicalPoetryStore.shared.allCollections.filter { collection in
            item.filePatterns.contains(where: { collection.title.contains($0) })
        }
        return matched.reduce(0) { $0 + $1.poems.count }
    }

    var body: some View {
        HStack(spacing: 10) {
            // 竖放书卷：左轴 + 卷身 + 右轴
            HStack(spacing: 0) {
                // 左木轴
                Rectangle()
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 110/255, green: 82/255, blue: 48/255),
                            Color(red: 154/255, green: 122/255, blue: 74/255)
                        ], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 5)
                // 卷身
                Rectangle()
                    .fill(
                        LinearGradient(colors: [item.colors.0, item.colors.1], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 26, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )
                // 右木轴
                Rectangle()
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 110/255, green: 82/255, blue: 48/255),
                            Color(red: 154/255, green: 122/255, blue: 74/255)
                        ], startPoint: .bottom, endPoint: .top)
                    )
                    .frame(width: 5)
            }
            .frame(height: 44)

            // 信息
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .tracking(1)
                    .foregroundStyle(Color(red: 59/255, green: 50/255, blue: 38/255))
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 122/255, blue: 96/255))
                    .lineLimit(1)

                Text("\(poemCount) 首")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 176/255, green: 58/255, blue: 46/255))
                    .padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        Color(red: 251/255, green: 246/255, blue: 234/255),
                        Color(red: 240/255, green: 228/255, blue: 204/255)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(Color(red: 120/255, green: 100/255, blue: 70/255).opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color(red: 60/255, green: 45/255, blue: 25/255).opacity(0.12), radius: 4, y: 2)
        )
    }
}

// MARK: - 教材同步：学段选择

struct TextbookStageSelectionView: View {
    var body: some View {
        VStack(spacing: 24) {
            ForEach(ClassicalPoetryStore.TextbookStage.allCases) { stage in
                NavigationLink(value: stage) {
                    HStack(spacing: 16) {
                        Text(stage.emoji)
                            .font(.system(size: 40))
                            .frame(width: 64, height: 64)
                            .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(stage.rawValue)
                                .font(.system(size: 22, weight: .heavy, design: .serif))
                                .foregroundStyle(.white)
                            Text(stageDesc(stage))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(20)
                    .background(
                        LinearGradient(colors: [stage.gradientColors.0, stage.gradientColors.1], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.bouncy)
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 20)
    }

    private func stageDesc(_ stage: ClassicalPoetryStore.TextbookStage) -> String {
        switch stage {
        case .primary: return "一年级 ~ 六年级"
        case .junior: return "七年级 ~ 九年级"
        case .senior: return "高一 ~ 高二"
        }
    }
}

struct TextbookEntryView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            TextbookStageSelectionView()
                .padding(.bottom, 40)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .unifiedBackButton(title: "教材同步")
    }
}

struct TextbookGradeListView: View {
    let stage: ClassicalPoetryStore.TextbookStage
    @StateObject private var store = ClassicalPoetryStore.shared
    @State private var collections: [PoetryCollection] = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                ForEach(collections) { collection in
                    NavigationLink(value: collection) {
                        GradeBookRow(collection: collection, stage: stage)
                    }
                    .buttonStyle(.bouncy)
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .unifiedBackButton(title: stage.rawValue)
        .onAppear {
            collections = store.textbookCollections(for: stage)
        }
    }
}

private struct GradeBookRow: View {
    let collection: PoetryCollection
    let stage: ClassicalPoetryStore.TextbookStage

    private var gradeIndex: Int {
        let title = collection.title
        if title.contains("一年级") || title.contains("高一") { return 0 }
        if title.contains("二年级") || title.contains("高二") { return 1 }
        if title.contains("三年级") { return 2 }
        if title.contains("四年级") { return 3 }
        if title.contains("五年级") { return 4 }
        if title.contains("六年级") { return 5 }
        if title.contains("七年级") { return 6 }
        if title.contains("八年级") { return 7 }
        if title.contains("九年级") { return 8 }
        return 0
    }

    private var isUpper: Bool { collection.title.contains("上册") }

    private static let gradeIcons = ["book.fill", "text.book.closed.fill", "books.vertical.fill", "bookmark.fill", "doc.text.fill", "scroll.fill", "book.pages.fill", "magazine.fill", "graduationcap.fill"]

    private static let gradeColors: [(Color, Color)] = [
        (AppTheme.accentCinnabar, Color(red: 168/255, green: 72/255, blue: 50/255)),
        (AppTheme.accentYellow, Color(red: 160/255, green: 130/255, blue: 50/255)),
        (AppTheme.accentSage, AppTheme.accentBamboo),
        (AppTheme.accentJade, AppTheme.accentBamboo),
        (AppTheme.accentIndigo, AppTheme.accentInkPurple),
        (AppTheme.accentInkPurple, Color(red: 70/255, green: 55/255, blue: 110/255)),
        (AppTheme.accentPink, AppTheme.accentCinnabar),
        (AppTheme.accentBamboo, AppTheme.accentSage),
        (Color.orange, AppTheme.accentYellow)
    ]

    private var iconName: String { Self.gradeIcons[gradeIndex % Self.gradeIcons.count] }
    private var colorPair: (Color, Color) { Self.gradeColors[gradeIndex % Self.gradeColors.count] }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(colorPair.0.opacity(0.1))
                    .frame(width: 52, height: 52)
                Image(systemName: iconName)
                    .font(.system(size: 22))
                    .foregroundStyle(colorPair.0)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(collection.title)
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("共 \(collection.poems.count) 首")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Text(isUpper ? "上" : "下")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(colorPair.0)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colorPair.0.opacity(0.08), in: Capsule())

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
        }
        .padding(14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: AppTheme.inkShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - 诗词集子列表页

struct PoetryCollectionListView: View {
    let item: PoetryLibraryItem
    @StateObject private var store = ClassicalPoetryStore.shared
    private let matchedPoems: [Poem]

    init(item: PoetryLibraryItem) {
        self.item = item
        if item.id == "textbook" {
            self.matchedPoems = []
        } else {
            let matched = ClassicalPoetryStore.shared.allCollections.filter { collection in
                item.filePatterns.contains(where: { collection.title.contains($0) })
            }
            self.matchedPoems = matched.flatMap(\.poems)
        }
    }

    var body: some View {
        Group {
            if item.id == "textbook" {
                ScrollView(showsIndicators: false) {
                    TextbookStageSelectionView()
                        .padding(.bottom, 40)
                }
            } else {
                PoemCollectionContent(
                    title: item.title,
                    subtitle: item.subtitle,
                    emoji: item.emoji,
                    colors: item.colors,
                    poems: matchedPoems
                )
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .unifiedBackButton(title: item.title)
    }
}

struct PoetryPoemListView: View {
    let title: String
    let poems: [Poem]

    var body: some View {
        PoemCollectionContent(
            title: title,
            subtitle: "\(poems.count) 首诗词",
            emoji: "📖",
            colors: (AppTheme.accentIndigo, AppTheme.accentInkPurple),
            poems: poems
        )
        .background(AppTheme.background.ignoresSafeArea())
        .unifiedBackButton(title: title)
    }
}

// MARK: - 诗词集内容

private struct PoemCollectionContent: View {
    let title: String
    let subtitle: String
    let emoji: String
    let colors: (Color, Color)
    let poems: [Poem]

    @EnvironmentObject private var progress: AppProgressStore

    private let pageSize = 20
    @State private var displayedCount = 20
    @State private var nextTarget: Poem?
    @State private var randomTarget: Poem?
    @State private var openRandom = false

    private var displayedPoems: [Poem] {
        Array(poems.prefix(displayedCount))
    }

    private var hasMore: Bool {
        displayedCount < poems.count
    }

    private var readCount: Int {
        poems.filter { progress.openedPoemIds.contains($0.id) }.count
    }

    var body: some View {
        if poems.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "tray")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.35))
                Text("暂无诗词数据")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    collectionHero

                    LazyVStack(spacing: 0) {
                        ForEach(Array(displayedPoems.enumerated()), id: \.element.id) { index, poem in
                            NavigationLink(value: poem) {
                                PoemCard(poem: poem, index: index, accentColor: colors.0)
                                    .equatable()
                            }
                            .onAppear {
                                if index == displayedPoems.count - 1, hasMore {
                                    displayedCount += pageSize
                                }
                            }
                        }

                        if hasMore {
                            ProgressView()
                                .padding(.vertical, 16)
                        }
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                    // 底部操作
                    HStack(spacing: 12) {
                        Button {
                            randomTarget = poems.randomElement()
                            openRandom = true
                        } label: {
                            Text("随机翻卷")
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .tracking(2)
                                .foregroundStyle(Color(red: 110/255, green: 98/255, blue: 80/255))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(Color(red: 120/255, green: 100/255, blue: 70/255).opacity(0.4), lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: nextTarget) {
                            HStack(spacing: 6) {
                                Text("继续读诗")
                                    .font(.system(size: 13, weight: .bold, design: .serif))
                                    .tracking(2)
                                Text("▸")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(Color(red: 246/255, green: 241/255, blue: 231/255))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color(red: 59/255, green: 50/255, blue: 38/255))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.bottom, 40)
                    .onAppear {
                        if nextTarget == nil {
                            nextTarget = poems.first(where: { !progress.openedPoemIds.contains($0.id) }) ?? poems.first
                        }
                    }
                    .navigationDestination(isPresented: $openRandom) {
                        if let randomTarget {
                            PoetryDetailView(poem: randomTarget)
                        }
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 246/255, green: 241/255, blue: 231/255),
                        Color(red: 243/255, green: 237/255, blue: 224/255)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }

    private var collectionHero: some View {
        VStack(spacing: 0) {
            // 上轴头
            ScrollAxisBar()

            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(Color(red: 160/255, green: 138/255, blue: 106/255))

                Text(title)
                    .font(.system(size: 30, weight: .heavy, design: .serif))
                    .tracking(4)
                    .foregroundStyle(Color(red: 59/255, green: 50/255, blue: 38/255))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                // 朱砂分隔线
                HStack(spacing: 8) {
                    Rectangle().fill(Color.clear).frame(width: 20, height: 1)
                    Rectangle()
                        .fill(
                            LinearGradient(colors: [.clear, Color(red: 176/255, green: 58/255, blue: 46/255), .clear], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: 46, height: 2)
                    Rectangle().fill(Color.clear).frame(width: 20, height: 1)
                }

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(Color(red: 110/255, green: 98/255, blue: 80/255))
                    .lineLimit(2)

                HStack(spacing: 28) {
                    heroStat(value: "\(poems.count)", label: "收录诗篇")
                    heroStat(value: "\(readCount)", label: "已读")
                    heroStat(value: "\(poems.count - readCount)", label: "待读")
                }
                .padding(.top, 6)

                // 印章
                Text("诗")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(Color(red: 246/255, green: 241/255, blue: 231/255))
                    .frame(width: 34, height: 34)
                    .background(Color(red: 176/255, green: 58/255, blue: 46/255), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .rotationEffect(.degrees(-5))
                    .shadow(color: Color(red: 120/255, green: 40/255, blue: 30/255).opacity(0.3), radius: 4, y: 3)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 24)

            // 下轴头
            ScrollAxisBar()
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        Color(red: 251/255, green: 246/255, blue: 234/255),
                        Color(red: 239/255, green: 228/255, blue: 204/255)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: Color(red: 60/255, green: 45/255, blue: 25/255).opacity(0.22), radius: 14, y: 7)
        )
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 12)
    }

    private func heroStat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 17, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 176/255, green: 58/255, blue: 46/255))
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color(red: 154/255, green: 140/255, blue: 116/255))
        }
    }

    /// 卷轴轴头（金色渐变 + 轴心木珠）· 两端圆角由外层 clipShape 统一裁剪
    private struct ScrollAxisBar: View {
        var body: some View {
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 201/255, green: 168/255, blue: 124/255),
                            Color(red: 169/255, green: 138/255, blue: 94/255)
                        ], startPoint: .top, endPoint: .bottom)
                    )
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 176/255, green: 138/255, blue: 94/255),
                            Color(red: 138/255, green: 106/255, blue: 62/255),
                            Color(red: 176/255, green: 138/255, blue: 94/255)
                        ], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 22, height: 30)
                    .shadow(color: Color(red: 60/255, green: 40/255, blue: 10/255).opacity(0.4), radius: 3, y: 2)
            }
            .frame(height: 16)
        }
    }
}

// MARK: - 诗词卡片 · 卷轴行（序号 + 楷体 + 状态印章）

private struct PoemCard: View, Equatable {
    let poem: Poem
    let index: Int
    let accentColor: Color
    @EnvironmentObject private var progress: AppProgressStore
    private let firstLine: String

    init(poem: Poem, index: Int, accentColor: Color) {
        self.poem = poem
        self.index = index
        self.accentColor = accentColor
        self.firstLine = poem.contents.components(separatedBy: "\n")
            .first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? ""
    }

    static func == (lhs: PoemCard, rhs: PoemCard) -> Bool {
        lhs.poem.id == rhs.poem.id && lhs.index == rhs.index
    }

    private var isRead: Bool {
        progress.openedPoemIds.contains(poem.id)
    }

    private var chineseNum: String {
        let nums = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十",
                    "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十"]
        let i = index
        if i < nums.count { return nums[i] }
        let tens = i / 10, ones = i % 10
        var s = tens > 1 ? "\(nums[tens - 1])十" : "十"
        if ones > 0 { s += nums[ones - 1] }
        return s
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // 中文序号
            Text(chineseNum)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 184/255, green: 168/255, blue: 138/255))
                .frame(width: 24)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(poem.title)
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundStyle(Color(red: 59/255, green: 50/255, blue: 38/255))
                        .lineLimit(1)
                    Spacer()
                    Text(poem.author)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 154/255, green: 140/255, blue: 116/255))
                }

                Text(firstLine)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(Color(red: 110/255, green: 98/255, blue: 80/255))
                    .lineLimit(1)
                    .lineSpacing(2)
            }

            // 状态：已读 ✓ / 印章「读」/ 未读灰字
            Group {
                if isRead {
                    Text("✓")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 124/255, green: 139/255, blue: 111/255))
                } else if index == 2 {
                    Text("读")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .foregroundStyle(Color(red: 246/255, green: 241/255, blue: 231/255))
                        .frame(width: 22, height: 22)
                        .background(Color(red: 176/255, green: 58/255, blue: 46/255), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .rotationEffect(.degrees(-6))
                } else {
                    Text("未读")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Color(red: 192/255, green: 180/255, blue: 154/255))
                }
            }
            .frame(width: 34)
            .padding(.top, 3)
        }
        .padding(.vertical, 15)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(red: 120/255, green: 100/255, blue: 70/255).opacity(0.15))
                .frame(height: 1)
        }
    }
}

// MARK: - 诗词详情页

struct PoetryDetailView: View {
    let poem: Poem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechService = PoemSpeechService.shared

    private let textDark = Color(red: 58/255, green: 52/255, blue: 42/255)
    private let textMid = Color(red: 120/255, green: 108/255, blue: 88/255)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial, in: Circle())
                        Text("返回")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(textDark)
                }
                Spacer()
            }
            .padding(.leading, AppTheme.paddingScreen)
            .padding(.top, 8)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer(minLength: 84)

                    HStack(spacing: 8) {
                        Rectangle().fill(textMid.opacity(0.2)).frame(width: 30, height: 1)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(textMid.opacity(0.4))
                        Rectangle().fill(textMid.opacity(0.2)).frame(width: 30, height: 1)
                    }

                    Text(poem.title)
                        .font(.system(size: 32, weight: .heavy, design: .serif))
                        .foregroundStyle(textDark)
                        .multilineTextAlignment(.center)

                    Text("\(poem.type) · \(poem.author)")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(textMid)

                    VStack(spacing: 16) {
                        ForEach(poem.contents.components(separatedBy: "\n"), id: \.self) { line in
                            if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(line)
                                    .font(.system(size: 22, weight: .medium, design: .serif))
                                    .foregroundStyle(textDark)
                                    .lineSpacing(8)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 8)

                    HStack(spacing: 8) {
                        Rectangle().fill(textMid.opacity(0.15)).frame(width: 40, height: 1)
                        Circle().fill(textMid.opacity(0.2)).frame(width: 5, height: 5)
                        Rectangle().fill(textMid.opacity(0.15)).frame(width: 40, height: 1)
                    }
                    .padding(.top, 30)

                    Spacer(minLength: 20)

                    Button {
                        speechService.toggleSpeak(poem: poem)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: speechService.activePoemId == poem.id ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .black))
                                .foregroundStyle(.white)
                            Text(speechService.activePoemId == poem.id ? "暂停朗读" : "开始朗读")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(colors: [AppTheme.accentBamboo, Color(red: 52/255, green: 100/255, blue: 70/255)],
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                        )
                        .shadow(color: AppTheme.accentBamboo.opacity(0.35), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 28)
            }
        }
        .background(
            Image("bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .overlay(Color.white.opacity(0.65))
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .enableSwipeBack()
        .onDisappear {
            if speechService.activePoemId == poem.id {
                speechService.stop()
            }
        }
    }
}

// MARK: - 我的 · 靛蓝风

struct ProfileView: View {
    @EnvironmentObject private var progress: AppProgressStore

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    HStack(alignment: .center) {
                        Text("我的")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundStyle(AppTheme.gradientProfile)
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentIndigo.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.accentIndigo)
                        }
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)

                    avatarBlock

                    HStack(spacing: 12) {
                        StatCard(
                            title: "火柴游戏 解对",
                            value: "\(progress.totalMatchstickSolves)",
                            tint: AppTheme.accentCinnabar
                        )
                        StatCard(
                            title: "已读诗篇",
                            value: "\(progress.openedPoemIds.count)",
                            tint: AppTheme.accentBamboo
                        )
                        StatCard(
                            title: "连续打卡",
                            value: "\(progress.streakDays) 天",
                            tint: AppTheme.accentSage
                        )
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)

                    voiceSettingsLink

                    achievementsSection

                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @State private var isBreathing = false

    private var avatarBlock: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 96, height: 96)
                .background(
                    LinearGradient(colors: [AppTheme.accentIndigo, AppTheme.accentInkPurple], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Circle()
                )
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 4)
                )
                .shadow(color: AppTheme.accentIndigo.opacity(0.25), radius: 10, y: 6)
                .scaleEffect(isBreathing ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isBreathing)
                .onAppear {
                    isBreathing = true
                }

            Text("学习伙伴")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
            Text("成就与打卡仅保存在本机")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.top, 16)
    }

    private var voiceSettingsLink: some View {
        NavigationLink {
            TencentTTSSettingsView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "waveform")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.accentIndigo, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("语音设置")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("切换朗读音色、语速与情感参数")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
            }
            .padding(14)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
            .padding(.horizontal, AppTheme.paddingScreen)
        }
        .buttonStyle(.plain)
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, AppTheme.paddingScreen)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Achievement.all) { a in
                    let unlocked = progress.unlockedAchievementIds.contains(a.id)
                    AchievementTile(achievement: a, unlocked: unlocked)
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
        }
    }
}

private struct AchievementTile: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: achievement.systemImage)
                .font(.title2)
                .foregroundStyle(unlocked ? AppTheme.accentIndigo : AppTheme.textSecondary.opacity(0.35))
            Text(achievement.title)
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundStyle(unlocked ? AppTheme.textPrimary : AppTheme.textSecondary)
            Text(achievement.subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card.opacity(unlocked ? 1 : 0.65))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                .strokeBorder(unlocked ? AppTheme.accentIndigo.opacity(0.2) : AppTheme.separator, lineWidth: unlocked ? 2 : 1)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(tint.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                .strokeBorder(tint.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - 横屏容器（火柴游戏用）

struct LandscapeContainer<Content: View>: View {
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let screenBounds = windowScene?.screen.bounds ?? CGRect(x: 0, y: 0, width: 390, height: 844)

        let screenW = screenBounds.width
        let screenH = screenBounds.height
        let physicalWidth = max(screenW, screenH)
        let physicalHeight = min(screenW, screenH)

        ZStack {
            MatchstickBackgroundView()
                .frame(width: physicalWidth, height: physicalHeight)
                .rotationEffect(.degrees(screenW < screenH ? 90 : 0))

            content()
                .frame(width: physicalWidth, height: physicalHeight)
                .rotationEffect(.degrees(screenW < screenH ? 90 : 0))
        }
        .frame(width: screenW, height: screenH)
        .ignoresSafeArea()
    }
}
