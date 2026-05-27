import SwiftUI

// MARK: - 首页

struct HomeView: View {
    @EnvironmentObject private var progress: AppProgressStore
    @State private var isGamePresented = false
    @State private var gameInitialIndex: Int?
    @State private var gameIsDaily = false
    @State private var presentedGame: GameKind? = nil

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
        let idx = dailyMatchIndex
        return Self.mathEngine.problemBank[idx]
    }

    private static let mathEngine = MathEngine()

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

    private var dailyIdiom: ChineseIdiom { Self.cachedDailyIdiom }

    private static let cachedDailyIdiom: ChineseIdiom = {
        let all = IdiomCatalog.all
        guard !all.isEmpty else {
            return ChineseIdiom(text: "学无止境", explanation: "学习没有尽头", example: nil)
        }
        let day = Calendar.current.startOfDay(for: Date())
        let ordinal = Int(day.timeIntervalSince1970 / 86400)
        return all[abs(ordinal) % all.count]
    }()

    private var todayCompletionCount: Int {
        var count = 0
        if progress.isDailyMatchstickCompletedToday() { count += 1 }
        if progress.openedPoemIds.count > 0 { count += 1 }
        count += 1 // 成语默认已展示
        return min(count, 3)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    heroHeader
                        .staggerAppear(index: 0)
                    bentoGrid
                        .staggerAppear(index: 1)
                    quickEntrySection
                        .staggerAppear(index: 2)
                    DailyIdiomCard(idiom: dailyIdiom) {
                        presentedGame = .idiomDictionary
                    }
                    .staggerAppear(index: 3)
                    WeeklyStatsCard(
                        matchSolves: progress.totalMatchstickSolves,
                        matchTotal: MatchstickProblemSet.count,
                        poemsRead: progress.openedPoemIds.count,
                        poemsTotal: poems.count,
                        streakDays: progress.streakDays
                    )
                    .staggerAppear(index: 4)
                    discoverySuggestion
                        .staggerAppear(index: 5)
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
            matchstickFullScreen
        }
        .fullScreenCover(item: $presentedGame) { kind in
            gameContainer(for: kind)
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                HStack(spacing: 14) {
                    if progress.streakDays > 0 {
                        Label("\(progress.streakDays)天连续", systemImage: "flame.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                    Label("今日 \(todayCompletionCount)/3", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(todayCompletionCount >= 3 ? AppTheme.accentSage : AppTheme.accentBlue)
                }
            }
            Spacer()
            Button {
                progress.selectedTab = 4
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
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

    // MARK: - Hero Card

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

    // MARK: - Quick Entry Section

    private var quickEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快捷入口")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, AppTheme.paddingScreen)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    QuickEntryView(icon: "scroll.fill", title: "诗词补全", color: AppTheme.accentIndigo) {
                        presentedGame = .poetryComplete
                    }
                    QuickEntryView(icon: "square.dashed", title: "成语填空", color: AppTheme.accentPurple) {
                        presentedGame = .idiomFillBlank
                    }
                    QuickEntryView(icon: "person.2.fill", title: "百家姓", color: AppTheme.accentMint) {
                        presentedGame = .surnameMatch
                    }
                    QuickEntryView(icon: "character.book.closed.fill", title: "词典", color: Color(red: 180/255, green: 130/255, blue: 70/255)) {
                        presentedGame = .dictionary
                    }
                    QuickEntryView(icon: "quote.bubble.fill", title: "歇后语", color: .orange) {
                        presentedGame = .xiehouyuDictionary
                    }
                    QuickEntryView(icon: "book.fill", title: "三字经", color: .teal) {
                        presentedGame = .sanzijing
                    }
                    QuickEntryView(icon: "map.fill", title: "地理", color: AppTheme.accentSage) {
                        progress.selectedTab = 2
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
            }
        }
    }

    // MARK: - Discovery Suggestion

    private var discoverySuggestion: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("推荐探索")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, AppTheme.paddingScreen)

            DiscoverySuggestionCard(
                icon: "play.tv.fill",
                title: "视频乐园",
                subtitle: "海量英语动画、科学百科，随时播放",
                colors: (AppTheme.accentPurple, AppTheme.accentPink)
            ) {
                progress.selectedTab = 2
            }

            DiscoverySuggestionCard(
                icon: "books.vertical.fill",
                title: "学习资料",
                subtitle: "课程笔记、单元练习，全科覆盖",
                colors: (AppTheme.accentMint, AppTheme.accentSage)
            ) {
                progress.selectedTab = 2
            }
        }
    }

    // MARK: - Full Screen Covers

    private var matchstickFullScreen: some View {
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

    @ViewBuilder
    private func gameContainer(for kind: GameKind) -> some View {
        switch kind {
        case .matchstick:
            MatchstickGameContainer(onExit: { presentedGame = nil })
                .environmentObject(progress)
                .environmentObject(PoemSpeechService.shared)
        case .poetryComplete:
            PoetryCompleteGameView(onExit: { presentedGame = nil })
        case .surnameMatch:
            SurnameMatchGameView(onExit: { presentedGame = nil })
        case .idiomFillBlank:
            IdiomFillBlankGameView(onExit: { presentedGame = nil })
        case .idiomDictionary:
            IdiomDictionaryView(onExit: { presentedGame = nil })
        case .xiehouyuDictionary:
            XiehouyuDictionaryView(onExit: { presentedGame = nil })
        case .sanzijing:
            SanzijingView(onExit: { presentedGame = nil })
        case .dictionary:
            DictionaryGameView(onExit: { presentedGame = nil })
        }
    }
}

// MARK: - 火柴游戏自由模式容器（从 PlayView 复用）

private struct MatchstickGameContainer: View {
    let onExit: () -> Void

    var body: some View {
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
                    onExit: onExit,
                    initialProblemIndex: nil,
                    isDailyChallenge: false
                )
            }
        }
        .ignoresSafeArea()
    }
}
