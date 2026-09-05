import Combine
import SwiftUI

// MARK: - 找规律题型

enum PatternMode: String, CaseIterable, Identifiable {
    case kanTu = "看图找规律"
    case shuZi = "数字找规律"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .kanTu: return "👀"
        case .shuZi: return "🔢"
        }
    }

    var subtitle: String {
        switch self {
        case .kanTu: return "观察图形序列，选出缺失的一块"
        case .shuZi: return "观察数字序列，填入空缺的数"
        }
    }

    var color: Color {
        switch self {
        case .kanTu: return AppTheme.accentJade
        case .shuZi: return AppTheme.accentInkPurple
        }
    }
}

struct PatternQuestion: Hashable {
    let mtype: String
    let lv: Int
    let tokens: [String]
    let options: [String]
    let answer: [String]
    let jiexi: String
    /// 规律类型标签：等差 / 幻方 / 数量增减 …
    let rule: String
    /// 展示版式：nil = 自适应横排；2/3/4 = 固定列数（九宫格=3、六宫格=3×2…）
    let columns: Int?

    var identity: String { "\(mtype)-\(lv)" }
    var mode: PatternMode { mtype.hasPrefix("kt") ? .kanTu : .shuZi }
    var blankCount: Int { tokens.filter { $0 == "_" }.count }
    var blankOrders: [Int] {
        tokens.enumerated().compactMap { $0.element == "_" ? $0.offset : nil }
    }
}

struct PatternRoute: Hashable {
    let mode: PatternMode
    let lv: Int
}

// MARK: - 题库

struct PatternBankItem: Codable {
    let mtype: String
    let lv: Int
    let timu: [String]
    var options: [String]?
    let answer: [String]
    var jiexi: String?
    var rule: String?
    var columns: Int?

    var question: PatternQuestion {
        PatternQuestion(
            mtype: mtype,
            lv: lv,
            tokens: timu,
            options: options ?? [],
            answer: answer,
            jiexi: jiexi ?? "",
            rule: rule ?? "",
            columns: columns
        )
    }
}

enum PatternBankStore {
    /// 内置生成题库：数字找规律 300 关 + 看图找规律 200 关
    private static let generated: [PatternQuestion] = PatternBankGenerator.generate()

    static var externalURL: URL? {
        try? FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("pattern_bank.json")
    }

    static func load() -> [PatternQuestion] {
        if let url = externalURL,
           let data = try? Data(contentsOf: url),
           let items = try? JSONDecoder().decode([PatternBankItem].self, from: data) {
            return items.map { $0.question }
        }
        return generated
    }

    static func questions(mode: PatternMode) -> [PatternQuestion] {
        load().filter { $0.mode == mode }.sorted { $0.lv < $1.lv }
    }
}

// MARK: - 进度

enum PatternProgressStore {
    private static func key(_ mode: PatternMode, _ lv: Int) -> String {
        "pattern.done.\(mode.rawValue).\(lv)"
    }

    static func isDone(_ mode: PatternMode, _ lv: Int) -> Bool {
        UserDefaults.standard.bool(forKey: key(mode, lv))
    }

    static func markDone(_ mode: PatternMode, _ lv: Int) {
        UserDefaults.standard.set(true, forKey: key(mode, lv))
        PatternProgressCenter.shared.touch()
    }

    static func doneCount(_ mode: PatternMode) -> Int {
        PatternBankStore.questions(mode: mode).filter { isDone(mode, $0.lv) }.count
    }
}

/// 进度/题库变更广播：返回关卡列表时用它强制刷新
@MainActor
final class PatternProgressCenter: ObservableObject {
    static let shared = PatternProgressCenter()
    @Published private(set) var stamp = 0
    func touch() { stamp += 1 }
}

// MARK: - 二级页：模式切换 + 关卡列表

struct PatternFindHomeView: View {
    let onExit: () -> Void

    @ObservedObject private var center = PatternProgressCenter.shared
    @State private var selectedMode: PatternMode = .kanTu

    private var questions: [PatternQuestion] {
        _ = center.stamp
        return PatternBankStore.questions(mode: selectedMode)
    }

    private var usingExternalBank: Bool {
        PatternBankStore.externalURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        ZStack {
            FieldBackground()

            homeSun
            homeCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            homeCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text("找规律")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                modeToggle
                statsStripe

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(questions, id: \.identity) { q in
                            NavigationLink(value: PatternRoute(mode: selectedMode, lv: q.lv)) {
                                levelCell(q)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)

                    Text(bankHint)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
                        .padding(.top, 14)
                        .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .onAppear { center.touch() }
        .navigationDestination(for: PatternRoute.self) { route in
            PatternPlayView(mode: route.mode, initialLv: route.lv)
        }
    }

    private var bankHint: String {
        if usingExternalBank {
            return questions.isEmpty
                ? "无可展示关卡 · 请检查 pattern_bank.json 内容"
                : "已接入完整题库 · \(questions.count) 关随点随玩 ✓"
        }
        return "内置题库 · 看图 200 关 / 数字 300 关 · 难度按年级渐进"
    }

    // MARK: 模式切换

    private var modeToggle: some View {
        HStack(spacing: 10) {
            ForEach(PatternMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(mode.icon)
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.rawValue)
                                .font(.system(size: 13, weight: .heavy, design: .serif))
                                .foregroundStyle(selectedMode == mode ? .white : AppTheme.fieldInk)
                            Text(mode.subtitle)
                                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                .foregroundStyle(selectedMode == mode ? .white.opacity(0.85) : AppTheme.fieldMoss)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selectedMode == mode
                                  ? AnyShapeStyle(LinearGradient(colors: [mode.color, mode.color.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                  : AnyShapeStyle(Color.white.opacity(0.92)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(selectedMode == mode ? mode.color : AppTheme.fieldOlive.opacity(0.25), lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    // MARK: 进度条

    private var statsStripe: some View {
        let done = PatternProgressStore.doneCount(selectedMode)
        let total = questions.count
        return VStack(spacing: 6) {
            HStack {
                Text("已通关")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                Spacer()
                Text("\(done) / \(total) 关")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMint)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.fieldOlive.opacity(0.18))
                    Capsule()
                        .fill(LinearGradient(colors: [AppTheme.fieldMint, AppTheme.accentJade], startPoint: .leading, endPoint: .trailing))
                        .frame(width: total > 0 ? geo.size.width * CGFloat(done) / CGFloat(total) : 0)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    // MARK: 关卡格

    private func levelCell(_ q: PatternQuestion) -> some View {
        let done = PatternProgressStore.isDone(selectedMode, q.lv)
        return ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(done ? AppTheme.fieldMint.opacity(0.55) : AppTheme.fieldOlive.opacity(0.28), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.06), radius: 4, y: 2)
            VStack(spacing: 3) {
                Text("\(q.lv)")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(done ? AppTheme.fieldMint : AppTheme.fieldInk)
                if !q.rule.isEmpty {
                    Text("【\(q.rule)】")
                        .font(.system(size: 7.5, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.fieldMint)
                } else {
                    Text("第\(q.lv)关")
                        .font(.system(size: 7.5, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                        .lineLimit(1)
                }
            }
        }
        .frame(height: 66)
    }

    // MARK: 背景装饰

    private var homeSun: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breathe = 1 + 0.03 * sin(t * 1.2)
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
        .padding(.top, 34)
        .allowsHitTesting(false)
    }

    private func homeCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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
}

// MARK: - 通关页：序列作答

struct PatternPlayView: View {
    let mode: PatternMode
    @State private var lv: Int
    @State private var blanks: [String?] = []
    @State private var selectedBlank = 0
    @State private var submitted = false
    @State private var correct = false

    init(mode: PatternMode, initialLv: Int) {
        self.mode = mode
        _lv = State(initialValue: initialLv)
    }

    private var question: PatternQuestion {
        let list = PatternBankStore.questions(mode: mode)
        return list.first { $0.lv == lv }
            ?? list.first
            ?? PatternQuestion(mtype: mode == .kanTu ? "kt" : "sz1", lv: 1,
                               tokens: ["_"], options: [], answer: ["?"], jiexi: "", rule: "", columns: nil)
    }

    private var totalInMode: Int {
        PatternBankStore.questions(mode: mode).count
    }

    private func reset(for q: PatternQuestion) {
        blanks = Array(repeating: nil, count: q.blankCount)
        selectedBlank = 0
        submitted = false
        correct = false
    }

    private var filledCount: Int {
        blanks.filter { $0 != nil }.count
    }

    private func fillNext(_ value: String) {
        guard !blanks.isEmpty else { return }
        if selectedBlank >= blanks.count { selectedBlank = 0 }
        blanks[selectedBlank] = value
        var next = selectedBlank + 1
        while next < blanks.count, blanks[next] != nil { next += 1 }
        selectedBlank = min(next, blanks.count - 1)
    }

    private func selectBlank(_ index: Int) {
        selectedBlank = index
    }

    private func isFig(_ s: String) -> Bool {
        guard mode == .kanTu, s != "_" else { return false }
        let parts = FigParser.parts(s)
        return !parts.isEmpty && parts.allSatisfy { PatternFig.emojis.values.contains($0.emoji) }
    }

    private func display(_ s: String) -> String {
        guard isFig(s) else { return s }
        return FigParser.parts(s)
            .map { String(repeating: $0.emoji, count: max(1, $0.count)) }
            .joined()
    }

    /// 渲染可含数量/旋转/大小的格内图形：11:3 → 🍎🍎🍎，17:r90 → 旋转箭头，11:2+12:1 → 🍎🍎🍌
    @ViewBuilder
    private func figContent(_ token: String, baseSize: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(FigParser.parts(token).enumerated()), id: \.offset) { _, part in
                ForEach(0..<max(1, part.count), id: \.self) { _ in
                    Text(part.emoji)
                        .font(.system(size: baseSize * part.scale))
                        .rotationEffect(.degrees(part.rotation))
                }
            }
        }
        .fixedSize()
        .minimumScaleFactor(0.55)
    }

    private var answerDisplay: String {
        question.answer.map { display($0) }
            .joined(separator: question.mode == .kanTu ? "" : "，")
    }

    var body: some View {
        ZStack {
            FieldBackground()

            listSun
            listCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)

            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                        HStack(spacing: 10) {
                            prevBtn
                            nextBtn
                        }
                    }
                    Text("\(mode.icon) \(mode.rawValue)")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        levelHeader
                        sequenceCard
                        if submitted {
                            resultCard
                        }
                        answerPad
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .onAppear { reset(for: question) }
        .onChange(of: lv) { reset(for: question) }
    }

    // MARK: 关卡头

    private var levelHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("第 \(lv) 关")
                    .font(.system(size: 17, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("填 \(question.blankCount) 处空 · 共 \(totalInMode) 关")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
            }
            Spacer()
            if !question.rule.isEmpty {
                Text("【\(question.rule)】")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.accentSage)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentSage.opacity(0.12))
                    )
            }
            if PatternProgressStore.isDone(mode, lv) {
                Label("已通关", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMint)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 5, y: 3)
        )
    }

    // MARK: 序列卡片

    /// 题目自选版式：九宫格/六宫格（columns=3）或自适应横排（默认 4 列）
    private var seqColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: question.columns ?? 4)
    }

    private var sequenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("观察规律，把空缺补齐")
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.fieldMoss)

            LazyVGrid(columns: seqColumns, spacing: 8) {
                ForEach(Array(question.tokens.enumerated()), id: \.offset) { idx, token in
                    if token == "_" {
                        blankCell(blankOrder: question.blankOrders.firstIndex(of: idx) ?? 0)
                    } else {
                        tokenCell(token)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppTheme.fieldMint.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.1), radius: 7, y: 4)
        )
    }

    private func tokenCell(_ token: String) -> some View {
        Group {
            if isFig(token) {
                figContent(token, baseSize: 22)
            } else {
                Text(display(token))
                    .font(.system(size: 17, weight: .heavy, design: .serif))
            }
        }
        .foregroundStyle(AppTheme.fieldInk)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(AppTheme.fieldMint.opacity(0.35), lineWidth: 1.5)
                    )
                    .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 3, y: 2)
            )
    }

    private func blankCell(blankOrder: Int) -> some View {
        Button {
            selectBlank(blankOrder)
        } label: {
            let filled = blanks[safe: blankOrder] ?? nil
            Group {
                if let filled, isFig(filled) {
                    figContent(filled, baseSize: 22)
                } else {
                    Text(filled.map { display($0) } ?? "?")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                }
            }
            .foregroundStyle(filled == nil ? (selectedBlank == blankOrder ? AppTheme.fieldMint : AppTheme.fieldMossLight) : AppTheme.fieldInk)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(selectedBlank == blankOrder
                              ? AppTheme.fieldMint.opacity(0.2)
                              : Color(red: 255/255, green: 244/255, blue: 214/255).opacity(0.96))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(selectedBlank == blankOrder ? AppTheme.fieldMint : AppTheme.fieldGold.opacity(0.6),
                                              style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                        )
                        .shadow(color: AppTheme.fieldGrassShadow.opacity(0.12), radius: 4, y: 2)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: 作答区

    @ViewBuilder
    private var answerPad: some View {
        if question.mode == .kanTu || !question.options.isEmpty {
            optionsPad
        } else {
            keypadPad
        }
    }

    // MARK: 选项（看图 / 数字高年级 4 选 1）

    private var optionsPad: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question.mode == .kanTu ? "点击图块，填入空位" : "点击数字，填入空位")
                .font(.system(size: 11, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.fieldMoss)

            if question.options.isEmpty {
                Text("（该题无候选，请直接在上方空格批量选择后提交）")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { _, opt in
                        Button {
                            fillNext(opt)
                        } label: {
                            Group {
                                if isFig(opt) {
                                    figContent(opt, baseSize: 22)
                                } else {
                                    Text(display(opt))
                                        .font(.system(size: 18, weight: .heavy, design: .serif))
                                }
                            }
                            .foregroundStyle(AppTheme.fieldInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.92))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(AppTheme.fieldMint.opacity(0.45), lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(.bouncy)
                    }
                }
            }

            submitButton
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 255/255, green: 251/255, blue: 243/255).opacity(0.94))
        )
    }

    // MARK: 数字 · 键盘

    private var keypadPad: some View {
        VStack(spacing: 12) {
            Text("在空格连续输入数字 · ⌫ 回删 · 点空格可切换")
                .font(.system(size: 11, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.fieldMoss)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "⌫", "清空"], id: \.self) { key in
                    keypadKey(key)
                }
            }

            submitButton
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 255/255, green: 251/255, blue: 243/255).opacity(0.94))
        )
    }

    private func keypadKey(_ key: String) -> some View {
        Button {
            handleKey(key)
        } label: {
            Text(key)
                .font(key == "⌫" || key == "清空" ? .system(size: 13, weight: .bold, design: .rounded)
                      : .system(size: 20, weight: .heavy, design: .serif))
                .foregroundStyle(key == "清空" ? Color(red: 232/255, green: 100/255, blue: 82/255) : AppTheme.fieldInk)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(key == "清空" ? 0.6 : 0.94))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(AppTheme.fieldOlive.opacity(0.28), lineWidth: 1.5)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func handleKey(_ key: String) {
        guard !blanks.isEmpty else { return }
        switch key {
        case "⌫":
            if let cur = blanks[selectedBlank], !cur.isEmpty {
                blanks[selectedBlank] = String(cur.dropLast())
            } else if selectedBlank > 0 {
                selectedBlank -= 1
                if let cur = blanks[selectedBlank], !cur.isEmpty {
                    blanks[selectedBlank] = String(cur.dropLast())
                }
            }
        case "清空":
            for i in 0..<blanks.count { blanks[i] = nil }
            selectedBlank = 0
        default:
            if let cur = blanks[selectedBlank] {
                blanks[selectedBlank] = (cur + key).count <= 4 ? cur + key : cur
            } else {
                blanks[selectedBlank] = key
            }
        }
    }

    // MARK: 提交

    private var canSubmit: Bool {
        !blanks.isEmpty && blanks.allSatisfy { $0 != nil }
    }

    private var submitButton: some View {
        Button {
            submitted = true
            let filled = blanks.compactMap { $0 }
            correct = filled.joined(separator: ",") == question.answer.joined(separator: ",")
            if correct {
                PatternProgressStore.markDone(mode, lv)
            }
        } label: {
            Text(submitted ? (correct ? "✓ 正确" : "再试一次") : "提交答案")
                .font(.system(size: 16, weight: .heavy, design: .serif))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(submitted
                              ? (correct ? AppTheme.fieldMint : Color(red: 232/255, green: 100/255, blue: 82/255))
                              : AppTheme.accentInkPurple)
                )
                .shadow(color: (submitted ? (correct ? AppTheme.fieldMint : Color(red: 232/255, green: 100/255, blue: 82/255)) : AppTheme.accentInkPurple).opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
        .opacity(canSubmit ? 1 : 0.5)
        .allowsHitTesting(canSubmit)
    }

    // MARK: 结果

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: correct ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(correct ? AppTheme.fieldMint : Color(red: 232/255, green: 100/255, blue: 82/255))
                Text(correct ? "回答正确！" : "还差一点点，继续试试")
                    .font(.system(size: 14, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Spacer()
                if !correct {
                    Text("正确答案：\(answerDisplay)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 232/255, green: 100/255, blue: 82/255))
                }
            }

            if !question.jiexi.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.fieldGold)
                        .padding(.top, 2)
                    Text(question.jiexi)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                        .lineSpacing(3)
                }
                .padding(.top, 4)
            }

            if correct {
                Button {
                    if lv < totalInMode { lv += 1 }
                } label: {
                    Text(lv < totalInMode ? "下一关 →" : "全部通关 🎉")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 9)
                        .background(AppTheme.fieldMint)
                        .clipShape(Capsule())
                }
                .disabled(lv >= totalInMode)
                .opacity(lv >= totalInMode ? 0.6 : 1)
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(correct ? AppTheme.fieldMint.opacity(0.5) : Color(red: 232/255, green: 100/255, blue: 82/255).opacity(0.4), lineWidth: 2)
                )
        )
    }

    // MARK: 上一关 / 下一关

    private var prevBtn: some View {
        Button {
            if lv > 1 { lv -= 1 }
        } label: {
            Image(systemName: "chevron.left.circle.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(lv > 1 ? AppTheme.fieldMint : AppTheme.fieldMossLight)
        }
        .disabled(lv <= 1)
        .buttonStyle(.plain)
    }

    private var nextBtn: some View {
        Button {
            if lv < totalInMode { lv += 1 }
        } label: {
            Image(systemName: "chevron.right.circle.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(lv < totalInMode ? AppTheme.fieldMint : AppTheme.fieldMossLight)
        }
        .disabled(lv >= totalInMode)
        .buttonStyle(.plain)
    }

    // MARK: 背景装饰

    private var listSun: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breathe = 1 + 0.03 * sin(t * 1.2)
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
        .padding(.top, 34)
        .allowsHitTesting(false)
    }

    private func listCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}