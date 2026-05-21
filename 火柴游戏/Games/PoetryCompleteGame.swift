import SwiftUI
import Combine

// MARK: - 行状态（文件级共享，供 ViewModifier 访问）
fileprivate enum LineState { case normal, correct, wrong }

// MARK: - 学段 / 年级 / 题册

enum SchoolStage: String, CaseIterable, Identifiable, Codable {
    case primary    // 小学
    case junior     // 初中
    case senior     // 高中
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .primary: return "小学"
        case .junior:  return "初中"
        case .senior:  return "高中"
        }
    }
}

/// 一本"册子" = 一个 JSON 文件
struct GradeBook: Hashable, Identifiable {
    let stage: SchoolStage
    let gradeIndex: Int    // 小学 1..6 / 初中 7..9 / 高中 10..12
    let term: Int          // 1=上册, 2=下册
    let track: Int         // 0=未区分, 1=课内, 2=课外（仅初中区分）
    let displayName: String   // "三上"
    let fileName: String      // "小学古诗·三年级上册"

    var id: String { fileName + (track == 0 ? "" : "·t\(track)") }

    /// 学段累积排序键（同学期的课内+课外算同一档，互相补给）
    var sortKey: Int { gradeIndex * 100 + term * 10 }

    static func gradeChinese(_ g: Int) -> String {
        switch g {
        case 1, 7, 10:  return "一"
        case 2, 8, 11:  return "二"
        case 3, 9, 12:  return "三"
        case 4: return "四"
        case 5: return "五"
        case 6: return "六"
        default: return "?"
        }
    }
}

// MARK: - 诗词补全数据层

struct PoemCompleteEntry: Hashable {
    let title: String
    let author: String
    let dynasty: String
    let lines: [String]   // 切分后的句子（不含标点）
    let charPerLine: Int  // 每句字数
}

enum PoetryCompleteCatalog {

    // 全部已知册子（与 Datas/JSON/ 下文件名对应）
    static let allBooks: [GradeBook] = buildAllBooks()

    private static func buildAllBooks() -> [GradeBook] {
        var arr: [GradeBook] = []
        // 小学：一上 ~ 六下
        for g in 1...6 {
            for term in 1...2 {
                let termCh = (term == 1) ? "上" : "下"
                let gradeCh = GradeBook.gradeChinese(g)
                arr.append(GradeBook(
                    stage: .primary,
                    gradeIndex: g,
                    term: term,
                    track: 0,
                    displayName: "\(gradeCh)\(termCh)",
                    fileName: "poetry_primary_g\(g)_t\(term)"
                ))
            }
        }
        // 初中：七上 ~ 九下，每册分课内/课外
        for g in 7...9 {
            for term in 1...2 {
                for track in [1, 2] {
                    let termCh = (term == 1) ? "上" : "下"
                    let gradeCh = GradeBook.gradeChinese(g)
                    let trackCh = (track == 1) ? "课内" : "课外"
                    let trackEn = (track == 1) ? "in" : "out"
                    arr.append(GradeBook(
                        stage: .junior,
                        gradeIndex: g,
                        term: term,
                        track: track,
                        displayName: "\(gradeCh)\(termCh)·\(trackCh)",
                        fileName: "poetry_junior_g\(g)_t\(term)_\(trackEn)"
                    ))
                }
            }
        }
        // 高中：一上 ~ 三下
        for g in 10...12 {
            for term in 1...2 {
                let termCh = (term == 1) ? "上" : "下"
                let gradeCh = GradeBook.gradeChinese(g)
                arr.append(GradeBook(
                    stage: .senior,
                    gradeIndex: g,
                    term: term,
                    track: 0,
                    displayName: "\(gradeCh)\(termCh)",
                    fileName: "poetry_senior_g\(g)_t\(term)"
                ))
            }
        }
        return arr
    }

    /// 学段下所有册子
    static func books(for stage: SchoolStage) -> [GradeBook] {
        allBooks.filter { $0.stage == stage }.sorted { $0.sortKey < $1.sortKey }
    }

    /// 累积模式下应包含的册子（同学段内 sortKey ≤ target）
    static func cumulativeBooks(upTo target: GradeBook) -> [GradeBook] {
        allBooks.filter { $0.stage == target.stage && $0.sortKey <= target.sortKey }
    }

    // MARK: 单文件加载（带缓存）

    private static var fileCache: [String: [PoemCompleteEntry]] = [:]
    private static let cacheLock = NSLock()

    /// 加载单个册子的入选诗集合（按学段规则过滤）
    static func entries(for book: GradeBook) -> [PoemCompleteEntry] {
        cacheLock.lock()
        if let cached = fileCache[book.fileName] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let raw = loadFile(name: book.fileName) ?? []
        let filtered = raw.compactMap { e -> PoemCompleteEntry? in
            return passFilter(entry: e, stage: book.stage)
        }

        cacheLock.lock()
        fileCache[book.fileName] = filtered
        cacheLock.unlock()
        return filtered
    }

    /// 累积模式下的入选诗集合（去重）
    static func entries(for book: GradeBook, cumulative: Bool) -> [PoemCompleteEntry] {
        let books = cumulative ? cumulativeBooks(upTo: book) : [book]
        var seen = Set<String>()
        var result: [PoemCompleteEntry] = []
        for b in books {
            for e in entries(for: b) {
                let key = e.lines.joined()
                if seen.insert(key).inserted {
                    result.append(e)
                }
            }
        }
        return result
    }

    private static func loadFile(name: String) -> [PoemCompleteEntry]? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }

        struct Entry: Decodable {
            let title: String?
            let author: String?
            let dynasty: String?
            let paragraphs: [String]?
            let contents: String?
        }
        guard let arr = try? JSONDecoder().decode([Entry].self, from: data) else { return nil }

        return arr.compactMap { e -> PoemCompleteEntry? in
            let raw: String = {
                if let p = e.paragraphs, !p.isEmpty { return p.joined(separator: "\n") }
                if let c = e.contents, !c.isEmpty { return c }
                return ""
            }()
            if raw.isEmpty { return nil }

            let lines = splitToShortLines(raw)
            guard !lines.isEmpty else { return nil }
            let lens = lines.map { $0.count }
            guard let n = lens.first else { return nil }
            return PoemCompleteEntry(
                title: e.title ?? "",
                author: e.author ?? "",
                dynasty: e.dynasty ?? "",
                lines: lines,
                charPerLine: n
            )
        }
    }

    /// 学段差异化入选规则
    /// - 小学：4 句 + 字数一致（4–7 字，兼容童诗）
    /// - 初中/高中：4 / 6 / 8 句 + 字数一致（4–7 字，兼容乐府/词牌/元曲）
    private static func passFilter(entry: PoemCompleteEntry, stage: SchoolStage) -> PoemCompleteEntry? {
        let lens = entry.lines.map { $0.count }
        guard let n = lens.first, lens.allSatisfy({ $0 == n }) else { return nil }
        guard n >= 4 && n <= 7 else { return nil }
        switch stage {
        case .primary:
            guard entry.lines.count == 4 else { return nil }
        case .junior, .senior:
            guard [4, 6, 8].contains(entry.lines.count) else { return nil }
        }
        return entry
    }

    /// 按 "，。；！？、\n" 切分为子句，返回不含标点的句子。
    private static func splitToShortLines(_ raw: String) -> [String] {
        let separators: Set<Character> = ["，", "。", "；", "！", "？", "、", "\n", "?", "!", ",", ";"]
        var result: [String] = []
        var buf = ""
        for ch in raw {
            if separators.contains(ch) {
                let trimmed = buf.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { result.append(trimmed) }
                buf = ""
            } else {
                buf.append(ch)
            }
        }
        let trimmed = buf.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { result.append(trimmed) }
        return result
    }

    // MARK: - 出题

    struct Question: Identifiable {
        let id = UUID()
        let entry: PoemCompleteEntry
        let blankIndex: Int    // 0..lines.count-1
        let answer: String     // 正确的那一句
        let options: [String]  // 4 选项已打乱
    }

    /// 在指定题库下出 N 道题。
    /// - 干扰句优先来自当前题库（同字数池），不够时回退到全学段。
    /// - 当前题库本体诗也不足时，自动并入同学段全部册子作兜底。
    static func makeQuestions(book: GradeBook, cumulative: Bool, count: Int) -> [Question] {
        var pool = entries(for: book, cumulative: cumulative)

        // 本体兜底：当前册（含累积）筛完 < count，自动扩到同学段全部册子
        if pool.count < count {
            var seen = Set(pool.map { $0.lines.joined() })
            for b in books(for: book.stage) {
                for e in entries(for: b) {
                    let key = e.lines.joined()
                    if seen.insert(key).inserted { pool.append(e) }
                }
            }
        }
        if pool.isEmpty { return [] }

        // 同字数干扰句池（来自当前题库）
        var distractorPool: [Int: [String]] = [:]
        for e in pool {
            distractorPool[e.charPerLine, default: []].append(contentsOf: e.lines)
        }
        // 去重
        for (k, v) in distractorPool { distractorPool[k] = Array(Set(v)) }

        // 当前池干扰句不够时（小池场景），从同学段全部册子补
        let needFallback = distractorPool.values.contains(where: { $0.count < 8 })
        if needFallback {
            for b in books(for: book.stage) {
                for e in entries(for: b) {
                    distractorPool[e.charPerLine, default: []].append(contentsOf: e.lines)
                }
            }
            for (k, v) in distractorPool { distractorPool[k] = Array(Set(v)) }
        }

        var qs: [Question] = []
        pool.shuffle()
        for entry in pool {
            if qs.count >= count { break }
            let blank = Int.random(in: 0..<entry.lines.count)
            let answer = entry.lines[blank]
            let exclude = Set(entry.lines)
            let candidates = distractorPool[entry.charPerLine] ?? []

            var distractors: [String] = []
            var seen = Set<String>([answer])
            var safety = 0
            while distractors.count < 3 && safety < 400 {
                if let s = candidates.randomElement(),
                   !exclude.contains(s),
                   seen.insert(s).inserted {
                    distractors.append(s)
                }
                safety += 1
            }
            guard distractors.count == 3 else { continue }

            var options = distractors
            options.append(answer)
            options.shuffle()

            qs.append(Question(entry: entry, blankIndex: blank, answer: answer, options: options))
        }

        // 题量不足时循环复用
        if qs.count < count, !qs.isEmpty {
            let original = qs
            var i = 0
            while qs.count < count {
                qs.append(original[i % original.count])
                i += 1
            }
        }
        return qs
    }
}

// MARK: - 视图模型（学段/年级/累积持久化）

@MainActor
final class PoetryCompleteSelection: ObservableObject {
    @Published var stage: SchoolStage
    @Published var book: GradeBook
    @Published var cumulative: Bool

    private let stageKey = "poetry.complete.stage"
    private let bookKey = "poetry.complete.book"
    private let cumKey  = "poetry.complete.cumulative"

    init() {
        let d = UserDefaults.standard
        let savedStage = SchoolStage(rawValue: d.string(forKey: "poetry.complete.stage") ?? "") ?? .primary
        let savedBookId = d.string(forKey: "poetry.complete.book") ?? ""
        let cum = d.object(forKey: "poetry.complete.cumulative") as? Bool ?? true

        let books = PoetryCompleteCatalog.books(for: savedStage)
        let book = books.first(where: { $0.id == savedBookId })
            ?? books.first(where: { savedStage == .primary && $0.gradeIndex == 3 && $0.term == 2 })
            ?? books.last
            ?? PoetryCompleteCatalog.allBooks[0]

        self.stage = savedStage
        self.book = book
        self.cumulative = cum
    }

    func selectStage(_ s: SchoolStage) {
        guard stage != s else { return }
        stage = s
        // 切学段时挑该学段最后一册（最容易"累积"覆盖最多）
        if let last = PoetryCompleteCatalog.books(for: s).last {
            book = last
        }
        persist()
    }

    func selectBook(_ b: GradeBook) {
        guard book != b else { return }
        book = b
        persist()
    }

    func setCumulative(_ on: Bool) {
        guard cumulative != on else { return }
        cumulative = on
        persist()
    }

    private func persist() {
        let d = UserDefaults.standard
        d.set(stage.rawValue, forKey: stageKey)
        d.set(book.id, forKey: bookKey)
        d.set(cumulative, forKey: cumKey)
    }
}

// MARK: - 诗词补全游戏视图

struct PoetryCompleteGameView: View {
    let onExit: () -> Void

    @StateObject private var selection = PoetryCompleteSelection()

    @State private var questions: [PoetryCompleteCatalog.Question] = []
    @State private var currentIndex = 0
    @State private var picked: String? = nil
    @State private var isCorrect: Bool? = nil
    @State private var correctCount = 0
    @State private var startTime = Date()
    @State private var showResult = false

    @Namespace private var animation

    private let totalQuestions = 10
    private let kind: GameKind = .poetryComplete

    private var current: PoetryCompleteCatalog.Question? {
        guard !questions.isEmpty, currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                GameTopBar(
                    title: kind.title,
                    progressText: "第 \(min(currentIndex + 1, totalQuestions)) / \(totalQuestions) 题 · 答对 \(correctCount)",
                    palette: kind.palette,
                    onExit: onExit
                )

                gradePicker
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                if let q = current {
                    questionBody(q: q).id(q.id)
                } else if questions.isEmpty {
                    emptyState
                } else {
                    ProgressView().frame(maxHeight: .infinity)
                }
            }

            if showResult {
                GameResultSheet(
                    result: GameResult(
                        kind: kind,
                        correct: correctCount,
                        total: totalQuestions,
                        elapsed: Date().timeIntervalSince(startTime)
                    ),
                    onRetry: restart,
                    onExit: onExit
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            if questions.isEmpty { reloadQuestions() }
        }
        .onChange(of: selection.book) { _, _ in reloadQuestions() }
        .onChange(of: selection.cumulative) { _, _ in reloadQuestions() }
    }

    // MARK: - 顶部学段 + 年级选择条

    private var gradePicker: some View {
        VStack(spacing: 8) {
            // 学段 segment
            HStack(spacing: 8) {
                ForEach(SchoolStage.allCases) { s in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.18)) { selection.selectStage(s) }
                    } label: {
                        Text(s.displayName)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(selection.stage == s ? .white : kind.palette.0)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(
                                    selection.stage == s
                                    ? AnyShapeStyle(LinearGradient(colors: [kind.palette.0, kind.palette.1],
                                                                   startPoint: .leading, endPoint: .trailing))
                                    : AnyShapeStyle(kind.palette.0.opacity(0.12))
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)

                // 累积/仅本册
                Toggle(isOn: Binding(get: { selection.cumulative },
                                     set: { selection.setCumulative($0) })) {
                    Text(selection.cumulative ? "累积" : "仅本册")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(kind.palette.0)
                .scaleEffect(0.78)
                .frame(width: 52)
                Text(selection.cumulative ? "累积" : "仅本册")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            // 年级胶囊（横向滚动）
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PoetryCompleteCatalog.books(for: selection.stage)) { b in
                        let selected = (b == selection.book)
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.18)) { selection.selectBook(b) }
                        } label: {
                            Text(b.displayName)
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(selected ? .white : AppTheme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(
                                        selected
                                        ? AnyShapeStyle(kind.palette.0)
                                        : AnyShapeStyle(AppTheme.card)
                                    )
                                )
                                .overlay(
                                    Capsule().strokeBorder(
                                        selected ? Color.clear : kind.palette.0.opacity(0.25),
                                        lineWidth: 1.5
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "scroll")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
            Text("当前题库为空")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            if !selection.cumulative {
                Button {
                    selection.setCumulative(true)
                } label: {
                    Text("切换为「累积」模式")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(kind.palette.0))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private func questionBody(q: PoetryCompleteCatalog.Question) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                poemCard(q: q)
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.top, 16)

                hintLabel

                optionList(q: q)
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: - 顶部诗卡

    private func poemCard(q: PoetryCompleteCatalog.Question) -> some View {
        let lines = q.entry.lines
        return VStack(spacing: 12) {
            Text(q.entry.title)
                .font(.system(size: 22, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            authorLabel(q: q)

            VStack(spacing: 8) {
                ForEach(Array(lines.enumerated()), id: \.offset) { (i, text) in
                    if i == q.blankIndex {
                        blankLineRow(q: q)
                    } else {
                        lineRow(text: text, idx: i, state: .normal)
                    }
                }
            }
            .padding(.top, 6)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerLarge))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerLarge)
                .strokeBorder(
                    isCorrect == true ? AppTheme.accentSage : kind.palette.0.opacity(0.25),
                    lineWidth: 2
                )
        )
    }

    @ViewBuilder
    private func authorLabel(q: PoetryCompleteCatalog.Question) -> some View {
        let dynasty = q.entry.dynasty
        let author = q.entry.author
        if !dynasty.isEmpty || !author.isEmpty {
            HStack(spacing: 4) {
                if !dynasty.isEmpty { Text("【\(dynasty)】") }
                if !author.isEmpty  { Text(author) }
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func lineRow(text: String, idx: Int, state: LineState) -> some View {
        let punc = (idx % 2 == 0) ? "，" : "。"
        let (fg, bgStart, bgEnd): (Color, Color, Color) = {
            switch state {
            case .normal:  return (AppTheme.textPrimary, .clear, .clear)
            case .correct: return (.white, AppTheme.accentSage, AppTheme.accentMint)
            case .wrong:   return (.white, AppTheme.accentPink, AppTheme.accentTerracotta)
            }
        }()
        return HStack(spacing: 0) {
            Text(text)
            Text(punc)
        }
        .font(.system(size: 22, weight: .heavy, design: .serif))
        .foregroundStyle(fg)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
            LinearGradient(colors: [bgStart, bgEnd], startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: AppTheme.cornerSmall)
        )
        .modifier(PoetryShake(state: state))
    }

    @ViewBuilder
    private func blankLineRow(q: PoetryCompleteCatalog.Question) -> some View {
        if let p = picked {
            let st: LineState = (isCorrect == true) ? .correct : .wrong
            HStack(spacing: 0) {
                Text(p)
                Text((q.blankIndex % 2 == 0) ? "，" : "。")
            }
            .font(.system(size: 22, weight: .heavy, design: .serif))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                LinearGradient(
                    colors: st == .correct
                        ? [AppTheme.accentSage, AppTheme.accentMint]
                        : [AppTheme.accentPink, AppTheme.accentTerracotta],
                    startPoint: .leading, endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: AppTheme.cornerSmall)
            )
            .matchedGeometryEffect(id: p, in: animation)
            .modifier(PoetryShake(state: st))
            .overlay(alignment: .bottom) {
                if isCorrect == false {
                    Text("正确：\(q.answer)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.accentSage)
                        .offset(y: 22)
                }
            }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerSmall)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .foregroundStyle(kind.palette.0.opacity(0.65))
                Image(systemName: "questionmark")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(kind.palette.0.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
    }

    private var hintLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: isCorrect == true ? "checkmark.circle.fill"
                              : (isCorrect == false ? "xmark.circle.fill" : "hand.tap.fill"))
                .foregroundStyle(
                    isCorrect == true ? AppTheme.accentSage
                    : (isCorrect == false ? AppTheme.accentPink : kind.palette.0)
                )
            Text(
                isCorrect == true ? "答对了！"
                : (isCorrect == false ? "再接再厉" : "选出隐藏的那一句")
            )
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.textSecondary)
        }
        .animation(.easeInOut(duration: 0.2), value: isCorrect)
    }

    private func optionList(q: PoetryCompleteCatalog.Question) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(q.options.enumerated()), id: \.element) { (idx, line) in
                optionRow(line: line, label: ["A", "B", "C", "D"][idx], q: q)
            }
        }
    }

    @ViewBuilder
    private func optionRow(line: String, label: String, q: PoetryCompleteCatalog.Question) -> some View {
        let isPicked = (picked == line)
        if isPicked {
            Color.clear.frame(height: 56)
        } else {
            Button {
                handleTap(line: line, q: q)
            } label: {
                HStack(spacing: 12) {
                    Text(label)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(kind.palette.0, in: Circle())
                    Text(line)
                        .font(.system(size: 20, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                        .strokeBorder(kind.palette.0.opacity(0.25), lineWidth: 2)
                )
                .shadow(color: AppTheme.textPrimary.opacity(0.06), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
            .matchedGeometryEffect(id: line, in: animation)
            .disabled(picked != nil)
        }
    }

    // MARK: - 交互

    private func handleTap(line: String, q: PoetryCompleteCatalog.Question) {
        guard picked == nil else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            picked = line
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let correct = (line == q.answer)
            withAnimation(.easeInOut(duration: 0.2)) { isCorrect = correct }
            if correct { correctCount += 1 }
            let dwell: Double = correct ? 1.0 : 1.6
            DispatchQueue.main.asyncAfter(deadline: .now() + dwell) {
                advance()
            }
        }
    }

    private func advance() {
        if currentIndex + 1 >= totalQuestions {
            GameBestScoreStore.update(kind, score: correctCount)
            withAnimation(.easeInOut(duration: 0.2)) { showResult = true }
            return
        }
        currentIndex += 1
        picked = nil
        isCorrect = nil
    }

    private func restart() {
        reloadQuestions()
        startTime = Date()
        showResult = false
    }

    private func reloadQuestions() {
        questions = PoetryCompleteCatalog.makeQuestions(
            book: selection.book,
            cumulative: selection.cumulative,
            count: totalQuestions
        )
        currentIndex = 0
        picked = nil
        isCorrect = nil
        correctCount = 0
        startTime = Date()
    }
}

// MARK: - 错误时的横向抖动

private struct PoetryShake: ViewModifier {
    let state: LineState
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: phase)
            .onChange(of: state) { _, new in
                guard new == .wrong else { return }
                let pattern: [CGFloat] = [-10, 10, -8, 8, -4, 4, 0]
                animatePattern(pattern, idx: 0)
            }
    }

    private func animatePattern(_ p: [CGFloat], idx: Int) {
        guard idx < p.count else { return }
        withAnimation(.linear(duration: 0.06)) { phase = p[idx] }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            animatePattern(p, idx: idx + 1)
        }
    }
}
