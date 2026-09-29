import SwiftUI
import Combine

// MARK: - 记忆翻牌（益智 · 专注力乐园）

enum MemoryCardsDifficulty: String, CaseIterable, Identifiable {
    case qihang, jinjie, tiaozhan, dashi

    var id: String { rawValue }

    var name: String {
        switch self {
        case .qihang: return "启航"
        case .jinjie: return "进阶"
        case .tiaozhan: return "挑战"
        case .dashi: return "大师"
        }
    }

    var pairs: Int {
        switch self {
        case .qihang: return 6
        case .jinjie: return 8
        case .tiaozhan: return 10
        case .dashi: return 12
        }
    }

    var cols: Int {
        switch self {
        case .qihang, .jinjie: return 4
        case .tiaozhan: return 5
        case .dashi: return 6
        }
    }

    var addMax: Int {
        switch self {
        case .qihang: return 8
        case .jinjie: return 14
        default: return 15
        }
    }

    var cap: Int {
        switch self {
        case .qihang: return 10
        default: return 20
        }
    }

    var mulLo: Int { 2 }
    var mulHi: Int {
        switch self {
        case .tiaozhan: return 6
        case .dashi: return 9
        default: return 5
        }
    }

    var ops: [String] {
        switch self {
        case .qihang, .jinjie: return ["+", "-"]
        case .tiaozhan: return ["+", "-", "×"]
        case .dashi: return ["×", "+", "-"]
        }
    }

    /// 三项连加（挑战起）
    var allowThreeTerm: Bool { self == .tiaozhan || self == .dashi }
    /// 带括号的两步式，如 (3+4)×6（大师）
    var allowParenMul: Bool { self == .dashi }
}

enum MemoryCardsStore {
    private static func key(_ id: String) -> String { "memorycards.best.\(id)" }

    static func best(_ id: String) -> Int { UserDefaults.standard.integer(forKey: key(id)) }

    @discardableResult
    static func update(_ id: String, score: Int) -> Bool {
        let old = best(id)
        if score <= old { return false }
        UserDefaults.standard.set(score, forKey: key(id))
        return true
    }

    static func hasAny() -> Bool {
        MemoryCardsDifficulty.allCases.contains { best($0.rawValue) > 0 }
    }
}

private struct MemoryCard: Hashable {
    let kind: Kind          // expr / result
    let text: String
    let value: Int

    enum Kind { case expr, result }
}

struct MemoryCardsView: View {
    let onExit: () -> Void

    @State private var diff: MemoryCardsDifficulty = .qihang
    @State private var cards: [MemoryCard] = []
    @State private var faceUp: Set<Int> = []
    @State private var matched: Set<Int> = []
    @State private var wrong: Set<Int> = []
    @State private var moves = 0
    @State private var lock = false
    @State private var solved = false
    @State private var startDate = Date()
    @State private var elapsed = 0
    @State private var showHelp = false
    @State private var toast: String? = nil
    @State private var flipTask: Task<Void, Never>? = nil
    @Namespace private var diffNS

    private let accent = Color(red: 0.58, green: 0.27, blue: 0.62)
    private let accentSoft = Color(red: 0.96, green: 0.90, blue: 0.97)

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            FieldBackground()
            decorations

            VStack(spacing: 0) {
                navBar
                difficultyBar
                statBar
                GeometryReader { geo in
                    boardArea(geo.size)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                footArea
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let toast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20).padding(.vertical, 11)
                        .background(Capsule().fill(AppTheme.fieldInk.opacity(0.9)))
                        .padding(.bottom, 96)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .sheet(isPresented: $showHelp) { helpSheet }
        .onAppear { newGame() }
        .onDisappear { flipTask?.cancel() }
        .onReceive(ticker) { _ in
            if !solved { elapsed = max(0, Int(Date().timeIntervalSince(startDate))) }
        }
    }

    // MARK: 顶栏

    private var navBar: some View {
        HStack(spacing: 8) {
            GracefulBackButton(action: onExit)
            Text("记忆翻牌")
                .font(.system(size: 16, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
                .frame(maxWidth: .infinity)
            HStack(spacing: 8) {
                bestChip
                helpButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 2)
    }

    private var bestChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(AppTheme.fieldGold)
            VStack(alignment: .leading, spacing: 0) {
                Text("最高分").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
                Text("\(MemoryCardsStore.best(diff.rawValue))")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.fieldInk)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(Color.white.opacity(0.9))
                .overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 1.5))
        )
    }

    private var helpButton: some View {
        Button { showHelp = true } label: {
            Text("?")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(accent)
                .frame(width: 34, height: 34)
                .background(Circle().fill(accentSoft))
                .overlay(Circle().strokeBorder(accent.opacity(0.35), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: 难度

    private var difficultyBar: some View {
        HStack(spacing: 4) {
            ForEach(MemoryCardsDifficulty.allCases) { d in
                let on = d == diff
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { diff = d }
                    newGame()
                } label: {
                    Text(d.name)
                        .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(on ? .white : AppTheme.fieldOliveDeep)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if on {
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(LinearGradient(colors: [accent, accent.opacity(0.82)],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .shadow(color: accent.opacity(0.35), radius: 6, y: 3)
                                    .matchedGeometryEffect(id: "diffPill", in: diffNS)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Color.white.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.18), lineWidth: 1.5)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.06), radius: 5, y: 2)
        )
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    // MARK: 状态

    private var statBar: some View {
        HStack(spacing: 12) {
            statChip("配对", "\(matched.count / 2)/\(diff.pairs)")
            statChip("步数", "\(moves)")
            statChip("用时", "\(elapsed)s")
        }
        .padding(.top, 14)
    }

    private func statChip(_ k: String, _ v: String) -> some View {
        HStack(spacing: 5) {
            Text(k).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
            Text(v).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(accent)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(
            Capsule().fill(Color.white.opacity(0.9))
                .overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.2), lineWidth: 1.5))
        )
    }

    // MARK: 棋盘

    private func boardArea(_ size: CGSize) -> some View {
        let cols = diff.cols
        let rows = max(1, Int(ceil(Double(max(cards.count, 1)) / Double(cols))))
        let spacing: CGFloat = 10
        let availW = size.width - 36
        let availH = size.height - 8
        let wByWidth = (availW - spacing * CGFloat(cols - 1)) / CGFloat(cols)
        let hByHeight = (availH - spacing * CGFloat(rows - 1)) / CGFloat(rows)
        let cardW = max(24, min(wByWidth, hByHeight / 1.06))
        let cardH = cardW * 1.06
        return LazyVGrid(columns: Array(repeating: GridItem(.fixed(cardW), spacing: spacing), count: cols), spacing: spacing) {
            ForEach(0..<cards.count, id: \.self) { i in
                cardView(i, w: cardW, h: cardH)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cardView(_ i: Int, w: CGFloat, h: CGFloat) -> some View {
        let card = cards[i]
        let up = faceUp.contains(i) || matched.contains(i)
        let isMatched = matched.contains(i)
        let isWrong = wrong.contains(i)
        let fontSize = max(11, min(34, w * 0.34))
        return ZStack {
            cardBack(w: w)
                .opacity(up ? 0 : 1)
            cardFront(card, matched: isMatched, wrong: isWrong, fontSize: fontSize)
                .opacity(up ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(width: w, height: h)
        .rotation3DEffect(.degrees(up ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: up)
        .contentShape(Rectangle())
        .onTapGesture { tapCard(i) }
    }

    private func cardBack(w: CGFloat) -> some View {
        let ring = max(26, min(46, w * 0.44))
        let radius = max(8, min(14, w * 0.11))
        return ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.75, green: 0.45, blue: 0.83),
                                              Color(red: 0.58, green: 0.29, blue: 0.66),
                                              Color(red: 0.42, green: 0.19, blue: 0.50)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: max(6, radius - 4), style: .continuous)
                .strokeBorder(Color.white.opacity(0.30), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .padding(max(5, w * 0.09))
            Text("?")
                .font(.system(size: ring * 0.6, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.94))
                .frame(width: ring, height: ring)
                .background(Circle().fill(Color.white.opacity(0.15)))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.45), lineWidth: 2))
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        }
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 2)
        )
        .shadow(color: Color(red: 0.42, green: 0.19, blue: 0.50).opacity(0.32), radius: 6, y: 3)
    }

    private func cardFront(_ card: MemoryCard, matched: Bool, wrong: Bool, fontSize: CGFloat) -> some View {
        let borderColor: Color = matched ? Color(red: 0.18, green: 0.69, blue: 0.43)
                                : wrong ? Color(red: 0.86, green: 0.31, blue: 0.24)
                                : Color(red: 0.87, green: 0.84, blue: 0.76)
        let radius: CGFloat = max(8, min(14, fontSize * 0.62))
        let pip: CGFloat = max(5, min(8, fontSize * 0.3))
        return ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.99, blue: 0.96),
                                              Color(red: 0.96, green: 0.94, blue: 0.89)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: max(6, radius - 4), style: .continuous)
                .strokeBorder(Color(red: 0.72, green: 0.66, blue: 0.52).opacity(0.35), lineWidth: 1.5)
                .padding(max(5, fontSize * 0.34))
            Text(card.text)
                .font(.system(size: fontSize, weight: .heavy, design: .serif))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .padding(.horizontal, 4)
                .foregroundStyle(card.kind == .result ? accent : AppTheme.fieldInk)
            VStack {
                HStack {
                    Circle()
                        .fill(card.kind == .result ? AppTheme.fieldGold.opacity(0.75) : accent.opacity(0.45))
                        .frame(width: pip, height: pip)
                    Spacer()
                }
                Spacer()
            }
            .padding(max(7, fontSize * 0.5))
        }
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(borderColor, lineWidth: matched || wrong ? 3 : 2)
        )
        .shadow(color: .black.opacity(0.14), radius: 6, y: 3)
    }

    // MARK: 底部

    private var footArea: some View {
        VStack(spacing: 12) {
            Text(statusText)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(solved ? Color(red: 0.20, green: 0.62, blue: 0.38) : AppTheme.fieldOliveDeep)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)

            Button { newGame() } label: {
                Text("重开")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        Capsule().fill(LinearGradient(colors: [accent, accent.opacity(0.82)],
                                                      startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .shadow(color: accent.opacity(0.3), radius: 7, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 18)
    }

    private var statusText: String {
        if solved { return "🎉 全部配对完成！" }
        if lock { return "不相等，记住位置再试" }
        return "翻开两张：算式和结果相等就配对"
    }

    // MARK: 逻辑

    private func newGame() {
        flipTask?.cancel()
        cards = Self.makeCards(diff)
        faceUp = []
        matched = []
        wrong = []
        moves = 0
        lock = false
        solved = false
        startDate = Date()
        elapsed = 0
    }

    private func tapCard(_ i: Int) {
        guard !solved, !lock, !faceUp.contains(i), !matched.contains(i) else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { _ = faceUp.insert(i) }
        guard faceUp.count == 2 else { return }

        moves += 1
        let arr = Array(faceUp)
        let a = cards[arr[0]], b = cards[arr[1]]
        if a.value == b.value {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                matched.formUnion(arr)
                faceUp.removeAll()
            }
            if matched.count == cards.count { win() }
        } else {
            lock = true
            wrong = Set(arr)
            flipTask?.cancel()
            flipTask = Task {
                try? await Task.sleep(nanoseconds: 780_000_000)
                if Task.isCancelled { return }
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { faceUp.removeAll() }
                    wrong = []
                    lock = false
                }
            }
        }
    }

    private func win() {
        solved = true
        let extra = max(0, moves - diff.pairs)
        let score = max(1, diff.pairs * 120 - extra * 18 - elapsed * 2)
        MemoryCardsStore.update(diff.rawValue, score: score)
        toast = "完成！\(moves) 步 · 得分 \(score)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            if toast?.hasPrefix("完成") == true { toast = nil }
        }
    }

    // MARK: 出题

    private static func makeCards(_ d: MemoryCardsDifficulty) -> [MemoryCard] {
        var used = Set<Int>()
        var pairs: [(text: String, value: Int)] = []
        var guardCount = 0
        while pairs.count < d.pairs && guardCount < 20000 {
            guardCount += 1
            guard let (text, val) = makeOne(d) else { continue }
            if val < 1 || val > 999 || used.contains(val) { continue }
            used.insert(val)
            pairs.append((text, val))
        }
        var out: [MemoryCard] = []
        for p in pairs {
            out.append(MemoryCard(kind: .expr, text: p.text, value: p.value))
            out.append(MemoryCard(kind: .result, text: "\(p.value)", value: p.value))
        }
        return out.shuffled()
    }

    /// 生成一条算式（按难度选择题型：单项 / 三项连加 / 带括号两步）
    private static func makeOne(_ d: MemoryCardsDifficulty) -> (String, Int)? {
        var forms = ["single"]
        if d.allowThreeTerm { forms.append("three") }
        if d.allowParenMul { forms.append("paren") }
        switch forms.randomElement() ?? "single" {
        case "three":
            let a = Int.random(in: 1...8), b = Int.random(in: 1...8), c = Int.random(in: 1...8)
            let v = a + b + c
            guard v <= 20 else { return nil }
            return ("\(a)+\(b)+\(c)", v)

        case "paren":
            let m = Int.random(in: 2...6)
            if Bool.random() {
                let a = Int.random(in: 1...9)
                let b = Int.random(in: 1...max(1, 12 - a))   // a+b ≤ 12
                let s = a + b
                return ("(\(a)+\(b))×\(m)", s * m)
            } else {
                let a = Int.random(in: 5...15)
                let b = Int.random(in: 1...(a - 1))
                let s = a - b
                guard s <= 12 else { return nil }
                return ("(\(a)−\(b))×\(m)", s * m)
            }

        default:
            let op = d.ops.randomElement() ?? "+"
            if op == "×" {
                let a = Int.random(in: d.mulLo...d.mulHi)
                let b = Int.random(in: d.mulLo...d.mulHi)
                return ("\(a)×\(b)", a * b)
            } else if op == "+" {
                let a = Int.random(in: 1...d.addMax)
                let b = Int.random(in: 1...d.addMax)
                let v = a + b
                guard v <= d.cap else { return nil }
                return ("\(a)+\(b)", v)
            } else {
                let a = Int.random(in: 2...d.addMax)
                let b = Int.random(in: 1...(a - 1))
                let v = a - b
                guard v >= 1 && v <= d.cap else { return nil }
                return ("\(a)−\(b)", v)
            }
        }
    }

    // MARK: 背景点缀

    private var decorations: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color(red: 1, green: 0.92, blue: 0.55), Color(red: 1, green: 0.78, blue: 0.30)],
                                         center: .center, startRadius: 0, endRadius: 32))
                    .frame(width: 62, height: 62).opacity(0.5)
                    .position(x: w * 0.85, y: h * 0.08)

                cloud.opacity(0.55).position(x: w * 0.16, y: h * 0.09)
                cloud.opacity(0.4).scaleEffect(0.7).position(x: w * 0.62, y: h * 0.04)

                ForEach(0..<10, id: \.self) { i in
                    Text("✨").font(.system(size: i % 3 == 0 ? 15 : 12)).opacity(0.28)
                        .position(x: w * Double((i * 67) % 100) / 100,
                                  y: h * Double((i * 43) % 90) / 100)
                }
                ForEach(0..<6, id: \.self) { i in
                    Text(i % 2 == 0 ? "🌸" : "🌿").font(.system(size: i % 3 == 0 ? 20 : 16)).opacity(0.38)
                        .position(x: w * Double(i + 1) / 7, y: h - 28 - Double((i * 13) % 16))
                }
            }
            .allowsHitTesting(false)
        }
    }

    private var cloud: some View {
        HStack(spacing: -6) {
            Circle().fill(Color.white.opacity(0.65)).frame(width: 28, height: 28)
            Circle().fill(Color.white.opacity(0.55)).frame(width: 36, height: 36)
            Circle().fill(Color.white.opacity(0.5)).frame(width: 24, height: 24)
        }
    }

    // MARK: 玩法弹窗

    private var helpSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Text("?").font(.system(size: 24, weight: .black))
                        .foregroundStyle(accent)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(accentSoft))
                    Text("记忆翻牌怎么玩")
                        .font(.system(size: 22, weight: .black, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                }
                VStack(alignment: .leading, spacing: 12) {
                    helpStep("1", "目标：配对所有等值卡片。")
                    helpStep("2", "每次翻开两张卡片。")
                    helpStep("3", "表达式和结果相等就会保留。")
                    helpStep("4", "记住位置，也要快速心算表达式。")
                }
                Button { showHelp = false } label: {
                    Text("知道了")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Capsule().fill(accent))
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(24)
        }
        .presentationDetents([.medium])
    }

    private func helpStep(_ n: String, _ t: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n).font(.system(size: 15, weight: .black, design: .rounded)).foregroundStyle(accent)
            Text(t).font(.system(size: 15.5, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
