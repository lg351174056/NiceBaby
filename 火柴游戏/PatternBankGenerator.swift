import Foundation

// MARK: - 图形映射（看图找规律用苹果 emoji）

enum PatternFig {
    static let emojis: [String: String] = [
        "1": "🔴", "2": "🟠", "3": "🟡", "4": "🟢",
        "5": "🔵", "6": "🟣", "7": "⭐", "8": "❤️",
        "9": "🔶", "10": "🔷", "11": "🍎", "12": "🍌",
        "13": "🍇", "14": "🐱", "15": "🦋", "16": "🎈",
        "17": "➡️",
    ]
    static let names: [String: String] = [
        "1": "红点点", "2": "橙点点", "3": "黄点点", "4": "绿点点",
        "5": "蓝点点", "6": "紫点点", "7": "小星星", "8": "小爱心",
        "9": "橙菱菱", "10": "蓝菱菱", "11": "红苹果", "12": "香蕉",
        "13": "葡萄", "14": "小猫咪", "15": "蝴蝶", "16": "气球",
        "17": "箭头",
    ]
    static func emoji(for token: String) -> String? { emojis[token] }
    static func name(for token: String) -> String { names[token] ?? token }
}

// MARK: - 格内编码解析：`id[:数量][:r角度][:s倍数]`，多段用 + 连接

struct FigPart {
    let emoji: String
    let count: Int
    let rotation: Double
    let scale: Double
}

enum FigParser {
    static func parts(_ token: String) -> [FigPart] {
        token.split(separator: "+").map { seg in
            let comps = seg.split(separator: ":")
            let id = String(comps[0])
            var count = 1
            var rotation = 0.0
            var scale = 1.0
            for c in comps.dropFirst() {
                if c.hasPrefix("r") { rotation = Double(c.dropFirst()) ?? 0 }
                else if c.hasPrefix("s") { scale = Double(c.dropFirst()) ?? 1 }
                else { count = Int(c) ?? 1 }
            }
            return FigPart(emoji: PatternFig.emoji(for: id) ?? id,
                           count: count, rotation: rotation, scale: scale)
        }
    }

    /// 提取 token 内所有基础图形 id（用于校验）
    static func ids(_ token: String) -> [String] {
        token.split(separator: "+").map { String($0.split(separator: ":")[0]) }
    }
}

// MARK: - 确定性随机（第 N 关永远生成同一题）

private struct SeedGen {
    var state: UInt64
    init(_ seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z = z ^ (z >> 31)
        return z
    }

    mutating func int(_ lo: Int, _ hi: Int) -> Int {
        lo + Int(Int64(next() % UInt64(hi - lo + 1)))
    }
}

// MARK: - 关卡生成器

enum PatternBankGenerator {
    static func generate() -> [PatternQuestion] {
        generateKt() + generateSz()
    }

    // MARK: 数字找规律 · 300 关

    private struct SzT {
        var values: [Int]
        var blanks: [Int]
        var answer: [Int]
        var jiexi: String
        var columns: Int? = nil
        var rule: String = ""
        var options: [String] = []

        var tokens: [String] {
            var t = values.map { String($0) }
            for b in blanks { t[b] = "_" }
            return t
        }
    }

    private typealias Tpl = (inout SeedGen) -> SzT

    private static func generateSz() -> [PatternQuestion] {
        (1...300).map { szQuestion($0) }
    }

    private static func szQuestion(_ lv: Int) -> PatternQuestion {
        var rng = SeedGen(UInt64(0xB14 + (lv << 16)))
        let g = szGrade(for: lv)
        let list = szTemplates[g]!
        var t: SzT = list[szTemplateIndex(lv: lv, g: g, count: list.count)](&rng)
        if g == 1 { t.options = [] }   // 低年级保留键盘输入；中高年级优先 4 选 1
        if g >= 3, let enhanced = tryAddSecondBlank(t, rng: &rng) {
            t = enhanced
        }
        return PatternQuestion(
            mtype: "sz1", lv: lv,
            tokens: t.tokens,
            options: t.options,
            answer: t.answer.map(String.init),
            jiexi: t.jiexi,
            rule: t.rule,
            columns: t.columns
        )
    }

    private static func szGrade(for lv: Int) -> Int {
        switch lv {
        case 1...50: return 1
        case 51...100: return 2
        case 101...150: return 3
        case 151...200: return 4
        case 201...250: return 5
        default: return 6
        }
    }

    private static func gradeStart(g: Int) -> Int {
        switch g {
        case 1: return 1
        case 2: return 51
        case 3: return 101
        case 4: return 151
        case 5: return 201
        default: return 251
        }
    }

    private static func shuffledDeck(salt: UInt64, g: Int, round: Int, count: Int) -> [Int] {
        var rng = SeedGen(salt &+ 0xDCCC &+ (UInt64(g) << 24) &+ (UInt64(round) << 8))
        var deck = Array(0..<count)
        for i in stride(from: count - 1, through: 1, by: -1) {
            let j = Int(Int64(rng.next() % UInt64(i + 1)))
            deck.swapAt(i, j)
        }
        return deck
    }

    private static func szTemplateIndex(lv: Int, g: Int, count: Int) -> Int {
        let pos = lv - gradeStart(g: g)
        var lastFinal = -1
        var result = 0
        for p in 0...max(pos, 0) {
            let round = p / count
            let idx = p % count
            var pick = shuffledDeck(salt: 0x1, g: g, round: round, count: count)[idx]
            if p > 0, pick == lastFinal { pick = (pick + 1) % count }
            lastFinal = pick
            result = pick
        }
        return result
    }

    private static var szTemplates: [Int: [Tpl]] {
        [
            1: [arithUp(1, 4, 1, 10), arithDown(1, 4, 25, 55),
                cycle(period: 2, lo: 1, hi: 9, distinct: false),
                cycle(period: 3, lo: 1, hi: 9, distinct: true),
                digitSum(2), pairSum(8, 10), gridRepeat3(), grid6Repeat()],
            2: [arithUp(2, 7, 2, 12), arithDown(3, 8, 55, 110),
                cycle(period: 4, lo: 2, hi: 16, distinct: true),
                twoSeq(1, 1, 5, 2, 6, 10, 20, 3, 8),
                diffChain(1, 2, 1, 1, 1, 5), digitSum(2), pairSum(11, 18),
                digitRule(1), grid6Plus(), butterfly("和", 2, 15, 2, 15)],
            3: [arithUp(5, 15, 5, 20), diffChain(2, 3, 1, 2, 3, 8),
                twoSeq(1, 2, 8, 3, 8, 20, 40, 4, 10),
                doubleUp(2, 1, 4, 120), digitSum(3),
                butterfly("差", 8, 30, 4, 20), magic(1), digitRule(2), gridRowArith()],
            4: [arithUp(10, 30, 10, 40), diffChain(3, 5, 1, 2, 5, 12),
                twoSeq(1, 3, 9, 3, 9, 30, 60, 5, 12),
                doubleUp(2, 3, 8, 200), squares(1),
                butterfly("积", 2, 9, 2, 9), magic(2), halve(192, 960), gridColArith()],
            5: [doubleUp(3, 1, 3, 150), squares(2), fib(1, 2, 1, 4, 400),
                mulAdd(2, 1, 3, 1, 3, 300), halve(128, 640), magic(2),
                twoSeq(2, 2, 6, 3, 7, 20, 40, 4, 10), gridStepGrow()],
            6: [squares(3), fib(2, 3, 2, 5, 600), mulAdd(3, -1, 1, 1, 4, 400),
                magic(3), diffChain(4, 6, 2, 3, 6, 15),
                twoSeq(2, 3, 9, 4, 9, 30, 60, 6, 12),
                butterfly("积", 3, 12, 3, 12), halve(640, 960)],
        ]
    }

    // MARK: 数字 · 选项干扰项（答案必在选项中）

    private static func pickOptions(answer: [Int], pool: [Int], rng: inout SeedGen) -> [String] {
        let aSet = Set(answer)
        var cands = pool
        for v in answer { cands.append(contentsOf: [v + 1, v - 1, v + 2]) }
        cands = cands.filter { !aSet.contains($0) }
        var uniq: [Int] = []
        for c in cands where !uniq.contains(c) { uniq.append(c) }
        cands = uniq
        for i in stride(from: cands.count - 1, through: 1, by: -1) {
            let j = Int(Int64(rng.next() % UInt64(i + 1)))
            cands.swapAt(i, j)
        }
        var seen: Set<Int> = []
        var result = answer.filter { seen.insert($0).inserted }
        for c in cands where result.count < 4 { result.append(c) }
        for i in stride(from: result.count - 1, through: 1, by: -1) {
            let j = Int(Int64(rng.next() % UInt64(i + 1)))
            result.swapAt(i, j)
        }
        return result.map(String.init)
    }

    // MARK: 数字 · 双空增强（高年级把部分单空线性题升级为双空，占比约 30%）

    private static func tryAddSecondBlank(_ t: SzT, rng: inout SeedGen) -> SzT? {
        // 只在线性/拆数/隔项等“任意一项都可由完整序列唯一推出”的题型上增强，
        // 幻方/蝴蝶数/宫格会出现两个未知、不唯一，不做双空。
        let safeRules: Set<String> = [
            "等差", "差链", "隔项", "循环", "平方", "斐波那契", "倍增", "乘加", "减半",
            "拆数", "分组和", "数位",
        ]
        guard t.blanks.count == 1, safeRules.contains(t.rule), t.values.count >= 6 else { return nil }
        guard rng.int(1, 100) <= 40 else { return nil }

        let existing = Set(t.blanks)
        var candidates: [Int] = []
        for i in 1..<(t.values.count - 1) where !existing.contains(i) {
            if !existing.contains(i - 1) && !existing.contains(i + 1) {
                candidates.append(i)
            }
        }
        guard !candidates.isEmpty else { return nil }

        let pos = candidates[rng.int(0, candidates.count - 1)]
        let ans1 = t.answer[0]
        let ans2 = t.values[pos]
        let answers = [ans1, ans2]
        let blanks = (t.blanks + [pos]).sorted()
        let pool = t.values + [ans1 + 1, ans1 - 1, ans2 + 1, ans2 - 1]
        let options = pickOptions(answer: answers, pool: pool, rng: &rng)
        let jiexi = t.jiexi + "；另一空也按同一规律填 \(ans2)"
        return SzT(values: t.values, blanks: blanks, answer: answers,
                   jiexi: jiexi, columns: t.columns, rule: t.rule, options: options)
    }

    private static func digitSumOf(_ n: Int) -> Int {
        var v = n, s = 0
        while v > 0 { s += v % 10; v /= 10 }
        return s
    }

    // MARK: 数字 · 模板工厂

    private static func arithUp(_ slo: Int, _ shi: Int, _ alo: Int, _ ahi: Int) -> Tpl {
        { rng in
            let step = rng.int(slo, shi)
            let start = rng.int(alo, ahi)
            let len = rng.int(6, 8)
            let bpos = rng.int(2, len - 2)
            let vals = (0..<len).map { start + $0 * step }
            let ans = vals[bpos]
            let pool = [ans + step, ans - step, ans + 1, ans - 1, vals[0], vals[len - 1]]
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "每一项都比前一项多 \(step)，所以空位填 \(ans)",
                       rule: "等差", options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func arithDown(_ slo: Int, _ shi: Int, _ alo: Int, _ ahi: Int) -> Tpl {
        { rng in
            let step = rng.int(slo, shi)
            let start = rng.int(alo, ahi)
            let len = rng.int(6, 8)
            let bpos = rng.int(2, len - 2)
            let vals = (0..<len).map { start - $0 * step }
            let ans = vals[bpos]
            let pool = [ans - step, ans + step, ans + 1, ans - 1, vals[0], vals[len - 1]]
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "每一项都比前一项少 \(step)，所以空位填 \(ans)",
                       rule: "等差", options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func cycle(period: Int, lo: Int, hi: Int, distinct: Bool, columns: Int? = nil) -> Tpl {
        { rng in
            var base: [Int] = []
            while base.count < period {
                let v = rng.int(lo, hi)
                if distinct && base.contains(v) { continue }
                base.append(v)
            }
            let len = period * 3
            let vals = (0..<len).map { base[$0 % period] }
            let bpos = rng.int(period, len - 1)
            let ans = vals[bpos]
            let pool = base + [ans + 1, ans - 1]
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "数字按 \(base.map(String.init).joined(separator: "、")) 循环出现，所以空位填 \(ans)",
                       columns: columns, rule: "循环",
                       options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func digitSum(_ digits: Int) -> Tpl {
        { rng in
            var vals: [Int] = []
            for _ in 0..<4 {
                let num = digits == 2 ? rng.int(12, 89) : rng.int(123, 789)
                vals.append(num)
                vals.append(digitSumOf(num))
            }
            let bpos = vals.count - 1
            let ans = vals[bpos]
            let numBefore = vals[bpos - 1]
            let pool = [digitSumOf(numBefore) + 1, digitSumOf(numBefore) - 1, ans + 1, ans - 1]
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "每个数的各位数字相加，就是它后面的数，所以空位填 \(ans)",
                       columns: 2, rule: "拆数",
                       options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func pairSum(_ slo: Int, _ shi: Int) -> Tpl {
        { rng in
            let s = rng.int(slo, shi)
            var vals: [Int] = []
            for _ in 0..<4 {
                let a = rng.int(1, s - 1)
                vals.append(a)
                vals.append(s - a)
            }
            let bpos = vals.count - 1
            let ans = vals[bpos]
            let pool = [s - 1, s + 1, ans - 1, ans + 1]
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "每两个数一组，相加都等于 \(s)，所以空位填 \(ans)",
                       columns: 2, rule: "分组和",
                       options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func digitRule(_ mode: Int) -> Tpl {
        { rng in
            let len = 5
            let vals: [Int]
            if mode == 1 {
                let t0 = rng.int(2, 5), u0 = rng.int(1, 4)
                vals = (0..<len).map { (t0 + $0) * 10 + (u0 + $0) }
            } else {
                let t0 = 2, u0 = rng.int(4, 6)
                vals = (0..<len).map { (t0 + 2 * $0) * 10 + (u0 - $0) }
            }
            let bpos = len - 1
            let ans = vals[bpos]
            let pool = mode == 1 ? [ans + 11, ans - 11, ans + 1, ans - 1]
                                 : [ans + 21, ans - 21, ans + 1, ans - 1]
            let ruleText = mode == 1 ? "十位和个位每次都各加 1" : "十位每次加 2、个位每次减 1"
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "\(ruleText)，所以空位填 \(ans)",
                       rule: "数位", options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func twoSeq(_ blanks: Int, _ s1Lo: Int, _ s1Hi: Int, _ st1Lo: Int, _ st1Hi: Int,
                               _ s2Lo: Int, _ s2Hi: Int, _ st2Lo: Int, _ st2Hi: Int) -> Tpl {
        { rng in
            let s1 = rng.int(s1Lo, s1Hi), st1 = rng.int(st1Lo, st1Hi)
            let s2 = rng.int(s2Lo, s2Hi), st2 = rng.int(st2Lo, st2Hi)
            let len = 11
            var vals: [Int] = []
            for i in 0..<len { vals.append(i % 2 == 0 ? s1 + (i / 2) * st1 : s2 + (i / 2) * st2) }
            if blanks == 1 {
                let bpos = rng.int(2, len - 3)
                let odd = bpos % 2 == 0
                let ans = vals[bpos]
                let pool = [ans + st1, ans + st2, ans - st1, ans - st2]
                return SzT(values: vals, blanks: [bpos], answer: [ans],
                           jiexi: "两个数列穿插：单数位每次 +\(st1)、双数位每次 +\(st2)，这个空位在\(odd ? "单数位" : "双数位")，所以填 \(ans)",
                           rule: "隔项", options: pickOptions(answer: [ans], pool: pool, rng: &rng))
            } else {
                let b1 = rng.int(2, 5), b2 = b1 + 4
                let ans1 = vals[b1], ans2 = vals[b2]
                return SzT(values: vals, blanks: [b1, b2], answer: [ans1, ans2],
                           jiexi: "两个数列穿插：它们的差分别是 \(st1) 和 \(st2)，所以填 \(ans1)、\(ans2)",
                           rule: "隔项", options: [])
            }
        }
    }

    private static func diffChain(_ d0Lo: Int, _ d0Hi: Int, _ dStepLo: Int, _ dStepHi: Int,
                                  _ startLo: Int, _ startHi: Int) -> Tpl {
        { rng in
            let start = rng.int(startLo, startHi)
            let d0 = rng.int(d0Lo, d0Hi)
            let dStep = rng.int(dStepLo, dStepHi)
            let len = 7
            var vals = [start]
            for i in 1..<len { vals.append(vals[i - 1] + d0 + (i - 1) * dStep) }
            let bpos = len - 2
            let ans = vals[bpos]
            let pool = [ans + (d0 + (len - 2) * dStep), ans + 1, ans - 1, ans + 2]
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "相邻两数的差越来越大，依次多 \(dStep)（差 \(d0)、\(d0 + dStep)、\(d0 + 2 * dStep)…），所以空位填 \(ans)",
                       rule: "差链", options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func doubleUp(_ m: Int, _ startLo: Int, _ startHi: Int, _ cap: Int) -> Tpl {
        { rng in
            let start = rng.int(startLo, startHi)
            var vals = [start]
            while vals.count < 6 && vals.last! * m <= cap { vals.append(vals.last! * m) }
            if vals.count < 5 { return arithUp(2, 7, 2, 12)(&rng) }
            let bpos = vals.count - 2
            let ans = vals[bpos]
            let pool = [ans * m, ans / m, ans + 1, ans - 1]
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "每一项都是前一项的 \(m) 倍，所以空位填 \(ans)",
                       rule: "倍增", options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func squares(_ startK: Int) -> Tpl {
        { rng in
            let len = 7
            let vals = (0..<len).map { ($0 + startK) * ($0 + startK) }
            let bpos = len - 2
            let ans = vals[bpos]
            let k = startK + bpos
            let pool = [(k + 1) * (k + 1), (k - 1) * (k - 1), ans + 1, ans - 1]
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "它们是 \(startK)²、\(startK + 1)²、\(startK + 2)²…，所以空位填 \(ans)",
                       rule: "平方", options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func fib(_ aLo: Int, _ aHi: Int, _ bLo: Int, _ bHi: Int, _ cap: Int) -> Tpl {
        { rng in
            let a = rng.int(aLo, aHi), b = rng.int(bLo, bHi)
            var vals = [a, b]
            while vals.count < 9 && vals[vals.count - 1] + vals[vals.count - 2] <= cap {
                vals.append(vals[vals.count - 1] + vals[vals.count - 2])
            }
            if vals.count < 6 { return squares(1)(&rng) }
            let bpos = vals.count - 2
            let ans = vals[bpos]
            let pool = [vals[bpos - 1] + vals[bpos - 2], vals[bpos + 1] - vals[bpos], ans + 1, ans - 1]
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "从第 3 项起，每一项等于前两项的和，所以空位填 \(ans)",
                       rule: "斐波那契", options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func mulAdd(_ m: Int, _ cLo: Int, _ cHi: Int, _ startLo: Int, _ startHi: Int, _ cap: Int) -> Tpl {
        { rng in
            let c = rng.int(cLo, cHi)
            let start = rng.int(startLo, startHi)
            var vals = [start]
            while vals.count < 6 && vals.last! * m + c <= cap && vals.last! * m + c >= 0 {
                vals.append(vals.last! * m + c)
            }
            if vals.count < 5 { return arithUp(2, 7, 2, 12)(&rng) }
            let bpos = vals.count - 2
            let ans = vals[bpos]
            let pool = [ans * m + c, ans + 1, ans - 1, ans + c]
            let op = c >= 0 ? "再加 \(c)" : "再减 \(-c)"
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "每一项都等于前一项乘 \(m) \(op)，所以空位填 \(ans)",
                       rule: "乘加", options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func halve(_ startLo: Int, _ startHi: Int) -> Tpl {
        { rng in
            let odd = rng.int(1, 9)
            var start = odd
            while start * 2 <= startHi { start *= 2 }
            if start < startLo { return arithDown(2, 6, 40, 90)(&rng) }
            var vals = [start]
            while vals.count < 6 && vals.last! % 2 == 0 { vals.append(vals.last! / 2) }
            let bpos = vals.count - 1
            let ans = vals[bpos]
            let pool = [ans * 2, ans / 2, ans + 1, ans - 1]
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "每一项都是前一项的一半，所以空位填 \(ans)",
                       rule: "减半", options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func butterfly(_ mode: String, _ aLo: Int, _ aHi: Int, _ bLo: Int, _ bHi: Int) -> Tpl {
        { rng in
            let a = rng.int(aLo, aHi)
            let b = rng.int(bLo, bHi)
            let ans: Int
            let desc: String
            switch mode {
            case "和": ans = a + b; desc = "和"
            case "差": ans = max(a, b) - min(a, b); desc = "差（大减小）"
            default: ans = a * b; desc = "积"
            }
            let pool: [Int] = mode == "和" ? [a + b + 1, a + b - 1, abs(a - b), a + b + 2]
                              : mode == "差" ? [abs(a - b) + 1, abs(a - b) - 1, a + b, abs(a - b) + 2]
                              : [a * b + 1, a * b - 1, a + b, a * b + a]
            return SzT(values: [a, ans, b], blanks: [1], answer: [ans],
                       jiexi: "中间数是两边数的\(desc)：\(a) 和 \(b) 的\(desc)是 \(ans)",
                       columns: 3, rule: "蝴蝶数",
                       options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func magic(_ level: Int) -> Tpl {
        { rng in
            if level == 1 {
                let S = rng.int(12, 20)
                var grid: [Int] = []
                for _ in 0..<3 {
                    let x = rng.int(1, S - 3)
                    let y = rng.int(1, S - x - 1)
                    grid.append(contentsOf: [x, y, S - x - y])
                }
                // 避免列也刚好凑成 S（造成歧义）
                var colSum: [Int] = []
                for c in 0..<3 { colSum.append(grid[c] + grid[c + 3] + grid[c + 6]) }
                var guardCount = 0
                while colSum.contains(S) && guardCount < 20 {
                    grid = []
                    for _ in 0..<3 {
                        let x = rng.int(1, S - 3)
                        let y = rng.int(1, S - x - 1)
                        grid.append(contentsOf: [x, y, S - x - y])
                    }
                    colSum = []
                    for c in 0..<3 { colSum.append(grid[c] + grid[c + 3] + grid[c + 6]) }
                    guardCount += 1
                }
                let bpos = rng.int(6, 8)
                let ans = grid[bpos]
                return SzT(values: grid, blanks: [bpos], answer: [ans],
                           jiexi: "每一行相加都等于 \(S)，所以空位填 \(ans)",
                           columns: 3, rule: "幻方",
                           options: pickOptions(answer: [ans], pool: [ans + 1, ans - 1, ans + 2], rng: &rng))
            } else if level == 2 {
                let S = rng.int(24, 45)
                let a = rng.int(1, S - 2), b = rng.int(1, S - a - 1), c = S - a - b
                let d = rng.int(1, S - 2), e = rng.int(1, S - d - 1), f = S - d - e
                let g = S - a - d, h = S - b - e, i = S - c - f
                if g < 1 || h < 1 || i < 1 { return magic(1)(&rng) }
                let grid = [a, b, c, d, e, f, g, h, i]
                let bpos = rng.int(6, 8)
                let ans = grid[bpos]
                return SzT(values: grid, blanks: [bpos], answer: [ans],
                           jiexi: "横着加、竖着加都等于 \(S)，所以空位填 \(ans)",
                           columns: 3, rule: "幻方",
                           options: pickOptions(answer: [ans], pool: [ans + 1, ans - 1, ans + 2], rng: &rng))
            } else {
                let k = rng.int(0, 3)
                var grid = [8, 1, 6, 3, 5, 7, 4, 9, 2].map { $0 + k }
                for _ in 0..<rng.int(0, 3) { grid = rotate90(grid) }
                if rng.int(0, 1) == 1 { grid = mirrorH(grid) }
                let bpos = rng.int(1, 8)
                let ans = grid[bpos]
                let S = 15 + 3 * k
                return SzT(values: grid, blanks: [bpos], answer: [ans],
                           jiexi: "横着、竖着、斜着相加都等于 \(S)（洛书幻方），所以空位填 \(ans)",
                           columns: 3, rule: "幻方",
                           options: pickOptions(answer: [ans], pool: [ans + 1, ans - 1, ans + 2], rng: &rng))
            }
        }
    }

    private static func rotate90(_ g: [Int]) -> [Int] { [g[6], g[3], g[0], g[7], g[4], g[1], g[8], g[5], g[2]] }
    private static func mirrorH(_ g: [Int]) -> [Int] { [g[2], g[1], g[0], g[5], g[4], g[3], g[8], g[7], g[6]] }

    // MARK: 数字 · 宫格版式

    private static func gridRepeat3() -> Tpl {
        { rng in
            var nums = Array(1...9)
            let a = nums.remove(at: rng.int(0, nums.count - 1))
            let b = nums.remove(at: rng.int(0, nums.count - 1))
            let c = nums.remove(at: rng.int(0, nums.count - 1))
            let vals = [a, b, c, a, b, c, a, b, c]
            let bpos = rng.int(0, 1) == 0 ? 5 : 8
            let ans = vals[bpos]
            let pool = [a, b, c].filter { $0 != ans } + [ans + 1, ans - 1]
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "九宫格里每一行都是 \(a)、\(b)、\(c)，所以空位填 \(ans)",
                       columns: 3, rule: "宫格",
                       options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func grid6Repeat() -> Tpl {
        { rng in
            let a = rng.int(1, 9), b = rng.int(1, 9), c = rng.int(1, 9)
            let vals = [a, b, c, a, b, c]
            let bpos = rng.int(3, 5)
            let ans = vals[bpos]
            let pool = [a, b, c].filter { $0 != ans } + [ans + 1]
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "下面一行和上面一行完全一样，所以空位填 \(ans)",
                       columns: 3, rule: "宫格",
                       options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func grid6Plus() -> Tpl {
        { rng in
            let a = rng.int(1, 9), b = rng.int(2, 10), c = rng.int(3, 12), k = rng.int(2, 9)
            let vals = [a, b, c, a + k, b + k, c + k]
            let bpos = rng.int(3, 5)
            let ans = vals[bpos]
            let pool = [a, b, c].filter { $0 != ans } + [ans + k, ans - k]
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "下面一行每个数都比上面一行多 \(k)，所以空位填 \(ans)",
                       columns: 3, rule: "宫格",
                       options: pickOptions(answer: [ans], pool: pool, rng: &rng))
        }
    }

    private static func gridRowArith() -> Tpl {
        { rng in
            let s = rng.int(1, 9), p = rng.int(2, 4), q = rng.int(5, 9)
            let vals = (0..<9).map { s + ($0 / 3) * q + ($0 % 3) * p }
            let bpos = rng.int(0, 1) == 0 ? 8 : 7
            let ans = vals[bpos]
            return SzT(values: vals, blanks: [bpos], answer: [ans],
                       jiexi: "每一行从左到右都多 \(p)，每行开头的数又比上一行多 \(q)，所以空位填 \(ans)",
                       columns: 3, rule: "宫格",
                       options: pickOptions(answer: [ans], pool: [ans + p, ans - p, ans + q], rng: &rng))
        }
    }

    private static func gridColArith() -> Tpl {
        { rng in
            let s = rng.int(1, 20), k1 = rng.int(3, 8), k2 = k1 + rng.int(2, 6), d = rng.int(4, 12)
            let starts = [s, s + k1, s + k2]
            let vals = (0..<9).map { starts[$0 % 3] + ($0 / 3) * d }
            let ans = vals[8]
            return SzT(values: vals, blanks: [8], answer: [ans],
                       jiexi: "竖着看：每一列从上到下都多 \(d)，所以空位填 \(ans)",
                       columns: 3, rule: "宫格",
                       options: pickOptions(answer: [ans], pool: [ans + d, ans - d, ans + 1], rng: &rng))
        }
    }

    private static func gridStepGrow() -> Tpl {
        { rng in
            let s = rng.int(1, 6), p = rng.int(2, 3)
            var g = rng.int(2 * p + 2, 9)
            if g == 2 * p + 2 { g += 1 }
            let vals = (0..<9).map { s + ($0 / 3) * g + ($0 % 3) * (p + $0 / 3) }
            let ans = vals[8]
            return SzT(values: vals, blanks: [8], answer: [ans],
                       jiexi: "每一行加的数越来越大（第1行加\(p)、第2行加\(p + 1)、第3行加\(p + 2)），每行开头又多 \(g)，所以空位填 \(ans)",
                       columns: 3, rule: "宫格",
                       options: pickOptions(answer: [ans], pool: [ans + p + 2, ans - (p + 2), ans + 1], rng: &rng))
        }
    }

    // MARK: 看图找规律 · 200 关

    private struct KtT {
        var base: [String]
        var blanks: [Int]
        var answer: [String]
        var jiexi: String
        var columns: Int? = nil
        var rule: String = ""
        var options: [String] = []

        var tokens: [String] {
            var t = base
            for b in blanks { t[b] = "_" }
            return t
        }
    }

    private typealias KtTpl = (inout SeedGen) -> KtT

    private static func generateKt() -> [PatternQuestion] {
        (1...200).map { ktQuestion($0) }
    }

    private static func ktQuestion(_ lv: Int) -> PatternQuestion {
        var rng = SeedGen(UInt64(0xB1A + (lv << 16)))
        let g = ktGrade(for: lv)
        let list = ktTemplates[g]!
        let t: KtT = list[ktTemplateIndex(lv: lv, g: g, count: list.count)](&rng)
        return PatternQuestion(
            mtype: "kt", lv: lv,
            tokens: t.tokens,
            options: t.options,
            answer: t.answer,
            jiexi: t.jiexi,
            rule: t.rule,
            columns: t.columns
        )
    }

    private static func ktGrade(for lv: Int) -> Int {
        switch lv {
        case 1...60: return 1
        case 61...140: return 2
        default: return 3
        }
    }

    private static func ktGradeStart(g: Int) -> Int {
        switch g {
        case 1: return 1
        case 2: return 61
        default: return 141
        }
    }

    private static func ktTemplateIndex(lv: Int, g: Int, count: Int) -> Int {
        let pos = lv - ktGradeStart(g: g)
        var lastFinal = -1
        var result = 0
        for p in 0...max(pos, 0) {
            let round = p / count
            let idx = p % count
            var pick = shuffledDeck(salt: 0x2, g: g, round: round, count: count)[idx]
            if p > 0, pick == lastFinal { pick = (pick + 1) % count }
            lastFinal = pick
            result = pick
        }
        return result
    }

    @MainActor private static var ktTemplates: [Int: [KtTpl]] {
        [
            1: [ktCycle2, ktCycle3, ktGrid6Pair, ktMirror, ktCountGrow, ktGroupPair],
            2: [ktCycle4, ktGroupPair, ktMirror, ktCountColorDual, ktRotate, ktCycle3, ktCountGrow],
            3: [ktGridRotate, ktInterleave, ktAddShape, ktRotate, ktCountColorDual, ktCycle4],
        ]
    }

    private static func kr(_ rng: inout SeedGen, away: Set<String> = []) -> String {
        var pool = (1...16).map(String.init).filter { !away.contains($0) }
        return pool.remove(at: rng.int(0, pool.count - 1))
    }

    private static func ktPickOptions(answers: [String], pool: [String], rng: inout SeedGen) -> [String] {
        let aSet = Set(answers)
        var cands = pool + ["11", "12", "13", "14"]
        cands = cands.filter { !aSet.contains($0) }
        var uniq: [String] = []
        for c in cands where !uniq.contains(c) { uniq.append(c) }
        cands = uniq
        for i in stride(from: cands.count - 1, through: 1, by: -1) {
            let j = Int(Int64(rng.next() % UInt64(i + 1)))
            cands.swapAt(i, j)
        }
        var seen: Set<String> = []
        var result = answers.filter { seen.insert($0).inserted }
        for c in cands where result.count < 4 { result.append(c) }
        for i in stride(from: result.count - 1, through: 1, by: -1) {
            let j = Int(Int64(rng.next() % UInt64(i + 1)))
            result.swapAt(i, j)
        }
        return result
    }

    // MARK: 看图 · 模板

    private static func ktCycle2(_ rng: inout SeedGen) -> KtT {
        let a = kr(&rng), b = kr(&rng, away: Set([a]))
        let vals = (0..<8).map { $0 % 2 == 0 ? a : b }
        let bpos = rng.int(1, 6)
        return KtT(base: vals, blanks: [bpos], answer: [vals[bpos]],
                   jiexi: "图形按「\(PatternFig.name(for: a))→\(PatternFig.name(for: b))」循环，所以空位是\(PatternFig.name(for: vals[bpos]))",
                   rule: "循环",
                   options: ktPickOptions(answers: [vals[bpos]], pool: [a, b], rng: &rng))
    }

    private static func ktCycle3(_ rng: inout SeedGen) -> KtT {
        let a = kr(&rng), b = kr(&rng, away: Set([a])), c = kr(&rng, away: Set([a, b]))
        let base = [a, b, c]
        let vals = (0..<9).map { base[$0 % 3] }
        let bpos = rng.int(3, 8)
        return KtT(base: vals, blanks: [bpos], answer: [vals[bpos]],
                   jiexi: "九宫格里每一行都是「\(PatternFig.name(for: a))→\(PatternFig.name(for: b))→\(PatternFig.name(for: c))」，所以空位是\(PatternFig.name(for: vals[bpos]))",
                   columns: 3, rule: "宫格",
                   options: ktPickOptions(answers: [vals[bpos]], pool: base, rng: &rng))
    }

    private static func ktCycle4(_ rng: inout SeedGen) -> KtT {
        let a = kr(&rng), b = kr(&rng, away: Set([a]))
        let c = kr(&rng, away: Set([a, b])), d = kr(&rng, away: Set([a, b, c]))
        let base = [a, b, c, d]
        let vals = (0..<12).map { base[$0 % 4] }
        let bpos = rng.int(4, 10)
        return KtT(base: vals, blanks: [bpos], answer: [vals[bpos]],
                   jiexi: "图形按「\(PatternFig.name(for: a))→\(PatternFig.name(for: b))→\(PatternFig.name(for: c))→\(PatternFig.name(for: d))」循环，所以空位是\(PatternFig.name(for: vals[bpos]))",
                   rule: "循环",
                   options: ktPickOptions(answers: [vals[bpos]], pool: base, rng: &rng))
    }

    private static func ktGroupPair(_ rng: inout SeedGen) -> KtT {
        let a = kr(&rng), b = kr(&rng, away: Set([a]))
        let c = kr(&rng, away: Set([a, b])), d = kr(&rng, away: Set([a, b, c]))
        let base = [a, a, b, b, c, c, d, d]
        let vals = (0..<12).map { base[$0 % 8] }
        let bpos = rng.int(4, 10)
        return KtT(base: vals, blanks: [bpos], answer: [vals[bpos]],
                   jiexi: "图形是成对出现的：\(PatternFig.name(for: a))、\(PatternFig.name(for: a))，\(PatternFig.name(for: b))、\(PatternFig.name(for: b))…，所以空位是\(PatternFig.name(for: vals[bpos]))",
                   rule: "成对",
                   options: ktPickOptions(answers: [vals[bpos]], pool: [a, b, c, d], rng: &rng))
    }

    private static func ktMirror(_ rng: inout SeedGen) -> KtT {
        let a = kr(&rng), b = kr(&rng, away: Set([a])), c = kr(&rng, away: Set([a, b]))
        let head = [a, b, c]
        let vals = head + head.reversed()
        let bpos = rng.int(1, 4)
        return KtT(base: vals, blanks: [bpos], answer: [vals[bpos]],
                   jiexi: "上面一行和下面一行是照镜子关系：\(PatternFig.name(for: a))\(PatternFig.name(for: b))\(PatternFig.name(for: c))｜反过来一样，所以空位是\(PatternFig.name(for: vals[bpos]))",
                   columns: 3, rule: "镜像",
                   options: ktPickOptions(answers: [vals[bpos]], pool: [a, b, c], rng: &rng))
    }

    private static func ktInterleave(_ rng: inout SeedGen) -> KtT {
        let a = kr(&rng), b = kr(&rng, away: Set([a]))
        let c = kr(&rng, away: Set([a, b])), d = kr(&rng, away: Set([a, b, c]))
        var vals: [String] = []
        for i in 0..<12 {
            if i % 2 == 0 { vals.append(i % 4 == 0 ? a : b) }
            else { vals.append(i % 4 == 1 ? c : d) }
        }
        let b1 = rng.int(2, 4), b2 = b1 + 4
        return KtT(base: vals, blanks: [b1, b2], answer: [vals[b1], vals[b2]],
                   jiexi: "单数位在「\(PatternFig.name(for: a))、\(PatternFig.name(for: b))」之间交替，双数位在「\(PatternFig.name(for: c))、\(PatternFig.name(for: d))」之间交替",
                   rule: "交替",
                   options: ktPickOptions(answers: [vals[b1], vals[b2]], pool: [a, b, c, d], rng: &rng))
    }

    private static func ktGrid6Pair(_ rng: inout SeedGen) -> KtT {
        let a = kr(&rng), b = kr(&rng, away: Set([a])), c = kr(&rng, away: Set([a, b]))
        let vals = [a, b, c, a, b, c]
        let bpos = rng.int(3, 5)
        return KtT(base: vals, blanks: [bpos], answer: [vals[bpos]],
                   jiexi: "下面一行和上面一行完全一样，所以空位是\(PatternFig.name(for: vals[bpos]))",
                   columns: 3, rule: "宫格",
                   options: ktPickOptions(answers: [vals[bpos]], pool: [a, b, c], rng: &rng))
    }

    private static func ktGridRotate(_ rng: inout SeedGen) -> KtT {
        let a = kr(&rng), b = kr(&rng, away: Set([a])), c = kr(&rng, away: Set([a, b]))
        let vals = [a, b, c, b, c, a, c, a, b]
        let bpos = rng.int(4, 8)
        return KtT(base: vals, blanks: [bpos], answer: [vals[bpos]],
                   jiexi: "每一行都是把上一行最前面的图形挪到最后面，所以空位是\(PatternFig.name(for: vals[bpos]))",
                   columns: 3, rule: "轮转",
                   options: ktPickOptions(answers: [vals[bpos]], pool: [a, b, c], rng: &rng))
    }

    private static func ktCountGrow(_ rng: inout SeedGen) -> KtT {
        let id = String(rng.int(11, 16))
        let start = rng.int(1, 2)
        let base = (0..<4).map { "\(id):\(start + $0)" }
        let ans = base[3]
        let pool = ["\(id):\(start)", "\(id):\(start + 1)", "\(id):\(start + 2)", "\(id):\(start + 4)"]
        return KtT(base: base, blanks: [3], answer: [ans],
                   jiexi: "每一格都比前一格多 1 个\(PatternFig.name(for: id))，所以空位是 \(start + 3) 个",
                   columns: 4, rule: "数量增减",
                   options: ktPickOptions(answers: [ans], pool: pool, rng: &rng))
    }

    private static func ktCountColorDual(_ rng: inout SeedGen) -> KtT {
        let a = String(rng.int(11, 16))
        let b = String(rng.int(1, 6))
        let base = ["\(a):1", "\(b):1", "\(a):2", "\(b):2", "\(a):3", "\(b):3"]
        let ans = base[5]
        let pool = ["\(b):2", "\(b):4", "\(a):3", "\(a):4"]
        return KtT(base: base, blanks: [5], answer: [ans],
                   jiexi: "颜色按「\(PatternFig.name(for: a))→\(PatternFig.name(for: b))」循环，个数每次都多 1，所以空位是 3 个\(PatternFig.name(for: b))",
                   columns: 3, rule: "双规则",
                   options: ktPickOptions(answers: [ans], pool: pool, rng: &rng))
    }

    private static func ktRotate(_ rng: inout SeedGen) -> KtT {
        let base = ["17:r0", "17:r90", "17:r180", "17:r270"]
        let ans = "17:r270"
        let pool = ["17:r0", "17:r90", "17:r180"]
        return KtT(base: base, blanks: [3], answer: [ans],
                   jiexi: "箭头每次都顺时针转 90°，所以空位是朝上的箭头",
                   columns: 4, rule: "旋转",
                   options: ktPickOptions(answers: [ans], pool: pool, rng: &rng))
    }

    private static func ktAddShape(_ rng: inout SeedGen) -> KtT {
        var ids = (1...16).map(String.init)
        let s1 = ids.remove(at: rng.int(0, ids.count - 1))
        let s2 = ids.remove(at: rng.int(0, ids.count - 1))
        let s3 = ids.remove(at: rng.int(0, ids.count - 1))
        let s4 = ids.remove(at: rng.int(0, ids.count - 1))
        let base = ["\(s1):1", "\(s1):1+\(s2):1", "\(s1):1+\(s2):1+\(s3):1", "\(s1):1+\(s2):1+\(s3):1+\(s4):1"]
        let ans = base[3]
        return KtT(base: base, blanks: [3], answer: [ans],
                   jiexi: "每一格都比前一格多一种新图形，所以空位是四种图形放在一起",
                   columns: 2, rule: "组合",
                   options: ktPickOptions(answers: [ans], pool: [base[0], base[1], base[2]], rng: &rng))
    }

    // MARK: 校验

    static func debugValidate(_ qs: [PatternQuestion]) -> [String] {
        var issues: [String] = []
        for q in qs {
            let underscore = q.tokens.filter { $0 == "_" }.count

            // ① 空白与答案一一对应
            if underscore == 0 {
                issues.append("\(q.identity): 没有空位")
            } else if underscore != q.answer.count {
                issues.append("\(q.identity): 空格数 \(underscore) ≠ 答案数 \(q.answer.count)")
            }

            if q.tokens.isEmpty { issues.append("\(q.identity): 空题面"); continue }

            // ③ 题面数值/图形合法性 + 数值范围
            if q.mode == .shuZi {
                for t in q.tokens where t != "_" {
                    guard let v = Int(t) else { issues.append("\(q.identity): 非数字 token \(t)"); continue }
                    if v < 0 || v > 999 { issues.append("\(q.identity): 数值越界 \(v)") }
                }
            } else {
                for t in q.tokens where t != "_" {
                    validateFigToken(t, q: q, issues: &issues)
                }
            }

            // ④ 空白可推断：首空之前至少 2 个已知项；末空如果不在末尾，其后至少 1 个已知项
            let blanks = q.blankOrders
            if let first = blanks.first {
                let knownBefore = q.tokens[0..<first].filter { $0 != "_" }.count
                if knownBefore < 1 {
                    issues.append("\(q.identity): 第 \(first) 个空格前无已知项")
                }
            }
            if let last = blanks.last {
                if last < q.tokens.count - 1 {
                    let knownAfter = q.tokens[(last + 1)...].filter { $0 != "_" }.count
                    if knownAfter < 1 {
                        issues.append("\(q.identity): 第 \(last) 个空格后无已知项")
                    }
                } else if blanks.count == 1 {
                    let knownBefore = q.tokens[0..<last].filter { $0 != "_" }.count
                    if knownBefore < 2 {
                        issues.append("\(q.identity): 末尾空格前已知项过少（\(knownBefore) 个）")
                    }
                }
            }

            // ⑤ 选项：互斥、恰好 4 个、答案必须在其中
            if !q.options.isEmpty {
                if Set(q.options).count != q.options.count { issues.append("\(q.identity): 选项重复") }
                for a in q.answer where !q.options.contains(a) { issues.append("\(q.identity): 答案 \(a) 不在选项中") }
                if q.options.count != 4 { issues.append("\(q.identity): 选项数 \(q.options.count) ≠ 4") }
                if q.mode == .shuZi {
                    for opt in q.options where Int(opt) == nil { issues.append("\(q.identity): 非数字选项 \(opt)") }
                } else {
                    for opt in q.options { validateFigToken(opt, q: q, issues: &issues) }
                }
            }

            // ⑥ 规律标签
            if q.rule.isEmpty { issues.append("\(q.identity): 缺少规则标签") }
        }
        return issues
    }

    private static func validateFigToken(_ token: String, q: PatternQuestion, issues: inout [String]) {
        for id in FigParser.ids(token) where PatternFig.emoji(for: id) == nil {
            issues.append("\(q.identity): 未知图形 id \(id) in \(token)")
        }
        for part in FigParser.parts(token) {
            if part.count < 1 || part.count > 9 {
                issues.append("\(q.identity): 数量越界 \(token) count=\(part.count)")
            }
            let r = part.rotation.truncatingRemainder(dividingBy: 360)
            if ![0.0, 90.0, 180.0, 270.0].contains(r) {
                issues.append("\(q.identity): 非法旋转 \(token) r=\(part.rotation)")
            }
            if part.scale < 0.5 || part.scale > 3 {
                issues.append("\(q.identity): 非法缩放 \(token) s=\(part.scale)")
            }
        }
    }
}
