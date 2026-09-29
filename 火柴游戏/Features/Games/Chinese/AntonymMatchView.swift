import SwiftUI
import Combine

// MARK: - 反义对对碰 · 儿童学反义词
//
// 设计：朱砂红 × 竹青绿 — 一红一绿，天生相反。
// 四模式：翻翻乐配对 / 跷跷板选择题 / 闯关地图 / 反义图册。
// 数据全部来自本地 AntonymCatalog（反义词库.txt，18,797 对，筛儿童友好子集）。
// 视觉：墨韵新风儿童版 — 宣纸底 + 双主色反义隐喻 + 印章奖章激励。

// MARK: - 配色（高还原设计图）

private enum AntColors {
    static let red = Color(red: 200/255, green: 66/255, blue: 58/255)        // #C8423A 朱砂
    static let redDark = Color(red: 168/255, green: 51/255, blue: 44/255)     // #A8332C
    static let redSoft = Color(red: 251/255, green: 233/255, blue: 230/255)   // #FBE9E6
    static let green = Color(red: 94/255, green: 138/255, blue: 82/255)       // #5E8A52 竹青
    static let greenDark = Color(red: 74/255, green: 111/255, blue: 64/255)   // #4A6F40
    static let greenSoft = Color(red: 230/255, green: 240/255, blue: 226/255) // #E6F0E2
    static let gold = Color(red: 200/255, green: 146/255, blue: 58/255)       // #C8923A 印章金
    static let goldSoft = Color(red: 247/255, green: 238/255, blue: 215/255)  // #F7EED7
    static let goldDark = Color(red: 154/255, green: 111/255, blue: 34/255)   // #9A6F22
    static let inkCard = Color(red: 58/255, green: 53/255, blue: 80/255)      // #3A3550 图册墨紫
    static let cardBack1 = Color(red: 92/255, green: 75/255, blue: 134/255)   // #5C4B86 卡背
    static let cardBack2 = Color(red: 73/255, green: 59/255, blue: 110/255)   // #493B6E
    static let borderSoft = Color(red: 239/255, green: 233/255, blue: 222/255)
    static let sealMark = Color(red: 217/255, green: 207/255, blue: 190/255)  // 跷跷板木色
    static let seesawWood = Color(red: 181/255, green: 171/255, blue: 152/255) // #B5AB98
}

// MARK: - 进度持久化

private enum AntonymProgress {
    private static let prefix = "antonym."
    static let stampCountKey = prefix + "stamps"
    static let adventureLevelKey = prefix + "adventureLevel"
    static let dailyCountKey = prefix + "dailyCount"
    static let dailyDateKey = prefix + "dailyDate"

    static var stampCount: Int {
        get { UserDefaults.standard.integer(forKey: stampCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: stampCountKey) }
    }
    static var adventureLevel: Int {
        get { max(1, UserDefaults.standard.integer(forKey: adventureLevelKey)) }
        set { UserDefaults.standard.set(newValue, forKey: adventureLevelKey) }
    }
    static var dailyCount: Int {
        get { UserDefaults.standard.integer(forKey: dailyCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: dailyCountKey) }
    }
    static func resetDailyIfNeeded() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        if UserDefaults.standard.string(forKey: dailyDateKey) != today {
            UserDefaults.standard.set(0, forKey: dailyCountKey)
            UserDefaults.standard.set(today, forKey: dailyDateKey)
        }
    }
    static func addStamp() {
        stampCount += 1
    }
    static func addDaily() {
        resetDailyIfNeeded()
        dailyCount = min(5, dailyCount + 1)
    }
}

// MARK: - 主容器

struct AntonymMatchView: View {
    let onExit: () -> Void

    @State private var mode: Mode? = nil

    var body: some View {
        ZStack {
            if mode == nil {
                ModeSelect(onExit: onExit, onPick: { picked in
                    withAnimation(.easeInOut(duration: 0.28)) { mode = picked }
                })
                .transition(.opacity)
            }

            if let mode {
                GameContainer(mode: mode, onHome: {
                    withAnimation(.easeInOut(duration: 0.28)) { self.mode = nil }
                })
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .preferredColorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
    }

    enum Mode: String, Hashable, Identifiable {
        case flipMatch     // 翻翻乐
        case seesaw        // 跷跷板
        case adventure     // 闯关地图
        case album         // 反义图册
        case collection    // 全部词汇合集
        var id: String { rawValue }
    }
}

// MARK: - 模式选择 · 主页

private struct ModeSelect: View {
    let onExit: () -> Void
    let onPick: (AntonymMatchView.Mode) -> Void

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "反义对对碰", subtitle: "找一找，谁和谁正好相反？", onBack: onExit)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    helloRow
                    heroCard
                    modeGrid
                    dailyCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: 问候 + 印章徽标

    private var helloRow: some View {
        HStack {
            Text("嗨，小语！")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            StampBadge(text: "已集 \(AntonymProgress.stampCount) 印")
        }
        .padding(.horizontal, 2)
        .padding(.top, 2)
    }

    // MARK: Hero 卡片

    private var heroCard: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                // 红绿点装饰
                HStack(spacing: 6) {
                    Circle().fill(AntColors.red).frame(width: 12, height: 12)
                    Capsule().fill(AppTheme.separator).frame(width: 14, height: 2)
                    Circle().fill(AntColors.green).frame(width: 12, height: 12)
                    Spacer()
                }

                Text("FIND THE OPPOSITE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.22)
                    .foregroundStyle(AntColors.red)
                    .padding(.top, 10)

                // 标题：反义(红) 对(墨) 对碰(绿)
                Text("\(Text("反义").foregroundStyle(AntColors.red))\(Text("对").foregroundStyle(AppTheme.textPrimary))\(Text("对碰").foregroundStyle(AntColors.green))")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .tracking(0.02)

                Text("找一找，谁和谁正好相反？")
                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)

            // 吉祥物：大/小 双卡（内嵌卡片右下）
            HStack(spacing: 4) {
                mascotBlock(word: "大", color: AntColors.red)
                mascotBlock(word: "小", color: AntColors.green)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(colors: [Color(red: 1.0, green: 0.993, blue: 0.973), Color(red: 0.957, green: 0.937, blue: 0.894)],
                           startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(AntColors.borderSoft, lineWidth: 1))
        .shadow(color: AppTheme.inkShadow, radius: 3, y: 1)
    }

    private func mascotBlock(word: String, color: Color) -> some View {
        Text(word)
            .font(.system(size: 18, weight: .bold, design: .serif))
            .foregroundStyle(.white)
            .frame(width: 38, height: 48)
            .background(color, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: 模式 2×2 网格

    private var modeGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return VStack(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 12) {
                modeCard(.flipMatch, tag: "FLIP MATCH", title: "翻翻乐", desc: "翻卡片，找反义对", color: .red)
                modeCard(.seesaw, tag: "SEESAW", title: "跷跷板", desc: "选词压平衡，三选一", color: .green)
                modeCard(.adventure, tag: "ADVENTURE", title: "闯关地图", desc: "30 关，集印章奖章", color: .gold)
                modeCard(.album, tag: "ALBUM", title: "反义图册", desc: "翻翻学，一红一绿", color: .ink)
            }
            collectionCard
        }
    }

    // MARK: 全部词汇合集入口（全宽）

    private var collectionCard: some View {
        Button { onPick(.collection) } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [AntColors.gold, AntColors.goldDark],
                                             startPoint: .top, endPoint: .bottom))
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 3) {
                    Text("全部词汇")
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("完整收录 9999+ 对反义词，可搜索浏览")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("合集")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(AntColors.goldDark)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(AntColors.goldSoft, in: Capsule())
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(AntColors.goldSoft.opacity(0.4), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(AntColors.borderSoft, lineWidth: 1))
        }
        .buttonStyle(BounceStyle())
    }

    private func modeCard(_ m: AntonymMatchView.Mode, tag: String, title: String, desc: String, color: ModeColor) -> some View {
        Button { onPick(m) } label: {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(tag)
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(0.16)
                        .foregroundStyle(color.tagColor)
                        .padding(.top, 18)
                        .padding(.leading, 16)

                    Text(title)
                        .font(.system(size: 21, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.top, 8)
                        .padding(.leading, 16)

                    Text(desc)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                        .padding(.top, 5)
                        .padding(.leading, 16)

                    HStack(spacing: 4) {
                        Text(m == .adventure ? "继续 · 第\(AntonymProgress.adventureLevel)关" : "开始")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(color.tagColor)
                    .padding(.leading, 16)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 图标
                Image(systemName: m.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(color.iconBg, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .padding(.top, 16)
                    .padding(.trailing, 14)
            }
            .frame(minHeight: 128)
            .background(color.cardBg, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(AntColors.borderSoft, lineWidth: 1))
            .shadow(color: AppTheme.inkShadow, radius: 3, y: 1)
        }
        .buttonStyle(BounceStyle())
    }

    private enum ModeColor {
        case red, green, gold, ink
        var tagColor: Color {
            switch self {
            case .red: return AntColors.redDark
            case .green: return AntColors.greenDark
            case .gold: return AntColors.goldDark
            case .ink: return Color(red: 74/255, green: 63/255, blue: 115/255)
            }
        }
        var iconBg: Color {
            switch self {
            case .red: return AntColors.red
            case .green: return AntColors.green
            case .gold: return AntColors.gold
            case .ink: return AntColors.inkCard
            }
        }
        var cardBg: LinearGradient {
            switch self {
            case .red: return LinearGradient(colors: [AntColors.redSoft, Color(red: 1.0, green: 0.965, blue: 0.957)],
                                             startPoint: .top, endPoint: .bottom)
            case .green: return LinearGradient(colors: [AntColors.greenSoft, Color(red: 0.951, green: 0.973, blue: 0.937)],
                                                startPoint: .top, endPoint: .bottom)
            case .gold: return LinearGradient(colors: [AntColors.goldSoft, Color(red: 0.984, green: 0.961, blue: 0.902)],
                                              startPoint: .top, endPoint: .bottom)
            case .ink: return LinearGradient(colors: [Color(red: 0.933, green: 0.918, blue: 0.965), Color(red: 0.965, green: 0.953, blue: 0.988)],
                                             startPoint: .top, endPoint: .bottom)
            }
        }
    }

    // MARK: 今日学习

    private var dailyCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("今日学习")
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("每天 5 对，养成好习惯")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            HStack(spacing: 7) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .strokeBorder(AntColors.green, lineWidth: 2)
                        .background(Circle().fill(i < AntonymProgress.dailyCount ? AntColors.green : Color.clear))
                        .frame(width: 13, height: 13)
                }
            }
            Text("\(AntonymProgress.dailyCount)/5")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(AntColors.greenDark)
                .padding(.leading, 4)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(AntColors.borderSoft, lineWidth: 1))
        .shadow(color: AppTheme.inkShadow, radius: 3, y: 1)
        .padding(.horizontal, 2)
    }
}

private extension AntonymMatchView.Mode {
    var icon: String {
        switch self {
        case .flipMatch: return "rectangle.on.rectangle.angled"
        case .seesaw:    return "scalemass"
        case .adventure: return "map.fill"
        case .album:     return "book.closed"
        case .collection: return "books.vertical.fill"
        }
    }
}

// MARK: - 游戏容器

private struct GameContainer: View {
    let mode: AntonymMatchView.Mode
    let onHome: () -> Void

    var body: some View {
        switch mode {
        case .flipMatch: FlipMatchGame(onHome: onHome)
        case .seesaw:    SeesawQuizGame(onHome: onHome)
        case .adventure: AdventureMapView(onHome: onHome)
        case .album:     AntonymAlbumView(onHome: onHome)
        case .collection: AntonymCollectionView(onHome: onHome)
        }
    }
}

// MARK: - 翻翻乐配对

private struct FlipMatchGame: View {
    let onHome: () -> Void

    @State private var cards: [FlipCard] = []
    @State private var flippedIndices: [Int] = []
    @State private var moves: Int = 0
    @State private var matchedPairs: Int = 0
    @State private var showCelebration: Bool = false
    @State private var hintActive: Bool = false
    @State private var lockInput: Bool = false
    @State private var difficulty: AntonymCatalog.Difficulty = .easy

    private let totalPairs = 6

    private var progress: Double { Double(matchedPairs) / Double(totalPairs) }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "翻翻乐", subtitle: nil, trailing: AnyView(
                Text("步数 \(moves)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            ), onBack: onHome)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    progressBar
                    difficultyPicker
                    board
                    actions
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
        }
        .overlay {
            if showCelebration {
                CelebrationOverlay(
                    title: "配对成功！",
                    sealText: "真棒",
                    subtitle: "获得印章 ×1",
                    buttonTitle: "继续翻牌"
                ) {
                    showCelebration = false
                    newGame()
                }
            }
        }
        .onAppear { newGame() }
    }

    private var progressBar: some View {
        VStack(spacing: 10) {
            HStack {
                Text("已配对")
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(matchedPairs) / \(totalPairs) 对")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AntColors.redDark)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AntColors.borderSoft).frame(height: 9)
                    Capsule()
                        .fill(LinearGradient(colors: [AntColors.red, AntColors.green], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress, height: 9)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: matchedPairs)
                }
            }
            .frame(height: 9)
        }
        .padding(.horizontal, 2)
    }

    private var difficultyPicker: some View {
        HStack(spacing: 8) {
            ForEach(AntonymCatalog.Difficulty.allCases, id: \.self) { d in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        difficulty = d
                        newGame()
                    }
                } label: {
                    Text(d.label)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(difficulty == d ? .white : AppTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            difficulty == d ? AntColors.red : AppTheme.card,
                            in: Capsule()
                        )
                        .overlay(Capsule().strokeBorder(AntColors.borderSoft, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 2)
    }

    private var board: some View {
        // 一行三张，2:3 竖版扑克牌，呼吸空间更足
        let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14),
                       GridItem(.flexible(), spacing: 14)]
        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(cards) { card in
                FlipCardView(card: card) {
                    tapCard(card)
                }
            }
        }
        .padding(.horizontal, 2)
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                useHint()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 14, weight: .semibold))
                    Text("求助提示")
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                }
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
            }
            .buttonStyle(BounceStyle())
            .disabled(hintActive || lockInput)

            Button {
                newGame()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("重新开始")
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(AntColors.inkCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(BounceStyle())
        }
        .padding(.horizontal, 2)
    }

    // MARK: 逻辑

    private func newGame() {
        let pairs = AntonymCatalog.randomPairs(count: totalPairs, difficulty: difficulty)
        var newCards: [FlipCard] = []
        for (i, pair) in pairs.enumerated() {
            newCards.append(FlipCard(pairId: i, word: pair.left, partner: pair.right, side: .red))
            newCards.append(FlipCard(pairId: i, word: pair.right, partner: pair.left, side: .green))
        }
        cards = newCards.shuffled()
        flippedIndices = []
        moves = 0
        matchedPairs = 0
        hintActive = false
        lockInput = false
        showCelebration = false
    }

    private func tapCard(_ card: FlipCard) {
        guard !lockInput, !card.isFlipped, !card.isMatched,
              let idx = cards.firstIndex(where: { $0.id == card.id }) else { return }

        withAnimation(.easeInOut(duration: 0.5)) {
            cards[idx].isFlipped = true
        }
        flippedIndices.append(idx)

        guard flippedIndices.count == 2 else { return }

        moves += 1
        lockInput = true
        let a = flippedIndices[0], b = flippedIndices[1]

        if cards[a].pairId == cards[b].pairId {
            // 配对成功
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    cards[a].isMatched = true
                    cards[b].isMatched = true
                }
                matchedPairs += 1
                AntonymProgress.addDaily()
                flippedIndices = []
                lockInput = false

                if matchedPairs == totalPairs {
                    AntonymProgress.addStamp()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showCelebration = true
                        }
                    }
                }
            }
        } else {
            // 不配对，翻回
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    cards[a].isFlipped = false
                    cards[b].isFlipped = false
                }
                flippedIndices = []
                lockInput = false
            }
        }
    }

    private func useHint() {
        guard !hintActive, !lockInput else { return }
        hintActive = true
        // 翻开所有未配对的卡 1.2 秒
        withAnimation(.easeInOut(duration: 0.4)) {
            for i in cards.indices where !cards[i].isMatched && !cards[i].isFlipped {
                cards[i].isFlipped = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                for i in cards.indices where !cards[i].isMatched {
                    // 只翻回非当前已选的卡
                    if !flippedIndices.contains(i) {
                        cards[i].isFlipped = false
                    }
                }
            }
            hintActive = false
        }
    }
}

// MARK: 翻牌数据 + 视图

private struct FlipCard: Identifiable {
    let id = UUID()
    let pairId: Int
    let word: String
    let partner: String
    let side: Side
    var isFlipped: Bool = false
    var isMatched: Bool = false

    enum Side { case red, green }
}

private struct FlipCardView: View {
    let card: FlipCard
    let onTap: () -> Void

    private var mainColor: Color { card.side == .red ? AntColors.red : AntColors.green }
    private var mainColorDark: Color { card.side == .red ? AntColors.redDark : AntColors.greenDark }

    var body: some View {
        // 真正的 3D 翻转：一张卡 0°→180°，超过 90° 显示正面
        ZStack {
            cardBack
                .opacity(card.isFlipped ? 0 : 1)
            cardFront
                .opacity(card.isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(
            .degrees(card.isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        // 2:3 竖版扑克牌比例
        .aspectRatio(2.0/3.0, contentMode: .fit)
        .shadow(color: Color.black.opacity(card.isMatched ? 0.10 : 0.22),
                radius: card.isMatched ? 3 : 7,
                x: 0,
                y: card.isMatched ? 2 : 5)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    // MARK: 牌背 · 墨紫印章纹
    private var cardBack: some View {
        ZStack {
            // 主体：墨紫径向渐变（从顶部散开）
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [AntColors.cardBack1,
                                 Color(red: 74/255, green: 61/255, blue: 114/255),
                                 Color(red: 58/255, green: 47/255, blue: 92/255)],
                        center: .top,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
            // 边框
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(red: 107/255, green: 90/255, blue: 154/255), lineWidth: 1.5)
            // 内描边（描金感）
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color(red: 1.0, green: 0.94, blue: 0.82).opacity(0.18), lineWidth: 1)
                .padding(8)
            // 纤维纹理：细斜线
            paperFiberBack
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .opacity(0.5)

            // 左上角朱砂小印「反」
            cornerSeal(text: "反", rotation: -4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(12)
            // 右下角朱砂小印「对」
            cornerSeal(text: "对", rotation: 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(12)
            // 中央圆印
            centerSeal
            // 底部标签
            Text("反 义 · ANTONYM")
                .font(.system(size: 7, weight: .bold, design: .serif))
                .tracking(2)
                .foregroundStyle(Color(red: 1.0, green: 0.94, blue: 0.82).opacity(0.42))
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 22)
        }
    }

    private func cornerSeal(text: String, rotation: Double) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black, design: .serif))
            .foregroundStyle(Color(red: 0.95, green: 0.93, blue: 0.87))
            .frame(width: 18, height: 18)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(AntColors.red)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(Color(red: 1.0, green: 0.94, blue: 0.82).opacity(0.35), lineWidth: 0.6)
            )
            .shadow(color: AntColors.redDark.opacity(0.45), radius: 1.5, y: 1)
            .rotationEffect(.degrees(rotation))
    }

    private var centerSeal: some View {
        Text("印")
            .font(.system(size: 26, weight: .black, design: .serif))
            .foregroundStyle(Color(red: 0.95, green: 0.93, blue: 0.87))
            .shadow(color: Color(red: 110/255, green: 20/255, blue: 16/255).opacity(0.5), radius: 0.5, y: 0.5)
            .frame(width: 48, height: 48)
            .background(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AntColors.red, AntColors.redDark,
                                     Color(red: 142/255, green: 42/255, blue: 34/255)],
                            center: .top,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
            )
            .overlay(
                // 外圈描金光环
                Circle()
                    .strokeBorder(Color(red: 1.0, green: 0.94, blue: 0.82).opacity(0.3), lineWidth: 1.5)
                    .scaleEffect(1.08)
            )
            .shadow(color: AntColors.redDark.opacity(0.5), radius: 5, y: 3)
    }

    private var paperFiberBack: some View {
        Canvas { context, size in
            let h = size.height, w = size.width
            // 细斜线纹理（水墨纤维）
            var p = Path()
            let step: CGFloat = 4
            var x: CGFloat = -h
            while x < w {
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x + h, y: h))
                x += step
            }
            context.stroke(p, with: .color(Color(red: 1.0, green: 0.94, blue: 0.82).opacity(0.02)),
                           lineWidth: 1)
        }
    }

    // MARK: 牌面 · 宣纸 + 朱砂大字 + 水墨笔触
    private var cardFront: some View {
        ZStack {
            // 宣纸渐变（170deg 对角）
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.97, blue: 0.95),
                                 Color(red: 0.95, green: 0.91, blue: 0.84),
                                 Color(red: 0.90, green: 0.86, blue: 0.77)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            // 边框
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(red: 168/255, green: 150/255, blue: 108/255).opacity(0.35),
                              lineWidth: 1.5)
            // 内描边
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(red: 168/255, green: 150/255, blue: 108/255).opacity(0.28),
                              lineWidth: 1)
                .padding(7)
            // 宣纸纤维纹理
            paperFiberFront
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .opacity(0.6)

            // 水墨笔触意象（写意墨撇，低透明度衬底）
            brushStroke
                .opacity(0.16)
                .frame(width: 100, height: 100)

            // 左上角花押（主字小字）
            Text(card.word)
                .font(.system(size: 10, weight: .black, design: .serif))
                .tracking(1.5)
                .foregroundStyle(AntColors.inkCard.opacity(0.55))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 12)
                .padding(.leading, 14)
            // 右上角序号
            Text(String(format: "%02d", card.pairId + 1))
                .font(.system(size: 10, weight: .black, design: .serif))
                .tracking(1.5)
                .foregroundStyle(AntColors.inkCard.opacity(0.55))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 12)
                .padding(.trailing, 14)

            // 主字（朱砂/竹青，大号宋体，正面居中）
            Text(card.word)
                .font(.system(size: 40, weight: .black, design: .serif))
                .foregroundStyle(mainColor)
                .shadow(color: mainColorDark.opacity(0.18), radius: 0.5, y: 0.5)
                .shadow(color: Color(red: 1.0, green: 0.96, blue: 0.88).opacity(0.4), radius: 0.5, y: -0.5)
                .offset(y: -3)

            // 底部反义配对提示胶囊
            partnerPill
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 12)

            // 右下角落款印「配」（配对完成时盖出）
            if card.isMatched {
                matchedSeal
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 10)
                    .padding(.bottom, 26)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(card.isMatched ? 0.95 : 1.0)
    }

    private var paperFiberFront: some View {
        Canvas { context, size in
            let h = size.height, w = size.width
            // 斜线纹理（宣纸纤维）
            var p = Path()
            let step: CGFloat = 5
            var x: CGFloat = -h
            while x < w {
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x + h, y: h))
                x += step
            }
            context.stroke(p, with: .color(Color(red: 168/255, green: 150/255, blue: 108/255).opacity(0.04)),
                           lineWidth: 1)
        }
    }

    // 水墨写意笔触：圆转大撇（对应 card.html 的 brush SVG）
    private var brushStroke: some View {
        Path { path in
            path.move(to: CGPoint(x: 35, y: 60))
            path.addQuadCurve(to: CGPoint(x: 110, y: 40), control: CGPoint(x: 60, y: 22))
            path.addQuadCurve(to: CGPoint(x: 150, y: 65), control: CGPoint(x: 132, y: 42))
            path.addQuadCurve(to: CGPoint(x: 145, y: 120), control: CGPoint(x: 168, y: 86))
            path.addQuadCurve(to: CGPoint(x: 90, y: 145), control: CGPoint(x: 140, y: 138))
            path.addQuadCurve(to: CGPoint(x: 42, y: 115), control: CGPoint(x: 52, y: 144))
            path.addQuadCurve(to: CGPoint(x: 58, y: 78), control: CGPoint(x: 32, y: 92))
            path.addQuadCurve(to: CGPoint(x: 118, y: 73), control: CGPoint(x: 82, y: 68))
        }
        .stroke(AntColors.inkCard, style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
    }

    private var partnerPill: some View {
        HStack(spacing: 5) {
            // 竹青「对」小章
            Text("对")
                .font(.system(size: 9, weight: .black, design: .serif))
                .foregroundStyle(Color(red: 0.95, green: 0.93, blue: 0.87))
                .frame(width: 15, height: 15)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(AntColors.green)
                )
                .rotationEffect(.degrees(-6))
            // 配对后揭示反义伴侣词，未配对只显「反义」保持记忆挑战
            if card.isMatched {
                Text("反义 · ")
                    .font(.system(size: 9, weight: .bold, design: .serif))
                    .tracking(0.5)
                    .foregroundStyle(AntColors.inkCard)
                Text(card.partner)
                    .font(.system(size: 9, weight: .black, design: .serif))
                    .tracking(0.5)
                    .foregroundStyle(AntColors.inkCard)
            } else {
                Text("反义")
                    .font(.system(size: 9, weight: .bold, design: .serif))
                    .tracking(1)
                    .foregroundStyle(AntColors.inkCard)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(AntColors.inkCard.opacity(0.06))
        )
        .overlay(
            Capsule()
                .strokeBorder(AntColors.inkCard.opacity(0.14), lineWidth: 1)
        )
    }

    // 右下角落款印「配」（配对完成盖出，spring 弹入）
    private var matchedSeal: some View {
        Text("配")
            .font(.system(size: 14, weight: .black, design: .serif))
            .foregroundStyle(Color(red: 0.95, green: 0.93, blue: 0.87))
            .frame(width: 26, height: 26)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(AntColors.red)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Color(red: 1.0, green: 0.94, blue: 0.82).opacity(0.3), lineWidth: 0.8)
            )
            .shadow(color: AntColors.redDark.opacity(0.5), radius: 3, y: 2)
            .rotationEffect(.degrees(-9))
    }
}

// MARK: - 跷跷板选择题

private struct SeesawQuizGame: View {
    let onHome: () -> Void

    @State private var question: AntonymCatalog.QuizQuestion?
    @State private var selectedIndex: Int? = nil
    @State private var streak: Int = 0
    @State private var score: Int = 0
    @State private var questionNum: Int = 1
    @State private var totalQuestions: Int = 10
    @State private var seesawTilt: Double = -9
    @State private var lockInput: Bool = false
    @State private var showResult: Bool = false
    @State private var difficulty: AntonymCatalog.Difficulty = .easy

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "跷跷板", subtitle: nil, trailing: AnyView(
                Text("连对 \(streak)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            ), onBack: onHome)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    quizHead
                    seesawVisual
                    choices
                    scoreBar
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
        }
        .overlay {
            if showResult {
                CelebrationOverlay(
                    title: score >= 80 ? "太厉害了！" : "完成挑战！",
                    sealText: score >= 80 ? "满分" : "通关",
                    subtitle: "获得印章 ×1 · 得分 \(score)",
                    buttonTitle: "再来一局"
                ) {
                    showResult = false
                    startNewRound()
                }
            }
        }
        .onAppear { startNewRound() }
    }

    private var quizHead: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ForEach(AntonymCatalog.Difficulty.allCases, id: \.self) { d in
                    Button {
                        withAnimation { difficulty = d; startNewRound() }
                    } label: {
                        Text(d.label)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(difficulty == d ? .white : AppTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(difficulty == d ? AntColors.green : AppTheme.card, in: Capsule())
                            .overlay(Capsule().strokeBorder(AntColors.borderSoft, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            Text("第 \(questionNum) 题 · \(String(format: "%02d", questionNum)) / \(totalQuestions)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.2)
                .foregroundStyle(AntColors.greenDark)
                .textCase(.uppercase)
                .padding(.top, 4)

            if let q = question {
                Text("谁和「\(q.prompt)」相反？放到右边压平衡")
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(.horizontal, 2)
    }

    private var seesawVisual: some View {
        ZStack {
            // 跷跷板
            ZStack {
                // 横杆
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 0.85, green: 0.81, blue: 0.75), Color(red: 0.76, green: 0.72, blue: 0.64)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 240, height: 14)
                    .shadow(color: AppTheme.inkShadow, radius: 3, y: 1)

                // 左盘：题面词（红）
                if let q = question {
                    seesawPlate(text: q.prompt, color: AntColors.red, isPrompt: true)
                        .offset(x: -100, y: -48)

                    // 右盘：答案/问号
                    seesawPlate(
                        text: selectedIndex != nil ? q.choices[selectedIndex!] : "?",
                        color: selectedIndex != nil ? (selectedIndex == q.correctIndex ? AntColors.green : AntColors.red) : AppTheme.card,
                        isPrompt: false,
                        isDashed: selectedIndex == nil
                    )
                    .offset(x: 100, y: -48)
                }
            }
            .rotationEffect(.degrees(seesawTilt), anchor: .center)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: seesawTilt)

            // 支点（三角）
            Triangle()
                .fill(AntColors.seesawWood)
                .frame(width: 52, height: 46)
                .offset(y: 26)
                .shadow(color: AppTheme.inkShadow, radius: 2, y: 2)

            // 地面线
            Capsule()
                .fill(AppTheme.separator)
                .frame(width: 200, height: 3)
                .offset(y: 50)
        }
        .frame(height: 200)
        .padding(.horizontal, 2)
    }

    private func seesawPlate(text: String, color: Color, isPrompt: Bool, isDashed: Bool = false) -> some View {
        VStack(spacing: 0) {
            Capsule().fill(AntColors.seesawWood.opacity(0.6)).frame(width: 2, height: 24)
            Text(text)
                .font(.system(size: isPrompt ? 30 : 24, weight: .bold, design: .serif))
                .foregroundStyle(isDashed ? AppTheme.textSecondary : .white)
                .frame(width: 96, height: 58)
                .background {
                    if isDashed {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppTheme.separator, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppTheme.card))
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(color)
                    }
                }
                .shadow(color: AppTheme.inkShadow, radius: 3, y: 1)
        }
        .rotationEffect(.degrees(-seesawTilt))
    }

    private var choices: some View {
        VStack(spacing: 10) {
            if let q = question {
                ForEach(Array(q.choices.enumerated()), id: \.offset) { idx, word in
                    let isCorrect = idx == q.correctIndex
                    let isSelected = idx == selectedIndex
                    let showCorrect = selectedIndex != nil && isCorrect
                    let showWrong = isSelected && !isCorrect

                    Button {
                        selectChoice(idx, correct: isCorrect)
                    } label: {
                        HStack(spacing: 14) {
                            Text(["A", "B", "C"][idx])
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(showCorrect ? .white : AppTheme.textSecondary)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(showCorrect ? AntColors.green : AppTheme.card))
                                .overlay(Circle().strokeBorder(showCorrect ? AntColors.green : AppTheme.separator, lineWidth: 1.5))

                            Text(word)
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .foregroundStyle(showCorrect ? AntColors.greenDark : (showWrong ? AntColors.redDark : AppTheme.textPrimary))

                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(
                            showCorrect ? AntColors.greenSoft :
                            (showWrong ? AntColors.redSoft : AppTheme.card),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(showCorrect ? AntColors.green : (showWrong ? AntColors.red : AntColors.borderSoft), lineWidth: 1.5)
                        )
                        .shadow(color: AppTheme.inkShadow, radius: 3, y: 1)
                    }
                    .buttonStyle(BounceStyle())
                    .disabled(lockInput)
                }
            }
        }
        .padding(.horizontal, 2)
    }

    private var scoreBar: some View {
        HStack {
            Text("本局得分")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AntColors.goldDark)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < starCount ? "star.fill" : "star")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AntColors.gold)
                }
            }
            Spacer()
            Text("\(score)")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(AntColors.gold)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(AntColors.goldSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 2)
        .padding(.top, 6)
    }

    private var starCount: Int {
        switch score {
        case 90...: return 3
        case 60...: return 2
        case 30...: return 1
        default: return 0
        }
    }

    // MARK: 逻辑

    private func startNewRound() {
        questionNum = 1
        score = 0
        streak = 0
        showResult = false
        nextQuestion()
    }

    private func nextQuestion() {
        selectedIndex = nil
        seesawTilt = -9
        lockInput = false
        question = AntonymCatalog.randomQuiz(difficulty: difficulty)
    }

    private func selectChoice(_ idx: Int, correct: Bool) {
        guard !lockInput else { return }
        lockInput = true
        selectedIndex = idx

        if correct {
            streak += 1
            score += 10 + min(streak, 5) * 2
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                seesawTilt = 0 // 平衡
            }
        } else {
            streak = 0
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                seesawTilt = -16 // 倾倒
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            questionNum += 1
            if questionNum > totalQuestions {
                if score >= 30 { AntonymProgress.addStamp(); AntonymProgress.addDaily() }
                withAnimation(.easeInOut(duration: 0.3)) { showResult = true }
            } else {
                nextQuestion()
            }
        }
    }
}

// MARK: - 闯关地图

private struct AdventureMapView: View {
    let onHome: () -> Void

    @State private var currentLevel: Int = AntonymProgress.adventureLevel
    @State private var selectedWorld: Int = 0
    @State private var launchedGame: LaunchType? = nil
    @State private var pulseScale: CGFloat = 1.0

    private let totalLevels = 30
    private let levelsPerWorld = 10

    private enum LaunchType: Identifiable {
        case flip, seesaw
        var id: String { self == .flip ? "flip" : "seesaw" }
    }

    // 三个世界
    private let worlds: [(name: String, color: Color, startLevel: Int)] = [
        ("启蒙林", AntColors.green, 1),
        ("进阶山", AntColors.red, 11),
        ("挑战殿", AntColors.gold, 21)
    ]

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "闯关地图", subtitle: nil, trailing: AnyView(
                StampBadge(text: "\(AntonymProgress.stampCount)/30", compact: true)
            ), onBack: onHome)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    worldTabs
                    mapArea
                    currentLevelCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
        }
        .fullScreenCover(item: $launchedGame) { type in
            switch type {
            case .flip:
                FlipMatchGame(onHome: { launchedGame = nil })
            case .seesaw:
                SeesawQuizGame(onHome: { launchedGame = nil })
            }
        }
        .onAppear {
            selectedWorld = max(0, min(2, (currentLevel - 1) / levelsPerWorld))
        }
    }

    private var worldTabs: some View {
        HStack(spacing: 8) {
            ForEach(Array(worlds.enumerated()), id: \.offset) { i, world in
                let isOn = selectedWorld == i
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedWorld = i
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(world.name)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .tracking(0.02)
                        Text("\(world.startLevel)–\(world.startLevel + levelsPerWorld - 1)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(isOn ? .white.opacity(0.7) : AppTheme.textSecondary.opacity(0.7))
                    }
                    .foregroundStyle(isOn ? .white : AppTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(isOn ? world.color : AppTheme.card, in: Capsule())
                    .overlay(Capsule().strokeBorder(isOn ? Color.clear : AntColors.borderSoft, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 2)
    }

    private var mapArea: some View {
        let world = worlds[selectedWorld]
        let start = world.startLevel
        let end = min(start + levelsPerWorld - 1, totalLevels)
        let levels = Array(start...end)

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // 背景：宣纸感渐变 + 远山轮廓
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            world.color.opacity(0.06),
                            Color(red: 0.984, green: 0.976, blue: 0.953)
                        ], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        // 远山 / 远林 装饰轮廓
                        MapScenery(world: selectedWorld)
                            .stroke(world.color.opacity(0.12), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .padding(20)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(AntColors.borderSoft, lineWidth: 1))

                // 世界标签（左上角）
                Text(world.name)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(world.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(world.color.opacity(0.1), in: Capsule())
                    .overlay(Capsule().strokeBorder(world.color.opacity(0.2), lineWidth: 1))
                    .position(x: 64, y: 26)

                // 不规则探宝路径（手绘曲线连接节点）
                TreasurePath(world: selectedWorld)
                    .stroke(world.color.opacity(0.55),
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round, dash: [2, 6]))

                // 节点（不规则位置）
                ForEach(levels, id: \.self) { level in
                    if let pos = nodePosition(level, mapSize: geo.size) {
                        levelNode(level: level, pos: pos)
                    }
                }
            }
        }
        .frame(height: 360)
        .padding(.horizontal, 2)
        .animation(.easeInOut(duration: 0.3), value: selectedWorld)
    }

    /// 不规则探宝节点位置：预设 10 个手绘感归一化坐标，转成绝对坐标
    /// 每个世界有独特的蜿蜒走向，像真实探宝路线
    private func nodePosition(_ level: Int, mapSize: CGSize) -> CGPoint? {
        let worldStart = worlds[selectedWorld].startLevel
        let idx = level - worldStart
        guard idx >= 0, idx < levelsPerWorld else { return nil }
        let coords = TreasureCoords.coords(for: selectedWorld)
        let xPad: CGFloat = 36
        let yPad: CGFloat = 56
        let xRange: CGFloat = mapSize.width - xPad * 2
        let yRange: CGFloat = mapSize.height - yPad - 40
        let c = coords[idx]
        return CGPoint(x: xPad + c.x * xRange, y: yPad + c.y * yRange)
    }

    private func levelNode(level: Int, pos: CGPoint) -> some View {
        let isDone = level < currentLevel
        let isCurrent = level == currentLevel
        let color = worlds[selectedWorld].color
        // 节点大小随位置微变，营造远近层次
        let baseSize: CGFloat = isCurrent ? 58 : (isDone ? 46 : 42)

        return VStack(spacing: 2) {
            if isCurrent {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: baseSize + 16, height: baseSize + 16)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                pulseScale = 1.12
                            }
                        }
                    Circle()
                        .fill(color)
                        .frame(width: baseSize, height: baseSize)
                        .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 2))
                        .shadow(color: color.opacity(0.4), radius: 8, y: 4)
                    Text("\(level)")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                }
            } else if isDone {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: baseSize, height: baseSize)
                        .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1.5))
                        .shadow(color: AppTheme.inkShadow, radius: 2, y: 1)
                    Text("\(level)")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                    // 已通关盖印章
                    Text("印")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(AntColors.gold, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .rotationEffect(.degrees(-8))
                        .offset(x: baseSize/2 - 6, y: -baseSize/2 + 6)
                }
            } else {
                ZStack {
                    Circle()
                        .fill(AppTheme.card)
                        .frame(width: baseSize, height: baseSize)
                        .overlay(Circle().strokeBorder(AppTheme.separator, style: StrokeStyle(lineWidth: 2, dash: [3, 3])))
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(red: 0.76, green: 0.72, blue: 0.64))
                }
            }
        }
        .position(x: pos.x, y: pos.y)
        .onTapGesture {
            if isCurrent { launchLevel(level) }
        }
    }

    private var currentLevelCard: some View {
        let world = max(0, min(2, (currentLevel - 1) / levelsPerWorld))
        let mode = currentLevel % 2 == 0 ? "翻翻乐" : "跷跷板"
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("第 \(currentLevel) 关 · \(worlds[world].name)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.16)
                    .foregroundStyle(AntColors.red)
                Text("\(mode) · 反义词")
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("通关获得朱砂印章 ×1")
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Button {
                launchLevel(currentLevel)
            } label: {
                Text("开始挑战")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AntColors.red, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(BounceStyle())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(AntColors.borderSoft, lineWidth: 1))
        .shadow(color: AppTheme.inkShadow, radius: 3, y: 1)
        .padding(.horizontal, 2)
    }

    private func launchLevel(_ level: Int) {
        if level % 2 == 0 {
            launchedGame = .flip
        } else {
            launchedGame = .seesaw
        }
    }
}

// MARK: - 全部词汇合集（9999+ 对 · 可搜索 · 按首字分组 · 多米诺骨牌式）

private struct AntonymCollectionView: View {
    let onHome: () -> Void

    private enum Filter: String, CaseIterable {
        case all, single, double
        var label: String { self == .all ? "全部" : (self == .single ? "单字" : "双字") }
    }

    @State private var searchText: String = ""
    @State private var filter: Filter = .all
    @State private var allRaw: [AntonymPair] = []
    @State private var singleCount: Int = 0
    @State private var doubleCount: Int = 0
    @State private var filteredCache: [AntonymPair] = []
    @State private var groupsCache: [(char: String, pairs: [AntonymPair])] = []
    @State private var loadedCount: Int = 120
    @State private var showcasePairs: [AntonymPair] = []
    @State private var showcaseIdx: Int = 0
    @State private var showcaseFaceUp: Bool = true
    @State private var currentGroup: (char: String, count: Int)? = nil

    private let pageSize: Int = 120
    private let showcaseTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    private let preferredShowcase = [
        ("大", "小"), ("光明", "黑暗"), ("冷", "热"),
        ("真", "假"), ("美丽", "丑陋"), ("高兴", "悲伤")
    ]

    private var showcasePair: AntonymPair? {
        guard !showcasePairs.isEmpty else { return nil }
        return showcasePairs[showcaseIdx % showcasePairs.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "全部词汇", onBack: onHome)

            hero
                .padding(.top, 4)

            searchBar
                .padding(.horizontal, 14)
                .padding(.top, 14)

            filterBar
                .padding(.horizontal, 14)
                .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                groupList
            }
            .scrollDismissesKeyboard(.immediately)
            .overlay(alignment: .top) {
                if let g = currentGroup, searchText.isEmpty {
                    stickyCapsule(g)
                        .padding(.top, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .onAppear { load() }
        .onChange(of: searchText) { _, _ in rebuild() }
        .onChange(of: filter) { _, _ in rebuild() }
        .onReceive(showcaseTimer) { _ in cycleShowcase() }
    }

    // MARK: 加载与重建

    private func load() {
        let raw = AntonymCatalog.allRawPairs
        allRaw = raw
        singleCount = raw.filter { $0.isSingleChar }.count
        doubleCount = raw.count - singleCount
        buildShowcase(from: raw)
        rebuild()
    }

    private func rebuild() {
        let filtered = allRaw.filter { pair in
            if filter != .all {
                if filter == .single && !pair.isSingleChar { return false }
                if filter == .double && pair.isSingleChar { return false }
            }
            if !searchText.isEmpty {
                return pair.left.localizedCaseInsensitiveContains(searchText) ||
                       pair.right.localizedCaseInsensitiveContains(searchText)
            }
            return true
        }
        filteredCache = filtered
        loadedCount = searchText.isEmpty ? pageSize : filtered.count
        rebuildGroups()
    }

    private func rebuildGroups() {
        let displayed = Array(filteredCache.prefix(loadedCount))
        var dict: [String: [AntonymPair]] = [:]
        var order: [String] = []
        for p in displayed {
            let c = String(p.left.prefix(1))
            if dict[c] == nil { order.append(c) }
            dict[c, default: []].append(p)
        }
        groupsCache = order.map { (char: $0, pairs: dict[$0] ?? []) }
    }

    private func buildShowcase(from raw: [AntonymPair]) {
        let set = Set(raw.map { "\($0.left)|\($0.right)" })
        var picked: [AntonymPair] = []
        for (l, r) in preferredShowcase where set.contains("\(l)|\(r)") {
            picked.append(AntonymPair(left: l, right: r))
        }
        if picked.count < 6 {
            let extra = raw.filter { p in !picked.contains { $0.left == p.left && $0.right == p.right } }
            picked.append(contentsOf: extra.shuffled().prefix(6 - picked.count))
        }
        showcasePairs = Array(picked.prefix(6))
        showcaseIdx = 0
    }

    private func cycleShowcase() {
        guard !showcasePairs.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.45)) { showcaseFaceUp = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showcaseIdx = (showcaseIdx + 1) % showcasePairs.count
            withAnimation(.easeInOut(duration: 0.45)) { showcaseFaceUp = true }
        }
    }

    private func shuffleShowcase() {
        guard !showcasePairs.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.4)) { showcaseFaceUp = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            showcaseIdx = Int.random(in: 0..<showcasePairs.count)
            withAnimation(.easeInOut(duration: 0.4)) { showcaseFaceUp = true }
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("9999")
                            .font(.system(size: 30, weight: .heavy, design: .serif))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("+对")
                            .font(.system(size: 18, weight: .bold, design: .serif))
                            .foregroundStyle(AntColors.red)
                    }
                    Text("本地词库 · 离线可学")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .tracking(1.4)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    countPill("单字 \(singleCount)", dot: AntColors.red)
                    countPill("双字 \(doubleCount)", dot: AntColors.green)
                }
            }

            showcaseCard

            HStack(spacing: 6) {
                Text("正在展示：")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                if let p = showcasePair {
                    Text("\(p.left) — \(p.right)")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                Spacer()
                Button { shuffleShowcase() } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.2.squarepath")
                            .font(.system(size: 11, weight: .bold))
                        Text("换一对")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(AntColors.redDark)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(AntColors.redSoft, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 255/255, green: 252/255, blue: 245/255),
                    Color(red: 251/255, green: 248/255, blue: 241/255),
                    Color(red: 241/255, green: 233/255, blue: 216/255)
                ],
                startPoint: .top, endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(AntColors.borderSoft, lineWidth: 1))
        .padding(.horizontal, 14)
    }

    private func countPill(_ text: String, dot: Color) -> some View {
        HStack(spacing: 5) {
            Circle().fill(dot).frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AppTheme.card.opacity(0.6), in: Capsule())
        .overlay(Capsule().strokeBorder(AntColors.borderSoft, lineWidth: 1))
    }

    // MARK: Hero 翻卡展示

    private var showcaseCard: some View {
        let pair = showcasePair
        return ZStack {
            // 牌背
            backFace
                .opacity(showcaseFaceUp ? 0 : 1)
            // 牌面
            frontFace(pair)
                .opacity(showcaseFaceUp ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 148)
        .rotation3DEffect(
            .degrees(showcaseFaceUp ? 0 : 180),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
    }

    private var backFace: some View {
        ZStack {
            Rectangle().fill(
                RadialGradient(
                    colors: [Color(red: 74/255, green: 67/255, blue: 104/255),
                             Color(red: 50/255, green: 43/255, blue: 78/255),
                             Color(red: 34/255, green: 29/255, blue: 56/255)],
                    center: .center, startRadius: 4, endRadius: 120
                )
            )
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [AntColors.red, AntColors.redDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                    .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 2))
                    .overlay(Circle().strokeBorder(AntColors.red, lineWidth: 3).blur(radius: 0))
                Text("印")
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .foregroundStyle(Color(red: 247/255, green: 243/255, blue: 234/255))
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(AntColors.gold.opacity(0.4), lineWidth: 1))
    }

    private func frontFace(_ pair: AntonymPair?) -> some View {
        let isSingle = pair?.isSingleChar ?? true
        return ZStack {
            Rectangle().fill(
                LinearGradient(
                    colors: [
                        Color(red: 255/255, green: 252/255, blue: 245/255),
                        Color(red: 251/255, green: 248/255, blue: 241/255),
                        Color(red: 240/255, green: 231/255, blue: 212/255)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
            if let p = pair {
                Text(p.left)
                    .font(.system(size: isSingle ? 54 : 40, weight: .black, design: .serif))
                    .foregroundStyle(AntColors.red)
                    .shadow(color: AntColors.redDark.opacity(0.15), radius: 0.5, x: 1, y: 1)
            }
            VStack {
                HStack {
                    Text("第 \(String(format: "%02d", (showcaseIdx % max(showcasePairs.count,1)) + 1)) / \(String(format: "%02d", max(showcasePairs.count,1))) 对")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .tracking(1.6)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                Spacer()
            }
            if let p = pair {
                HStack(spacing: 4) {
                    Text("反义")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(AntColors.greenDark)
                        .tracking(1)
                    Text(p.right)
                        .font(.system(size: 18, weight: .black, design: .serif))
                        .foregroundStyle(AntColors.green)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 14)
                .padding(.bottom, 12)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(AntColors.borderSoft, lineWidth: 1))
    }

    // MARK: 搜索

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
            TextField("搜索反义词，如「大」「光明」", text: $searchText)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(AppTheme.card.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(AntColors.borderSoft, lineWidth: 1))
    }

    // MARK: 筛选

    private var filterBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(Filter.allCases, id: \.self) { f in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { filter = f }
                    } label: {
                        HStack(spacing: 4) {
                            Text(f.label)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            Text(filterBadgeText(for: f))
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(filter == f ? AntColors.red : AppTheme.textSecondary.opacity(0.3),
                                            in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .foregroundStyle(filter == f ? AppTheme.textPrimary : AppTheme.textSecondary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            filter == f ? AppTheme.card : Color.clear,
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                        )
                        .shadow(color: filter == f ? .black.opacity(0.08) : .clear, radius: 1, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(AppTheme.card.opacity(0.4), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(AntColors.borderSoft, lineWidth: 1))

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    loadedCount = filteredCache.count
                    rebuildGroups()
                }
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(red: 242/255, green: 237/255, blue: 226/255))
                    .frame(width: 42, height: 36)
                    .background(AppTheme.textPrimary, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func filterBadgeText(for f: Filter) -> String {
        switch f {
        case .all: return "9999+"
        case .single: return "\(singleCount)"
        case .double: return "\(doubleCount)"
        }
    }

    // MARK: 分组列表

    private var groupList: some View {
        VStack(spacing: 0) {
            ForEach(groupsCache, id: \.char) { g in
                groupSection(g)
            }
            if loadedCount < filteredCache.count {
                Color.clear
                    .frame(height: 44)
                    .onAppear {
                        DispatchQueue.main.async {
                            loadedCount = min(loadedCount + pageSize, filteredCache.count)
                            rebuildGroups()
                        }
                    }
            } else if !groupsCache.isEmpty {
                Text("已加载 \(filteredCache.count) / 9999+ 对")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 18)
            }
        }
        .padding(.top, 10)
    }

    private func groupSection(_ g: (char: String, pairs: [AntonymPair])) -> some View {
        let left = Array(g.pairs.enumerated()).filter { $0.offset % 2 == 0 }.map { $0.element }
        let right = Array(g.pairs.enumerated()).filter { $0.offset % 2 == 1 }.map { $0.element }
        return VStack(spacing: 10) {
            groupTitle(g.char, count: g.pairs.count)
            HStack(alignment: .top, spacing: 10) {
                LazyVStack(spacing: 10) {
                    ForEach(left) { DominoTile(pair: $0) }
                }
                LazyVStack(spacing: 10) {
                    ForEach(right) { DominoTile(pair: $0) }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
        .onAppear { currentGroup = (g.char, g.pairs.count) }
    }

    private func groupTitle(_ char: String, count: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(char)
                .font(.system(size: 22, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
            Rectangle()
                .fill(AntColors.borderSoft)
                .frame(height: 1)
            Text("\(count) 对")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AntColors.red)
        }
        .padding(.horizontal, 2)
        .padding(.top, 14)
        .padding(.bottom, 2)
    }

    private func stickyCapsule(_ g: (char: String, count: Int)) -> some View {
        HStack(spacing: 8) {
            Text("当前")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(1)
            Text("「\(g.char)」")
                .font(.system(size: 18, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
            Text("\(g.count) 对")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AntColors.red)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(AntColors.borderSoft, lineWidth: 1))
        .padding(.horizontal, 14)
    }
}

// MARK: 多米诺骨牌式词条 tile

private struct DominoTile: View {
    let pair: AntonymPair

    private var isSingle: Bool { pair.isSingleChar }

    var body: some View {
        if isSingle { singleBody } else { doubleBody }
    }

    private var singleBody: some View {
        HStack(spacing: 0) {
            half(pair.left, isRed: true, compact: true)
            Rectangle().fill(AntColors.borderSoft).frame(width: 1)
            half(pair.right, isRed: false, compact: true)
        }
        .frame(height: 62)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(AntColors.borderSoft, lineWidth: 1))
    }

    private var doubleBody: some View {
        VStack(spacing: 0) {
            half(pair.left, isRed: true, compact: false)
            HStack(spacing: 6) {
                Rectangle().fill(AntColors.borderSoft).frame(height: 1)
                Text("↔")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(AppTheme.textSecondary)
                Rectangle().fill(AntColors.borderSoft).frame(height: 1)
            }
            .padding(.horizontal, 8)
            .frame(height: 16)
            half(pair.right, isRed: false, compact: false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(AntColors.borderSoft, lineWidth: 1))
    }

    private func half(_ word: String, isRed: Bool, compact: Bool) -> some View {
        let bg = LinearGradient(
            colors: isRed ? [AntColors.red, AntColors.redDark] : [AntColors.green, AntColors.greenDark],
            startPoint: isRed ? .topLeading : .topTrailing,
            endPoint: isRed ? .bottomTrailing : .bottomLeading
        )
        return ZStack {
            Rectangle().fill(bg)
            Text(word)
                .font(.system(size: compact ? 22 : 20, weight: .heavy, design: .serif))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - 反义图册

private struct AntonymAlbumView: View {
    let onHome: () -> Void

    @State private var difficulty: AntonymCatalog.Difficulty = .easy
    @State private var pairs: [AntonymPair] = []

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "反义图册", subtitle: "一红一绿，天生相反", onBack: onHome)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    difficultyPicker
                    pairGrid
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
        }
        .onAppear { reload() }
    }

    private var difficultyPicker: some View {
        HStack(spacing: 8) {
            ForEach(AntonymCatalog.Difficulty.allCases, id: \.self) { d in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        difficulty = d
                        reload()
                    }
                } label: {
                    Text(d.label)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(difficulty == d ? .white : AppTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(difficulty == d ? AntColors.inkCard : AppTheme.card, in: Capsule())
                        .overlay(Capsule().strokeBorder(AntColors.borderSoft, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 2)
    }

    private var pairGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(pairs) { pair in
                AlbumCard(pair: pair)
            }
        }
        .padding(.horizontal, 2)
    }

    private func reload() {
        pairs = AntonymCatalog.albumPairs(difficulty: difficulty, limit: 80)
    }
}

private struct AlbumCard: View {
    let pair: AntonymPair

    var body: some View {
        HStack(spacing: 0) {
            // 红：左词
            Text(pair.left)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(AntColors.red)

            // 绿：右词
            Text(pair.right)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(AntColors.green)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(AntColors.borderSoft, lineWidth: 1))
    }
}

// MARK: - 庆祝浮层

private struct CelebrationOverlay: View {
    let title: String
    let sealText: String
    let subtitle: String
    let buttonTitle: String
    let onContinue: () -> Void

    @State private var appeared: Bool = false

    var body: some View {
        ZStack {
            // 暗色背景
            Color.black.opacity(0.42)
                .ignoresSafeArea()
                .onTapGesture { onContinue() }

            // 彩纸
            AntonymConfettiView()
                .allowsHitTesting(false)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 大印章
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(AntColors.red)
                        .frame(width: 128, height: 128)
                        .overlay(
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 2.5)
                                .padding(9)
                        )
                        .rotationEffect(.degrees(-8))
                        .shadow(color: AntColors.redDark.opacity(0.5), radius: 16, y: 8)

                    Text(sealText)
                        .font(.system(size: 40, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(-8))
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: appeared)

                // 标题
                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.top, 22)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut.delay(0.4), value: appeared)

                // 副标题（印章获得）
                HStack(spacing: 8) {
                    Text("印")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(AntColors.gold, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .rotationEffect(.degrees(-6))
                    Text(subtitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .padding(.leading, 12)
                .background(Capsule().fill(Color.white.opacity(0.16)).overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1)))
                .padding(.top, 8)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.55), value: appeared)

                // 继续按钮
                Button(action: onContinue) {
                    Text(buttonTitle)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .tracking(0.06)
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 44)
                        .padding(.vertical, 14)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.top, 28)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.7), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - 彩纸粒子

private struct AntonymConfettiView: View {
    private let pieces: [ConfettiPiece] = (0..<14).map { _ in ConfettiPiece.random() }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { p in
                    ConfettiPieceView(piece: p, canvas: geo.size)
                }
            }
        }
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let xRatio: CGFloat
    let yRatio: CGFloat
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let rotation: Double
    let delay: Double

    static func random() -> ConfettiPiece {
        let colors: [Color] = [AntColors.red, AntColors.green, AntColors.gold]
        return ConfettiPiece(
            xRatio: CGFloat.random(in: 0.05...0.95),
            yRatio: CGFloat.random(in: 0.08...0.85),
            color: colors.randomElement()!,
            width: CGFloat.random(in: 6...9),
            height: CGFloat.random(in: 10...13),
            rotation: Double.random(in: -40...40),
            delay: Double.random(in: 0...0.3)
        )
    }
}

private struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let canvas: CGSize
    @State private var animate: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.width, height: piece.height)
            .position(x: piece.xRatio * canvas.width, y: piece.yRatio * canvas.height)
            .rotationEffect(.degrees(piece.rotation))
            .opacity(animate ? 0 : 0.92)
            .offset(y: animate ? 60 : 0)
            .onAppear {
                withAnimation(.easeIn(duration: 2.0).delay(piece.delay)) {
                    animate = true
                }
            }
    }
}

// MARK: - 共享组件

private struct TopBar: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil
    var onBack: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.card, in: Circle())
                        .overlay(Circle().strokeBorder(AppTheme.separator, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 19, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer()
            if let trailing { trailing }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }
}

private struct StampBadge: View {
    let text: String
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Text("印")
                .font(.system(size: compact ? 10 : 11, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .frame(width: compact ? 15 : 18, height: compact ? 15 : 18)
                .background(AntColors.red, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                .rotationEffect(.degrees(-6))
            Text(text)
                .font(.system(size: compact ? 11 : 12, weight: .bold, design: .rounded))
                .foregroundStyle(AntColors.gold)
        }
        .padding(.leading, compact ? 7 : 8)
        .padding(.trailing, compact ? 9 : 11)
        .padding(.vertical, 5)
        .background(AntColors.goldSoft, in: Capsule())
    }
}

private struct BounceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - 跷跷板三角支点

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - 不规则探宝路径数据 + 形状

/// 每个世界 10 个节点的归一化坐标（x: 0~1, y: 0~1），相对地图绘制区。
/// 坐标刻意不规则，模拟手绘探宝线路的蜿蜒走向。
private enum TreasureCoords {
    /// 启蒙林：S 形蜿蜒，左下起步→右上收尾
    static let world0: [CGPoint] = [
        CGPoint(x: 0.12, y: 0.82),
        CGPoint(x: 0.28, y: 0.66),
        CGPoint(x: 0.20, y: 0.46),
        CGPoint(x: 0.38, y: 0.32),
        CGPoint(x: 0.52, y: 0.50),
        CGPoint(x: 0.66, y: 0.34),
        CGPoint(x: 0.78, y: 0.54),
        CGPoint(x: 0.72, y: 0.74),
        CGPoint(x: 0.86, y: 0.82),
        CGPoint(x: 0.92, y: 0.60)
    ]

    /// 进阶山：Z 字形翻山，起伏明显
    static let world1: [CGPoint] = [
        CGPoint(x: 0.10, y: 0.72),
        CGPoint(x: 0.26, y: 0.86),
        CGPoint(x: 0.38, y: 0.64),
        CGPoint(x: 0.30, y: 0.42),
        CGPoint(x: 0.48, y: 0.28),
        CGPoint(x: 0.62, y: 0.50),
        CGPoint(x: 0.58, y: 0.72),
        CGPoint(x: 0.74, y: 0.82),
        CGPoint(x: 0.84, y: 0.58),
        CGPoint(x: 0.90, y: 0.36)
    ]

    /// 挑战殿：螺旋收束，终点居中偏上
    static let world2: [CGPoint] = [
        CGPoint(x: 0.16, y: 0.84),
        CGPoint(x: 0.36, y: 0.80),
        CGPoint(x: 0.52, y: 0.68),
        CGPoint(x: 0.68, y: 0.78),
        CGPoint(x: 0.80, y: 0.62),
        CGPoint(x: 0.70, y: 0.46),
        CGPoint(x: 0.54, y: 0.54),
        CGPoint(x: 0.42, y: 0.38),
        CGPoint(x: 0.52, y: 0.24),
        CGPoint(x: 0.58, y: 0.42)
    ]

    static func coords(for world: Int) -> [CGPoint] {
        switch world {
        case 0:  return world0
        case 1:  return world1
        default: return world2
        }
    }
}

/// 手绘风蜿蜒路径：用二次贝塞尔曲线连接节点，控制点带随机偏移，
/// 让线条呈现真实探宝线路的曲折感。
private struct TreasurePath: Shape {
    let world: Int

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let coords = TreasureCoords.coords(for: world)
        guard coords.count >= 2 else { return p }

        let xPad: CGFloat = 36
        let yPad: CGFloat = 56
        let xRange: CGFloat = rect.width - xPad * 2
        let yRange: CGFloat = rect.height - yPad - 40

        func pt(_ c: CGPoint) -> CGPoint {
            CGPoint(x: xPad + c.x * xRange, y: yPad + c.y * yRange)
        }

        p.move(to: pt(coords[0]))
        for i in 1..<coords.count {
            let prev = pt(coords[i - 1])
            let curr = pt(coords[i])
            // 控制点：两点的中点 + 垂直方向偏移，制造曲线弯绕
            let mid = CGPoint(x: (prev.x + curr.x) / 2, y: (prev.y + curr.y) / 2)
            let dx = curr.x - prev.x
            let dy = curr.y - prev.y
            // 垂直法线
            let len = max(1, sqrt(dx * dx + dy * dy))
            let nx = -dy / len
            let ny = dx / len
            // 偏移量随世界变化，制造不同的蜿蜒感
            let offset: CGFloat = CGFloat(((i * 17 + world * 31) % 40) - 20) * 0.8
            let ctrl = CGPoint(x: mid.x + nx * offset, y: mid.y + ny * offset)
            p.addQuadCurve(to: curr, control: ctrl)
        }
        return p
    }
}

/// 远景轮廓：山形 / 林冠 / 殿塔，营造探宝地图的氛围
private struct MapScenery: Shape {
    let world: Int

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        switch world {
        case 0: // 启蒙林：底部连绵树冠
            p.move(to: CGPoint(x: 0, y: h))
            let treeCount = 6
            for i in 0...treeCount {
                let x = CGFloat(i) / CGFloat(treeCount) * w
                let peak = h - (20 + CGFloat((i * 13) % 18))
                p.addLine(to: CGPoint(x: x - w / CGFloat(treeCount) * 0.3, y: h - 6))
                p.addLine(to: CGPoint(x: x, y: peak))
                p.addLine(to: CGPoint(x: x + w / CGFloat(treeCount) * 0.3, y: h - 6))
            }
        case 1: // 进阶山：远山轮廓
            p.move(to: CGPoint(x: 0, y: h))
            p.addLine(to: CGPoint(x: 0, y: h * 0.7))
            p.addLine(to: CGPoint(x: w * 0.25, y: h * 0.4))
            p.addLine(to: CGPoint(x: w * 0.4, y: h * 0.6))
            p.addLine(to: CGPoint(x: w * 0.55, y: h * 0.35))
            p.addLine(to: CGPoint(x: w * 0.72, y: h * 0.55))
            p.addLine(to: CGPoint(x: w * 0.88, y: h * 0.42))
            p.addLine(to: CGPoint(x: w, y: h * 0.65))
            p.addLine(to: CGPoint(x: w, y: h))
        default: // 挑战殿：塔形轮廓
            p.move(to: CGPoint(x: 0, y: h))
            p.addLine(to: CGPoint(x: 0, y: h * 0.75))
            p.addLine(to: CGPoint(x: w * 0.35, y: h * 0.75))
            p.addLine(to: CGPoint(x: w * 0.4, y: h * 0.4))
            p.addLine(to: CGPoint(x: w * 0.45, y: h * 0.5))
            p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.3))
            p.addLine(to: CGPoint(x: w * 0.55, y: h * 0.5))
            p.addLine(to: CGPoint(x: w * 0.6, y: h * 0.4))
            p.addLine(to: CGPoint(x: w * 0.65, y: h * 0.75))
            p.addLine(to: CGPoint(x: w, y: h * 0.75))
            p.addLine(to: CGPoint(x: w, y: h))
        }
        p.closeSubpath()
        return p
    }
}
