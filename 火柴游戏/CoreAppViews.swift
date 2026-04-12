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
            Tab("我的", systemImage: "person.crop.circle.fill", value: 2) {
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
                        Text("学习中心")
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
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentBlue.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "puzzlepiece.extension.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppTheme.accentBlue)
                    }
                    Spacer()
                    if done {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.accentSage)
                    }
                }
                Text("火柴游戏 · 每日一题")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(done ? "今日已完成" : "第 \(dailyMatchIndex + 1) 题")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .swCardStyle(
                strokeColor: AppTheme.accentBlue.opacity(0.55),
                background: AppTheme.card,
                cornerRadius: AppTheme.cornerMedium,
                padding: 16,
                strokeWidth: 0.8
            )
            .shadow(color: .black.opacity(0.06), radius: AppTheme.cardShadowRadius, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var todayPoemCard: some View {
        Button {
            progress.selectedTab = 1
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentTerracotta.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppTheme.accentTerracotta)
                    }
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                }
                Text("唐诗 · 今日一诗")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                if let p = dailyPoem {
                    Text(p.title)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                } else {
                    Text("加载中…")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .swCardStyle(
                strokeColor: AppTheme.accentTerracotta.opacity(0.5),
                background: AppTheme.card,
                cornerRadius: AppTheme.cornerMedium,
                padding: 16,
                strokeWidth: 0.8
            )
            .shadow(color: .black.opacity(0.06), radius: AppTheme.cardShadowRadius, x: 0, y: 4)
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
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                        Text("移动一根火柴，让等式成立")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Image(systemName: "function")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(22)

                SWShimmer(duration: 2.4, delay: 1.0) {
                    HStack {
                        Text(matchstickHeroSubtitle)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                        Spacer()
                        Text("开始")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.accentBlue)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(.white, in: Capsule())
                    }
                    .padding(18)
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
            .shadow(color: AppTheme.accentBlue.opacity(0.28), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    private var poemLibraryCard: some View {
        Button {
            progress.selectedTab = 1
        } label: {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentTerracotta.opacity(0.85), AppTheme.accentTerracotta],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "text.book.closed.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text("唐诗三百首")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("按篇浏览 · 今日一诗在「诗库」置顶")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
            }
            .padding(18)
            .swCardStyle(
                strokeColor: AppTheme.accentTerracotta.opacity(0.45),
                background: AppTheme.card,
                cornerRadius: AppTheme.cornerLarge,
                padding: 0,
                strokeWidth: 0.8
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
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
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.accentTerracotta.opacity(0.15), in: Capsule())
                        .foregroundStyle(AppTheme.accentTerracotta)

                    Text(poem.title)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Text(poem.author)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(poem.type)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.accentBlue.opacity(0.1), in: Capsule())
                            .foregroundStyle(AppTheme.accentBlue)
                    }
                }

                Spacer(minLength: 8)

                PoemPlayButton(poem: poem, emphasized: true)
            }

            PoemBodyBlock(contents: poem.contents, font: .body, lineSpacing: 8)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .swCardStyle(
            strokeColor: AppTheme.accentTerracotta.opacity(0.35),
            background: Color.white.opacity(0.88),
            cornerRadius: AppTheme.cornerLarge,
            padding: 0,
            strokeWidth: 0.8
        )
        .shadow(color: AppTheme.accentTerracotta.opacity(0.08), radius: 14, x: 0, y: 6)
        .onAppear(perform: onAppearAction)
    }
}

private struct PoemPlayButton: View {
    let poem: Poem
    var emphasized: Bool = false
    @EnvironmentObject private var speech: PoemSpeechService

    var body: some View {
        Button {
            speech.toggleSpeak(poem: poem)
        } label: {
            Image(systemName: speech.activePoemId == poem.id ? "stop.fill" : "play.fill")
                .font(.system(size: emphasized ? 16 : 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: emphasized ? 42 : 34, height: emphasized ? 42 : 34)
                .background(
                    LinearGradient(
                        colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .shadow(color: AppTheme.accentBlue.opacity(0.2), radius: emphasized ? 10 : 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(speech.activePoemId == poem.id ? "停止朗读" : "朗读全诗")
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
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        if isRead {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.accentSage)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(poem.author)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(poem.type)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.accentBlue.opacity(0.1), in: Capsule())
                            .foregroundStyle(AppTheme.accentBlue)
                    }
                }

                Spacer(minLength: 8)

                PoemPlayButton(poem: poem)
            }

            PoemBodyBlock(contents: poem.contents, font: .body, lineSpacing: 7)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .swCardStyle(
            strokeColor: AppTheme.accentBlue.opacity(0.24),
            background: Color.white.opacity(0.82),
            cornerRadius: AppTheme.cornerLarge,
            padding: 0,
            strokeWidth: 0.75
        )
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
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
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.72), Color.white.opacity(0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.separator.opacity(0.12), lineWidth: 0.6)
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

    private var avatarBlock: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 28))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(.white.opacity(0.22), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("学习伙伴")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text("成就与打卡仅保存在本机")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()

            if progress.streakDays > 0 {
                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.orange)
                        Text("\(progress.streakDays)")
                            .font(.system(.title2, design: .rounded).weight(.black))
                            .foregroundStyle(.white)
                    }
                    Text("天连续打卡")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
        )
        .shadow(color: AppTheme.accentBlue.opacity(0.28), radius: 16, x: 0, y: 8)
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 8)
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
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(unlocked ? AppTheme.textPrimary : AppTheme.textSecondary)
            Text(achievement.subtitle)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            unlocked
                ? LinearGradient(
                    colors: [AppTheme.accentBlue.opacity(0.14), AppTheme.accentIndigo.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                : LinearGradient(
                    colors: [AppTheme.card.opacity(0.65), AppTheme.card.opacity(0.65)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                .strokeBorder(
                    unlocked ? AppTheme.accentBlue.opacity(0.35) : AppTheme.separator.opacity(0.5),
                    lineWidth: unlocked ? 1.0 : 0.5
                )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.black))
                .foregroundStyle(tint)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(tint.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous))
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
