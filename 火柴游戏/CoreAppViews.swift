import SwiftUI

// MARK: - App 主容器

struct MainTabView: View {
    @EnvironmentObject private var progress: AppProgressStore

    var body: some View {
        TabView(selection: $progress.selectedTab) {
            Tab("首页", systemImage: "sun.max.fill", value: 0) {
                HomeView()
            }
            Tab("诗库", systemImage: "book.closed.fill", value: 1) {
                DiscoverView()
            }
            Tab("探索", systemImage: "binoculars.fill", value: 2) {
                ExploreView()
            }
            Tab("益智", systemImage: "gamecontroller.fill", value: 3) {
                PlayView()
            }
            Tab("我的", systemImage: "leaf.fill", value: 4) {
                ProfileView()
            }
        }
        .tint(Color(red: 76/255, green: 175/255, blue: 125/255))
        .onAppear { progress.refreshStreakOnActivity() }
    }
}

// MARK: - 诗库 · 竹青风

struct DiscoverView: View {
    @EnvironmentObject private var progress: AppProgressStore
    @StateObject private var store = ClassicalPoetryStore.shared
    @State private var navPath = NavigationPath()

    private var poems: [Poem] { PoemCatalog.poems() }

    private var hideTabBar: Bool { !navPath.isEmpty }

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                // 蓝天草地背景（固定）
                LinearGradient(
                    colors: [
                        Color(red: 190/255, green: 227/255, blue: 245/255),
                        Color(red: 220/255, green: 242/255, blue: 220/255),
                        Color(red: 207/255, green: 235/255, blue: 196/255)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                // 太阳 + 白云 + 书堆猫头鹰
                fieldSun
                fieldCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
                fieldCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)
                owlBooks

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if !store.isReady {
                            Spacer()
                            ProgressView("正在加载诗词数据...")
                                .controlSize(.large)
                            Spacer()
                        } else {
                            // 顶部 · 书野营地
                            fieldHeader
                                .padding(.top, 10)

                            // 学段路径牌
                            gradePath
                                .padding(.top, 14)

                            // 今日一诗横卡
                            fieldPoemCard
                                .padding(.top, 14)

                            // 诗集书摊
                            fieldSectionTitle(seal: "摊", title: "诗集书摊")
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
                    }
                    .padding(.top, 8)
                }
            }
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

    // MARK: - 书野营地 · 顶部

    private var fieldHeader: some View {
        VStack(spacing: 0) {
            Text("BOOKS IN FIELD")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(5)
                .foregroundStyle(Color(red: 110/255, green: 138/255, blue: 90/255))
            Text("诗库")
                .font(.system(size: 30, weight: .heavy, design: .serif))
                .tracking(3)
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                .padding(.top, 6)
            Text("在草地上，翻开一本诗集")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 122/255, green: 138/255, blue: 110/255))
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
    }

    // 学段路径牌
    private var gradePath: some View {
        HStack(spacing: 10) {
            ForEach(Array(ClassicalPoetryStore.TextbookStage.allCases.enumerated()), id: \.offset) { idx, stage in
                NavigationLink(value: stage) {
                    gradePathCard(stage: stage, delay: Double(idx) * 0.2)
                }
                .buttonStyle(.bouncy)
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    private func gradePathCard(stage: ClassicalPoetryStore.TextbookStage, delay: Double) -> some View {
        VStack(spacing: 4) {
            Text(stage.emoji)
                .font(.system(size: 22))
                .modifier(FieldBob(delay: delay))
            Text(stage.rawValue)
                .font(.system(size: 13, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            Text(stage == .primary ? "小学课文" : stage == .junior ? "初中课文" : "高中课文")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(gradePathBackground(active: stage == .primary))
    }

    private func gradePathBackground(active: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(active ? Color(red: 216/255, green: 240/255, blue: 200/255).opacity(0.95)
                : Color.white.opacity(0.88))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        active ? Color(red: 76/255, green: 175/255, blue: 125/255)
                            : Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35),
                        lineWidth: active ? 2.5 : 2
                    )
            )
            .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 6, y: 3)
    }

    // 分组标题（书摊）
    private func fieldSectionTitle(seal: String, title: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color(red: 76/255, green: 175/255, blue: 125/255))
                .frame(width: 6, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .serif))
                .tracking(2)
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            Spacer()
            Text("\(PoetryLibraryItem.allItems.count) 卷 · 已读 \(progress.openedPoemIds.count)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    // MARK: - 今日一诗（云蓝书本横卡）

    private var fieldPoemCard: some View {
        let poem = poems.isEmpty ? nil : poems[PoemCatalog.dailyPoemIndex(total: poems.count)]
        return Group {
            if let poem {
                NavigationLink(value: poem) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(colors: [
                                        Color(red: 214/255, green: 232/255, blue: 245/255),
                                        Color(red: 168/255, green: 200/255, blue: 232/255)
                                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                            Text("📖")
                                .font(.system(size: 24))
                                .modifier(FieldBob(delay: 0.2))
                        }
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35), lineWidth: 2)
                        )
                        .overlay(alignment: .topTrailing) {
                            Text("🐦")
                                .font(.system(size: 13))
                                .modifier(FieldBob(delay: 0.5))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("今日一诗 · \(poem.title)")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                            Text(poem.author)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                            Text(firstTwoLines(of: poem))
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .foregroundStyle(Color(red: 59/255, green: 142/255, blue: 165/255))
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(red: 160/255, green: 176/255, blue: 152/255))
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2)
                            )
                            .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.12), radius: 8, y: 4)
                    )
                    .padding(.horizontal, AppTheme.paddingScreen)
                }
                .buttonStyle(.bouncy)
            }
        }
    }

    private func firstTwoLines(of poem: Poem) -> String {
        poem.contents.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .prefix(1)
            .joined(separator: "\n")
    }

    // MARK: - 背景装饰（太阳/云/书堆猫头鹰）

    private var fieldSun: some View {
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

    private func fieldCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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

    // 书堆 + 猫头鹰（右上）
    private var owlBooks: some View {
        VStack(spacing: 3) {
            Text("🦉")
                .font(.system(size: 30))
                .modifier(OwlFlap())
            VStack(spacing: 3) {
                Rectangle().fill(Color(red: 232/255, green: 201/255, blue: 160/255)).frame(width: 66, height: 14).cornerRadius(3).rotationEffect(.degrees(-4))
                Rectangle().fill(Color(red: 168/255, green: 200/255, blue: 152/255)).frame(width: 58, height: 12).cornerRadius(3).rotationEffect(.degrees(3))
                Rectangle().fill(Color(red: 184/255, green: 216/255, blue: 240/255)).frame(width: 62, height: 13).cornerRadius(3).rotationEffect(.degrees(-2))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.trailing, 16)
        .padding(.top, 112)
        .allowsHitTesting(false)
        .opacity(0.9)
    }

    private struct OwlFlap: ViewModifier {
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                content
                    .rotationEffect(.degrees(sin(t * 2.6) * 5), anchor: .bottom)
            }
        }
    }

    private struct FieldBob: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(y: CGFloat(sin(t * 2.2) * 4.0))
            }
        }
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

// MARK: - 集子卡片 · 书摊卡（书堆图标 + 标题）

private struct CollectionCardView: View {
    let item: PoetryLibraryItem

    private var poemCount: Int {
        let matched = ClassicalPoetryStore.shared.allCollections.filter { collection in
            item.filePatterns.contains(where: { collection.title.contains($0) })
        }
        return matched.reduce(0) { $0 + $1.poems.count }
    }

    private var tint: Color {
        switch item.id {
        case "tangshi": return Color(red: 255/255, green: 238/255, blue: 216/255)
        case "songci": return Color(red: 227/255, green: 240/255, blue: 248/255)
        case "gushi19", "shijing": return Color(red: 232/255, green: 245/255, blue: 224/255)
        case "huajian", "nantang": return Color(red: 245/255, green: 232/255, blue: 245/255)
        case "wyjueju", "qyjueju", "wylvshi", "qylvshi", "yuefu": return Color(red: 248/255, green: 240/255, blue: 216/255)
        default: return Color(red: 242/255, green: 247/255, blue: 236/255)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // 书堆图标
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint)
                Text(item.emoji)
                    .font(.system(size: 20))
            }
            .frame(width: 44, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .lineLimit(1)
                Text("\(poemCount) 首")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(red: 160/255, green: 176/255, blue: 152/255))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.1), radius: 6, y: 3)
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
            ZStack {
                // 蓝天草地背景（固定）
                LinearGradient(
                    colors: [
                        Color(red: 190/255, green: 227/255, blue: 245/255),
                        Color(red: 220/255, green: 242/255, blue: 220/255),
                        Color(red: 207/255, green: 235/255, blue: 196/255)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                // 白云留在背景层，太阳放进内容坐标，明确位于成长卡 Y 方向上方
                cloudDecor(x: 0.02, y: 0.10, scale: 1.0, delay: 0)
                cloudDecor(x: 0.72, y: 0.16, scale: 0.72, delay: 2.5)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 顶部（与探索营地同风格：kicker + 居中标题 + 副标 + 植物元素）
                        VStack(spacing: 0) {
                            Text("MY GARDEN")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(5)
                                .foregroundStyle(Color(red: 110/255, green: 138/255, blue: 90/255))

                            Text("我的")
                                .font(.system(size: 32, weight: .black, design: .serif))
                                .tracking(5)
                                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                                .padding(.top, 6)

                            Text("每一滴浇水，都在让知识长大")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 122/255, green: 138/255, blue: 110/255))
                                .padding(.top, 6)

                            Text("🪴")
                                .font(.system(size: 32))
                                .modifier(FloatUp(delay: 0))
                                .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                        .padding(.bottom, 2)

                        // 太阳：作为卡片前的独立内容行，不用 ZStack 覆盖关系定位
                        sunDecor
                            .frame(height: 42, alignment: .bottomTrailing)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)

                        growCard
                            .padding(.top, 8)

                        // 花园统计
                        HStack(spacing: 10) {
                            gardenStat(icon: "🧡", value: "\(progress.totalMatchstickSolves)", label: "火柴解对")
                            gardenStat(icon: "📖", value: "\(progress.openedPoemIds.count)", label: "已读诗篇")
                            gardenStat(icon: "🔥", value: "\(progress.streakDays)天", label: "连续打卡")
                        }
                        .padding(.horizontal, AppTheme.paddingScreen)
                        .padding(.top, 14)

                        voiceSettingsLink
                            .padding(.top, 16)

                        achievementsSection
                            .padding(.top, 6)

                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - 成长卡（花盆 + 小树 + 浇水）

    private var growCard: some View {
        HStack(spacing: 16) {
            // 花盆
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 214/255, green: 232/255, blue: 200/255),
                            Color(red: 184/255, green: 216/255, blue: 168/255)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text(treeEmoji)
                    .font(.system(size: 40))
                    .modifier(TreeSway())
            }
            .frame(width: 76, height: 76)
            .overlay(alignment: .bottom) {
                Text("Lv.\(growLevel)")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(Color(red: 110/255, green: 138/255, blue: 62/255), in: Capsule())
                    .offset(y: 6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("学习伙伴")
                    .font(.system(size: 18, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Text(growHint)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                // 成长条（动画增长）
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.15))
                            .frame(height: 10)
                        Capsule()
                            .fill(
                                LinearGradient(colors: [
                                    Color(red: 143/255, green: 206/255, blue: 143/255),
                                    Color(red: 76/255, green: 175/255, blue: 125/255)
                                ], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * growProgress, height: 10)
                    }
                }
                .frame(height: 10)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 浇水
            VStack(spacing: 2) {
                Text("💧")
                    .font(.system(size: 26))
                    .modifier(WaterDropFloat())
                Text("\(progress.streakDays)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                Text("浇水天数")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.12), radius: 10, y: 5)
        )
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    // 等级：按火柴题 + 读诗总数
    private var growLevel: Int {
        let points = progress.totalMatchstickSolves + progress.openedPoemIds.count
        return min(1 + points / 40, 12)
    }

    private var treeEmoji: String {
        switch growLevel {
        case ..<3: return "🌱"
        case ..<6: return "🌿"
        default:   return "🌳"
        }
    }

    private var growHint: String {
        switch treeEmoji {
        case "🌱": return "小苗刚发芽 · 多读诗多解题"
        case "🌿": return "小树正在长高 · 坚持浇水"
        default:   return "小树已经 \(growLevel) 岁啦 · 再浇 3 次水就能结果"
        }
    }

    private var growProgress: Double {
        let points = progress.totalMatchstickSolves + progress.openedPoemIds.count
        return min(Double(points % 40) / 40.0, 1.0)
    }

    // MARK: - 花园统计牌

    private func gardenStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(icon).font(.system(size: 16))
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 6, y: 3)
        )
    }

    // MARK: - 语音设置（园丁工具）

    private var voiceSettingsLink: some View {
        NavigationLink {
            TencentTTSSettingsView()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(colors: [
                                Color(red: 214/255, green: 232/255, blue: 200/255),
                                Color(red: 168/255, green: 200/255, blue: 152/255)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Text("🎙")
                        .font(.system(size: 19))
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 3) {
                    Text("语音设置")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    Text("切换朗读音色、语速与情感参数")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 160/255, green: 176/255, blue: 152/255))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.25), lineWidth: 2)
                    )
                    .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 6, y: 3)
            )
            .padding(.horizontal, AppTheme.paddingScreen)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 成就花园（开花 / 待发芽）

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color(red: 76/255, green: 175/255, blue: 125/255))
                    .frame(width: 6, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                Text("成就花园")
                    .font(.system(size: 18, weight: .heavy, design: .serif))
                    .tracking(2)
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Spacer()
                Text("已开花 \(unlockedCount) / \(Achievement.all.count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 10)
            .padding(.bottom, 4)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Array(Achievement.all.enumerated()), id: \.element.id) { index, a in
                    let unlocked = progress.unlockedAchievementIds.contains(a.id)
                    gardenFlower(index: index, achievement: a, unlocked: unlocked)
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
        }
    }

    private var unlockedCount: Int {
        Achievement.all.filter { progress.unlockedAchievementIds.contains($0.id) }.count
    }

    private let flowerEmojis = ["🌼", "🌺", "🌷", "🌸"]
    private let seedEmojis = ["🌱", "🌿", "🍃", "🪴"]

    private func gardenFlower(index: Int, achievement: Achievement, unlocked: Bool) -> some View {
        VStack(spacing: 6) {
            Text(unlocked ? flowerEmojis[index % flowerEmojis.count] : seedEmojis[index % seedEmojis.count])
                .font(.system(size: 30))
                .modifier(FlowerSway(delay: Double(index) * 0.3, enabled: unlocked))
            Text(achievement.title)
                .font(.system(size: 13, weight: .heavy, design: .serif))
                .foregroundStyle(unlocked ? Color(red: 61/255, green: 74/255, blue: 54/255) : Color(red: 138/255, green: 154/255, blue: 122/255))
            Text(achievement.subtitle + (unlocked ? "" : " · 待发芽"))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(unlocked
                    ? Color(red: 248/255, green: 251/255, blue: 243/255)
                    : Color(red: 244/255, green: 243/255, blue: 237/255))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            unlocked ? Color(red: 110/255, green: 160/255, blue: 90/255).opacity(0.45)
                                : Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.2),
                            lineWidth: unlocked ? 2 : 1.5
                        )
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.1), radius: 6, y: 3)
        )
        .opacity(unlocked ? 1 : 0.75)
    }

    // MARK: - 背景装饰（太阳/白云，与探索营地同款）

    private var sunDecor: some View {
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
            .padding(.trailing, 24)
            .padding(.top, 106)
        }
        .allowsHitTesting(false)
        .zIndex(1)
    }

    private func cloudDecor(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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

    // MARK: - 动效修饰符

    /// 树轻微上下浮动
    private struct TreeSway: ViewModifier {
        @State private var floating = false
        func body(content: Content) -> some View {
            content
                .offset(y: floating ? -4 : 0)
                .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: floating)
                .onAppear { floating = true }
        }
    }

    /// 花朵摇曳（错开 delay）
    private struct FlowerSway: ViewModifier {
        let delay: Double
        let enabled: Bool
        @State private var swaying = false
        func body(content: Content) -> some View {
            content
                .rotationEffect(.degrees(swaying ? 3 : -3), anchor: .bottom)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(delay), value: swaying)
                .onAppear { if enabled { swaying = true } }
        }
    }

    /// 顶部叶片：缓慢、轻微的自然摆动
    private struct LeafSway: ViewModifier {
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                content
                    .rotationEffect(.degrees(sin(t * 1.35) * 2.0), anchor: .bottom)
                    .offset(y: CGFloat(sin(t * 1.35 + 0.8) * 1.2))
            }
        }
    }

    /// 水滴只沿 Y 轴上下浮动，不使用横向位移或旋转
    private struct WaterDropFloat: ViewModifier {
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                content
                    .offset(y: CGFloat(sin(t * 2.2) * 5.0))
            }
        }
    }

    /// 上下浮动（叶子）
    private struct FloatUp: ViewModifier {
        let delay: Double
        @State private var floating = false
        func body(content: Content) -> some View {
            content
                .offset(y: floating ? -6 : 0)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(delay), value: floating)
                .onAppear { floating = true }
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
