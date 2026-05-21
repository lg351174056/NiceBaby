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
        .tint(AppTheme.accentBlue)
        .onAppear { progress.refreshStreakOnActivity() }
    }
}

// MARK: - 首页

struct HomeView: View {
    @EnvironmentObject private var progress: AppProgressStore
    @State private var isGamePresented = false
    @State private var gameInitialIndex: Int?
    @State private var gameIsDaily = false

    private var poems: [Poem] { PoemCatalog.poems() }
    private var dailyPoem: Poem? {
        let list = poems
        guard !list.isEmpty else { return nil }
        let idx = PoemCatalog.dailyPoemIndex(total: list.count)
        return list[idx]
    }

    private var dailyMatchIndex: Int {
        progress.dailyMatchstickProblemIndex(totalProblems: MatchstickProblemSet.count)
    }

    private var matchstickHeroSubtitle: String {
        let n = progress.matchstickBookmarkIndex
        let total = MatchstickProblemSet.count
        if n > 0 {
            return "上次做到第 \(n + 1) 题 · 共 \(total) 题"
        }
        return "共 \(total) 道谜题 · 横屏畅玩"
    }

    private var todayEquation: String {
        let engine = MathEngine()
        let idx = dailyMatchIndex
        return engine.problemBank[idx]
    }

    private var dailyPoemFirstLines: String {
        guard let poem = dailyPoem else { return "" }
        let lines = poem.contents.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return lines.prefix(2).joined(separator: "\n")
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "早上好"
        case 12..<18: return "下午好"
        default: return "晚上好"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    heroHeader
                    bentoGrid
                    statsRow
                }
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background {
                SWAnimatedMeshGradient(
                    paletteA: AppTheme.homeMeshA,
                    paletteB: AppTheme.homeMeshB,
                    duration: 10
                )
                .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $isGamePresented) {
            ZStack {
                Image("bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.38),
                        Color.white.opacity(0.14),
                        Color(red: 0.94, green: 0.95, blue: 0.97).opacity(0.28)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                SWAnimatedMeshGradient(
                    paletteA: MatchstickGameStyle.meshA,
                    paletteB: MatchstickGameStyle.meshB,
                    duration: 14
                )
                .opacity(0.1)
                .ignoresSafeArea()

                LandscapeContainer {
                    MatchstickContentView(
                        onExit: { isGamePresented = false },
                        initialProblemIndex: gameInitialIndex,
                        isDailyChallenge: gameIsDaily
                    )
                }
            }
            .ignoresSafeArea()
            .environmentObject(progress)
            .environmentObject(PoemSpeechService.shared)
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                HStack(spacing: 16) {
                    if progress.streakDays > 0 {
                        Label("\(progress.streakDays)天连续", systemImage: "flame.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                    Label("已做\(progress.matchstickBookmarkIndex)题", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.accentSage)
                }
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    // MARK: - Bento Grid

    private var bentoGrid: some View {
        VStack(spacing: 14) {
            matchstickHeroCard

            HStack(spacing: 14) {
                dailyMatchCard
                dailyPoemCard
            }
            .padding(.horizontal, AppTheme.paddingScreen)
        }
    }

    private var dailyMatchCard: some View {
        let done = progress.isDailyMatchstickCompletedToday()
        return Button {
            gameInitialIndex = dailyMatchIndex
            gameIsDaily = true
            isGamePresented = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "puzzlepiece.extension.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Spacer()
                    if done {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.accentSage)
                    }
                }
                Spacer()
                Text("每日一题")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(done ? "已完成" : "第 \(dailyMatchIndex + 1) 题")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
            .glassCard()
        }
        .buttonStyle(.bouncy)
    }

    private var dailyPoemCard: some View {
        Button {
            progress.selectedTab = 1
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.accentTerracotta)
                    Text("今日一诗")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                if let p = dailyPoem {
                    Text(dailyPoemFirstLines)
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(3)
                        .lineSpacing(4)
                    Text("-- \(p.author)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
            .glassCard()
        }
        .buttonStyle(.bouncy)
    }

    // MARK: - Hero Card (火柴游戏主卡 + 题面预览)

    private var matchstickHeroCard: some View {
        Button {
            gameInitialIndex = nil
            gameIsDaily = false
            isGamePresented = true
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("火柴游戏")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(matchstickHeroSubtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }

                HStack(spacing: 4) {
                    ForEach(Array(todayEquation.enumerated()), id: \.offset) { _, char in
                        Text(String(char))
                            .font(.system(size: 42, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.white)
                            .frame(width: char == "=" ? 36 : 30)
                    }
                }
                .frame(maxWidth: .infinity)

                HStack {
                    Text("移动一根火柴，让等式成立")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Label("开始挑战", systemImage: "play.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.2), in: Capsule())
                }
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [AppTheme.accentBlue, AppTheme.accentIndigo.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))
            .shadow(color: AppTheme.accentBlue.opacity(0.25), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(.bouncy)
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statBadge(icon: "flame.fill", value: "\(progress.streakDays)", label: "连续", color: .orange)
            statBadge(icon: "checkmark.circle.fill", value: "\(progress.matchstickBookmarkIndex)", label: "已做", color: AppTheme.accentSage)
            statBadge(icon: "book.fill", value: "\(poems.count)", label: "诗词", color: AppTheme.accentTerracotta)
        }
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    private func statBadge(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 16, padding: 14)
    }
}

// MARK: - 诗库

/// 诗库首页 —— 展示各诗词集子卡片
struct DiscoverView: View {
    @StateObject private var store = ClassicalPoetryStore.shared
    @State private var navPath = NavigationPath()
    
    private var hideTabBar: Bool { !navPath.isEmpty }
    
    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                // 统一 TopBar（同益智 Tab 风格）
                HStack(alignment: .center) {
                    Text("诗库")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentTerracotta.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.accentTerracotta)
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(AppTheme.background)
                
                if !store.isReady {
                    Spacer()
                    ProgressView("正在加载诗词数据...")
                        .controlSize(.large)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // 教材同步 —— 特殊大卡片
                            textbookCard
                            
                            // 其他集子 —— 双列网格
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                                ForEach(PoetryLibraryItem.allItems) { item in
                                    NavigationLink(value: item) {
                                        CollectionCardView(item: item)
                                    }
                                    .buttonStyle(BounceButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.paddingScreen)
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(
                ZStack {
                    AppTheme.background
                    Image("f")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .opacity(0.35)
                }
                .ignoresSafeArea()
            )
            .toolbar(.hidden, for: .navigationBar)
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
        .animation(.easeInOut(duration: 0.25), value: hideTabBar)
    }
    
    // 教材同步大横卡
    private var textbookCard: some View {
        NavigationLink(value: PoetryLibraryItem.textbookPlaceholder) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("📚")
                            .font(.system(size: 28))
                        Text("教材同步")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
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
                LinearGradient(colors: [AppTheme.accentMint, AppTheme.accentSage], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: AppTheme.accentMint.opacity(0.35), radius: 12, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - 诗词集子数据模型

struct PoetryLibraryItem: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let emoji: String
    let colors: (Color, Color)
    let filePatterns: [String] // 用于从 allCollections 匹配
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PoetryLibraryItem, rhs: PoetryLibraryItem) -> Bool { lhs.id == rhs.id }
    
    /// 教材同步占位（用于 NavigationLink 特殊处理）
    static let textbookPlaceholder = PoetryLibraryItem(
        id: "textbook", title: "教材同步", subtitle: "", emoji: "📚",
        colors: (AppTheme.accentMint, AppTheme.accentSage), filePatterns: []
    )
    
    static let allItems: [PoetryLibraryItem] = [
        PoetryLibraryItem(id: "tangshi", title: "唐诗三百首", subtitle: "唐代经典诗歌精选", emoji: "🏮",
                          colors: (Color(red: 220/255, green: 38/255, blue: 38/255), Color(red: 248/255, green: 113/255, blue: 113/255)),
                          filePatterns: ["唐诗三百首"]),
        PoetryLibraryItem(id: "songci", title: "宋词三百首", subtitle: "宋代婉约豪放词", emoji: "🌙",
                          colors: (Color(red: 124/255, green: 58/255, blue: 237/255), Color(red: 167/255, green: 139/255, blue: 250/255)),
                          filePatterns: ["宋词三百首"]),
        PoetryLibraryItem(id: "gushi19", title: "古诗十九首", subtitle: "汉代五言抒情经典", emoji: "🎋",
                          colors: (Color(red: 13/255, green: 148/255, blue: 136/255), Color(red: 94/255, green: 234/255, blue: 212/255)),
                          filePatterns: ["古诗十九首"]),
        PoetryLibraryItem(id: "huajian", title: "花间集", subtitle: "婉约派的巅峰之作", emoji: "🌸",
                          colors: (Color(red: 236/255, green: 72/255, blue: 153/255), Color(red: 244/255, green: 114/255, blue: 182/255)),
                          filePatterns: ["花间集"]),
        PoetryLibraryItem(id: "shijing", title: "诗经·国风", subtitle: "追溯华夏诗歌源头", emoji: "🍃",
                          colors: (Color(red: 5/255, green: 150/255, blue: 105/255), Color(red: 16/255, green: 185/255, blue: 129/255)),
                          filePatterns: ["国风"]),
        PoetryLibraryItem(id: "wyjueju", title: "五言绝句", subtitle: "字字珠玑二十字", emoji: "✨",
                          colors: (Color(red: 217/255, green: 119/255, blue: 6/255), Color(red: 251/255, green: 191/255, blue: 36/255)),
                          filePatterns: ["五言绝句"]),
        PoetryLibraryItem(id: "qyjueju", title: "七言绝句", subtitle: "四句二十八字的艺术", emoji: "🎭",
                          colors: (Color(red: 180/255, green: 83/255, blue: 9/255), Color(red: 245/255, green: 158/255, blue: 11/255)),
                          filePatterns: ["七言绝句"]),
        PoetryLibraryItem(id: "wylvshi", title: "五言律诗", subtitle: "格律精严意境深", emoji: "🏔️",
                          colors: (Color(red: 15/255, green: 118/255, blue: 110/255), Color(red: 20/255, green: 184/255, blue: 166/255)),
                          filePatterns: ["五言律诗"]),
        PoetryLibraryItem(id: "qylvshi", title: "七言律诗", subtitle: "大气磅礴的格律美", emoji: "🐉",
                          colors: (Color(red: 153/255, green: 27/255, blue: 27/255), Color(red: 220/255, green: 38/255, blue: 38/255)),
                          filePatterns: ["七言律诗"]),
        PoetryLibraryItem(id: "yuefu", title: "乐府", subtitle: "民歌与叙事的传承", emoji: "🎵",
                          colors: (Color(red: 8/255, green: 145/255, blue: 178/255), Color(red: 34/255, green: 211/255, blue: 238/255)),
                          filePatterns: ["乐府"]),
        PoetryLibraryItem(id: "nantang", title: "南唐二主词", subtitle: "李煜李璟词作精选", emoji: "👑",
                          colors: (Color(red: 120/255, green: 53/255, blue: 15/255), Color(red: 180/255, green: 83/255, blue: 9/255)),
                          filePatterns: ["南唐二主词"])
    ]
}

// MARK: - 集子卡片 (双列网格用)

private struct CollectionCardView: View {
    let item: PoetryLibraryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.emoji)
                .font(.system(size: 36))
            
            Spacer(minLength: 4)
            
            Text(item.title)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            
            Text(item.subtitle)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(
            LinearGradient(colors: [item.colors.0, item.colors.1], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: item.colors.0.opacity(0.3), radius: 8, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
        )
    }
}

private struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - 教材同步：学段选择 → 年级/册

struct TextbookStageSelectionView: View {
    var body: some View {
        VStack(spacing: 24) {
            ForEach(ClassicalPoetryStore.TextbookStage.allCases) { stage in
                NavigationLink(value: stage) {
                    HStack(spacing: 16) {
                        Text(stage.emoji)
                            .font(.system(size: 40))
                            .frame(width: 64, height: 64)
                            .background(Color.white.opacity(0.25), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stage.rawValue)
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
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
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: stage.gradientColors.0.opacity(0.3), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(BounceButtonStyle())
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

/// 教材同步二级页 —— 教材同步入口（三个学段）
struct TextbookEntryView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            TextbookStageSelectionView()
                .padding(.bottom, 40)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("教材同步")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
    }
}

/// 教材同步三级页 —— 年级册列表
struct TextbookGradeListView: View {
    let stage: ClassicalPoetryStore.TextbookStage
    @StateObject private var store = ClassicalPoetryStore.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ForEach(store.textbookCollections(for: stage)) { collection in
                    NavigationLink(value: collection) {
                        GradeBookRow(collection: collection, stage: stage)
                    }
                    .buttonStyle(BounceButtonStyle())
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text(stage.rawValue)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
    }
}

private struct GradeBookRow: View {
    let collection: PoetryCollection
    let stage: ClassicalPoetryStore.TextbookStage
    
    // 根据册子名推算年级序号（用于差异化图标和颜色）
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
        (Color(red: 239/255, green: 68/255, blue: 68/255), Color(red: 252/255, green: 165/255, blue: 165/255)),     // 红
        (Color(red: 249/255, green: 115/255, blue: 22/255), Color(red: 253/255, green: 186/255, blue: 116/255)),    // 橙
        (Color(red: 234/255, green: 179/255, blue: 8/255), Color(red: 253/255, green: 224/255, blue: 71/255)),      // 黄
        (Color(red: 34/255, green: 197/255, blue: 94/255), Color(red: 134/255, green: 239/255, blue: 172/255)),     // 绿
        (Color(red: 6/255, green: 182/255, blue: 212/255), Color(red: 103/255, green: 232/255, blue: 249/255)),     // 青
        (Color(red: 59/255, green: 130/255, blue: 246/255), Color(red: 147/255, green: 197/255, blue: 253/255)),    // 蓝
        (Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 165/255, green: 180/255, blue: 252/255)),    // 靛
        (Color(red: 168/255, green: 85/255, blue: 247/255), Color(red: 216/255, green: 180/255, blue: 254/255)),    // 紫
        (Color(red: 236/255, green: 72/255, blue: 153/255), Color(red: 249/255, green: 168/255, blue: 212/255))     // 粉
    ]
    
    private var iconName: String { Self.gradeIcons[gradeIndex % Self.gradeIcons.count] }
    private var colorPair: (Color, Color) { Self.gradeColors[gradeIndex % Self.gradeColors.count] }
    
    var body: some View {
        HStack(spacing: 14) {
            // 左侧差异化图标
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(colors: [colorPair.0.opacity(0.18), colorPair.1.opacity(0.12)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 52, height: 52)
                Image(systemName: iconName)
                    .font(.system(size: 22))
                    .foregroundStyle(colorPair.0)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("共 \(collection.poems.count) 首")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // 上/下册小标签
            Text(isUpper ? "上" : "下")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(colorPair.0)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colorPair.0.opacity(0.1), in: Capsule())
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}

// MARK: - 普通集子二级页 —— 诗词列表（从 allCollections 中查找匹配的 collections）

struct PoetryCollectionListView: View {
    let item: PoetryLibraryItem
    @StateObject private var store = ClassicalPoetryStore.shared
    @Environment(\.dismiss) private var dismiss
    
    private var matchedPoems: [Poem] {
        // 教材同步走特殊路径
        if item.id == "textbook" { return [] }
        
        let matched = store.allCollections.filter { collection in
            item.filePatterns.contains(where: { collection.title.contains($0) })
        }
        return matched.flatMap { $0.poems }
    }
    
    var body: some View {
        Group {
            if item.id == "textbook" {
                // 教材同步 → 学段选择
                ScrollView(showsIndicators: false) {
                    TextbookStageSelectionView()
                        .padding(.bottom, 40)
                }
            } else {
                // 普通集子 → 直接显示诗列表
                poemListContent(poems: matchedPoems)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text(item.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
    }
}

// MARK: - 诗词列表页（教材册子点进来 / 集子合并后的诗词列表）

struct PoetryPoemListView: View {
    let title: String
    let poems: [Poem]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        poemListContent(poems: poems)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text(title)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
    }
}

// MARK: - 通用诗词列表内容（可复用）

@ViewBuilder
private func poemListContent(poems: [Poem]) -> some View {
    if poems.isEmpty {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
            Text("暂无诗词数据")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(poems) { poem in
                    NavigationLink(value: poem) {
                        PoemRow(poem: poem)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
    }
}

private struct PoemRow: View {
    let poem: Poem
    
    var body: some View {
        HStack(spacing: 14) {
            // 左侧小色块装饰
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(
                    LinearGradient(colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
                                   startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 4, height: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(poem.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(poem.author)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }
}

// MARK: - 诗词详情页（三/四级页：护眼阅读体验）

struct PoetryDetailView: View {
    let poem: Poem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechService = PoemSpeechService.shared
    
    // 护眼暖色文字
    private let textDark = Color(red: 58/255, green: 52/255, blue: 42/255)  // 深棕墨
    private let textMid = Color(red: 120/255, green: 108/255, blue: 88/255) // 中棕
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部返回按钮
            HStack {
                Button { dismiss() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                        Text("返回")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(textDark)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.9), in: Capsule())
                    .shadow(color: .black.opacity(0.08), radius: 5, y: 3)
                }
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)

            // 诗词内容
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer(minLength: 84)
                        
                        // 装饰分隔线
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
                        
                        // 诗句
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
                        
                        // 底部装饰
                        HStack(spacing: 8) {
                            Rectangle().fill(textMid.opacity(0.15)).frame(width: 40, height: 1)
                            Circle().fill(textMid.opacity(0.2)).frame(width: 5, height: 5)
                            Rectangle().fill(textMid.opacity(0.15)).frame(width: 40, height: 1)
                        }
                        .padding(.top, 30)
                        
                        Spacer(minLength: 20)
                        
                        // 播放按钮（在 ScrollView 内部，永远可见）
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
                                        LinearGradient(colors: [Color(red: 76/255, green: 140/255, blue: 100/255),
                                                               Color(red: 52/255, green: 120/255, blue: 80/255)],
                                                      startPoint: .leading, endPoint: .trailing)
                                    )
                            )
                            .shadow(color: Color(red: 52/255, green: 120/255, blue: 80/255).opacity(0.4), radius: 10, y: 5)
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
        .onDisappear {
            if speechService.activePoemId == poem.id {
                speechService.stop()
            }
        }
    }
}

// MARK: - 我的

struct ProfileView: View {
    @EnvironmentObject private var progress: AppProgressStore

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    HStack(alignment: .center) {
                        Text("我的")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentBlue.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.accentBlue)
                        }
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)

                    avatarBlock

                    HStack(spacing: 12) {
                        StatCard(
                            title: "火柴游戏 解对",
                            value: "\(progress.totalMatchstickSolves)",
                            tint: AppTheme.accentBlue
                        )
                        StatCard(
                            title: "已读诗篇",
                            value: "\(progress.openedPoemIds.count)",
                            tint: AppTheme.accentTerracotta
                        )
                        StatCard(
                            title: "连续打卡",
                            value: "\(progress.streakDays) 天",
                            tint: AppTheme.accentSage
                        )
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)

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
                    LinearGradient(colors: [AppTheme.accentBlue, AppTheme.accentIndigo], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Circle()
                )
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 4)
                )
                .overlay(
                    Circle().strokeBorder(Color.black.opacity(0.15), lineWidth: 4).offset(y: 4).clipShape(Circle())
                )
                .shadow(color: AppTheme.accentBlue.opacity(0.3), radius: 10, y: 6)
                .scaleEffect(isBreathing ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isBreathing)
                .onAppear {
                    isBreathing = true
                }
            
            Text("学习伙伴")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text("成就与打卡仅保存在本机")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.top, 16)
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就")
                .font(.title2.weight(.bold))
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
                .foregroundStyle(unlocked ? AppTheme.accentBlue : AppTheme.textSecondary.opacity(0.35))
            Text(achievement.title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
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
                .strokeBorder(unlocked ? AppTheme.accentBlue.opacity(0.3) : AppTheme.separator.opacity(0.5), lineWidth: unlocked ? 2 : 1)
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
        .background(tint.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                .strokeBorder(tint.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - 火柴全屏横屏画布（竖握手机时旋转内容，棋盘更宽、火柴更大）

struct LandscapeContainer<Content: View>: View {
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let screenBounds = windowScene?.screen.bounds ?? UIScreen.main.bounds
        
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
