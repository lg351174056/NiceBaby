import SwiftUI

// MARK: - 首页 · 墨韵新风

struct HomeView: View {
    @EnvironmentObject private var progress: AppProgressStore
    @State private var isGamePresented = false
    @State private var gameInitialIndex: Int?
    @State private var gameIsDaily = false
    @State private var presentedGame: GameKind? = nil

    private static let cachedPoems = PoemCatalog.poems()
    private var poems: [Poem] { Self.cachedPoems }
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
        count += 1
        return min(count, 3)
    }

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

                // 太阳 + 彩虹 + 云朵 + 风筝（背景层装饰）
                sunDecor
                rainbowDecor
                cloudDecor(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
                cloudDecor(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)
                kiteDecor

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 顶部问候 + 气球
                        greetingHeader
                        balloonsRow

                        // 每日一题大卡
                        dailyMatchCard
                            .padding(.horizontal, AppTheme.paddingScreen)

                        // 今日一诗横卡
                        dailyPoemCard
                            .padding(.horizontal, AppTheme.paddingScreen)

                        // 三统计
                        statsRow
                            .padding(.horizontal, AppTheme.paddingScreen)

                        // 快捷入口
                        quickEntrySection

                        // 今日成语
                        DailyIdiomCard(idiom: dailyIdiom) {
                            presentedGame = .idiomDictionary
                        }

                        // 周统计
                        WeeklyStatsCard(
                            matchSolves: progress.totalMatchstickSolves,
                            matchTotal: MatchstickProblemSet.count,
                            poemsRead: progress.openedPoemIds.count,
                            poemsTotal: poems.count,
                            streakDays: progress.streakDays
                        )

                        // 推荐探索
                        discoverySuggestion
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
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

    // MARK: - 顶部问候（彩虹田野 · 居中）

    private var greetingHeader: some View {
        VStack(spacing: 0) {
            Text("SUNNY DAY")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(5)
                .foregroundStyle(Color(red: 110/255, green: 138/255, blue: 90/255))

            Text("\(greeting)，小火柴！")
                .font(.system(size: 30, weight: .heavy, design: .serif))
                .tracking(1)
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                .padding(.top, 6)

            Text("彩虹桥搭好了，今天从哪边开始玩？")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 122/255, green: 138/255, blue: 110/255))
                .padding(.top, 6)

            // 金币
            HStack(spacing: 4) {
                Text("🪙")
                Text("\(progress.streakDays > 0 ? progress.streakDays * 60 + 1280 : 1280)")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 176/255, green: 138/255, blue: 62/255))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.85), in: Capsule())
            .overlay(
                Capsule().strokeBorder(Color(red: 217/255, green: 164/255, blue: 91/255).opacity(0.5), lineWidth: 2)
            )
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // 三颗气球（错开浮动）
    private var balloonsRow: some View {
        HStack(spacing: 14) {
            Text("🎈").font(.system(size: 28)).modifier(BalloonFloat(delay: 0))
            Text("🎈").font(.system(size: 28)).modifier(BalloonFloat(delay: 0.3))
            Text("🎈").font(.system(size: 28)).modifier(BalloonFloat(delay: 0.6))
        }
        .padding(.top, 6)
    }

    private struct BalloonFloat: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(y: CGFloat(sin(t * 2.2) * 5.0))
            }
        }
    }

    // MARK: - 三统计（彩虹田野牌）

    private var statsRow: some View {
        HStack(spacing: 10) {
            fieldStat(icon: "🧡", value: "\(progress.totalMatchstickSolves)", label: "火柴解对")
            fieldStat(icon: "📖", value: "\(progress.openedPoemIds.count)", label: "已读诗篇")
            fieldStat(icon: "🔥", value: "\(progress.streakDays)天", label: "连续打卡")
        }
    }

    private func fieldStat(icon: String, value: String, label: String) -> some View {
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

    // MARK: - 背景装饰（太阳/彩虹/云/风筝）

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
            .padding(.trailing, 20)
            .padding(.top, 30)
        }
        .allowsHitTesting(false)
    }

    private var rainbowDecor: some View {
        Canvas { ctx, _ in
            let center = CGPoint(x: 200, y: 190)
            let colors: [(Color, CGFloat)] = [
                (Color(red: 255/255, green: 107/255, blue: 107/255), 52),
                (Color(red: 255/255, green: 201/255, blue: 61/255), 60),
                (Color(red: 76/255, green: 175/255, blue: 125/255), 68),
                (Color(red: 125/255, green: 249/255, blue: 255/255), 76),
            ]
            for (color, radius) in colors {
                var p = Path()
                p.addArc(center: center,
                         radius: radius,
                         startAngle: .degrees(0),
                         endAngle: .degrees(90),
                         clockwise: false)
                ctx.stroke(p, with: .color(color), lineWidth: 7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .frame(width: 210, height: 130, alignment: .topTrailing)
        .padding(.trailing, 8)
        .padding(.top, 44)
        .allowsHitTesting(false)
        .opacity(0.8)
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

    // 风筝：摆荡 + 风筝线
    private var kiteDecor: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let angle = 6 * sin(t * 0.9)
            ZStack {
                // 风筝线
                Rectangle()
                    .fill(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3))
                    .frame(width: 1.5, height: 130)
                Text("🪁")
                    .font(.system(size: 22))
                    .offset(y: -68)
            }
            .rotationEffect(.degrees(angle), anchor: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, 30)
            .padding(.top, 70)
        }
        .allowsHitTesting(false)
    }

    // MARK: - 每日一题（彩虹田野 · 薄荷绿大卡）

    private var dailyMatchCard: some View {
        let done = progress.isDailyMatchstickCompletedToday()
        return Button {
            gameInitialIndex = nil
            gameIsDaily = false
            isGamePresented = true
        } label: {
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [
                        Color(red: 143/255, green: 227/255, blue: 192/255),
                        Color(red: 76/255, green: 175/255, blue: 125/255)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                // 火柴人装饰（摇摆）
                Text("🧡")
                    .font(.system(size: 48))
                    .padding(.trailing, 14)
                    .padding(.top, 10)
                    .modifier(SwaySoft())

                VStack(alignment: .leading, spacing: 0) {
                    Text(done ? "今日已完成" : "每日一题")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color(red: 61/255, green: 74/255, blue: 54/255), lineWidth: 2)
                        )

                    Text(done ? "今天的等式已经解开啦" : "移动一根火柴\n让等式变对！")
                        .font(.system(size: 22, weight: .heavy, design: .serif))
                        .foregroundStyle(.white)
                        .shadow(color: Color(red: 61/255, green: 74/255, blue: 54/255).opacity(0.25), radius: 2, y: 2)
                        .padding(.top, 10)

                    Text(done ? "明天再来挑战 · 奖励金币已到账" : "\(matchstickHeroSubtitle) · 答对得 50 金币")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.top, 5)

                    // 进度
                    HStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.4)).frame(height: 10)
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: geo.size.width * matchProgress, height: 10)
                            }
                        }
                        .frame(height: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color(red: 61/255, green: 74/255, blue: 54/255), lineWidth: 2)
                        )
                        Text("\(Int(matchProgress * 100))%")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 12)
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(minHeight: 150)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color(red: 61/255, green: 74/255, blue: 54/255), lineWidth: 3)
            )
            .shadow(color: Color(red: 60/255, green: 80/255, blue: 50/255).opacity(0.3), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var matchProgress: Double {
        let total = MatchstickProblemSet.count
        guard total > 0 else { return 0 }
        return min(Double(progress.totalMatchstickSolves) / Double(total), 1.0)
    }

    private struct SwaySoft: ViewModifier {
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                content
                    .rotationEffect(.degrees(sin(t * 1.6) * 4), anchor: .bottom)
            }
        }
    }

    // MARK: - 今日一诗（云上之书横卡）

    private var dailyPoemCard: some View {
        Button {
            progress.selectedTab = 1
        } label: {
            HStack(spacing: 14) {
                // 书本图标（云上之书）
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
                        .modifier(SwaySoft())
                }
                .frame(width: 52, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35), lineWidth: 2)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text("今日一诗 · \(dailyPoem?.title ?? "")")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    if let p = dailyPoem {
                        Text(p.author)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                        Text(dailyPoemFirstLines)
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .foregroundStyle(Color(red: 59/255, green: 142/255, blue: 165/255))
                            .lineLimit(1)
                    }
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
        }
        .buttonStyle(.plain)
    }

    // MARK: - 快捷入口 · 线性图标

    private var quickEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快捷入口")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, AppTheme.paddingScreen)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    QuickEntryView(icon: "scroll.fill", title: "诗词补全", color: AppTheme.accentInkPurple) {
                        presentedGame = .poetryComplete
                    }
                    QuickEntryLinkView(icon: "sparkles.rectangle.stack.fill", title: "知识百科", color: AppTheme.accentJade) {
                        KnowledgeWikiHomeView()
                    }
                    QuickEntryLinkView(icon: "square.and.pencil", title: "作文精选", color: AppTheme.accentIndigo) {
                        BishenEssayHomeView()
                    }
                    QuickEntryLinkView(icon: "doc.text.image", title: "文章精选", color: AppTheme.accentJade) {
                        BishenFeatureArticleHomeView()
                    }
                    QuickEntryView(icon: "square.dashed", title: "成语填空", color: AppTheme.accentCinnabar) {
                        presentedGame = .idiomFillBlank
                    }
                    QuickEntryView(icon: "character.book.closed.fill", title: "语文作业", color: AppTheme.accentBlue) {
                        presentedGame = .chineseHomework
                    }
                    QuickEntryView(icon: "number.circle.fill", title: "语文批改", color: AppTheme.accentTerracotta) {
                        presentedGame = .mathHomework
                    }
                    QuickEntryView(icon: "person.2.fill", title: "百家姓", color: AppTheme.accentJade) {
                        presentedGame = .surnameMatch
                    }
                    QuickEntryView(icon: "character.book.closed.fill", title: "词典", color: AppTheme.accentYellow) {
                        presentedGame = .dictionary
                    }
                    QuickEntryView(icon: "quote.bubble.fill", title: "歇后语", color: AppTheme.accentPink) {
                        presentedGame = .xiehouyuDictionary
                    }
                    QuickEntryView(icon: "book.fill", title: "三字经", color: AppTheme.accentBamboo) {
                        presentedGame = .sanzijing
                    }
                    QuickEntryView(icon: "map.fill", title: "地理", color: AppTheme.accentJade) {
                        progress.selectedTab = 2
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
            }
        }
    }

    // MARK: - 推荐探索

    private var discoverySuggestion: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("推荐探索")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, AppTheme.paddingScreen)

            DiscoverySuggestionCard(
                icon: "play.tv.fill",
                title: "视频乐园",
                subtitle: "海量英语动画、科学百科，随时播放",
                colors: (AppTheme.accentInkPurple, AppTheme.accentPink)
            ) {
                progress.selectedTab = 2
            }

            DiscoverySuggestionCard(
                icon: "books.vertical.fill",
                title: "学习资料",
                subtitle: "课程笔记、单元练习，全科覆盖",
                colors: (AppTheme.accentJade, AppTheme.accentBamboo)
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
        case .antonymMatch:
            AntonymMatchView(onExit: { presentedGame = nil })
        case .idiomFillLevel:
            IdiomFillLevelView(onExit: { presentedGame = nil })
        case .brainTeaser:
            BrainTeaserHomeView(onExit: { presentedGame = nil })
        case .knowledgeWiki:
            KnowledgeWikiHomeView()
        case .funQuiz:
            FunQuizHomeView()
        case .maze:
            MazeGameView(onExit: { presentedGame = nil })
        case .sudoku:
            SudokuHomeView(onExit: { presentedGame = nil })
        case .arithmetic:
            ArithmeticHomeView(onExit: { presentedGame = nil })
        case .chineseHomework:
            ChineseHomeworkView(onExit: { presentedGame = nil })
        case .mathHomework:
            MathHomeworkView(onExit: { presentedGame = nil })
        }
    }
}

// MARK: - 火柴游戏自由模式容器

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
