import SwiftUI

// MARK: - 数学批改作业 · 红笔圈错

// MARK: 年级配置

enum MathHomeworkGrade: Int, CaseIterable, Identifiable {
    case one = 1, two = 2, three = 3, four = 4, five = 5, six = 6

    var id: Int { rawValue }
    var name: String { "\(rawValue) 年级" }

    var color: Color {
        switch self {
        case .one:   return Color(red: 232/255, green: 106/255, blue: 158/255)
        case .two:   return Color(red: 245/255, green: 166/255, blue: 35/255)
        case .three: return AppTheme.fieldMint
        case .four:  return Color(red: 74/255, green: 163/255, blue: 223/255)
        case .five:  return Color(red: 155/255, green: 123/255, blue: 216/255)
        case .six:   return Color(red: 232/255, green: 100/255, blue: 82/255)
        }
    }

    var light: Color {
        switch self {
        case .one:   return Color(red: 255/255, green: 227/255, blue: 239/255)
        case .two:   return Color(red: 255/255, green: 243/255, blue: 214/255)
        case .three: return Color(red: 223/255, green: 245/255, blue: 231/255)
        case .four:  return Color(red: 231/255, green: 243/255, blue: 252/255)
        case .five:  return Color(red: 241/255, green: 234/255, blue: 252/255)
        case .six:   return Color(red: 255/255, green: 227/255, blue: 222/255)
        }
    }

    var tags: [String] {
        switch self {
        case .one:   return ["20 以内", "比大小", "看图列式"]
        case .two:   return ["100 以内", "乘除", "单位换算"]
        case .three: return ["多位数", "竖式", "单位"]
        case .four:  return ["两位数", "简便", "混合"]
        case .five:  return ["小数", "分数", "方程"]
        case .six:   return ["分数乘除", "百分数", "比例"]
        }
    }
}

// MARK: 题目模型

struct MathHomeworkProblem: Identifiable {
    enum Kind: String {
        case horizontal      // 口算横式
        case vertical        // 竖式
        case compare         // 比大小
        case fill            // 填空求未知
        case picture         // 看图列式
        case clock           // 认识钟表
        case count           // 数图形
        case sequence        // 规律填数
        case units           // 单位换算
        case simplify        // 简便运算
        case equation        // 简易方程
        case percent         // 百分数
        case ratio           // 比例
        // —— 一年级动脑思考题 ——
        case queue           // 排队问题
        case balance         // 移多补少
        case sameNumber      // 填相同数
        case substitute      // 图形代换
        case blocks          // 数方块
        case age             // 年龄差不变
        case symbol          // 巧填符号
        case money           // 人民币
        case redundant       // 多余条件
        case atLeast         // 至少/最多
        case period          // 周期规律
        case fold            // 对折分割
        case reverse         // 逆向还原
        // —— 二年级思维题 ——
        case sawWood         // 锯木头/爬楼梯
        case combo           // 搭配问题
        case remainder       // 有余数除法
        case overlap         // 重叠拼接
        case sumDiff         // 和差问题
        case groupExtra      // 几组多几个
    }

    let id = UUID()
    let kind: Kind
    /// 题面（不含答案）
    let prompt: String
    /// 学生写的答案（错或对）
    let studentAnswer: String
    let correctAnswer: String
    let isWrong: Bool
    let hint: String
    let options: [String]
}

// MARK: - 出题生成器（按年级，一轮 15 题，约 1/3 错）

enum MathHomeworkGen {

    static func makeRound(grade: MathHomeworkGrade) -> [MathHomeworkProblem] {
        let total = Int.random(in: 15...20)
        let wrongCount = Int.random(in: 3...6)
        let pool = kindPool(for: grade)
        var problems: [MathHomeworkProblem] = []
        var seenPrompts: Set<String> = []
        var lastKind: MathHomeworkProblem.Kind?
        var attempts = 0
        while problems.count < total && attempts < total * 5 {
            attempts += 1
            var kind = pool.randomElement()!
            if kind == lastKind {
                kind = pool.filter { $0 != lastKind }.randomElement() ?? kind
            }
            lastKind = kind
            if let p = makeOne(kind: kind, grade: grade) {
                guard !seenPrompts.contains(p.prompt) else { continue }
                seenPrompts.insert(p.prompt)
                problems.append(p)
            }
        }
        var corrected = problems.map { p -> MathHomeworkProblem in
            MathHomeworkProblem(kind: p.kind, prompt: p.prompt,
                               studentAnswer: p.correctAnswer, correctAnswer: p.correctAnswer,
                               isWrong: false, hint: p.hint, options: p.options)
        }
        let wrongIndices = Array(corrected.indices).shuffled().prefix(wrongCount)
        for i in wrongIndices {
            let p = corrected[i]
            let wrongAns = wrongVariant(of: p.correctAnswer)
            corrected[i] = MathHomeworkProblem(kind: p.kind, prompt: p.prompt,
                                               studentAnswer: wrongAns, correctAnswer: p.correctAnswer,
                                               isWrong: true, hint: p.hint, options: options(for: p.correctAnswer))
        }
        return corrected
    }

    private static func kindPool(for grade: MathHomeworkGrade) -> [MathHomeworkProblem.Kind] {
        switch grade {
        case .one:
            return [.horizontal, .horizontal, .compare, .fill, .picture, .clock, .count,
                    .queue, .queue, .balance, .sameNumber, .substitute, .blocks,
                    .age, .symbol, .money, .redundant, .atLeast, .period, .fold, .reverse]
        case .two:
            return [.horizontal, .horizontal, .horizontal, .horizontal,
                    .vertical, .vertical, .compare, .compare, .fill, .fill,
                    .sequence, .units, .units,
                    .balance, .queue, .substitute, .sawWood, .combo, .remainder,
                    .period, .redundant, .reverse, .money, .overlap, .sumDiff, .groupExtra]
        case .three:
            return [.horizontal, .vertical, .fill, .units, .horizontal, .vertical]
        case .four:
            return [.horizontal, .simplify, .vertical, .horizontal, .units]
        case .five:
            return [.horizontal, .horizontal, .equation, .units]
        case .six:
            return [.percent, .ratio, .equation, .horizontal, .units]
        }
    }

    // MARK: 出题入口

    private static func makeOne(kind: MathHomeworkProblem.Kind, grade: MathHomeworkGrade) -> MathHomeworkProblem? {
        switch kind {
        case .horizontal: return horizontal(grade: grade)
        case .vertical:   return vertical(grade: grade)
        case .compare:    return compare(grade: grade)
        case .fill:       return fill(grade: grade)
        case .picture:    return picture()
        case .clock:      return clock()
        case .count:      return count()
        case .sequence:   return sequence()
        case .units:      return units(grade: grade)
        case .simplify:   return simplify()
        case .equation:   return equation(grade: grade)
        case .percent:    return percent()
        case .ratio:      return ratio()
        case .queue:      return queue()
        case .balance:    return balance()
        case .sameNumber: return sameNumber()
        case .substitute: return substitute()
        case .blocks:     return blocks()
        case .age:        return age()
        case .symbol:     return symbol()
        case .money:      return money()
        case .redundant:  return redundant()
        case .atLeast:    return atLeast()
        case .period:     return period()
        case .fold:       return fold()
        case .reverse:    return reverse()
        case .sawWood:    return sawWood()
        case .combo:      return combo()
        case .remainder:  return remainder()
        case .overlap:    return overlap()
        case .sumDiff:    return sumDiff()
        case .groupExtra: return groupExtra()
        }
    }

    // MARK: 错误答案派生（典型马虎错误）

    private static func wrongVariant(of answer: String) -> String {
        // 符号答案反向
        if answer == ">" { return "<" }
        if answer == "<" { return ">" }
        if answer == "=" { return ">" }
        if answer == "+" { return "-" }
        if answer == "-" { return "+" }
        // 数字/带单位答案：数值 ± 小偏差
        if let num = Int(answer) {
            let deltas = [-2, -1, 1, 2, -10, 10]
            for d in deltas.shuffled() where num + d > 0 {
                return "\(num + d)"
            }
            return "\(num + 1)"
        }
        if let v = answer.split(separator: " ").first, let num = Int(v) {
            let rest = answer.dropFirst(v.count)
            let deltas = [-2, -1, 1, 2]
            let d = deltas.randomElement() ?? 1
            return "\(num + d)\(rest)"
        }
        return answer
    }

    private static func options(for answer: String) -> [String] {
        var set: [String] = [answer]
        var guardCount = 0
        while set.count < 3 && guardCount < 20 {
            guardCount += 1
            let v = wrongVariant(of: answer)
            if !set.contains(v) { set.append(v) }
        }
        while set.count < 3 { set.append("?") }
        return set.shuffled()
    }

    private static func problem(kind: MathHomeworkProblem.Kind, prompt: String, correct: String, isWrong: Bool, hint: String) -> MathHomeworkProblem {
        let student = isWrong ? wrongVariant(of: correct) : correct
        return MathHomeworkProblem(kind: kind,
                                   prompt: prompt,
                                   studentAnswer: student,
                                   correctAnswer: correct,
                                   isWrong: isWrong,
                                   hint: hint,
                                   options: options(for: correct))
    }

    // MARK: 各题型

    private static func horizontal(grade: MathHomeworkGrade) -> MathHomeworkProblem {
        switch grade {
        case .one:
            if Bool.random() {
                let a = Int.random(in: 1...9), b = Int.random(in: 1...9)
                if a + b <= 20 {
                    let wrong = Bool.random()
                    return problem(kind: .horizontal, prompt: "\(a) + \(b) = ?", correct: "\(a + b)",
                                   isWrong: wrong, hint: "凑十法：先把 \(b) 拆出 \(10 - a)，凑成 10 再加")
                }
                return horizontal(grade: grade)
            } else {
                let a = Int.random(in: 5...20), b = Int.random(in: 1...(a - 1))
                return problem(kind: .horizontal, prompt: "\(a) − \(b) = ?", correct: "\(a - b)",
                               isWrong: Bool.random(), hint: "个位不够减，向十位借 1 当 10")
            }
        case .two:
            let r = Int.random(in: 0..<4)
            if r == 0 {
                let a = Int.random(in: 21...69), b = Int.random(in: 21...69)
                if a + b <= 100 {
                    return problem(kind: .horizontal, prompt: "\(a) + \(b) = ?", correct: "\(a + b)",
                                   isWrong: Bool.random(), hint: "个位相加满十，向十位进 1")
                }
                return horizontal(grade: grade)
            } else if r == 1 {
                let a = Int.random(in: 2...9), b = Int.random(in: 2...9)
                return problem(kind: .horizontal, prompt: "\(a) × \(b) = ?", correct: "\(a * b)",
                               isWrong: Bool.random(), hint: "背一背九九乘法表")
            } else if r == 2 {
                let a = Int.random(in: 2...9), b = Int.random(in: 2...9)
                return problem(kind: .horizontal, prompt: "\(a * b) ÷ \(a) = ?", correct: "\(b)",
                               isWrong: Bool.random(), hint: "想乘法：几乘 \(a) 等于 \(a * b)？")
            } else {
                let a = Int.random(in: 2...9), b = Int.random(in: 2...9), c = Int.random(in: 1...9)
                return problem(kind: .horizontal, prompt: "\(a) × \(b) + \(c) = ?", correct: "\(a * b + c)",
                               isWrong: Bool.random(), hint: "先算乘法，再算加法")
            }
        case .three:
            let a = Int.random(in: 3...9), b = Int.random(in: 12...99)
            return problem(kind: .horizontal, prompt: "\(a) × \(b) = ?", correct: "\(a * b)",
                           isWrong: Bool.random(), hint: "一位数乘两位数，从个位乘起，满十进一")
        case .four:
            let a = Int.random(in: 11...49), b = Int.random(in: 11...49)
            return problem(kind: .horizontal, prompt: "\(a) × \(b) = ?", correct: "\(a * b)",
                           isWrong: Bool.random(), hint: "先用个位乘，再用十位乘，最后相加")
        case .five:
            let a = Int.random(in: 5...90), b = Int.random(in: 5...90)
            if a + b <= 100 {
                let x = Double(a) / 10, y = Double(b) / 10
                let correct = x + y
                let text = "\(fmt(x)) + \(fmt(y)) = ?"
                let wrong = Bool.random()
                let student = wrong ? fmt(correct + (Bool.random() ? 0.1 : -0.1)) : fmt(correct)
                return MathHomeworkProblem(kind: .horizontal, prompt: text, studentAnswer: student,
                                           correctAnswer: fmt(correct), isWrong: wrong,
                                           hint: "小数点对齐，按整数加法算", options: options(for: fmt(correct)))
            }
            return horizontal(grade: grade)
        case .six:
            let a = Int.random(in: 1...4), b = Int.random(in: 2...9)
            let c = Int.random(in: 1...4), d = Int.random(in: 2...9)
            let correct = simplified(a * c, b * d)
            let wrong = Bool.random()
            let student = wrong ? wrongFraction(a, b, c, d) : correct
            return MathHomeworkProblem(kind: .horizontal, prompt: "\(a)/\(b) × \(c)/\(d) = ?",
                                       studentAnswer: student, correctAnswer: correct, isWrong: wrong,
                                       hint: "分子乘分子，分母乘分母，结果要约分",
                                       options: fractionOptions(correct: correct))
        }
    }

    private static func vertical(grade: MathHomeworkGrade) -> MathHomeworkProblem {
        switch grade {
        case .two:
            let a = Int.random(in: 21...78), b = Int.random(in: 11...99)
            if a + b <= 100 && a >= b {
                return problem(kind: .vertical, prompt: "竖式：\(a) + \(b)", correct: "\(a + b)",
                               isWrong: Bool.random(), hint: "相同数位对齐，从个位加起")
            }
            return vertical(grade: grade)
        case .three:
            if Bool.random() {
                let a = Int.random(in: 200...600), b = Int.random(in: 100...399)
                return problem(kind: .vertical, prompt: "竖式：\(a) − \(b)", correct: "\(a - b)",
                               isWrong: Bool.random(), hint: "相同数位对齐，不够减就退位")
            } else {
                let d = Int.random(in: 2...9), q = Int.random(in: 12...99)
                let n = d * q
                if n <= 999 {
                    return problem(kind: .vertical, prompt: "竖式：\(n) ÷ \(d)", correct: "\(q)",
                                   isWrong: Bool.random(), hint: "从高位除起，商写在对应数位上")
                }
                return vertical(grade: grade)
            }
        case .four:
            let d = Int.random(in: 11...49), q = Int.random(in: 2...9)
            return problem(kind: .vertical, prompt: "竖式：\(d * q) ÷ \(d)", correct: "\(q)",
                           isWrong: Bool.random(), hint: "把除数看成整十数来试商")
        default:
            return horizontal(grade: grade)
        }
    }

    private static func compare(grade: MathHomeworkGrade) -> MathHomeworkProblem {
        switch grade {
        case .one:
            let a = Int.random(in: 1...9), b = Int.random(in: 1...9)
            if a != b {
                return problem(kind: .compare, prompt: "\(a) 和 \(b) 比大小", correct: a > b ? ">" : "<",
                               isWrong: Bool.random(), hint: "开口朝大数")
            }
            return compare(grade: grade)
        default:
            let a = Int.random(in: 2...9), b = Int.random(in: 2...9), c = Int.random(in: 1...20)
            if a * b != c {
                return problem(kind: .compare, prompt: "\(a) × \(b) 和 \(c) 比大小", correct: a * b > c ? ">" : "<",
                               isWrong: Bool.random(), hint: "先算出左边，再比大小")
            }
            return compare(grade: grade)
        }
    }

    private static func fill(grade: MathHomeworkGrade) -> MathHomeworkProblem {
        switch grade {
        case .one:
            let a = Int.random(in: 1...9), x = Int.random(in: 1...10)
            let b = a + x
            if b <= 20 {
                return problem(kind: .fill, prompt: "□ + \(a) = \(b)，□ = ?", correct: "\(x)",
                               isWrong: Bool.random(), hint: "用减法：\(b) − \(a)")
            }
            return fill(grade: grade)
        case .two, .three:
            let a = Int.random(in: 2...9), b = Int.random(in: 3...9)
            return problem(kind: .fill, prompt: "□ × \(b) = \(a * b)，□ = ?", correct: "\(a)",
                           isWrong: Bool.random(), hint: "几乘 \(b) 得 \(a * b)？想乘法口诀")
        default:
            let a = Int.random(in: 2...9), b = Int.random(in: 3...9)
            return problem(kind: .fill, prompt: "\(a * b) ÷ □ = \(a)，□ = ?", correct: "\(b)",
                           isWrong: Bool.random(), hint: "被除数 ÷ 商 = 除数")
        }
    }

    private static func picture() -> MathHomeworkProblem {
        let a = Int.random(in: 1...4), b = Int.random(in: 1...4)
        let fruits = ["🍎", "🍊", "🍇", "🍓", "🐤", "🌼"]
        let f = fruits.randomElement()!
        let left = String(repeating: f, count: a)
        let right = String(repeating: f, count: b)
        return problem(kind: .picture, prompt: "\(left) ＋ \(right) 一共几个？", correct: "\(a + b)",
                       isWrong: Bool.random(), hint: "左边 \(a) 个，右边 \(b) 个，合起来数")
    }

    private static func clock() -> MathHomeworkProblem {
        let half = Bool.random()
        let h = Int.random(in: 1...12)
        let correct = half ? "\(h) 时半" : "\(h) 时"
        let wrong = Bool.random()
        let student: String
        if wrong {
            if half {
                student = Bool.random() ? "\(h) 时" : "\((h % 12) + 1) 时半"
            } else {
                student = "\((h % 12) + 1) 时"
            }
        } else {
            student = correct
        }
        return MathHomeworkProblem(kind: .clock, prompt: "钟面上是几时？", studentAnswer: student,
                                   correctAnswer: correct, isWrong: wrong,
                                   hint: half ? "分针指向 6，是半点" : "分针指向 12，是整点",
                                   options: clockOptions(correct: correct))
    }

    private static func count() -> MathHomeworkProblem {
        let shapes = ["△", "○", "□", "☆"]
        let target = shapes.randomElement()!
        let others = shapes.filter { $0 != target }
        var line = ""
        var total = 0
        var targetCount = 0
        for _ in 0..<9 {
            if Bool.random() && targetCount < 6 {
                line += target
                targetCount += 1
            } else {
                line += others.randomElement()!
            }
            total += 1
        }
        let correct = "\(targetCount)"
        let wrong = Bool.random()
        let student = wrong ? wrongVariant(of: correct) : correct
        return MathHomeworkProblem(kind: .count, prompt: "数一数：\(line)\n\(target) 有几个？",
                                   studentAnswer: student, correctAnswer: correct, isWrong: wrong,
                                   hint: "一个一个数，数到几个就是几个", options: options(for: correct))
    }

    private static func sequence() -> MathHomeworkProblem {
        let start = Int.random(in: 1...3)
        let step = Int.random(in: 2...3)
        let vals = (0..<5).map { start + $0 * step }
        var text = ""
        for (i, v) in vals.enumerated() {
            text += i == 3 ? "（ ）" : "\(v)"
            if i < 4 { text += "  " }
        }
        return problem(kind: .sequence, prompt: "找规律填一填：\(text)", correct: "\(vals[3])",
                       isWrong: Bool.random(), hint: "每次加 \(step)，\(vals[2]) 加 \(step) 得 \(vals[3])")
    }

    private static func units(grade: MathHomeworkGrade) -> MathHomeworkProblem {
        switch grade {
        case .one, .two:
            if Bool.random() {
                return problem(kind: .units, prompt: "1 米 = （ ）厘米", correct: "100",
                               isWrong: Bool.random(), hint: "1 米有 100 厘米")
            } else {
                return problem(kind: .units, prompt: "1 元 = （ ）角", correct: "10",
                               isWrong: Bool.random(), hint: "1 元可以换 10 个 1 角")
            }
        case .three:
            return problem(kind: .units, prompt: "1 时 = （ ）分", correct: "60",
                           isWrong: Bool.random(), hint: "1 小时有 60 分钟")
        case .four:
            return problem(kind: .units, prompt: "1 平方米 = （ ）平方分米", correct: "100",
                           isWrong: Bool.random(), hint: "相邻面积单位进率是 100")
        case .five:
            return problem(kind: .units, prompt: "1 千米 = （ ）米", correct: "1000",
                           isWrong: Bool.random(), hint: "千米和米之间的进率是 1000")
        case .six:
            return problem(kind: .units, prompt: "1 吨 = （ ）千克", correct: "1000",
                           isWrong: Bool.random(), hint: "吨和千克之间的进率是 1000")
        }
    }

    private static func simplify() -> MathHomeworkProblem {
        let k = [4, 8, 12, 16, 20, 24, 28, 32, 40, 80].randomElement()!
        let m = Bool.random() ? 25 : 125
        return problem(kind: .simplify, prompt: "简便计算：\(k) × \(m) = ?", correct: "\(k * m)",
                       isWrong: Bool.random(), hint: "\(k) × \(m)：凑整百整千，口算更快")
    }

    private static func equation(grade: MathHomeworkGrade) -> MathHomeworkProblem {
        switch grade {
        case .five:
            if Bool.random() {
                let x = Int.random(in: 1...9), b = Int.random(in: 1...9)
                return problem(kind: .equation, prompt: "解方程：x + \(b) = \(x + b)，x = ?", correct: "\(x)",
                               isWrong: Bool.random(), hint: "等式两边同时减去 \(b)")
            } else {
                let x = Int.random(in: 1...9), b = Int.random(in: 1...9)
                return problem(kind: .equation, prompt: "解方程：x − \(b) = \(x - b)，x = ?", correct: "\(x)",
                               isWrong: Bool.random(), hint: "等式两边同时加上 \(b)")
            }
        default:
            let a = Int.random(in: 1...9), b = Int.random(in: 1...9)
            return problem(kind: .equation, prompt: "解方程：\(a)x = \(a * b)，x = ?", correct: "\(b)",
                           isWrong: Bool.random(), hint: "两边同时除以 \(a)")
        }
    }

    private static func percent() -> MathHomeworkProblem {
        let pct = [10, 20, 25, 50, 75].randomElement()!
        let y: Int
        switch pct {
        case 25, 75: y = [8, 12, 16, 20, 24, 28, 32, 36, 40].randomElement()!
        case 20:     y = [20, 30, 40, 50, 60, 70, 80, 90].randomElement()!
        case 50:     y = Int.random(in: 10...98) * 2
        default:     y = Int.random(in: 10...99)
        }
        return problem(kind: .percent, prompt: "\(y) 的 \(pct)% = ?", correct: "\(y * pct / 100)",
                       isWrong: Bool.random(), hint: "\(pct)% = \(pct)/100，用它乘 \(y)")
    }

    private static func ratio() -> MathHomeworkProblem {
        let a = Int.random(in: 2...5), k = Int.random(in: 2...4)
        let b = a * k
        let c = Int.random(in: 2...5)
        return problem(kind: .ratio, prompt: "\(a) : \(b) = \(c) : □，□ = ?", correct: "\(k * c)",
                       isWrong: Bool.random(), hint: "内项之积 = 外项之积")
    }

    // MARK: 一年级动脑思考题

    /// 排队问题：漏算自己 / 重复数是坑
    private static func queue() -> MathHomeworkProblem {
        let type = Int.random(in: 0..<3)
        if type == 0 {
            let a = Int.random(in: 1...6), b = Int.random(in: 1...6)
            return problem(kind: .queue, prompt: "小明排队，他前面有 \(a) 人，后面有 \(b) 人，这一队一共有多少人？",
                           correct: "\(a + b + 1)", isWrong: Bool.random(),
                           hint: "别忘了加上小明自己：\(a) + \(b) + 1")
        } else if type == 1 {
            let n = Int.random(in: 6...12), k = Int.random(in: 2...5)
            return problem(kind: .queue, prompt: "一队一共有 \(n) 人，小红排在第 \(k) 个，小红后面有几人？",
                           correct: "\(n - k)", isWrong: Bool.random(),
                           hint: "总人数减去小红和她前面的人：\(n) − \(k)")
        } else {
            let a = Int.random(in: 2...5), b = Int.random(in: 2...5)
            return problem(kind: .queue, prompt: "从前面数，小丽排第 \(a)；从后面数，小丽排第 \(b)。全队一共有多少人？",
                           correct: "\(a + b - 1)", isWrong: Bool.random(),
                           hint: "小丽被数了两次，要减 1：\(a) + \(b) − 1")
        }
    }

    /// 移多补少：差的一半
    private static func balance() -> MathHomeworkProblem {
        let a = Int.random(in: 4...10), diff = [2, 4, 6, 8].randomElement()!
        let b = a - diff
        if b >= 1 && diff % 2 == 0 {
            return problem(kind: .balance, prompt: "小红有 \(a) 颗糖，小明有 \(b) 颗。小红给小明几颗糖，两人的糖就一样多？",
                           correct: "\(diff / 2)", isWrong: Bool.random(),
                           hint: "先算差 \(diff)，把差的一半给出去：\(diff) ÷ 2")
        }
        return balance()
    }

    /// 填相同数：两边相等
    private static func sameNumber() -> MathHomeworkProblem {
        let a = Int.random(in: 5...10), b = Int.random(in: 1...4)
        let diff = a - b
        if diff > 0 && diff % 2 == 0 {
            return problem(kind: .sameNumber, prompt: "\(a) − □ = \(b) + □，□ 里填同一个数，□ = ?",
                           correct: "\(diff / 2)", isWrong: Bool.random(),
                           hint: "两边要相等：\(a) − \(b) = \(diff)，再把 \(diff) 平分")
        }
        return sameNumber()
    }

    /// 图形代换
    private static func substitute() -> MathHomeworkProblem {
        let type = Int.random(in: 0..<3)
        if type == 0 {
            let a = Int.random(in: 1...5), b = Int.random(in: 1...5)
            return problem(kind: .substitute, prompt: "○ = \(a)，△ = \(b)，○ + △ = ?",
                           correct: "\(a + b)", isWrong: Bool.random(),
                           hint: "把图形换成数字：\(a) + \(b)")
        } else if type == 1 {
            let a = Int.random(in: 2...5), b = Int.random(in: 1...(a - 1))
            return problem(kind: .substitute, prompt: "○ = \(a)，△ = \(b)，△ − ○ = ?（△ 比 ○ 大）",
                           correct: "\(a - b)", isWrong: Bool.random(),
                           hint: "△ − ○ = \(a) − \(b)")
        } else {
            let a = [2, 3, 4, 5].randomElement()!
            return problem(kind: .substitute, prompt: "○ + ○ = \(a * 2)，○ = ?",
                           correct: "\(a)", isWrong: Bool.random(),
                           hint: "两个 ○ 合起来是 \(a * 2)，一个 ○ 是 \(a * 2) ÷ 2")
        }
    }

    /// 数方块：别忘了被挡住的
    private static func blocks() -> MathHomeworkProblem {
        let type = Int.random(in: 0..<3)
        if type == 0 {
            let a = Int.random(in: 1...4), b = Int.random(in: 1...4)
            return problem(kind: .blocks, prompt: "搭积木：下面一层放 \(a) 块，上面一层放 \(b) 块，一共用了几块小方块？",
                           correct: "\(a + b)", isWrong: Bool.random(),
                           hint: "两层加起来：\(a) + \(b)")
        } else if type == 1 {
            let a = Int.random(in: 1...3), b = Int.random(in: 1...3), c = Int.random(in: 1...3)
            return problem(kind: .blocks, prompt: "小塔有三层：第一层 \(a) 块，第二层 \(b) 块，第三层 \(c) 块，一共几块？",
                           correct: "\(a + b + c)", isWrong: Bool.random(),
                           hint: "三层全加上：\(a) + \(b) + \(c)")
        } else {
            let a = Int.random(in: 3...5)
            return problem(kind: .blocks, prompt: "用积木搭一座小塔，看得见 \(a) 块，还有 1 块藏在下面看不见，一共几块？",
                           correct: "\(a + 1)", isWrong: Bool.random(),
                           hint: "看不见的也要数：\(a) + 1")
        }
    }

    /// 年龄差不变
    private static func age() -> MathHomeworkProblem {
        let a = Int.random(in: 5...9), b = Int.random(in: 1...(a - 2))
        let years = [1, 2, 3].randomElement()!
        return problem(kind: .age, prompt: "哥哥今年 \(a) 岁，弟弟今年 \(b) 岁。\(years) 年后，哥哥比弟弟大几岁？",
                       correct: "\(a - b)", isWrong: Bool.random(),
                       hint: "年龄差永远不变，别加 \(years)：\(a) − \(b)")
    }

    /// 巧填符号
    private static func symbol() -> MathHomeworkProblem {
        let a = Int.random(in: 2...9), b = Int.random(in: 1...(a - 1))
        if Bool.random() {
            return problem(kind: .symbol, prompt: "在 □ 里填 + 或 −，使等式成立：\(a) □ \(b) = \(a - b)",
                           correct: "-", isWrong: Bool.random(),
                           hint: "\(a) − \(b) = \(a - b)，减号才成立")
        } else {
            let c = Int.random(in: 2...9)
            if a + c <= 20 {
                return problem(kind: .symbol, prompt: "在 □ 里填 + 或 −，使等式成立：\(a) □ \(c) = \(a + c)",
                               correct: "+", isWrong: Bool.random(),
                               hint: "\(a) + \(c) = \(a + c)，加号才成立")
            }
            return symbol()
        }
    }

    /// 人民币
    private static func money() -> MathHomeworkProblem {
        if Bool.random() {
            let b = Int.random(in: 1...9)
            return problem(kind: .money, prompt: "一支铅笔 \(b) 角，付 1 元，应找回几角？",
                           correct: "\(10 - b)", isWrong: Bool.random(),
                           hint: "1 元 = 10 角，10 − \(b)")
        } else {
            let a = Int.random(in: 6...15), b = Int.random(in: 2...(a - 1))
            return problem(kind: .money, prompt: "一个玩具 \(a) 元，只带了 \(b) 元，还差多少元？",
                           correct: "\(a - b)", isWrong: Bool.random(),
                           hint: "\(a) − \(b)")
        }
    }

    /// 多余条件：筛选信息
    private static func redundant() -> MathHomeworkProblem {
        let a = Int.random(in: 8...15), b = Int.random(in: 1...(a - 3))
        return problem(kind: .redundant, prompt: "树上原来有 \(a) 只小鸟，飞走了 \(b) 只。树下有 4 只鸡。树上还剩几只小鸟？",
                       correct: "\(a - b)", isWrong: Bool.random(),
                       hint: "鸡是多余条件，别管它：\(a) − \(b)")
    }

    /// 至少 / 最多
    private static func atLeast() -> MathHomeworkProblem {
        if Bool.random() {
            let total = Int.random(in: 10...20), each = Int.random(in: 2...5)
            return problem(kind: .atLeast, prompt: "\(total) 个苹果，每个小朋友分 \(each) 个，最多可以分给几个小朋友？",
                           correct: "\(total / each)", isWrong: Bool.random(),
                           hint: "\(total) ÷ \(each) = \(total / each) 余 \(total % each)，剩下的不够再分 1 人")
        } else {
            let kids = Int.random(in: 2...6), each = Int.random(in: 2...4)
            return problem(kind: .atLeast, prompt: "有一些糖，分给 \(kids) 个小朋友，每人分 \(each) 颗后还有剩余。这些糖最少有几颗？",
                           correct: "\(kids * each + 1)", isWrong: Bool.random(),
                           hint: "先每人 \(each) 颗：\(kids) × \(each) = \(kids * each)，还剩就再加 1")
        }
    }

    /// 周期规律
    private static func period() -> MathHomeworkProblem {
        let shapes = ["○", "△", "□", "☆", "◇"]
        let cycle = Array(shapes.shuffled().prefix(3))
        var line = ""
        for i in 0..<7 {
            line += cycle[i % 3]
            if i < 6 { line += "  " }
        }
        let next = cycle[7 % 3]
        let others = cycle.filter { $0 != next }
        let wrong = Bool.random()
        let student = wrong ? (others.randomElement() ?? next) : next
        return MathHomeworkProblem(kind: .period, prompt: "\(line)  （  ）\n找规律，下一个图形是什么？",
                                   studentAnswer: student, correctAnswer: next, isWrong: wrong,
                                   hint: "\(cycle.joined(separator: "、")) 三个一循环，按顺序排",
                                   options: cycle.shuffled())
    }

    /// 对折分割
    private static func fold() -> MathHomeworkProblem {
        let times = Int.random(in: 1...3)
        let parts = times == 1 ? 2 : (times == 2 ? 4 : 8)
        let hintText = times == 1 ? "对折 1 次就是分成 2 份"
            : times == 2 ? "对折 1 次 2 份，再对折翻倍：2 × 2 = 4"
            : "每次对折都翻倍：2 × 2 × 2 = 8"
        return problem(kind: .fold, prompt: "把一张纸对折 \(times) 次，可以分成几份？",
                       correct: "\(parts)", isWrong: Bool.random(), hint: hintText)
    }

    /// 逆向还原
    private static func reverse() -> MathHomeworkProblem {
        if Bool.random() {
            let x = Int.random(in: 2...9), add = Int.random(in: 2...9)
            return problem(kind: .reverse, prompt: "一个数加上 \(add) 等于 \(x + add)，这个数是几？",
                           correct: "\(x)", isWrong: Bool.random(),
                           hint: "倒着算：\(x + add) − \(add)")
        } else {
            let x = Int.random(in: 5...15), take = Int.random(in: 2...6)
            return problem(kind: .reverse, prompt: "篮子里有桃子，拿走 \(take) 个后还剩 \(x) 个。原来有几个桃子？",
                           correct: "\(x + take)", isWrong: Bool.random(),
                           hint: "倒着算：\(x) + \(take)")
        }
    }

    // MARK: 二年级思维题

    /// 锯木头 / 爬楼梯
    private static func sawWood() -> MathHomeworkProblem {
        if Bool.random() {
            let segments = Int.random(in: 3...6)
            let minutes = Int.random(in: 2...5)
            let cuts = segments - 1
            return problem(kind: .sawWood,
                           prompt: "一根木头锯成 \(segments) 段，每锯一次 \(minutes) 分钟，一共要几分钟？",
                           correct: "\(cuts * minutes)", isWrong: Bool.random(),
                           hint: "锯 \(segments) 段只需 \(cuts) 刀：\(cuts) × \(minutes) = \(cuts * minutes)")
        } else {
            let floor = Int.random(in: 3...6)
            let minutes = Int.random(in: 1...3)
            let stairs = floor - 1
            return problem(kind: .sawWood,
                           prompt: "小明家住 \(floor) 楼，每层楼梯走 \(minutes) 分钟，从 1 楼走到家要几分钟？",
                           correct: "\(stairs * minutes)", isWrong: Bool.random(),
                           hint: "走 \(floor) 楼要爬 \(stairs) 层楼梯：\(stairs) × \(minutes) = \(stairs * minutes)")
        }
    }

    /// 搭配问题
    private static func combo() -> MathHomeworkProblem {
        let type = Int.random(in: 0..<3)
        if type == 0 {
            let tops = Int.random(in: 2...3), bottoms = Int.random(in: 2...4)
            return problem(kind: .combo,
                           prompt: "\(tops) 件上衣，\(bottoms) 条裤子，一共有几种搭配穿法？",
                           correct: "\(tops * bottoms)", isWrong: Bool.random(),
                           hint: "每件上衣配 \(bottoms) 条裤子：\(tops) × \(bottoms)")
        } else if type == 1 {
            let drinks = Int.random(in: 2...3), foods = Int.random(in: 2...4)
            let drinkNames = drinks == 2 ? "豆浆、牛奶" : "豆浆、牛奶、果汁"
            let foodNames = foods == 2 ? "包子、油条" : (foods == 3 ? "包子、油条、面包" : "包子、油条、面包、蛋糕")
            return problem(kind: .combo,
                           prompt: "饮品有 \(drinkNames)，主食有 \(foodNames)，选 1 杯饮品 + 1 种主食，几种组合？",
                           correct: "\(drinks * foods)", isWrong: Bool.random(),
                           hint: "\(drinks) 种饮品 × \(foods) 种主食 = \(drinks * foods)")
        } else {
            let a = Int.random(in: 2...4), b = Int.random(in: 2...3)
            return problem(kind: .combo,
                           prompt: "从家到学校有 \(a) 条路，从学校到图书馆有 \(b) 条路，从家经学校到图书馆有几种走法？",
                           correct: "\(a * b)", isWrong: Bool.random(),
                           hint: "\(a) × \(b) = \(a * b) 种走法")
        }
    }

    /// 有余数除法
    private static func remainder() -> MathHomeworkProblem {
        let type = Int.random(in: 0..<3)
        if type == 0 {
            let divisor = Int.random(in: 3...8)
            let quotient = Int.random(in: 2...6)
            let maxR = divisor - 1
            let dividend = divisor * quotient + maxR
            return problem(kind: .remainder,
                           prompt: "□ ÷ \(divisor) = \(quotient)……△，△最大是几？此时□是多少？",
                           correct: "\(maxR)，\(dividend)", isWrong: Bool.random(),
                           hint: "余数最大是 \(divisor)−1=\(maxR)，□=\(divisor)×\(quotient)+\(maxR)=\(dividend)")
        } else if type == 1 {
            let total = Int.random(in: 15...40)
            let each = Int.random(in: 3...7)
            let people = total / each
            let leftover = total % each
            return problem(kind: .remainder,
                           prompt: "\(total) 个🍊，每人分 \(each) 个，最多分给几人？剩几个？",
                           correct: "\(people)，\(leftover)", isWrong: Bool.random(),
                           hint: "\(total) ÷ \(each) = \(people)……\(leftover)")
        } else {
            let kids = Int.random(in: 3...7)
            let maxLeft = kids - 1
            return problem(kind: .remainder,
                           prompt: "一些🍬分给 \(kids) 个小朋友，每人一样多，最多能剩几块糖？",
                           correct: "\(maxLeft)", isWrong: Bool.random(),
                           hint: "余数 < 除数，最多剩 \(kids)−1=\(maxLeft) 块")
        }
    }

    /// 重叠拼接
    private static func overlap() -> MathHomeworkProblem {
        let n = Int.random(in: 2...3)
        let each = Int.random(in: 8...15)
        let lap = Int.random(in: 1...3)
        let total = each * n - lap * (n - 1)
        if n == 2 {
            return problem(kind: .overlap,
                           prompt: "两根木条各长 \(each) 厘米，绑在一起重叠 \(lap) 厘米，绑完总长多少厘米？",
                           correct: "\(total)", isWrong: Bool.random(),
                           hint: "\(each) + \(each) − \(lap) = \(total)")
        } else {
            return problem(kind: .overlap,
                           prompt: "三根木条各长 \(each) 厘米，每两根重叠 \(lap) 厘米拼起来，总长多少厘米？",
                           correct: "\(total)", isWrong: Bool.random(),
                           hint: "\(each)×3 − \(lap)×2 = \(total)")
        }
    }

    /// 和差问题
    private static func sumDiff() -> MathHomeworkProblem {
        let diff = Int.random(in: 2...8)
        let small = Int.random(in: 3...15)
        let big = small + diff
        let sum = big + small
        let animals = [("🐔", "🐤"), ("🐱", "🐶"), ("哥哥", "弟弟")]
        let pair = animals.randomElement()!
        return problem(kind: .sumDiff,
                       prompt: "\(pair.0)和\(pair.1)一共 \(sum) 个，\(pair.0)比\(pair.1)多 \(diff) 个，\(pair.0)有几个？\(pair.1)有几个？",
                       correct: "\(big)，\(small)", isWrong: Bool.random(),
                       hint: "大数=(\(sum)+\(diff))÷2=\(big)，小数=\(sum)−\(big)=\(small)")
    }

    /// 几组多几个 / 少几个
    private static func groupExtra() -> MathHomeworkProblem {
        let groups = Int.random(in: 3...6)
        let each = Int.random(in: 3...8)
        if Bool.random() {
            let extra = Int.random(in: 1...4)
            let total = groups * each + extra
            let item = ["🍎", "🍪", "⭐️", "🌸"].randomElement()!
            return problem(kind: .groupExtra,
                           prompt: "有 \(groups) 盘\(item)，每盘 \(each) 个，还多 \(extra) 个，一共多少个？",
                           correct: "\(total)", isWrong: Bool.random(),
                           hint: "\(groups)×\(each)+\(extra) = \(total)")
        } else {
            let less = Int.random(in: 1...3)
            let total = groups * each - less
            let item = ["🍬", "🖍", "🧩", "🎈"].randomElement()!
            return problem(kind: .groupExtra,
                           prompt: "\(groups) 盒\(item)，每盒 \(each) 个，还差 \(less) 个装满，实际有几个？",
                           correct: "\(total)", isWrong: Bool.random(),
                           hint: "\(groups)×\(each)−\(less) = \(total)")
        }
    }

    // MARK: 工具

    private static func fmt(_ v: Double) -> String {
        v == v.rounded() ? "\(Int(v.rounded()))" : String(format: "%g", v)
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        var x = abs(a), y = abs(b)
        while y != 0 { (x, y) = (y, x % y) }
        return x
    }

    private static func simplified(_ n: Int, _ d: Int) -> String {
        guard n != 0 else { return "0" }
        if n % d == 0 { return "\(n / d)" }
        let g = gcd(n, d)
        return "\(n / g)/\(d / g)"
    }

    private static func wrongFraction(_ a: Int, _ b: Int, _ c: Int, _ d: Int) -> String {
        let n = a * c + Int.random(in: -1...1)
        let den = b * d + (Bool.random() ? 1 : 0)
        return n > 0 && den > 0 && n != den ? simplified(n, den) : simplified(a * c, b * d)
    }

    private static func fractionOptions(correct: String) -> [String] {
        var set: [String] = [correct]
        var guardCount = 0
        while set.count < 3 && guardCount < 30 {
            guardCount += 1
            let parts = correct.split(separator: "/").compactMap { Int($0) }
            if parts.count == 2 {
                let n = parts[0] + Int.random(in: -2...2)
                let d = parts[1] + Int.random(in: 0...1)
                if n > 0 && d > 0 {
                    let v = n == d ? "1" : simplified(n, d)
                    if !set.contains(v) { set.append(v) }
                }
            } else if let num = Int(correct) {
                let v = "\(num + Int.random(in: -2...2))"
                if !set.contains(v) { set.append(v) }
            }
        }
        while set.count < 3 { set.append("?") }
        return set.shuffled()
    }

    private static func clockOptions(correct: String) -> [String] {
        var set: [String] = [correct]
        let parts = correct.split(separator: " ").compactMap { Int($0) }
        if let h = parts.first {
            for delta in [-1, 1] {
                let nh = ((h - 1 + delta + 12) % 12) + 1
                set.append(correct.contains("半") ? "\(nh) 时半" : "\(nh) 时")
            }
        }
        while set.count < 3 { set.append(correct) }
        return set.shuffled()
    }
}

// MARK: - 钟面视图

struct HomeworkClockFace: View {
    let hour: Int
    let half: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .overlay(Circle().strokeBorder(AppTheme.fieldInk, lineWidth: 2))
                .frame(width: 64, height: 64)
            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(AppTheme.fieldInk.opacity(0.5))
                    .frame(width: 1, height: i % 3 == 0 ? 5 : 3)
                    .offset(y: -29)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            // 分针
            Rectangle()
                .fill(Color(red: 232/255, green: 100/255, blue: 82/255))
                .frame(width: 2, height: 26)
                .offset(y: -13)
                .rotationEffect(.degrees(half ? 180 : 0))
            // 时针
            Rectangle()
                .fill(AppTheme.fieldInk)
                .frame(width: 2.5, height: 16)
                .offset(y: -8)
                .rotationEffect(.degrees(Double(hour % 12) * 30 + (half ? 15 : 0)))
            Circle()
                .fill(AppTheme.fieldInk)
                .frame(width: 4, height: 4)
        }
        .frame(width: 64, height: 64)
    }
}
import SwiftUI

// MARK: - 数学作业 · 主容器（年级切换 + 一轮 15 题）

struct MathHomeworkView: View {
    let onExit: () -> Void

    @State private var grade: MathHomeworkGrade = .one
    @State private var roundKey = UUID()

    var body: some View {
        ZStack {
            mathBackground

            MathHomeworkGameView(
                grade: $grade,
                onExit: onExit,
                onRefresh: { roundKey = UUID() }
            )
            .id(roundKey)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var mathBackground: some View {
        ZStack {
            FieldBackground()

            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let drift = 12 * sin(t * 0.42)
                let bob = 2.5 * sin(t * 0.8 + 1.0)
                ZStack {
                    Capsule().fill(Color.white.opacity(0.92)).frame(width: 38, height: 13).offset(y: 3)
                    Circle().fill(Color.white.opacity(0.92)).frame(width: 22, height: 22).offset(x: -8, y: -5)
                    Circle().fill(Color.white.opacity(0.88)).frame(width: 18, height: 18).offset(x: 6, y: -3)
                }
                .frame(width: 46, height: 26)
                .offset(x: drift, y: bob)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, -10)
                .padding(.top, 44)
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - 批改页

struct MathHomeworkGameView: View {
    @Binding var grade: MathHomeworkGrade
    let onExit: () -> Void
    let onRefresh: () -> Void

    @State private var problems: [MathHomeworkProblem] = []
    @State private var states: [UUID: ProblemUIState] = [:]
    @State private var markedCount = 0
    @State private var showStamp = false
    @State private var comment = ""

    struct ProblemUIState {
        var marked = false        // 已圈红（正在改正）
        var fixed = false         // 已改正/确认对
        var correctNow = false    // 点到对题
    }

    @State private var showGradePicker = false

    var body: some View {
        VStack(spacing: 0) {
            // 试卷纸面（全屏白纸感）
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 试卷头
                    paperHeader

                    // 题目
                    VStack(spacing: 0) {
                        ForEach(Array(problems.enumerated()), id: \.element.id) { index, problem in
                            problemRow(problem, index: index)
                            if index < problems.count - 1 {
                                Rectangle()
                                    .fill(Color(red: 180/255, green: 180/255, blue: 180/255).opacity(0.3))
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color(red: 252/255, green: 251/255, blue: 247/255).ignoresSafeArea())
        .overlay(alignment: .top) {
            // 浮动工具栏
            HStack(spacing: 12) {
                GracefulBackButton(action: onExit)

                Button { showGradePicker = true } label: {
                    HStack(spacing: 3) {
                        Text(grade.name)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.fieldInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                Text("🖊 \(markedCount)/\(wrongTotal)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 232/255, green: 100/255, blue: 82/255))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.ultraThinMaterial))

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.fieldOliveDeep)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
        }
        .overlay {
            if showStamp {
                MathStampOverlay(comment: $comment,
                                 wrongTotal: wrongTotal,
                                 onReset: { resetRound() },
                                 onExit: onExit,
                                 onRefresh: onRefresh)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showStamp)
        .onAppear { resetRound() }
        .onChange(of: grade) { _, _ in resetRound() }
        .sheet(isPresented: $showGradePicker) {
            VStack(spacing: 12) {
                Text("选择年级")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .padding(.top, 18)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(MathHomeworkGrade.allCases) { g in
                        Button {
                            grade = g
                            showGradePicker = false
                        } label: {
                            Text(g.name)
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(grade == g ? .white : AppTheme.fieldInk)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(grade == g ? g.color : Color(red: 245/255, green: 245/255, blue: 240/255))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .presentationDetents([.height(200)])
        }
    }

    private var wrongTotal: Int {
        problems.filter { $0.isWrong }.count
    }

    // MARK: 题目行

    private func displayText(_ problem: MathHomeworkProblem) -> String {
        let p = problem.prompt
        let ans = problem.studentAnswer
        if p.contains("= ?") { return p.replacingOccurrences(of: "= ?", with: "= \(ans)") }
        if p.contains("□ = ?") { return p.replacingOccurrences(of: "□ = ?", with: "□ = \(ans)") }
        if p.contains("（ ）") { return p.replacingOccurrences(of: "（ ）", with: "（\(ans)）") }
        if p.contains("□") { return p.replacingOccurrences(of: "□", with: ans) }
        return "\(p)\n答：\(ans)"
    }

    @ViewBuilder
    private func problemRow(_ problem: MathHomeworkProblem, index: Int) -> some View {
        let state = states[problem.id] ?? ProblemUIState()
        let isDone = state.fixed || state.correctNow

        VStack(alignment: .leading, spacing: 4) {
            Button {
                tapRow(problem)
            } label: {
                HStack(alignment: .top, spacing: 0) {
                    Text("\(index + 1).")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(red: 100/255, green: 100/255, blue: 100/255))
                        .frame(width: 28, alignment: .leading)

                    if problem.kind == .clock, let parts = clockParts(of: problem) {
                        HStack(spacing: 8) {
                            HomeworkClockFace(hour: parts.0, half: parts.1)
                            Text("答：\(problem.studentAnswer)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(state.fixed && problem.isWrong
                                    ? Color(red: 232/255, green: 100/255, blue: 82/255)
                                    : Color(red: 40/255, green: 40/255, blue: 40/255))
                                .strikethrough(state.fixed && problem.isWrong, color: Color(red: 232/255, green: 100/255, blue: 82/255))
                        }
                    } else {
                        problemContentView(problem, state: state)
                    }

                    Spacer(minLength: 8)

                    if state.fixed && problem.isWrong {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(red: 232/255, green: 100/255, blue: 82/255))
                    } else if state.correctNow {
                        Text("没错")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 160/255, green: 160/255, blue: 160/255))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    state.fixed && problem.isWrong
                        ? Color(red: 255/255, green: 240/255, blue: 237/255)
                        : Color.clear
                )
            }
            .buttonStyle(.plain)
            .disabled(isDone)

            if state.fixed && problem.isWrong {
                HStack(spacing: 4) {
                    Text("✎ 正确：\(problem.correctAnswer)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 232/255, green: 100/255, blue: 82/255))
                    Text("· \(problem.hint)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 140/255, green: 140/255, blue: 140/255))
                }
                .padding(.leading, 44)
                .padding(.bottom, 6)
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: state.fixed)
        .animation(.easeOut(duration: 0.25), value: state.correctNow)
    }

    @ViewBuilder
    private func problemContentView(_ problem: MathHomeworkProblem, state: ProblemUIState) -> some View {
        let textColor = state.fixed && problem.isWrong
            ? Color(red: 232/255, green: 100/255, blue: 82/255)
            : Color(red: 40/255, green: 40/255, blue: 40/255)
        let struck = state.fixed && problem.isWrong

        switch problem.kind {
        case .picture:
            VStack(alignment: .leading, spacing: 2) {
                Text(problem.prompt)
                    .font(.system(size: 18))
                    .foregroundStyle(textColor)
                Text("答：\(problem.studentAnswer)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(textColor)
                    .strikethrough(struck, color: Color(red: 232/255, green: 100/255, blue: 82/255))
            }
        case .count:
            VStack(alignment: .leading, spacing: 2) {
                Text(problem.prompt.components(separatedBy: "\n").first ?? "")
                    .font(.system(size: 18))
                Text(problem.prompt.components(separatedBy: "\n").last ?? "")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(textColor)
                Text("答：\(problem.studentAnswer)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(textColor)
                    .strikethrough(struck, color: Color(red: 232/255, green: 100/255, blue: 82/255))
            }
        case .period:
            VStack(alignment: .leading, spacing: 2) {
                Text(problem.prompt.components(separatedBy: "\n").first ?? "")
                    .font(.system(size: 18))
                Text(problem.prompt.components(separatedBy: "\n").last ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(red: 120/255, green: 120/255, blue: 120/255))
                Text("答：\(problem.studentAnswer)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(textColor)
                    .strikethrough(struck, color: Color(red: 232/255, green: 100/255, blue: 82/255))
            }
        default:
            Text(displayText(problem))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(textColor)
                .strikethrough(struck, color: Color(red: 232/255, green: 100/255, blue: 82/255))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: 交互

    private func tapRow(_ problem: MathHomeworkProblem) {
        let state = states[problem.id] ?? ProblemUIState()
        guard !state.fixed, !state.correctNow else { return }

        if problem.isWrong {
            withAnimation(.easeOut(duration: 0.25)) {
                states[problem.id] = ProblemUIState(marked: true, fixed: true)
            }
            markedCount += 1
            if markedCount == wrongTotal {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showStamp = true
                    }
                }
            }
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                states[problem.id] = ProblemUIState(correctNow: true)
            }
        }
    }

    // MARK: 试卷头部

    private var paperHeader: some View {
        VStack(spacing: 6) {
            Spacer().frame(height: 60)

            Text("\(grade.name)数学练习卷")
                .font(.system(size: 18, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 40/255, green: 40/255, blue: 40/255))

            Text("(共 \(problems.count) 题，其中 \(wrongTotal) 题有错误，请用红笔圈出)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(red: 120/255, green: 120/255, blue: 120/255))

            HStack(spacing: 30) {
                Text("班级：________")
                Text("姓名：---")
                Text("得分：___")
            }
            .font(.system(size: 11))
            .foregroundStyle(Color(red: 80/255, green: 80/255, blue: 80/255))
            .padding(.top, 4)

            Rectangle()
                .fill(Color(red: 60/255, green: 60/255, blue: 60/255))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.top, 8)
        }
        .padding(.bottom, 10)
    }

    private func resetRound() {
        problems = MathHomeworkGen.makeRound(grade: grade)
        states = [:]
        markedCount = 0
        showStamp = false
        comment = ""
    }

    // MARK: 工具

    private func clockParts(of problem: MathHomeworkProblem) -> (Int, Bool)? {
        // 从正确答案解析钟面时间（正确时间展示）
        let parts = problem.correctAnswer.split(separator: " ")
        guard let h = parts.first.flatMap({ Int($0) }) else { return nil }
        return (h, problem.correctAnswer.contains("半"))
    }
}

// MARK: - 印章结算页

struct MathStampOverlay: View {
    @Binding var comment: String
    let wrongTotal: Int
    let onReset: () -> Void
    let onExit: () -> Void
    let onRefresh: () -> Void

    @State private var stampIn = false
    @State private var flowers = ""
    @State private var thank = false
    @State private var appear = false

    private let comments = ["你真棒！", "进步很大！", "下次加油"]

    var body: some View {
        ZStack {
            Color(red: 30/255, green: 40/255, blue: 28/255).opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                Text("🎉")
                    .font(.system(size: 46))
                    .scaleEffect(appear ? 1 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appear)

                Text("\(wrongTotal) 处错误全揪出来！")
                    .font(.system(size: 20, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.15), value: appear)

                Text("李慕子的作业本被小老师改得干干净净")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.25), value: appear)

                Text("优")
                    .font(.system(size: 34, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 232/255, green: 100/255, blue: 82/255))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color(red: 232/255, green: 100/255, blue: 82/255), lineWidth: 5)
                    )
                    .rotationEffect(.degrees(-12))
                    .scaleEffect(stampIn ? 1 : 2.2)
                    .opacity(stampIn ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: stampIn)

                Text("挑一句评语盖上去：")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 181/255, green: 118/255, blue: 10/255))
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.4), value: appear)

                HStack(spacing: 8) {
                    ForEach(comments, id: \.self) { c in
                        Button {
                            comment = c
                            stampComment()
                        } label: {
                            Text(c)
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundStyle(comment == c ? AppTheme.fieldMint : AppTheme.fieldInk)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(comment == c ? Color(red: 223/255, green: 245/255, blue: 231/255) : Color(red: 244/255, green: 248/255, blue: 238/255))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(comment == c ? AppTheme.fieldMint : AppTheme.fieldOlive.opacity(0.35), lineWidth: 2)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(flowers)
                    .font(.system(size: 24))
                    .frame(height: 30)
                    .opacity(flowers.isEmpty ? 0 : 1)

                if thank {
                    Text("李慕子：谢谢小老师！评语我记下啦 🥰")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 194/255, green: 90/255, blue: 126/255))
                        .transition(.scale.combined(with: .opacity))
                }

                HStack(spacing: 10) {
                    Button(action: onReset) {
                        Text("再批一本")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(colors: [Color(red: 126/255, green: 211/255, blue: 160/255), AppTheme.fieldMint], startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .shadow(color: AppTheme.fieldMint.opacity(0.4), radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)

                    Button(action: onRefresh) {
                        Text("换一本")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.fieldInk)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Color.white,
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(AppTheme.fieldOlive.opacity(0.32), lineWidth: 2.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 14)
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.5), value: appear)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 22)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 255/255, green: 253/255, blue: 246/255))
                    .shadow(color: Color(red: 30/255, green: 40/255, blue: 28/255).opacity(0.35), radius: 20, y: 8)
            )
            .scaleEffect(appear ? 1 : 0.85)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appear)
        }
        .onAppear {
            appear = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                stampIn = true
            }
        }
    }

    private func stampComment() {
        guard flowers.isEmpty else { return }
        var count = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { t in
            count += 1
            flowers += "🌸"
            if count >= 3 {
                t.invalidate()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    thank = true
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }
}
