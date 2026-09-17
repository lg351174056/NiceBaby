import SwiftUI
import Combine

// MARK: - 钟表（探索 · 学问营地）

enum ClockQType { case read, readWord, pickDial, elapsed, compareLater, set }

enum ClockDifficulty: String, CaseIterable, Identifiable {
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

    var minutes: [Int] {
        switch self {
        case .qihang: return [0, 30, 15, 45, 5, 55]          // 整点/半点/一刻/三刻/五分/五十五
        case .jinjie: return [0, 15, 30, 45, 5, 10, 20, 25, 35, 40, 50, 55]
        case .tiaozhan, .dashi: return [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
        }
    }

    var types: [ClockQType] {
        switch self {
        case .qihang: return [.read, .readWord, .pickDial]
        case .jinjie: return [.read, .pickDial, .readWord, .elapsed]
        case .tiaozhan: return [.read, .pickDial, .elapsed, .compareLater, .readWord]
        case .dashi: return [.set, .elapsed, .compareLater, .pickDial, .read]
        }
    }
}

enum ClockStore {
    private static func key(_ id: String) -> String { "clock.best.\(id)" }
    static func best(_ id: String) -> Int { UserDefaults.standard.integer(forKey: key(id)) }
    @discardableResult
    static func update(_ id: String, score: Int) -> Bool {
        let old = best(id)
        if score <= old { return false }
        UserDefaults.standard.set(score, forKey: key(id))
        return true
    }
    static func hasAny() -> Bool { ClockDifficulty.allCases.contains { best($0.rawValue) > 0 } }
}

private struct DialOption: Hashable {
    let h: Int
    let m: Int
}

struct ClockLearningView: View {
    private enum Hand { case hour, minute }

    @State private var diff: ClockDifficulty = .qihang
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

    // 通用题面
    @State private var kind: ClockQType = .read
    @State private var h1 = 12
    @State private var m1 = 0
    @State private var h2 = 12
    @State private var m2 = 0
    @State private var ansH = 12
    @State private var ansM = 0
    @State private var addMin = 0
    @State private var elapsedForm = 0
    @State private var askText = ""
    // 文字选项
    @State private var options: [String] = []
    @State private var correctText = ""
    @State private var picked: String? = nil
    // 选表盘
    @State private var dials: [DialOption] = []
    @State private var pickedDial: DialOption? = nil
    // 比谁晚
    @State private var laterSide = 0
    @State private var pickedSide: Int? = nil
    // 调表
    @State private var setH = 12
    @State private var setM = 0
    @State private var dragging: Hand? = nil

    private let accent = Color(red: 0.23, green: 0.56, blue: 0.65)
    private let accentSoft = Color(red: 0.90, green: 0.95, blue: 0.96)
    private let total = 8
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
                Text("钟表").font(.system(size: 16, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                Text("看时间 · 读时间").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
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
                Text("\(ClockStore.best(diff.rawValue))").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldInk)
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
            ForEach(ClockDifficulty.allCases) { d in
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
                                    .matchedGeometryEffect(id: "clockPill", in: diffNS)
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
        VStack(spacing: 14) {
            Spacer(minLength: 4)
            askCard
            clockSection
            answerSection
            Spacer(minLength: 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 18)
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

    private var bigSide: CGFloat { min(UIScreen.main.bounds.width - 90, 246) }
    private var smallSide: CGFloat { min((UIScreen.main.bounds.width - 90) / 2, 132) }

    @ViewBuilder
    private var clockSection: some View {
        switch kind {
        case .set:
            ClockFace(hour: setH, minute: setM, accent: accent)
                .frame(width: bigSide, height: bigSide)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in dragChanged(v.location, side: bigSide) }
                        .onEnded { _ in dragging = nil }
                )
        case .pickDial:
            EmptyView()
        case .compareLater:
            HStack(spacing: 14) {
                labeledClock(0, "左", h1, m1)
                labeledClock(1, "右", h2, m2)
            }
        default:
            ClockFace(hour: h1, minute: m1, accent: accent)
                .frame(width: bigSide, height: bigSide)
        }
    }

    private func labeledClock(_ side: Int, _ tag: String, _ h: Int, _ m: Int) -> some View {
        let isRight = answered && side == laterSide
        let isWrong = answered && pickedSide == side && side != laterSide
        return VStack(spacing: 6) {
            ClockFace(hour: h, minute: m, accent: accent)
                .frame(width: smallSide, height: smallSide)
            Text(tag)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isRight ? Color(red: 0.49, green: 0.83, blue: 0.63).opacity(0.28)
                      : isWrong ? Color(red: 0.80, green: 0.30, blue: 0.22).opacity(0.22)
                      : Color.white.opacity(0.6))
        )
    }

    private func dragChanged(_ loc: CGPoint, side: CGFloat) {
        guard !answered else { return }
        let c = side / 2
        let dx = loc.x - c, dy = loc.y - c
        var a = atan2(dx, -dy) * 180 / .pi
        if a < 0 { a += 360 }
        if dragging == nil { dragging = hypot(dx, dy) < side * 0.30 ? .hour : .minute }
        if dragging == .minute {
            setM = (Int((a / 30).rounded()) * 5) % 60
        } else {
            var h = Int((a / 30).rounded()) % 12
            if h == 0 { h = 12 }
            setH = h
        }
    }

    @ViewBuilder
    private var answerSection: some View {
        switch kind {
        case .set:
            Button { confirmSet() } label: {
                Text("确定")
                    .font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                    .frame(width: 200, height: 52)
                    .background(Capsule().fill(LinearGradient(colors: [accent, accent.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    .shadow(color: accent.opacity(0.35), radius: 8, y: 4)
            }
            .buttonStyle(.plain).disabled(answered)

        case .pickDial:
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Array(dials.enumerated()), id: \.offset) { _, d in
                    dialButton(d)
                }
            }

        case .compareLater:
            HStack(spacing: 12) {
                sideButton(0, "左边更晚")
                sideButton(1, "右边更晚")
            }

        default:
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(options, id: \.self) { opt in optionButton(opt) }
            }
        }
    }

    private func dialButton(_ d: DialOption) -> some View {
        let isCorrect = d.h == ansH && d.m == ansM
        let isPicked = pickedDial == d
        let showGood = answered && isCorrect
        let showBad = answered && isPicked && !isCorrect
        return Button { chooseDial(d) } label: {
            ClockFace(hour: d.h, minute: d.m, accent: accent)
                .frame(width: smallSide, height: smallSide)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(showGood ? Color(red: 0.49, green: 0.83, blue: 0.63).opacity(0.3)
                              : showBad ? Color(red: 0.80, green: 0.30, blue: 0.22).opacity(0.24)
                              : Color.white.opacity(0.9))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(showGood ? Color(red: 0.30, green: 0.69, blue: 0.49)
                                          : showBad ? Color(red: 0.80, green: 0.30, blue: 0.22)
                                          : AppTheme.fieldOlive.opacity(0.25),
                                          lineWidth: 2))
                )
        }
        .buttonStyle(.plain)
        .disabled(answered)
    }

    private func sideButton(_ side: Int, _ title: String) -> some View {
        let isCorrect = answered && side == laterSide
        let isWrong = answered && pickedSide == side && side != laterSide
        return Button { chooseSide(side) } label: {
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(isCorrect || isWrong ? .white : AppTheme.fieldInk)
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isCorrect ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.49, green: 0.83, blue: 0.63), Color(red: 0.30, green: 0.69, blue: 0.49)], startPoint: .topLeading, endPoint: .bottomTrailing))
                              : isWrong ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.93, green: 0.54, blue: 0.45), Color(red: 0.80, green: 0.30, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing))
                              : AnyShapeStyle(Color.white.opacity(0.92)))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder((isCorrect || isWrong) ? Color.clear : AppTheme.fieldOlive.opacity(0.28), lineWidth: 2))
                )
        }
        .buttonStyle(.plain).disabled(answered)
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
        answered = false; picked = nil; pickedDial = nil; pickedSide = nil
        nextVisible = false; fbText = ""; fbOK = false
        kind = diff.types.randomElement() ?? .read
        switch kind {
        case .read: buildRead()
        case .readWord: buildReadWord()
        case .pickDial: buildPickDial()
        case .elapsed: buildElapsed()
        case .compareLater: buildCompareLater()
        case .set: buildSet()
        }
    }

    // 看表选时间
    private func buildRead() {
        h1 = Int.random(in: 1...12); m1 = diff.minutes.randomElement() ?? 0
        ansH = h1; ansM = m1
        correctText = fmt(h1, m1)
        askText = "现在是几点？"
        options = uniq([fmt(h1 % 12 + 1, m1), fmt(h1, (m1 + 30) % 60), fmt(h1, (m1 + 5) % 60), fmt(h1 == 1 ? 12 : h1 - 1, m1)])
    }

    // 中文读法
    private func buildReadWord() {
        h1 = Int.random(in: 1...12); m1 = diff.minutes.randomElement() ?? 0
        ansH = h1; ansM = m1
        correctText = word(h1, m1)
        askText = "钟面上的时间，中文怎么说？"
        let alt = h1 == 1 ? 12 : h1 - 1
        let cands: [String]
        if m1 == 0 {
            cands = ["\(h1)时12分", "\(h1)时30分", "\(alt)时"]
        } else if m1 % 5 == 0 && m1 / 5 != m1 {
            cands = ["\(h1)时\(m1 / 5)分", "\(h1)时\(max(0, m1 - 5))分", "\(alt)时\(m1)分"]
        } else {
            cands = ["\(h1)时\(m1 + 5)分", "\(alt)时\(m1)分", "\(h1)时\(max(0, m1 - 5))分"]
        }
        options = uniq(cands)
    }

    // 选正确表盘
    private func buildPickDial() {
        ansH = Int.random(in: 1...12); ansM = diff.minutes.randomElement() ?? 0
        askText = "哪个钟显示的是 \(fmt(ansH, ansM))？"
        let alt = ansH == 1 ? 12 : ansH - 1
        var ds: [DialOption] = [DialOption(h: ansH, m: ansM)]
        for c in [DialOption(h: ansH % 12 + 1, m: ansM),
                  DialOption(h: ansH, m: (ansM + 30) % 60),
                  DialOption(h: ansH, m: (ansM + 5) % 60),
                  DialOption(h: alt, m: ansM)] {
            if ds.count < 4, !ds.contains(c), !(c.h == ansH && c.m == ansM) { ds.append(c) }
        }
        dials = ds.shuffled()
    }

    // 经过时间
    private func buildElapsed() {
        h1 = Int.random(in: 1...12); m1 = diff.minutes.randomElement() ?? 0
        elapsedForm = Int.random(in: 0...1)
        let step = [5, 10, 15, 20, 30].randomElement() ?? 10
        addMin = step * Int.random(in: 1...3)
        var tm = m1 + addMin, th = h1 + tm / 60
        tm %= 60; th = ((th - 1) % 12) + 1
        ansH = th; ansM = tm
        if elapsedForm == 0 {
            askText = "现在是 \(fmt(h1, m1))，再过 \(addMin) 分钟是几点？"
            correctText = fmt(ansH, ansM)
            options = uniq([fmt((th % 12) + 1, tm), fmt(th, (tm + 5) % 60), fmt(th, (tm + 10) % 60), fmt(th == 1 ? 12 : th - 1, tm)])
        } else {
            askText = "钟面上是 \(fmt(h1, m1))，到 \(fmt(ansH, ansM)) 要过多久？"
            correctText = "\(addMin)分钟"
            options = uniqMin([addMin, addMin + 5, max(5, addMin - 5), addMin + 10])
        }
    }

    // 比谁晚
    private func buildCompareLater() {
        var hh = Int.random(in: 1...12), mm = diff.minutes.randomElement() ?? 0
        let delta = [5, 10, 15, 20, 25].randomElement() ?? 10
        var tm = mm + delta, th = hh + tm / 60
        tm %= 60; th = ((th - 1) % 12) + 1
        h1 = hh; m1 = mm; h2 = th; m2 = tm
        askText = "哪个钟的时间更晚？"
        laterSide = minutesOfDay(h2, m2) > minutesOfDay(h1, m1) ? 1 : 0
        options = []; correctText = ""
    }

    private func buildSet() {
        ansH = Int.random(in: 1...12); ansM = diff.minutes.randomElement() ?? 0
        setH = Int.random(in: 1...12); setM = diff.minutes.randomElement() ?? 0
        askText = "请把钟调到 \(word(ansH, ansM))（拖动长针 / 短针）"
        options = []; correctText = ""
    }

    private func choose(_ opt: String) {
        guard !answered else { return }
        answered = true; picked = opt
        if opt == correctText { okCount += 1; fbText = "✓ 答对了！"; fbOK = true }
        else { fbText = "✗ 正确答案是 \(correctText)"; fbOK = false }
        nextVisible = true
    }

    private func chooseDial(_ d: DialOption) {
        guard !answered else { return }
        answered = true; pickedDial = d
        if d.h == ansH && d.m == ansM { okCount += 1; fbText = "✓ 就是这个！"; fbOK = true }
        else { fbText = "✗ 应该是 \(fmt(ansH, ansM))"; fbOK = false }
        nextVisible = true
    }

    private func chooseSide(_ side: Int) {
        guard !answered else { return }
        answered = true; pickedSide = side
        if side == laterSide { okCount += 1; fbText = "✓ 答对了！"; fbOK = true }
        else { fbText = "✗ 是\(laterSide == 0 ? "左" : "右")边的更晚"; fbOK = false }
        nextVisible = true
    }

    private func confirmSet() {
        guard !answered else { return }
        answered = true
        if setH == ansH && setM == ansM { okCount += 1; fbText = "✓ 调对啦！"; fbOK = true }
        else { fbText = "✗ 应该是 \(fmt(ansH, ansM))（你调成了 \(fmt(setH, setM))）"; fbOK = false }
        nextVisible = true
    }

    private func next() {
        qIndex += 1
        if qIndex >= total { finish() } else { nextQuestion() }
    }

    private func finish() {
        let score = max(1, okCount * 100 + max(0, 120 - elapsed) * 2)
        ClockStore.update(diff.rawValue, score: score)
        showResult = true
    }

    // MARK: 工具

    private func fmt(_ h: Int, _ m: Int) -> String { "\(h):\(String(format: "%02d", m))" }
    private func word(_ h: Int, _ m: Int) -> String { m == 0 ? "\(h)时" : "\(h)时\(m)分" }
    private func minutesOfDay(_ h: Int, _ m: Int) -> Int { (h % 12) * 60 + m }

    /// 数字/文字选项：保证 4 个互异
    private func uniq(_ cands: [String]) -> [String] {
        var out: [String] = [correctText]
        for c in cands where out.count < 4 { if !out.contains(c) { out.append(c) } }
        return out.shuffled()
    }

    private func uniqMin(_ mins: [Int]) -> [String] {
        var out: [String] = [correctText]
        for v in mins where out.count < 4 {
            let s = "\(v)分钟"
            if !out.contains(s) { out.append(s) }
        }
        return out.shuffled()
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
                Text(acc >= 90 ? "时间小达人！" : acc >= 75 ? "很棒！" : acc >= 60 ? "不错哦" : acc >= 40 ? "有点难吧" : "继续加油")
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
                    Text(["✨", "🌸", "🌼", "🍃"][i % 4])
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
                    Text("钟表怎么玩").font(.system(size: 22, weight: .black, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                }
                VStack(alignment: .leading, spacing: 12) {
                    helpStep("1", "目标：认识时钟，看指针读出时间。")
                    helpStep("2", "短针是时针，长针是分针；分针指 12 是整点、指 6 是半点。")
                    helpStep("3", "还会考：哪个钟是对的、再过几分钟是几点、哪个更晚。")
                    helpStep("4", "「大师」里可以拖动指针，把钟调到指定时间。")
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

// MARK: - 表盘

private struct ClockFace: View {
    let hour: Int
    let minute: Int
    let accent: Color

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let R = s / 2
            ZStack {
                Circle().fill(Color.white)
                    .overlay(Circle().strokeBorder(AppTheme.fieldOlive.opacity(0.35), lineWidth: 3))
                Circle().fill(Color(red: 0.99, green: 1.0, blue: 0.985)).padding(s * 0.055)
                Canvas { ctx, size in
                    let c = CGPoint(x: size.width / 2, y: size.height / 2)
                    let rr = size.width / 2
                    for i in 0..<60 {
                        let a = Double(i) * 6 * .pi / 180
                        let big = i % 5 == 0
                        let r1 = big ? rr * 0.82 : rr * 0.86
                        let r2 = rr * 0.90
                        var p = Path()
                        p.move(to: CGPoint(x: c.x + sin(a) * r1, y: c.y - cos(a) * r1))
                        p.addLine(to: CGPoint(x: c.x + sin(a) * r2, y: c.y - cos(a) * r2))
                        ctx.stroke(p, with: .color(big ? AppTheme.fieldInk : AppTheme.fieldOlive.opacity(0.45)),
                                   lineWidth: big ? 2.2 : 1.0)
                    }
                    for n in 1...12 {
                        let a = Double(n) * 30 * .pi / 180
                        let pt = CGPoint(x: c.x + sin(a) * rr * 0.68, y: c.y - cos(a) * rr * 0.68)
                        let txt = Text("\(n)").font(.system(size: rr * 0.16, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                        ctx.draw(txt, at: pt, anchor: .center)
                    }
                }
                Capsule().fill(AppTheme.fieldInk)
                    .frame(width: R * 0.085, height: R * 0.50)
                    .offset(y: -R * 0.25)
                    .rotationEffect(.degrees(Double(hour % 12) * 30 + Double(minute) * 0.5))
                Capsule().fill(accent)
                    .frame(width: R * 0.06, height: R * 0.72)
                    .offset(y: -R * 0.36)
                    .rotationEffect(.degrees(Double(minute) * 6))
                Circle().fill(AppTheme.fieldInk).frame(width: R * 0.12, height: R * 0.12)
                Circle().fill(Color.white).frame(width: R * 0.045, height: R * 0.045)
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.16), radius: 9, y: 5)
    }
}
