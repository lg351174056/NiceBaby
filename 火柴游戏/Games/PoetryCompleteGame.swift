import SwiftUI

// MARK: - 行状态（文件级共享，供 ViewModifier 访问）
fileprivate enum LineState { case normal, correct, wrong }

// MARK: - 诗词补全数据层
//
// 数据来源：Bundle 里的“唐诗三百首.json”“唐诗三百首(二).json”
// 同时支持两种字段格式：
//   a) paragraphs: ["床前明月光，疑是地上霜。", "举头望明月，低头思故乡。"]
//   b) contents:   "床前明月光，疑是地上霜。\n举头望明月，低头思故乡。"
//
// 入选标准：切完子句后 = 4 句或 8 句，且全部句子字数一致（5 或 7），
// 这样填空时 4 个候选字数相同，不会一眼穿。

struct PoemCompleteEntry: Hashable {
    let title: String
    let author: String
    let dynasty: String
    let lines: [String]   // 切分后的句子（不含标点）
    let charPerLine: Int  // 每句字数（5 或 7）
}

enum PoetryCompleteCatalog {
    /// 启动时一次性构建。
    static let entries: [PoemCompleteEntry] = build()

    private static let resourceFiles = ["唐诗三百首", "唐诗三百首(二)"]

    private static func build() -> [PoemCompleteEntry] {
        var result: [PoemCompleteEntry] = []
        for name in resourceFiles {
            if let arr = loadFile(name: name) {
                result.append(contentsOf: arr)
            }
        }
        // 跨文件去重（按所有句子拼接做 key）
        var seen = Set<String>()
        var unique: [PoemCompleteEntry] = []
        for e in result {
            let key = e.lines.joined()
            if seen.insert(key).inserted {
                unique.append(e)
            }
        }
        return unique
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

        return arr.compactMap { e in
            let raw: String = {
                if let p = e.paragraphs, !p.isEmpty { return p.joined(separator: "\n") }
                if let c = e.contents, !c.isEmpty { return c }
                return ""
            }()
            if raw.isEmpty { return nil }

            let lines = splitToShortLines(raw)
            // 仅收 4/8 句、字数一致、5 或 7 字
            guard lines.count == 4 || lines.count == 8 else { return nil }
            let lens = lines.map { $0.count }
            guard let n = lens.first, lens.allSatisfy({ $0 == n }) else { return nil }
            guard n == 5 || n == 7 else { return nil }

            return PoemCompleteEntry(
                title: e.title ?? "",
                author: e.author ?? "",
                dynasty: e.dynasty ?? "",
                lines: lines,
                charPerLine: n
            )
        }
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
        let answer: String     // 正确的那一句（无标点）
        let options: [String]  // 4 选项已打乱
    }

    /// 出 N 道题。干扰句来自同字数池，要求与该首诗任何一句都不重复，且选项互不重复。
    static func makeQuestions(count: Int) -> [Question] {
        guard !entries.isEmpty else { return [] }

        // 按字数建立干扰句池
        var poolByLen: [Int: [String]] = [:]
        for e in entries {
            poolByLen[e.charPerLine, default: []].append(contentsOf: e.lines)
        }
        for (k, v) in poolByLen {
            poolByLen[k] = Array(Set(v))
        }

        var qs: [Question] = []
        for entry in entries.shuffled() {
            if qs.count >= count { break }
            let blank = Int.random(in: 0..<entry.lines.count)
            let answer = entry.lines[blank]
            let exclude = Set(entry.lines)
            let pool = poolByLen[entry.charPerLine] ?? []

            var distractors: [String] = []
            var seen = Set<String>([answer])
            var safety = 0
            while distractors.count < 3 && safety < 300 {
                if let s = pool.randomElement(),
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

// MARK: - 诗词补全游戏视图

struct PoetryCompleteGameView: View {
    let onExit: () -> Void

    @State private var questions: [PoetryCompleteCatalog.Question] = []
    @State private var currentIndex = 0
    @State private var picked: String? = nil      // 用户已点击的选项
    @State private var isCorrect: Bool? = nil     // nil = 未作答
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
            if questions.isEmpty {
                questions = PoetryCompleteCatalog.makeQuestions(count: totalQuestions)
                startTime = Date()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "scroll")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
            Text("暂无可用诗题")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
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
                if !dynasty.isEmpty {
                    Text("【\(dynasty)】")
                }
                if !author.isEmpty {
                    Text(author)
                }
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.textSecondary)
        }
    }

    /// 正常一行：文字 + 末标点（偶数索引"，"，奇数索引"。"）
    private func lineRow(text: String, idx: Int, state: LineState) -> some View {
        let punc = (idx % 2 == 0) ? "，" : "。"
        let (fg, bgStart, bgEnd): (Color, Color, Color) = {
            switch state {
            case .normal:
                return (AppTheme.textPrimary, .clear, .clear)
            case .correct:
                return (.white, AppTheme.accentSage, AppTheme.accentMint)
            case .wrong:
                return (.white, AppTheme.accentPink, AppTheme.accentTerracotta)
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

    /// 隐藏的那一行：未答 = 虚线方框 + 问号；已答 = 飞入的句子，颜色按对错
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

    // MARK: - 提示文字

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

    // MARK: - 候选选项

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
            // 占位（matchedGeometryEffect 的 source 端，让网格不抖）
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
        // 等飞行完成再判定
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
        questions = PoetryCompleteCatalog.makeQuestions(count: totalQuestions)
        currentIndex = 0
        picked = nil
        isCorrect = nil
        correctCount = 0
        startTime = Date()
        showResult = false
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
