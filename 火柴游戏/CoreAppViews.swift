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
            return "上次做到第 \(n + 1) 题 · 共 \(total) 题 · 横屏畅玩"
        }
        return "共 \(total) 道谜题 · 横屏畅玩"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.paddingScreen) {
                    HStack(alignment: .center) {
                        Text("Welcome")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        HStack(spacing: 8) {
                            if progress.streakDays > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "flame.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.orange)
                                    Text("\(progress.streakDays)")
                                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                }
                            }
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentBlue.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16))
                                    .foregroundStyle(AppTheme.accentBlue)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)

                    todaySection

                    matchstickHeroCard

                    poemLibraryCard
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(AppTheme.background.ignoresSafeArea())
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

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, AppTheme.paddingScreen)

            HStack(spacing: 12) {
                todayMatchCard
                todayPoemCard
            }
            .padding(.horizontal, AppTheme.paddingScreen)
        }
    }

    private var todayMatchCard: some View {
        let done = progress.isDailyMatchstickCompletedToday()
        return Button {
            gameInitialIndex = dailyMatchIndex
            gameIsDaily = true
            isGamePresented = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "puzzlepiece.extension.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.accentBlue)
                    Spacer()
                    if done {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.accentSage)
                    }
                }
                Text("火柴游戏 · 每日一题")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(done ? "今日已完成" : "第 \(dailyMatchIndex + 1) 题")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.accentBlue.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .swCardStyle(
                strokeColor: AppTheme.accentBlue,
                background: AppTheme.card,
                cornerRadius: AppTheme.cornerLarge,
                padding: 20,
                strokeWidth: 3
            )
        }
        .buttonStyle(.plain)
    }

    private var todayPoemCard: some View {
        Button {
            progress.selectedTab = 1
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.accentTerracotta)
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.accentTerracotta.opacity(0.5))
                }
                Text("唐诗 · 今日一诗")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                if let p = dailyPoem {
                    Text(p.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.accentTerracotta.opacity(0.8))
                        .lineLimit(1)
                } else {
                    Text("加载中…")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .swCardStyle(
                strokeColor: AppTheme.accentTerracotta,
                background: AppTheme.card,
                cornerRadius: AppTheme.cornerLarge,
                padding: 20,
                strokeWidth: 3
            )
        }
        .buttonStyle(.plain)
    }

    private var matchstickHeroCard: some View {
        Button {
            gameInitialIndex = nil
            gameIsDaily = false
            isGamePresented = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("火柴游戏")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("移动一根火柴，让等式成立")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Image(systemName: "function")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(24)

                SWShimmer(duration: 2.4, delay: 1.0) {
                    HStack {
                        Text(matchstickHeroSubtitle)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                        Spacer()
                        Text("开始")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.accentBlue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.white, in: Capsule())
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                }
            }
            .background(
                LinearGradient(
                    colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.15), lineWidth: 4)
                    .offset(y: 4)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))
            )
            .shadow(color: AppTheme.accentBlue.opacity(0.3), radius: 0, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    private var poemLibraryCard: some View {
        Button {
            progress.selectedTab = 1
        } label: {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentTerracotta.opacity(0.85), AppTheme.accentTerracotta],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "text.book.closed.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text("唐诗三百首")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("按篇浏览 · 今日一诗在“诗库”置顶")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
            }
            .swCardStyle(
                strokeColor: AppTheme.accentTerracotta,
                background: AppTheme.card,
                cornerRadius: AppTheme.cornerLarge,
                padding: 20,
                strokeWidth: 3
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppTheme.paddingScreen)
    }
}

// MARK: - 诗库

struct DiscoverView: View {
    @EnvironmentObject private var progress: AppProgressStore
    @State private var poems: [Poem] = []
    @State private var searchText = ""

    private var dailyPoem: Poem? {
        guard !poems.isEmpty else { return nil }
        let idx = PoemCatalog.dailyPoemIndex(total: poems.count)
        return poems[idx]
    }

    private var otherPoems: [Poem] {
        poems.filter { $0.id != dailyPoem?.id }
    }

    private var filteredPoems: [Poem] {
        if searchText.isEmpty { return otherPoems }
        return otherPoems.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 固定 header：不随滚动移动
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        Text("诗库")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentTerracotta.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "text.book.closed.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.accentTerracotta)
                        }
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("搜索标题、作者", text: $searchText)
                            .font(.body)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerMedium))
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(AppTheme.background)

                // 可滚动内容区
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        if poems.isEmpty {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                                    .fill(AppTheme.card)
                                    .frame(height: 190)
                                    .overlay {
                                        SWShimmer(duration: 1.6, delay: 0.2) {
                                            RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                                                .fill(.white.opacity(0.35))
                                                .padding(1)
                                        }
                                    }
                                    .padding(.horizontal, AppTheme.paddingScreen)
                            }
                        } else {
                            if searchText.isEmpty {
                                PoemLibraryHeroCard(totalCount: poems.count, dailyPoem: dailyPoem)
                                    .padding(.horizontal, AppTheme.paddingScreen)

                                if let p = dailyPoem {
                                    PoemOfDayCard(poem: p) {
                                        progress.recordPoemOpened(id: p.id)
                                    }
                                    .padding(.horizontal, AppTheme.paddingScreen)
                                }
                            }

                            HStack(alignment: .firstTextBaseline) {
                                Text(searchText.isEmpty ? "全部篇目" : "搜索结果")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                Text("\(filteredPoems.count) 首")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .padding(.horizontal, AppTheme.paddingScreen)

                            LazyVStack(alignment: .leading, spacing: 14) {
                                ForEach(filteredPoems, id: \.id) { poem in
                                    PoemRow(poem: poem, isRead: progress.openedPoemIds.contains(poem.id)) {
                                        progress.recordPoemOpened(id: poem.id)
                                    }
                                    .padding(.horizontal, AppTheme.paddingScreen)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 28)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .swPageLoading(.discover)
            .task {
                guard poems.isEmpty else { return }
                SWLoadingManager.shared.show(page: .discover, message: "正在载入诗集…", systemImage: "book.closed")
                try? await Task.sleep(for: .milliseconds(100))
                let loaded = PoemCatalog.poems()
                poems = loaded
                SWLoadingManager.shared.hide(page: .discover)
            }
        }
    }
}

private struct PoemLibraryHeroCard: View {
    let totalCount: Int
    let dailyPoem: Poem?

    private let paletteA: [Color] = [
        Color(red: 0.95, green: 0.83, blue: 0.80),
        Color(red: 0.89, green: 0.90, blue: 0.98),
        Color(red: 0.97, green: 0.90, blue: 0.78),
        Color(red: 0.82, green: 0.90, blue: 0.95),
        Color(red: 0.94, green: 0.87, blue: 0.95),
        Color(red: 0.87, green: 0.94, blue: 0.89),
        Color(red: 0.92, green: 0.84, blue: 0.88),
        Color(red: 0.86, green: 0.88, blue: 0.97),
        Color(red: 0.98, green: 0.92, blue: 0.86)
    ]

    private let paletteB: [Color] = [
        Color(red: 0.89, green: 0.86, blue: 0.98),
        Color(red: 0.97, green: 0.88, blue: 0.83),
        Color(red: 0.86, green: 0.92, blue: 0.95),
        Color(red: 0.95, green: 0.91, blue: 0.80),
        Color(red: 0.92, green: 0.86, blue: 0.93),
        Color(red: 0.85, green: 0.92, blue: 0.89),
        Color(red: 0.98, green: 0.90, blue: 0.88),
        Color(red: 0.87, green: 0.89, blue: 0.96),
        Color(red: 0.95, green: 0.93, blue: 0.85)
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.95), Color(red: 0.97, green: 0.96, blue: 0.99)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            SWAnimatedMeshGradient(
                paletteA: paletteA,
                paletteB: paletteB,
                duration: 14
            )
            .opacity(0.3)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                SWShimmer(duration: 2.4, delay: 0.5) {
                    Text("唐诗三百首")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Text("完整展示每首诗的题目、作者与正文，阅读体验更舒展。")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    heroTag(text: "共 \(totalCount) 首", tint: AppTheme.accentTerracotta)
                    if let dailyPoem {
                        heroTag(text: "今日推荐 · \(dailyPoem.title)", tint: AppTheme.accentBlue)
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .swCardStyle(
            strokeColor: AppTheme.accentIndigo.opacity(0.35),
            background: .clear,
            cornerRadius: AppTheme.cornerLarge,
            padding: 0,
            strokeWidth: 0.8
        )
        .shadow(color: AppTheme.accentIndigo.opacity(0.08), radius: 18, x: 0, y: 8)
    }

    private func heroTag(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
            .lineLimit(1)
    }
}

private struct PoemOfDayCard: View {
    let poem: Poem
    var onAppearAction: () -> Void
    @EnvironmentObject private var speech: PoemSpeechService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("今日一诗")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.accentTerracotta.opacity(0.15), in: Capsule())
                        .foregroundStyle(AppTheme.accentTerracotta)

                    Text(poem.title)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Text(poem.author)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(poem.type)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.accentBlue.opacity(0.15), in: Capsule())
                            .foregroundStyle(AppTheme.accentBlue)
                    }
                }

                Spacer(minLength: 8)

                PoemPlayButton(poem: poem, emphasized: true)
            }

            PoemBodyBlock(contents: poem.contents, font: .system(size: 20, weight: .medium, design: .rounded), lineSpacing: 14)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .swCardStyle(
            strokeColor: AppTheme.accentTerracotta,
            background: Color.white,
            cornerRadius: AppTheme.cornerLarge,
            padding: 0,
            strokeWidth: 3
        )
        .onAppear(perform: onAppearAction)
    }
}

private struct PoemPlayButton: View {
    let poem: Poem
    var emphasized: Bool = false
    @EnvironmentObject private var speech: PoemSpeechService
    
    @State private var isRippling = false

    var body: some View {
        let isPlaying = speech.activePoemId == poem.id
        Button {
            speech.toggleSpeak(poem: poem)
        } label: {
            ZStack {
                if isPlaying {
                    Circle()
                        .stroke(AppTheme.accentBlue.opacity(0.4), lineWidth: 4)
                        .scaleEffect(isRippling ? 1.8 : 1.0)
                        .opacity(isRippling ? 0 : 1)
                        .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: isRippling)
                        .onAppear { isRippling = true }
                        .onDisappear { isRippling = false }
                }

                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: emphasized ? 20 : 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: emphasized ? 54 : 44, height: emphasized ? 54 : 44)
                    .background(
                        LinearGradient(
                            colors: isPlaying ? [AppTheme.accentTerracotta, AppTheme.accentTerracotta.opacity(0.8)] : [AppTheme.accentBlue, AppTheme.accentIndigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                    .overlay(
                        Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .overlay(
                        Circle().strokeBorder(Color.black.opacity(0.15), lineWidth: 3).offset(y: 3).clipShape(Circle())
                    )
                    .shadow(color: (isPlaying ? AppTheme.accentTerracotta : AppTheme.accentBlue).opacity(0.3), radius: 6, x: 0, y: 4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "停止朗读" : "朗读全诗")
        .onChange(of: isPlaying) { playing in
            isRippling = playing
        }
    }
}

private struct PoemRow: View {
    let poem: Poem
    var isRead: Bool = false
    var onTap: () -> Void
    @EnvironmentObject private var speech: PoemSpeechService

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(poem.title)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        if isRead {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.accentSage)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(poem.author)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(poem.type)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppTheme.accentBlue.opacity(0.15), in: Capsule())
                            .foregroundStyle(AppTheme.accentBlue)
                    }
                }

                Spacer(minLength: 8)

                PoemPlayButton(poem: poem)
            }

            PoemBodyBlock(contents: poem.contents, font: .system(size: 18, weight: .medium, design: .rounded), lineSpacing: 10)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .swCardStyle(
            strokeColor: AppTheme.accentBlue,
            background: Color.white,
            cornerRadius: AppTheme.cornerLarge,
            padding: 0,
            strokeWidth: 2.5
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

private struct PoemBodyBlock: View {
    let contents: String
    let font: Font
    let lineSpacing: CGFloat

    private var lines: [String] {
        contents
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(font)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.9))
                    .lineSpacing(lineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            Color(red: 248/255.0, green: 250/255.0, blue: 252/255.0), // 更暖的纸张白
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 2)
        )
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
