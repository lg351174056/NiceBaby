import SwiftUI

// MARK: - 反义词库 · 儿童友好子集
//
// 数据源：Datas/TEXT/反义词库.txt（18,797 对，格式 `前——后`）
// 按字数与常用度分三档：启蒙(单字·核心) / 进阶(单字·扩展) / 挑战(双字)

struct AntonymPair: Hashable, Identifiable {
    let left: String
    let right: String
    let id = UUID()

    var isSingleChar: Bool { left.count == 1 && right.count == 1 }
    var maxCharCount: Int { max(left.count, right.count) }

    /// 是否包含指定词（任一侧匹配）
    func contains(_ word: String) -> Bool { left == word || right == word }

    /// 给定一侧，返回另一侧
    func opposite(of word: String) -> String? {
        if left == word { return right }
        if right == word { return left }
        return nil
    }
}

enum AntonymCatalog {
    /// 启蒙级核心单字对——最常用、最可视觉化，优先出现在翻翻乐与跷跷板易档。
    /// 排序即优先级：越靠前越优先被选中。
    private static let coreSinglePriority = [
        "大", "小", "多", "少", "上", "下", "左", "右", "前", "后",
        "里", "外", "高", "矮", "长", "短", "深", "浅", "厚", "薄",
        "宽", "窄", "远", "近", "快", "慢", "轻", "重", "冷", "热",
        "新", "旧", "好", "坏", "美", "丑", "真", "假", "对", "错",
        "有", "无", "生", "死", "动", "静", "来", "去", "开", "关",
        "黑", "白", "明", "暗", "胖", "瘦", "干", "湿", "早", "晚",
        "东", "西", "南", "北", "升", "降", "得", "失", "成", "败",
        "爱", "恨", "善", "恶", "是", "非", "强", "弱", "粗", "细"
    ]

    private static var allPairs: [AntonymPair] = []
    private static var singleCharPairs: [AntonymPair] = []
    private static var doubleCharPairs: [AntonymPair] = []
    private static var corePairs: [AntonymPair] = []
    private static var loaded = false

    /// 全量原始词对（不过滤字数/纯中文，仅去空白与空行），用于「全部词汇」合集浏览
    private static var rawAllPairs: [AntonymPair] = []
    private static var rawLoaded = false

    private static func ensureLoaded() {
        guard !loaded else { return }
        loaded = true

        guard let url = Bundle.main.url(forResource: "反义词库", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else { return }

        var seen = Set<String>()
        var singles: [AntonymPair] = []
        var doubles: [AntonymPair] = []

        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.contains("——") else { continue }
            let parts = trimmed.components(separatedBy: "——")
            guard parts.count == 2 else { continue }
            let l = parts[0].trimmingCharacters(in: .whitespaces)
            let r = parts[1].trimmingCharacters(in: .whitespaces)
            guard !l.isEmpty, !r.isEmpty, l != r else { continue }
            // 仅保留纯中文、字数 1–2
            guard isChinese(l), isChinese(r) else { continue }
            guard l.count <= 2, r.count <= 2 else { continue }
            // 去重（双向）
            let key = l < r ? "\(l)|\(r)" : "\(r)|\(l)"
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            let pair = AntonymPair(left: l, right: r)
            if pair.isSingleChar {
                singles.append(pair)
            } else {
                doubles.append(pair)
            }
        }

        singleCharPairs = singles
        doubleCharPairs = doubles
        allPairs = singles + doubles

        // 核心对：按优先级排序的常用单字对
        let prioritySet = coreSinglePriority
        var core: [AntonymPair] = []
        var usedWords = Set<String>()
        // 先按优先级顺序匹配
        for word in prioritySet {
            if let pair = singles.first(where: { $0.contains(word) && !usedWords.contains($0.left) && !usedWords.contains($0.right) }) {
                core.append(pair)
                usedWords.insert(pair.left)
                usedWords.insert(pair.right)
            }
        }
        // 补充剩余单字对
        for pair in singles where !usedWords.contains(pair.left) && !usedWords.contains(pair.right) {
            core.append(pair)
            usedWords.insert(pair.left)
            usedWords.insert(pair.right)
        }
        corePairs = core
    }

    private static func isChinese(_ s: String) -> Bool {
        s.unicodeScalars.allSatisfy { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
    }

    // MARK: - 难度档位

    enum Difficulty: String, CaseIterable {
        case easy    // 启蒙：核心单字对
        case medium  // 进阶：扩展单字对
        case hard    // 挑战：双字对

        var label: String {
            switch self {
            case .easy:   return "启蒙"
            case .medium: return "进阶"
            case .hard:   return "挑战"
            }
        }
    }

    /// 获取指定难度的随机 N 对（不重复）
    static func randomPairs(count: Int, difficulty: Difficulty) -> [AntonymPair] {
        ensureLoaded()
        let pool: [AntonymPair]
        switch difficulty {
        case .easy:   pool = corePairs.isEmpty ? singleCharPairs : Array(corePairs.prefix(60))
        case .medium: pool = singleCharPairs.isEmpty ? allPairs : singleCharPairs
        case .hard:   pool = doubleCharPairs.isEmpty ? allPairs : doubleCharPairs
        }
        guard pool.count >= count else { return Array(pool.shuffled()) }
        return Array(pool.shuffled().prefix(count))
    }

    /// 获取一个随机对（指定难度）
    static func randomPair(difficulty: Difficulty) -> AntonymPair? {
        ensureLoaded()
        let pool: [AntonymPair]
        switch difficulty {
        case .easy:   pool = corePairs.isEmpty ? singleCharPairs : corePairs
        case .medium: pool = singleCharPairs
        case .hard:   pool = doubleCharPairs
        }
        return pool.randomElement()
    }

    /// 生成一道选择题：返回正确对 + 2 个干扰选项（干扰项来自同难度池的其他对）
    struct QuizQuestion {
        let prompt: String         // 题面词
        let answer: String         // 正确反义词
        let choices: [String]      // 3 个选项（含正确答案，已打乱）
        let correctIndex: Int
        let pair: AntonymPair
    }

    static func randomQuiz(difficulty: Difficulty) -> QuizQuestion? {
        ensureLoaded()
        guard let pair = randomPair(difficulty: difficulty) else { return nil }

        let pool: [AntonymPair]
        switch difficulty {
        case .easy:   pool = corePairs.isEmpty ? singleCharPairs : corePairs
        case .medium: pool = singleCharPairs
        case .hard:   pool = doubleCharPairs
        }

        // 随机选哪一侧做题面
        let useLeftAsPrompt = Bool.random()
        let prompt = useLeftAsPrompt ? pair.left : pair.right
        let answer = useLeftAsPrompt ? pair.right : pair.left

        // 取 2 个干扰项：同字数的其他词
        let distractorPool = pool.filter { $0.left != pair.left && $0.right != pair.right }
        let distractors = Array(distractorPool.shuffled().prefix(2)).map { useLeftAsPrompt ? $0.right : $0.left }

        var choices = distractors + [answer]
        choices.shuffle()
        guard let correctIndex = choices.firstIndex(of: answer) else { return nil }

        return QuizQuestion(prompt: prompt, answer: answer, choices: choices, correctIndex: correctIndex, pair: pair)
    }

    /// 图册浏览：返回按难度分组的全部对（限量）
    static func albumPairs(difficulty: Difficulty, limit: Int = 60) -> [AntonymPair] {
        ensureLoaded()
        let pool: [AntonymPair]
        switch difficulty {
        case .easy:   pool = corePairs
        case .medium: pool = singleCharPairs
        case .hard:   pool = doubleCharPairs
        }
        return Array(pool.prefix(limit))
    }

    /// 总对数（统计用）
    static var totalCount: Int {
        ensureLoaded()
        return allPairs.count
    }

    /// 全量原始词对（不过滤，去重），覆盖 .txt 全部 18,797 行（去重后约 14,900+）
    static var allRawPairs: [AntonymPair] {
        ensureRawLoaded()
        return rawAllPairs
    }

    /// 原始总行数（统计「合集」总量用，含重复）
    static var rawLineCount: Int {
        ensureRawLoaded()
        return rawAllPairs.count
    }

    private static func ensureRawLoaded() {
        guard !rawLoaded else { return }
        rawLoaded = true
        guard let url = Bundle.main.url(forResource: "反义词库", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        var seen = Set<String>()
        var pairs: [AntonymPair] = []
        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.contains("——") else { continue }
            let parts = trimmed.components(separatedBy: "——")
            guard parts.count == 2 else { continue }
            let l = parts[0].trimmingCharacters(in: .whitespaces)
            let r = parts[1].trimmingCharacters(in: .whitespaces)
            guard !l.isEmpty, !r.isEmpty, l != r else { continue }
            let key = l < r ? "\(l)|\(r)" : "\(r)|\(l)"
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            pairs.append(AntonymPair(left: l, right: r))
        }
        rawAllPairs = pairs
    }
}
