import SwiftUI
import Combine

// MARK: - 人民币初步（探索 · 学问营地）

enum RmbQType { case count, convert, total2, compare, pay, change }

enum MoneySymbol: String, CaseIterable, Identifiable {
    case c1, c5, c10, n1, n5, n10, n20, n50

    var id: String { rawValue }

    /// 面额，单位：角
    var value: Int {
        switch self {
        case .c1: return 1
        case .c5: return 5
        case .c10: return 10
        case .n1: return 10
        case .n5: return 50
        case .n10: return 100
        case .n20: return 200
        case .n50: return 500
        }
    }

    var isCoin: Bool { self == .c1 || self == .c5 || self == .c10 }
    var isNote: Bool { !isCoin }

    var label: String {
        switch self {
        case .c1: return "1角"
        case .c5: return "5角"
        case .c10, .n1: return "1元"
        case .n5: return "5元"
        case .n10: return "10元"
        case .n20: return "20元"
        case .n50: return "50元"
        }
    }

    var coinSilver: Bool { self == .c1 }

    var noteColors: (Color, Color) {
        switch self {
        case .n1: return (Color(red: 0.53, green: 0.74, blue: 0.52), Color(red: 0.31, green: 0.56, blue: 0.32))
        case .n5: return (Color(red: 0.68, green: 0.56, blue: 0.86), Color(red: 0.44, green: 0.34, blue: 0.70))
        case .n10: return (Color(red: 0.45, green: 0.67, blue: 0.87), Color(red: 0.24, green: 0.42, blue: 0.68))
        case .n20: return (Color(red: 0.86, green: 0.66, blue: 0.42), Color(red: 0.66, green: 0.45, blue: 0.22))
        case .n50: return (Color(red: 0.39, green: 0.72, blue: 0.63), Color(red: 0.16, green: 0.53, blue: 0.44))
        default: return (.gray, .gray)
        }
    }
}

enum RmbDifficulty: String, CaseIterable, Identifiable {
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

    var types: [RmbQType] {
        switch self {
        case .qihang: return [.count, .convert]
        case .jinjie: return [.count, .convert, .total2, .compare]
        case .tiaozhan: return [.count, .total2, .pay, .change]
        case .dashi: return [.pay, .change, .total2, .convert]
        }
    }

    /// 金额上限（角）
    var cap: Int {
        switch self {
        case .qihang: return 50
        case .jinjie, .tiaozhan: return 200
        case .dashi: return 500
        }
    }

    var pool: [MoneySymbol] {
        switch self {
        case .qihang: return [.c1, .c5, .c10]
        case .jinjie: return [.c1, .c5, .c10, .n1, .n5]
        case .tiaozhan: return [.c1, .c5, .c10, .n1, .n5, .n10]
        case .dashi: return [.c1, .c5, .c10, .n1, .n5, .n10, .n20, .n50]
        }
    }

    var wallet: [MoneySymbol] {
        switch self {
        case .qihang: return [.c1, .c5, .c10]
        case .jinjie: return [.c1, .c5, .c10, .n1, .n5]
        case .tiaozhan: return [.c1, .c5, .c10, .n1, .n5, .n10]
        case .dashi: return [.c1, .c5, .c10, .n1, .n5, .n10, .n20, .n50]
        }
    }
}

enum RmbStore {
    private static func key(_ id: String) -> String { "rmb.best.\(id)" }
    static func best(_ id: String) -> Int { UserDefaults.standard.integer(forKey: key(id)) }
    @discardableResult
    static func update(_ id: String, score: Int) -> Bool {
        let old = best(id)
        if score <= old { return false }
        UserDefaults.standard.set(score, forKey: key(id))
        return true
    }
    static func hasAny() -> Bool { RmbDifficulty.allCases.contains { best($0.rawValue) > 0 } }
}

struct RmbBasicsView: View {
    @State private var diff: RmbDifficulty = .qihang
    @State private var qIndex = 0
    @State private var okCount = 0
    @State private var answered = false
    @State private var startDate = Date()
    @State private var elapsed = 0
    @State private var showHelp = false
    @State private var showResult = false
    @State private var nextVisible = false
    @State private var fbText = ""
    @State private var fbOK = false
    @Namespace private var diffNS

    // 当前题
    @State private var kind: RmbQType = .count
    @State private var askText = ""
    @State private var options: [String] = []
    @State private var correctText = ""
    @State private var picked: String? = nil
    @State private var countItems: [MoneySymbol] = []
    @State private var itemA: (emoji: String, price: Int) = ("✏️", 35)
    @State private var itemB: (emoji: String, price: Int) = ("📒", 20)
    @State private var paid: [MoneySymbol] = []
    @State private var payTarget = 0

    private let accent = Color(red: 0.75, green: 0.54, blue: 0.18)
    private let accentSoft = Color(red: 0.98, green: 0.95, blue: 0.86)
    private let total = 8
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let perRow = 4

    var body: some View {
        ZStack {
            FieldBackground()
            decorations

            VStack(spacing: 0) {
                navBar
                difficultyBar
                statBar
                stage
                footArea
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showResult { resultOverlay }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .sheet(isPresented: $showHelp) { helpSheet }
        .onAppear { newGame() }
        .onReceive(ticker) { _ in
            if !showResult { elapsed = max(0, Int(Date().timeIntervalSince(startDate))) }
        }
    }

    // MARK: 顶栏

    private var navBar: some View {
        HStack(spacing: 8) {
            GracefulBackButton()
            VStack(alignment: .leading, spacing: 0) {
                Text("人民币初步").font(.system(size: 16, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                Text("数钱 · 付钱 · 找零").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
            }
            Spacer()
            HStack(spacing: 8) { bestChip; helpButton }
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 2)
    }

    private var bestChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(AppTheme.fieldGold)
            VStack(alignment: .leading, spacing: 0) {
                Text("最高分").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
                Text("\(RmbStore.best(diff.rawValue))").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldInk)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Capsule().fill(Color.white.opacity(0.9))
            .overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 1.5)))
    }

    private var helpButton: some View {
        Button { showHelp = true } label: {
            Text("?").font(.system(size: 15, weight: .black)).foregroundStyle(accent)
                .frame(width: 34, height: 34)
                .background(Circle().fill(accentSoft))
                .overlay(Circle().strokeBorder(accent.opacity(0.35), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private var difficultyBar: some View {
        HStack(spacing: 4) {
            ForEach(RmbDifficulty.allCases) { d in
                let on = d == diff
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { diff = d }
                    newGame()
                } label: {
                    Text(d.name)
                        .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(on ? .white : AppTheme.fieldOliveDeep)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background {
                            if on {
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(LinearGradient(colors: [accent, accent.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .shadow(color: accent.opacity(0.35), radius: 6, y: 3)
                                    .matchedGeometryEffect(id: "rmbPill", in: diffNS)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 17, style: .continuous)
            .fill(Color.white.opacity(0.55))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder(AppTheme.fieldOlive.opacity(0.18), lineWidth: 1.5)))
        .padding(.horizontal, 16).padding(.top, 8)
    }

    private var statBar: some View {
        HStack(spacing: 12) {
            statChip("第", "\(min(qIndex + 1, total))/\(total)")
            statChip("答对", "\(okCount)")
            statChip("用时", "\(elapsed)s")
        }
        .padding(.top, 12)
    }

    private func statChip(_ k: String, _ v: String) -> some View {
        HStack(spacing: 5) {
            Text(k).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
            Text(v).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(accent)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.9))
            .overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.2), lineWidth: 1.5)))
    }

    // MARK: 题面

    private var stage: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Spacer(minLength: 0)
                    askCard
                    questionContent
                    answerSection
                    Spacer(minLength: 0)
                }
                .frame(minHeight: geo.size.height)
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
            }
        }
    }

    private var askCard: some View {
        Text(askText)
            .font(.system(size: 15, weight: .heavy, design: .serif))
            .foregroundStyle(AppTheme.fieldInk)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(AppTheme.fieldOlive.opacity(0.22), lineWidth: 2)))
    }

    @ViewBuilder
    private var questionContent: some View {
        switch kind {
        case .count:
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: perRow), spacing: 14) {
                ForEach(Array(countItems.enumerated()), id: \.offset) { _, sym in
                    moneyView(sym)
                }
            }
        case .total2:
            HStack(spacing: 14) {
                itemCard(itemA)
                Text("+").font(.system(size: 22, weight: .black)).foregroundStyle(AppTheme.fieldMoss)
                itemCard(itemB)
            }
        case .pay:
            payContent
        default:
            EmptyView()
        }
    }

    private func itemCard(_ it: (emoji: String, price: Int)) -> some View {
        VStack(spacing: 6) {
            Text(it.emoji).font(.system(size: 40))
            Text(fmt(it.price))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(accent))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.92))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 2)))
    }

    @ViewBuilder
    private var answerSection: some View {
        if kind == .pay {
            Button { confirmPay() } label: {
                Text("确定")
                    .font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                    .frame(width: 200, height: 52)
                    .background(Capsule().fill(LinearGradient(colors: [accent, accent.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    .shadow(color: accent.opacity(0.35), radius: 8, y: 4)
            }
            .buttonStyle(.plain).disabled(answered)
        } else {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(options, id: \.self) { opt in optionButton(opt) }
            }
        }
    }

    private func optionButton(_ opt: String) -> some View {
        let isRight = answered && opt == correctText
        let isWrong = answered && picked == opt && opt != correctText
        return Button { choose(opt) } label: {
            Text(opt)
                .font(.system(size: 18, weight: .heavy, design: .serif))
                .foregroundStyle(isRight || isWrong ? .white : AppTheme.fieldInk)
                .frame(maxWidth: .infinity).frame(minHeight: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isRight ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.49, green: 0.83, blue: 0.63), Color(red: 0.30, green: 0.69, blue: 0.49)], startPoint: .topLeading, endPoint: .bottomTrailing))
                              : isWrong ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.93, green: 0.54, blue: 0.45), Color(red: 0.80, green: 0.30, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing))
                              : AnyShapeStyle(Color.white.opacity(0.92)))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder((isRight || isWrong) ? Color.clear : AppTheme.fieldOlive.opacity(0.28), lineWidth: 2))
                )
        }
        .buttonStyle(.plain).disabled(answered)
    }

    // MARK: 付款区（重排：收银台 → 合计 → 钱包）

    private var payContent: some View {
        VStack(spacing: 14) {
            // 收银台
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(accent.opacity(0.55), style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                if paid.isEmpty {
                    Text("点下面的钱，放进收银台")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: perRow), spacing: 12) {
                        ForEach(Array(paid.enumerated()), id: \.offset) { idx, sym in
                            moneyView(sym)
                                .onTapGesture { if !answered { paid.remove(at: idx) } }
                        }
                    }
                    .padding(14)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 104)

            // 合计
            HStack(spacing: 6) {
                Text("合计").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldOliveDeep)
                Text(fmt(paid.reduce(0) { $0 + $1.value }))
                    .font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(accent)
            }
            .padding(.horizontal, 16).padding(.vertical, 7)
            .background(Capsule().fill(accentSoft)
                .overlay(Capsule().strokeBorder(accent.opacity(0.35), lineWidth: 1.5)))

            // 钱包
            VStack(alignment: .leading, spacing: 8) {
                Text("钱包").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: perRow), spacing: 12) {
                    ForEach(diff.wallet) { sym in
                        moneyView(sym)
                            .contentShape(Rectangle())
                            .onTapGesture { if !answered { paid.append(sym) } }
                    }
                }
            }
        }
    }

    // MARK: 底部

    private var footArea: some View {
        VStack(spacing: 10) {
            if !fbText.isEmpty {
                Text(fbText)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(fbOK ? Color(red: 0.18, green: 0.56, blue: 0.32) : Color(red: 0.78, green: 0.25, blue: 0.17))
                    .multilineTextAlignment(.center)
            }
            if nextVisible {
                Button { next() } label: {
                    Text(qIndex >= total - 1 ? "看看成绩" : "下一题")
                        .font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                        .frame(width: 200, height: 48)
                        .background(Capsule().fill(LinearGradient(colors: [Color(red: 0.49, green: 0.83, blue: 0.63), Color(red: 0.30, green: 0.69, blue: 0.49)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                        .shadow(color: Color(red: 0.30, green: 0.69, blue: 0.49).opacity(0.35), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 72)
        .padding(.horizontal, 20)
    }

    // MARK: 逻辑

    private func newGame() {
        qIndex = 0; okCount = 0
        startDate = Date(); elapsed = 0
        showResult = false
        nextQuestion()
    }

    private func nextQuestion() {
        answered = false; picked = nil; nextVisible = false
        fbText = ""; fbOK = false; paid = []
        kind = diff.types.randomElement() ?? .count
        switch kind {
        case .count: buildCount()
        case .convert: buildConvert()
        case .total2: buildTotal2()
        case .compare: buildCompare()
        case .pay: buildPay()
        case .change: buildChange()
        }
    }

    private func buildCount() {
        var items: [MoneySymbol] = []
        var sum = 0
        for _ in 0..<4 {
            let s = diff.pool.randomElement()!
            items.append(s); sum += s.value
        }
        if sum > diff.cap {   // 超上限则退化为 1 元以内的组合
            items = [.c5, .c10, .c5, .c10]
            sum = items.reduce(0) { $0 + $1.value }
        }
        countItems = items
        correctText = fmt(sum)
        askText = "这些钱一共多少钱？"
        options = moneyOptions(sum)
    }

    private func buildConvert() {
        let forms = (diff == .qihang) ? [0, 1, 2] : [0, 1, 2, 3]
        switch forms.randomElement()! {
        case 0:
            let y = Int.random(in: 1...9)
            correctText = "\(y * 10)角"; askText = "\(y)元 = ?角"
            options = uniq([ "\(y * 10 + 1)角", "\(y * 10 - 1)角", "\(y * 10 + 10)角" ])
        case 1:
            let j = Int.random(in: 1...9) * 10
            correctText = "\(j / 10)元"; askText = "\(j)角 = ?元"
            options = uniq([ "\(j / 10 + 1)元", "\(max(1, j / 10 - 1))元", "\(j / 10 + 10)元" ])
        case 2:
            let y = Int.random(in: 1...5), j = Int.random(in: 1...9)
            let c = y * 10 + j
            correctText = "\(c)角"; askText = "\(y)元\(j)角 = ?角"
            options = uniq([ "\(c + 1)角", "\(c - 1)角", "\(c + 10)角" ])
        default:
            let v = [5, 10, 20, 50].randomElement()!
            correctText = "\(v)张"; askText = "1 张 \(v) 元，可以换 ? 张 1 元"
            options = uniq([ "\(v + 1)张", "\(max(1, v - 1))张", "\(v + 5)张" ])
        }
    }

    private func buildTotal2() {
        let pool: [(String, Int)] = [("✏️", 35), ("📒", 20), ("🧸", 45), ("🍬", 15), ("🍎", 25), ("🎈", 30), ("📕", 60), ("🖍️", 40)]
        var a = pool.randomElement()!, b = pool.randomElement()!
        var guardCount = 0
        while (a.1 == b.1) && guardCount < 10 { b = pool.randomElement()!; guardCount += 1 }
        if diff.cap <= 50 { a = ("✏️", 35); b = ("🍬", 15) }
        itemA = a; itemB = b
        let sum = a.1 + b.1
        correctText = fmt(sum)
        askText = "买这两样东西，一共多少钱？"
        options = moneyOptions(sum)
    }

    private func buildCompare() {
        // 四个金额里挑出最贵的（元/角混合，练比较）
        var vals: [Int] = []
        var guardCount = 0
        while vals.count < 4 && guardCount < 60 {
            guardCount += 1
            let v = Int.random(in: 5...min(diff.cap, 500))
            if !vals.contains(v) { vals.append(v) }
        }
        while vals.count < 4 { vals.append(vals.count * 10 + 5) }
        let most = vals.max() ?? 10
        correctText = fmt(most)
        askText = "哪个金额最大？"
        options = vals.map { fmt($0) }.shuffled()
    }

    private func buildPay() {
        let arr = diff == .dashi ? [260, 315, 408, 550, 180, 760, 95, 240] : [35, 50, 85, 120, 18, 66, 95]
        payTarget = arr.randomElement()!
        askText = "请付 \(fmt(payTarget))（点钱包里的钱凑一凑）"
        options = []
        paid = []
    }

    private func buildChange() {
        let pays = [1000, 2000, 5000]
        let pay = pays.randomElement()!
        var price = pay - Int.random(in: 1...8) * 10 - Int.random(in: 1...9)
        if price < 10 { price = 10 }
        if price > diff.cap && diff.cap < pay { price = diff.cap }
        let change = pay - price
        correctText = fmt(change)
        askText = "带了 \(fmt(pay))，买了 \(fmt(price)) 的东西，找回多少？"
        options = uniq([fmt(change + 10), fmt(max(1, change - 10)), fmt(change + 5)])
    }

    private func moneyOptions(_ v: Int) -> [String] {
        uniq([fmt(v + 1), fmt(v + 10), fmt(max(1, v - 1)), fmt(v + 5)])
    }

    /// 选项：保证含正确答案且 4 个互异
    private func uniq(_ cands: [String]) -> [String] {
        var out: [String] = [correctText]
        for c in cands where out.count < 4 { if !out.contains(c) { out.append(c) } }
        return out.shuffled()
    }

    private func fmt(_ v: Int) -> String {
        if v < 10 { return "\(v)角" }
        let y = v / 10, r = v % 10
        return r == 0 ? "\(y)元" : "\(y)元\(r)角"
    }

    private func choose(_ opt: String) {
        guard !answered else { return }
        answered = true; picked = opt
        if opt == correctText { okCount += 1; fbText = "✓ 答对了！"; fbOK = true }
        else { fbText = "✗ 正确答案：\(correctText)"; fbOK = false }
        nextVisible = true
    }

    private func confirmPay() {
        guard !answered else { return }
        answered = true
        let sum = paid.reduce(0) { $0 + $1.value }
        if sum == payTarget { okCount += 1; fbText = "✓ 付对啦，正好！"; fbOK = true }
        else { fbText = "✗ 你付了 \(fmt(sum))，应该是 \(fmt(payTarget))"; fbOK = false }
        nextVisible = true
    }

    private func next() {
        qIndex += 1
        if qIndex >= total { finish() } else { nextQuestion() }
    }

    private func finish() {
        let score = max(1, okCount * 100 + max(0, 120 - elapsed) * 2)
        RmbStore.update(diff.rawValue, score: score)
        showResult = true
    }

    // MARK: 组件

    private func moneyView(_ sym: MoneySymbol) -> some View {
        Group { if sym.isCoin { coinView(sym) } else { noteView(sym) } }
    }

    private func coinView(_ sym: MoneySymbol) -> some View {
        let gold = !sym.coinSilver
        return Text(sym.label)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(gold ? Color(red: 0.42, green: 0.33, blue: 0.09) : Color(red: 0.29, green: 0.33, blue: 0.38))
            .frame(width: 54, height: 54)
            .background(
                Circle().fill(
                    RadialGradient(colors: gold
                                   ? [Color(red: 1.0, green: 0.96, blue: 0.78), Color(red: 0.91, green: 0.78, blue: 0.40), Color(red: 0.78, green: 0.63, blue: 0.23)]
                                   : [Color(red: 0.99, green: 1.0, blue: 1.0), Color(red: 0.85, green: 0.88, blue: 0.90), Color(red: 0.70, green: 0.74, blue: 0.78)],
                                   center: .init(x: 0.35, y: 0.3), startRadius: 2, endRadius: 34)
                )
            )
            .overlay(Circle().strokeBorder(gold ? Color(red: 0.86, green: 0.73, blue: 0.33) : Color(red: 0.78, green: 0.82, blue: 0.85), lineWidth: 3))
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }

    private func noteView(_ sym: MoneySymbol) -> some View {
        let c = sym.noteColors
        return Text(sym.label)
            .font(.system(size: 14, weight: .heavy, design: .serif))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
            .frame(width: 92, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(LinearGradient(colors: [c.0, c.1], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .padding(6))
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(Color.white.opacity(0.35), lineWidth: 2))
            )
            .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
    }

    // MARK: 结算

    private var resultOverlay: some View {
        let acc = Int((Double(okCount) / Double(total) * 100).rounded())
        let score = max(1, okCount * 100 + max(0, 120 - elapsed) * 2)
        return ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 14) {
                ZStack {
                    Circle().stroke(AppTheme.fieldOlive.opacity(0.15), lineWidth: 12)
                    Circle().trim(from: 0, to: CGFloat(acc) / 100)
                        .stroke(LinearGradient(colors: [accent.opacity(0.75), accent], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(acc)%").font(.system(size: 28, weight: .black, design: .serif)).foregroundStyle(accent)
                        Text("正确率").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
                    }
                }
                .frame(width: 130, height: 130)
                Text(acc >= 90 ? "小小理财家！" : acc >= 75 ? "很棒！" : acc >= 60 ? "不错哦" : acc >= 40 ? "有点难吧" : "继续加油")
                    .font(.system(size: 20, weight: .black, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                Text(acc >= 90 ? "★★★★★ 大师级" : acc >= 75 ? "★★★★ 熟练" : acc >= 60 ? "★★★ 进阶" : acc >= 40 ? "★★ 入门" : "★ 慢慢来")
                    .font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(accent)
                HStack(spacing: 10) {
                    rstat("答对", "\(okCount)", Color(red: 0.18, green: 0.56, blue: 0.32))
                    rstat("答错", "\(total - okCount)", Color(red: 0.78, green: 0.25, blue: 0.17))
                    rstat("用时", "\(elapsed)s", accent)
                }
                Text("得分 \(score)").font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
                HStack(spacing: 12) {
                    Button { showResult = false } label: {
                        Text("换难度").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldInk)
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .background(Capsule().fill(Color.white.opacity(0.92)).overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)))
                    }.buttonStyle(.plain)
                    Button { newGame() } label: {
                        Text("再来一局").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .background(Capsule().fill(LinearGradient(colors: [accent, accent.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    }.buttonStyle(.plain)
                }
            }
            .padding(24).frame(maxWidth: 360)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white))
        }
        .transition(.opacity)
    }

    private func rstat(_ k: String, _ v: String, _ c: Color) -> some View {
        VStack(spacing: 3) {
            Text(v).font(.system(size: 19, weight: .black, design: .serif)).foregroundStyle(c)
            Text(k).font(.system(size: 10.5, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppTheme.fieldOlive.opacity(0.06)))
    }

    // MARK: 背景点缀

    private var decorations: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color(red: 1, green: 0.92, blue: 0.55), Color(red: 1, green: 0.78, blue: 0.30)], center: .center, startRadius: 0, endRadius: 32))
                    .frame(width: 62, height: 62).opacity(0.5)
                    .position(x: w * 0.85, y: h * 0.08)
                cloud.opacity(0.55).position(x: w * 0.16, y: h * 0.09)
                cloud.opacity(0.4).scaleEffect(0.7).position(x: w * 0.62, y: h * 0.04)
                ForEach(0..<10, id: \.self) { i in
                    Text(["✨", "🌸", "🌼", "🪙"][i % 4])
                        .font(.system(size: i % 3 == 0 ? 15 : 12)).opacity(0.28)
                        .position(x: w * Double((i * 67) % 100) / 100, y: h * Double((i * 43) % 90) / 100)
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
                    Text("?").font(.system(size: 24, weight: .black)).foregroundStyle(accent)
                        .frame(width: 46, height: 46).background(Circle().fill(accentSoft))
                    Text("人民币怎么玩").font(.system(size: 22, weight: .black, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                }
                VStack(alignment: .leading, spacing: 12) {
                    helpStep("1", "目标：认识人民币，会数钱、付钱、找零。")
                    helpStep("2", "1 元 = 10 角；硬币有 1角、5角、1元。")
                    helpStep("3", "会考：一堆钱多少、两样东西合计、换算、比价。")
                    helpStep("4", "付钱：点钱包里的钱放进收银台，凑出「正好」的金额。")
                }
                Button { showHelp = false } label: {
                    Text("知道了").font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Capsule().fill(accent))
                }
                .buttonStyle(.plain).padding(.top, 6)
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
