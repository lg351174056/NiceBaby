import SwiftUI
import Combine

// MARK: - 口算摩天轮 · 进度持久化

enum ArithmeticProgressStore {
    private static func starsKey(_ g: Int) -> String { "arith.stars.\(g)" }
    private static func timeKey(_ g: Int) -> String { "arith.time.\(g)" }
    private static func countKey(_ g: Int) -> String { "arith.count.\(g)" }

    static func stars(grade: Int) -> Int {
        UserDefaults.standard.integer(forKey: starsKey(grade))
    }

    static func bestTime(grade: Int) -> Int {
        UserDefaults.standard.integer(forKey: timeKey(grade))
    }

    static func playCount(grade: Int) -> Int {
        UserDefaults.standard.integer(forKey: countKey(grade))
    }

    /// 记录一局结果：星级取历史最高，用时取历史最短。
    @discardableResult
    static func record(grade: Int, stars: Int, seconds: Int) -> Bool {
        let oldStars = self.stars(grade: grade)
        let oldTime = bestTime(grade: grade)
        let isNewBest = stars > oldStars || (oldTime == 0 || seconds < oldTime)
        if stars > oldStars { UserDefaults.standard.set(stars, forKey: starsKey(grade)) }
        if oldTime == 0 || seconds < oldTime { UserDefaults.standard.set(seconds, forKey: timeKey(grade)) }
        UserDefaults.standard.set(playCount(grade: grade) + 1, forKey: countKey(grade))
        return isNewBest
    }

    // MARK: 每题限时设置（5-60 秒，5 秒步进；0 = 使用年级默认）

    static var timeLimitOverride: Int {
        UserDefaults.standard.integer(forKey: "arith.limitOverride")
    }

    static func setTimeLimitOverride(_ value: Int) {
        UserDefaults.standard.set(value, forKey: "arith.limitOverride")
    }

    /// 当前生效的每题限时
    static func effectiveTimeLimit(grade: Int) -> Int {
        let override = timeLimitOverride
        return override > 0 ? override : ArithmeticGrade(rawValue: grade)?.timeLimit ?? 15
    }
}

// MARK: - 年级配置

enum ArithmeticGrade: Int, CaseIterable, Identifiable {
    case one = 1, two = 2, three = 3, four = 4, five = 5, six = 6

    var id: Int { rawValue }

    var name: String { "\(rawValue) 年级" }

    var tags: [String] {
        switch self {
        case .one:   return ["20 以内", "加减"]
        case .two:   return ["九九表", "100 以内"]
        case .three: return ["多位数乘除", "求未知数"]
        case .four:  return ["两位数乘除", "简便运算"]
        case .five:  return ["小数乘除", "分数加减"]
        case .six:   return ["分数乘除", "百分数", "比例"]
        }
    }

    var color: Color {
        switch self {
        case .one:   return Color(red: 232/255, green: 106/255, blue: 158/255)
        case .two:   return Color(red: 245/255, green: 166/255, blue: 35/255)
        case .three: return Color(red: 76/255, green: 175/255, blue: 125/255)
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

    /// 每题限时（秒）
    var timeLimit: Int {
        switch self {
        case .one, .two:   return 15
        case .three:       return 20
        case .four:        return 25
        case .five, .six:  return 30
        }
    }

    /// 3 年级起用数字键盘输入
    var usesKeypad: Bool { rawValue >= 3 }

    /// 3 年级起有 3 次机会（❤️）
    var usesHearts: Bool { rawValue >= 3 }
}

// MARK: - 题目

struct ArithmeticProblem: Identifiable {
    let id = UUID()
    /// 表达式文本：普通 "8 + 5 = ?"，比较 "8 + 5 ___ 14"，分数 "1/3 + 1/6 = ?"
    let text: String
    let answer: String
    /// 四选一选项；nil 表示键盘输入。比较题为 ["<", "=", ">"]
    let options: [String]?
    let hint: String
    var isCompare: Bool { options == ["<", "=", ">"] }
}

// MARK: - 题目生成器（按年级严格限定数值范围与运算类型）

enum ArithmeticGen {

    static func makeProblem(grade: ArithmeticGrade, avoid: Set<String>) -> ArithmeticProblem {
        for _ in 0..<40 {
            let p = randomProblem(grade: grade)
            if !avoid.contains(p.text) { return p }
        }
        return randomProblem(grade: grade)
    }

    // MARK: 工具

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

    private static func options(for answer: Int) -> [String] {
        var set: Set<Int> = [answer]
        var delta = 1
        while set.count < 4 {
            for d in [delta, -delta, delta + 1, -(delta + 1)] where answer + d >= 0 {
                set.insert(answer + d)
                if set.count == 4 { break }
            }
            delta += 2
        }
        return set.shuffled().map(String.init)
    }

    private static func compareOptions(_ sum: Int, _ c: Int) -> (answer: String, options: [String]) {
        let ans: String = sum > c ? ">" : (sum < c ? "<" : "=")
        return (ans, ["<", "=", ">"])
    }

    // MARK: 各年级出题

    private static func randomProblem(grade: ArithmeticGrade) -> ArithmeticProblem {
        switch grade {
        case .one:   return gradeOne()
        case .two:   return gradeTwo()
        case .three: return gradeThree()
        case .four:  return gradeFour()
        case .five:  return gradeFive()
        case .six:   return gradeSix()
        }
    }

    /// 一年级：20 以内加减（含凑十、退位），比大小
    private static func gradeOne() -> ArithmeticProblem {
        switch Int.random(in: 0..<5) {
        case 0: // 不进位加
            let a = Int.random(in: 1...8), b = Int.random(in: 1...9)
            let sum = a + b
            if sum <= 10 {
                return ArithmeticProblem(text: "\(a) + \(b) = ?", answer: "\(sum)",
                                         options: options(for: sum), hint: "凑十法：先补成 10，再加剩下的")
            }
            return gradeOne()
        case 1: // 进位加（11-20）
            let a = Int.random(in: 3...9), b = Int.random(in: 2...9)
            let sum = a + b
            if sum >= 11 && sum <= 20 {
                return ArithmeticProblem(text: "\(a) + \(b) = ?", answer: "\(sum)",
                                         options: options(for: sum), hint: "凑十法：把 \(b) 拆出 \(10 - a)，先凑成 10")
            }
            return gradeOne()
        case 2: // 不退位减
            let a = Int.random(in: 10...19), b = Int.random(in: 1...8)
            if a - b >= 0 && a % 10 >= b {
                return ArithmeticProblem(text: "\(a) − \(b) = ?", answer: "\(a - b)",
                                         options: options(for: a - b), hint: "个位够减，直接减")
            }
            return gradeOne()
        case 3: // 退位减
            let a = Int.random(in: 11...19), b = Int.random(in: 2...9)
            if a % 10 < b {
                return ArithmeticProblem(text: "\(a) − \(b) = ?", answer: "\(a - b)",
                                         options: options(for: a - b), hint: "个位不够减，向十位借 1 当 10")
            }
            return gradeOne()
        default: // 比大小
            let a = Int.random(in: 1...9), b = Int.random(in: 1...9)
            let sum = a + b
            let c = max(0, sum + Int.random(in: -2...2))
            let (ans, opts) = compareOptions(sum, c)
            return ArithmeticProblem(text: "\(a) + \(b) ___ \(c)", answer: ans,
                                     options: opts, hint: "先算出左边，再和右边比一比")
        }
    }

    /// 二年级：100 以内进位加/退位减、表内乘除、乘加乘减、比大小
    private static func gradeTwo() -> ArithmeticProblem {
        switch Int.random(in: 0..<7) {
        case 0: // 100 以内进位加
            let a = Int.random(in: 21...69), b = Int.random(in: 21...69)
            if a + b <= 100 && (a % 10) + (b % 10) >= 10 {
                return ArithmeticProblem(text: "\(a) + \(b) = ?", answer: "\(a + b)",
                                         options: options(for: a + b), hint: "个位相加满十，向十位进 1")
            }
            return gradeTwo()
        case 1: // 退位减
            let a = Int.random(in: 21...99), b = Int.random(in: 11...99)
            if b < a && a % 10 < b % 10 {
                return ArithmeticProblem(text: "\(a) − \(b) = ?", answer: "\(a - b)",
                                         options: options(for: a - b), hint: "个位不够减，从十位退 1 当 10")
            }
            return gradeTwo()
        case 2: // 表内乘法
            let a = Int.random(in: 2...9), b = Int.random(in: 2...9)
            return ArithmeticProblem(text: "\(a) × \(b) = ?", answer: "\(a * b)",
                                     options: options(for: a * b), hint: "背一背九九乘法表")
        case 3: // 表内除法
            let a = Int.random(in: 2...9), b = Int.random(in: 2...9)
            return ArithmeticProblem(text: "\(a * b) ÷ \(a) = ?", answer: "\(b)",
                                     options: options(for: b), hint: "想乘法：几乘 \(a) 等于 \(a * b)？")
        case 4: // 乘加
            let a = Int.random(in: 2...9), b = Int.random(in: 2...9), c = Int.random(in: 1...9)
            return ArithmeticProblem(text: "\(a) × \(b) + \(c) = ?", answer: "\(a * b + c)",
                                     options: options(for: a * b + c), hint: "先算乘法，再算加法")
        case 5: // 乘减
            let a = Int.random(in: 2...9), b = Int.random(in: 2...9)
            let prod = a * b
            let c = Int.random(in: 1...(prod - 1))
            return ArithmeticProblem(text: "\(a) × \(b) − \(c) = ?", answer: "\(prod - c)",
                                     options: options(for: prod - c), hint: "先算乘法，再算减法")
        default: // 比大小
            let a = Int.random(in: 2...9), b = Int.random(in: 2...9)
            let prod = a * b
            let c = max(0, prod + Int.random(in: -3...3))
            let (ans, opts) = compareOptions(prod, c)
            return ArithmeticProblem(text: "\(a) × \(b) ___ \(c)", answer: ans,
                                     options: opts, hint: "先算出左边，再和右边比一比")
        }
    }

    /// 三年级：多位数乘除、三位数加减、求未知数
    private static func gradeThree() -> ArithmeticProblem {
        switch Int.random(in: 0..<6) {
        case 0: // 一位数乘两位数
            let a = Int.random(in: 3...9), b = Int.random(in: 12...99)
            return ArithmeticProblem(text: "\(a) × \(b) = ?", answer: "\(a * b)",
                                     options: nil, hint: "一位数乘两位数，从个位乘起，满十进一")
        case 1: // 两位数除以一位数（整除）
            let d = Int.random(in: 2...9), q = Int.random(in: 12...99)
            let n = d * q
            if n <= 999 {
                return ArithmeticProblem(text: "\(n) ÷ \(d) = ?", answer: "\(q)",
                                         options: nil, hint: "从高位除起，商写在对应数位上")
            }
            return gradeThree()
        case 2: // 三位数加减
            let a = Int.random(in: 200...600), b = Int.random(in: 100...300)
            if a + b <= 999 {
                return ArithmeticProblem(text: "\(a) + \(b) = ?", answer: "\(a + b)",
                                         options: nil, hint: "相同数位对齐，从个位加起")
            }
            return gradeThree()
        case 3: // 三位数减法
            let a = Int.random(in: 400...900), b = Int.random(in: 100...399)
            return ArithmeticProblem(text: "\(a) − \(b) = ?", answer: "\(a - b)",
                                     options: nil, hint: "相同数位对齐，不够减就退位")
        case 4: // 求因数 □ × b = c
            let a = Int.random(in: 2...9), b = Int.random(in: 3...9)
            return ArithmeticProblem(text: "□ × \(b) = \(a * b)", answer: "\(a)",
                                     options: nil, hint: "几乘 \(b) 得 \(a * b)？想乘法口诀")
        default: // 求除数 a ÷ □ = b
            let a = Int.random(in: 2...9), b = Int.random(in: 3...9)
            return ArithmeticProblem(text: "\(a * b) ÷ □ = \(a)", answer: "\(b)",
                                     options: nil, hint: "被除数 ÷ 商 = 除数")
        }
    }

    /// 四年级：两位数乘除、简便运算、四则混合
    private static func gradeFour() -> ArithmeticProblem {
        switch Int.random(in: 0..<5) {
        case 0: // 两位数乘两位数
            let a = Int.random(in: 11...49), b = Int.random(in: 11...49)
            return ArithmeticProblem(text: "\(a) × \(b) = ?", answer: "\(a * b)",
                                     options: nil, hint: "先用个位乘，再用十位乘，最后相加")
        case 1: // 两位数除以两位数（整除）
            let d = Int.random(in: 11...49), q = Int.random(in: 2...9)
            let n = d * q
            return ArithmeticProblem(text: "\(n) ÷ \(d) = ?", answer: "\(q)",
                                     options: nil, hint: "把除数看成整十数来试商")
        case 2: // 简便运算（25/125 凑整）
            let k = [4, 8, 12, 16, 20, 24, 28, 32, 40, 80].randomElement()!
            let m = Bool.random() ? 25 : 125
            return ArithmeticProblem(text: "\(k) × \(m) = ?", answer: "\(k * m)",
                                     options: nil, hint: "\(k) × \(m)：凑整百整千，口算更快")
        case 3: // 四则混合 · 乘加
            let a = Int.random(in: 2...9), b = Int.random(in: 2...9), c = Int.random(in: 1...9)
            return ArithmeticProblem(text: "\(a) × \(b) + \(c) = ?", answer: "\(a * b + c)",
                                     options: nil, hint: "先乘除后加减，别急着算")
        default: // 四则混合 · 乘减
            let a = Int.random(in: 2...9), b = Int.random(in: 2...9)
            let prod = a * b
            let c = Int.random(in: 1...(prod - 1))
            return ArithmeticProblem(text: "\(a) × \(b) − \(c) = ?", answer: "\(prod - c)",
                                     options: nil, hint: "先乘除后加减，别急着算")
        }
    }

    /// 五年级：小数加减乘除、同分母分数加减、简易方程
    private static func gradeFive() -> ArithmeticProblem {
        switch Int.random(in: 0..<6) {
        case 0: // 小数加法（1 位小数）
            let a = Int.random(in: 5...90), b = Int.random(in: 5...90)
            if a + b <= 100 {
                let x = Double(a) / 10, y = Double(b) / 10
                return ArithmeticProblem(text: "\(fmt(x)) + \(fmt(y)) = ?", answer: fmt(x + y),
                                         options: nil, hint: "小数点对齐，按整数加法算")
            }
            return gradeFive()
        case 1: // 小数减法（1 位小数）
            let a = Int.random(in: 20...90), b = Int.random(in: 5...(a - 5))
            let x = Double(a) / 10, y = Double(b) / 10
            return ArithmeticProblem(text: "\(fmt(x)) − \(fmt(y)) = ?", answer: fmt(x - y),
                                     options: nil, hint: "小数点对齐，不够减就退位")
        case 2: // 小数乘法：一位小数 × 整数
            let a = Int.random(in: 2...9), b = Int.random(in: 2...9)
            let x = Double(a), y = Double(b) / 10
            return ArithmeticProblem(text: "\(a) × \(fmt(y)) = ?", answer: fmt(x * y),
                                     options: nil, hint: "先按整数乘，再点小数点")
        case 3: // 小数除法（整除）
            let c = Int.random(in: 2...9), a = Int.random(in: 2...9)
            if (a * 10) % c == 0 {
                let d = Double(a * 10 / c) / 10
                return ArithmeticProblem(text: "\(a) ÷ \(fmt(d)) = ?", answer: "\(c)",
                                         options: nil, hint: "除数扩大几倍，被除数也扩大几倍")
            }
            return gradeFive()
        case 4: // 同分母分数加减
            let b = Int.random(in: 2...9), a = Int.random(in: 1...b - 1), c = Int.random(in: 1...b - 1)
            return ArithmeticProblem(text: "\(a)/\(b) + \(c)/\(b) = ?", answer: simplified(a + c, b),
                                     options: nil, hint: "分母相同，分子相加，记得约分")
        default: // 简易方程
            if Bool.random() {
                let x = Int.random(in: 1...9), b = Int.random(in: 1...9)
                return ArithmeticProblem(text: "x + \(b) = \(x + b)", answer: "\(x)",
                                         options: nil, hint: "等式两边同时减去 \(b)")
            } else {
                let x = Int.random(in: 1...9), b = Int.random(in: 1...9)
                return ArithmeticProblem(text: "x − \(b) = \(x - b)", answer: "\(x)",
                                         options: nil, hint: "等式两边同时加上 \(b)")
            }
        }
    }

    /// 六年级：分数乘除、百分数、比例
    private static func gradeSix() -> ArithmeticProblem {
        switch Int.random(in: 0..<4) {
        case 0: // 分数乘法
            let a = Int.random(in: 1...4), b = Int.random(in: 2...9)
            let c = Int.random(in: 1...4), d = Int.random(in: 2...9)
            return ArithmeticProblem(text: "\(a)/\(b) × \(c)/\(d) = ?", answer: simplified(a * c, b * d),
                                     options: nil, hint: "分子乘分子，分母乘分母，结果约分")
        case 1: // 分数除法
            let a = Int.random(in: 1...4), b = Int.random(in: 2...9)
            let c = Int.random(in: 1...4), d = Int.random(in: 2...9)
            return ArithmeticProblem(text: "\(a)/\(b) ÷ \(c)/\(d) = ?", answer: simplified(a * d, b * c),
                                     options: nil, hint: "除以一个数，等于乘它的倒数")
        case 2: // 百分数
            let pct = [10, 20, 25, 50, 75].randomElement()!
            let y: Int
            switch pct {
            case 25, 75: y = [8, 12, 16, 20, 24, 28, 32, 36, 40].randomElement()!
            case 20:     y = [20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95].randomElement()!
            case 50:     y = Int.random(in: 10...98) * 2
            default:     y = Int.random(in: 10...99)
            }
            return ArithmeticProblem(text: "\(y) 的 \(pct)% = ?", answer: "\(y * pct / 100)",
                                     options: nil, hint: "\(pct)% = \(pct)/100，用它乘 \(y)")
        default: // 比例 a : b = c : □
            let a = Int.random(in: 2...5), k = Int.random(in: 2...4)
            let b = a * k
            let c = Int.random(in: 2...5)
            return ArithmeticProblem(text: "\(a) : \(b) = \(c) : □", answer: "\(k * c)",
                                     options: nil, hint: "内项之积 = 外项之积")
        }
    }

    private static func fmt(_ v: Double) -> String {
        v == v.rounded() ? "\(Int(v.rounded()))" : String(format: "%g", v)
    }
}

// MARK: - 摩天轮（底座静止 + 轮盘旋转）

struct FerrisWheel: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2 - 4)
            let radius = size / 2 - 8
            let wood = Color(red: 176/255, green: 138/255, blue: 94/255)
            let woodDeep = Color(red: 143/255, green: 110/255, blue: 70/255)

            ZStack {
                // 底座支架（静止）
                Path { p in
                    p.move(to: CGPoint(x: center.x - radius * 0.88, y: center.y + radius * 0.98))
                    p.addLine(to: CGPoint(x: center.x - 2, y: center.y + radius * 0.26))
                    p.addLine(to: CGPoint(x: center.x + radius * 0.88, y: center.y + radius * 0.98))
                }
                .stroke(woodDeep, style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))

                Path { p in
                    p.move(to: CGPoint(x: center.x - radius * 0.48, y: center.y + radius * 0.62))
                    p.addLine(to: CGPoint(x: center.x + radius * 0.48, y: center.y + radius * 0.62))
                }
                .stroke(woodDeep.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round))

                Ellipse()
                    .fill(LinearGradient(colors: [wood, woodDeep], startPoint: .top, endPoint: .bottom))
                    .frame(width: radius * 1.3, height: 13)
                    .position(x: center.x, y: center.y + radius * 0.98)

                // 轮盘（旋转）
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let angle = (t * 0.7).truncatingRemainder(dividingBy: 2 * .pi)
                    Canvas { ctx, _ in
                        let ring = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                          width: radius * 2, height: radius * 2))
                        ctx.stroke(ring, with: .color(wood), lineWidth: 5)

                        for i in 0..<8 {
                            let a = angle + Double(i) * (2 * .pi / 8)
                            let dir = CGPoint(x: cos(a), y: sin(a))
                            var spoke = Path()
                            spoke.move(to: center)
                            spoke.addLine(to: CGPoint(x: center.x + dir.x * (radius - 6),
                                                      y: center.y + dir.y * (radius - 6)))
                            ctx.stroke(spoke, with: .color(wood.opacity(0.75)), lineWidth: 3)

                            let cab = CGPoint(x: center.x + dir.x * (radius - 12),
                                              y: center.y + dir.y * (radius - 12))
                            let rect = CGRect(x: cab.x - 9, y: cab.y - 9, width: 18, height: 18)
                            ctx.fill(Path(ellipseIn: rect), with: .color(cabinColor(i)))
                            ctx.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.85)), lineWidth: 2)
                        }
                    }
                }

                // 轮轴（静止）
                Circle()
                    .fill(LinearGradient(colors: [Color(red: 255/255, green: 233/255, blue: 168/255),
                                                  Color(red: 212/255, green: 168/255, blue: 75/255)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 14, height: 14)
                    .position(center)
                    .shadow(color: woodDeep.opacity(0.5), radius: 3)
            }
        }
        .allowsHitTesting(false)
    }

    private func cabinColor(_ i: Int) -> Color {
        let colors: [Color] = [
            Color(red: 232/255, green: 106/255, blue: 158/255),
            Color(red: 245/255, green: 166/255, blue: 35/255),
            Color(red: 76/255, green: 175/255, blue: 125/255),
            Color(red: 74/255, green: 163/255, blue: 223/255),
            Color(red: 155/255, green: 123/255, blue: 216/255),
            Color(red: 232/255, green: 100/255, blue: 82/255)
        ]
        return colors[i % colors.count]
    }
}

// MARK: - 首页 · 年级选择

struct ArithmeticHomeView: View {
    let onExit: () -> Void

    @State private var selectedGrade: ArithmeticGrade?
    @State private var showLimitPanel = false
    @State private var limitOverride: Int = ArithmeticProgressStore.timeLimitOverride

    var body: some View {
        ZStack {
            fairBackground

            if let grade = selectedGrade {
                ArithmeticGameView(grade: grade, onBack: { selectedGrade = nil }, onExit: onExit)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                homeContent
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .overlay {
            if showLimitPanel {
                limitPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showLimitPanel)
        .animation(.easeInOut(duration: 0.28), value: selectedGrade)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: 底部限时设置面板

    private var limitPanel: some View {
        ZStack(alignment: .bottom) {
            // 透明蒙层（仅拦截点击关闭，不可见）
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture { dismissLimitPanel() }

            VStack(spacing: 16) {
                Capsule()
                    .fill(Color(red: 200/255, green: 205/255, blue: 192/255))
                    .frame(width: 38, height: 4)

                HStack(spacing: 8) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                    Text("每题限时")
                        .font(.system(size: 17, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    Spacer()
                    Text("当前 \(limitOverride > 0 ? "\(limitOverride) 秒" : "按年级默认")")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(limitOverride > 0 ? Color(red: 76/255, green: 175/255, blue: 125/255)
                            : Color(red: 168/255, green: 184/255, blue: 154/255))
                }

                // 非懒加载 Grid：选项与面板同一帧渲染，避免弹出时选项先冒出来
                let values = Array(stride(from: 0, through: 60, by: 5))
                Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                    ForEach(0..<3, id: \.self) { row in
                        GridRow {
                            ForEach(0..<5, id: \.self) { col in
                                let idx = row * 5 + col
                                if idx < values.count {
                                    limitChip(sec: values[idx])
                                } else {
                                    Color.clear.frame(height: 38)
                                }
                            }
                        }
                    }
                }

                Text("选完自动保存 · 低年级建议 15 秒以上")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 26)
            .frame(maxWidth: .infinity)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                    .fill(Color(red: 252/255, green: 250/255, blue: 244/255))
                    .overlay(
                        UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                            .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.25), lineWidth: 1.5)
                    )
            )
            .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.2), radius: 18, y: -4)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    /// 点击选项：立即高亮选中 → 保存 → 稍候收起
    private func pickLimit(_ sec: Int) {
        limitOverride = sec
        ArithmeticProgressStore.setTimeLimitOverride(sec)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            dismissLimitPanel()
        }
    }

    private func dismissLimitPanel() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showLimitPanel = false
        }
    }

    private func limitChip(sec: Int) -> some View {
        let isOn = sec == limitOverride
        return Button {
            pickLimit(sec)
        } label: {
            Text(sec == 0 ? "自动" : "\(sec)s")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(isOn ? .white : Color(red: 74/255, green: 92/255, blue: 66/255))
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isOn
                            ? AnyShapeStyle(LinearGradient(colors: [Color(red: 126/255, green: 211/255, blue: 160/255), Color(red: 76/255, green: 175/255, blue: 125/255)],
                                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color(red: 238/255, green: 245/255, blue: 230/255)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(isOn ? Color(red: 76/255, green: 175/255, blue: 125/255)
                                    : Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 1.5)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var fairBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 190/255, green: 227/255, blue: 245/255),
                    Color(red: 220/255, green: 242/255, blue: 220/255),
                    Color(red: 207/255, green: 235/255, blue: 196/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // 太阳
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 24)
                    .padding(.top, 30)
            }
            .allowsHitTesting(false)

            driftCloud(top: 60)
        }
    }

    private func driftCloud(top: CGFloat) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let drift = 14 * sin(t * 0.42)
            let bob = 3 * sin(t * 0.85 + 1.2)
            ZStack {
                Capsule().fill(Color.white.opacity(0.95)).frame(width: 42, height: 15).offset(y: 4)
                Circle().fill(Color.white.opacity(0.95)).frame(width: 25, height: 25).offset(x: -9, y: -6)
                Circle().fill(Color.white.opacity(0.9)).frame(width: 21, height: 21).offset(x: 7, y: -4)
                Circle().fill(Color.white.opacity(0.9)).frame(width: 15, height: 15).offset(x: 0, y: -10)
            }
            .frame(width: 52, height: 30)
            .offset(x: drift, y: bob)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, -14)
            .padding(.top, top)
        }
        .allowsHitTesting(false)
    }

    private var homeContent: some View {
        VStack(spacing: 0) {
            // 透明导航条（左返回 + 右限时入口）
            ZStack {
                HStack {
                    GracefulBackButton(action: onExit)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showLimitPanel = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "hourglass")
                                .font(.system(size: 11, weight: .bold))
                            Text(limitOverride > 0 ? "\(limitOverride)s" : "自动")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                        }
                        .foregroundStyle(Color(red: 74/255, green: 92/255, blue: 66/255))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.8))
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.7), lineWidth: 1))
                        )
                        .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 3, y: 1)
                    }
                    .buttonStyle(.plain)
                }
                Text("口算摩天轮")
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 6)

            // Hero：摩天轮 + 标题
            VStack(spacing: 8) {
                FerrisWheel()
                    .frame(width: 128, height: 138)
                Text("选一座座舱吧")
                    .font(.system(size: 22, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Text("每个年级一道风景 · 全部通关就是算术之王 🏆")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }
            .padding(.top, 2)
            .padding(.bottom, 14)

            // 座舱网格（6 个年级全解锁）
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(ArithmeticGrade.allCases) { grade in
                        cabinCard(grade)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 10)

                Text("🌱 建议从一年级开始，逐级挑战")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
                    .padding(.bottom, 18)
            }
        }
    }

    private func cabinCard(_ grade: ArithmeticGrade) -> some View {
        let stars = ArithmeticProgressStore.stars(grade: grade.rawValue)
        let best = ArithmeticProgressStore.bestTime(grade: grade.rawValue)
        let count = ArithmeticProgressStore.playCount(grade: grade.rawValue)

        return Button {
            selectedGrade = grade
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("🎠")
                        .font(.system(size: 13))
                    Spacer()
                    Text("🎡")
                        .font(.system(size: 13))
                        .opacity(0.9)
                }

                Text("\(grade.rawValue) 年级")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(grade.rawValue)")
                        .font(.system(size: 40, weight: .heavy, design: .serif))
                        .foregroundStyle(grade.color)
                    Text("年级")
                        .font(.system(size: 11, weight: .heavy, design: .serif))
                        .foregroundStyle(grade.color.opacity(0.85))
                }
                .padding(.leading, 2)

                HStack(spacing: 4) {
                    ForEach(grade.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 74/255, green: 92/255, blue: 66/255))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(grade.light.opacity(0.7))
                                    .overlay(Capsule().strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 1))
                            )
                    }
                }

                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { i in
                        Text("★")
                            .font(.system(size: 13))
                            .foregroundStyle(i < stars ? Color(red: 245/255, green: 166/255, blue: 35/255)
                                : Color(red: 224/255, green: 230/255, blue: 216/255))
                    }
                    Spacer()
                    if best > 0 {
                        Text("最快 \(fmtTime(best))")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 194/255, green: 90/255, blue: 126/255))
                    } else if count > 0 {
                        Text("已玩 \(count) 次")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
                    } else {
                        Text("未开始")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2.5)
                    )
                    .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.1), radius: 6, y: 3)
            )
        }
        .buttonStyle(.bouncy)
    }

    private func fmtTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return "\(m):\(s < 10 ? "0\(s)" : "\(s)")"
    }
}

// MARK: - 答题页 + 结算

private enum QuizPhase {
    case playing
    case result
}

private enum QuizFeedback {
    case correct
    case wrong(correctAnswer: String)
}

private struct QuizMistake: Identifiable {
    let id = UUID()
    let text: String
    let my: String
    let correct: String
    let hint: String
}

private struct QuizResult {
    var correct: Int = 0
    var total: Int = 10
    var elapsed: TimeInterval = 0
    var bestCombo: Int = 0
    var mistakes: [QuizMistake] = []

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var stars: Int {
        switch accuracy {
        case 0.9...: return 3
        case 0.7...: return 2
        case 0.5...: return 1
        default:     return 0
        }
    }
}

struct ArithmeticGameView: View {
    let grade: ArithmeticGrade
    let onBack: () -> Void
    let onExit: () -> Void

    @State private var phase: QuizPhase = .playing
    @State private var current: ArithmeticProblem?
    @State private var index = 0
    @State private var usedTexts: Set<String> = []
    @State private var remaining = 15
    @State private var feedback: QuizFeedback?
    @State private var tappedWrong: String?
    @State private var input = ""
    @State private var combo = 0
    @State private var lives = 3
    @State private var result = QuizResult()
    @State private var advancing = false
    @State private var startDate = Date()
    @State private var appeared = false

    private let roundLength = 10
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            if phase == .result {
                resultView
                    .transition(.opacity)
            } else {
                ZStack {
                    quizDecor
                    quizContent
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: phase == .result)
        .onAppear { startRound() }
        .onReceive(ticker) { _ in tick() }
    }

    // MARK: 答题页点缀（云 + 气球 + 小花）

    private var quizDecor: some View {
        ZStack {
            // 左上小云
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let drift = 10 * sin(t * 0.4)
                let bob = 2.5 * sin(t * 0.8 + 1.0)
                ZStack {
                    Capsule().fill(Color.white.opacity(0.9)).frame(width: 34, height: 12).offset(y: 3)
                    Circle().fill(Color.white.opacity(0.9)).frame(width: 20, height: 20).offset(x: -7, y: -5)
                    Circle().fill(Color.white.opacity(0.85)).frame(width: 16, height: 16).offset(x: 5, y: -3)
                }
                .frame(width: 42, height: 24)
                .offset(x: drift, y: bob)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, -8)
                .padding(.top, 40)
            }

            // 右下气球 + 左下小花（浮动）
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    VStack(spacing: 2) {
                        Text("🎈")
                            .font(.system(size: 22))
                        Text("🎈")
                            .font(.system(size: 16))
                            .opacity(0.85)
                    }
                    .offset(y: CGFloat(sin(t * 1.6) * 5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 18)
                    .padding(.bottom, 10)

                    Text("🌼")
                        .font(.system(size: 18))
                        .offset(y: CGFloat(sin(t * 1.3 + 1.5) * 4))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(.leading, 20)
                        .padding(.bottom, 8)

                    Text("⭐")
                        .font(.system(size: 13))
                        .offset(y: CGFloat(sin(t * 1.9 + 0.6) * 6))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.trailing, 60)
                        .padding(.top, 70)
                }
            }

            // 底部中央：小摩天轮 + 小旗（填补一年级空旷区）
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                HStack(spacing: 30) {
                    Text("🚩")
                        .font(.system(size: 13))
                        .offset(y: CGFloat(sin(t * 1.7 + 0.4) * 3))
                    Text("🎡")
                        .font(.system(size: 30))
                        .offset(y: CGFloat(sin(t * 1.4) * 4))
                    Text("🚩")
                        .font(.system(size: 13))
                        .offset(y: CGFloat(sin(t * 1.7 + 1.2) * 3))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 10)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: 回合控制

    private func startRound() {
        phase = .playing
        index = 0
        usedTexts = []
        input = ""
        feedback = nil
        tappedWrong = nil
        advancing = false
        combo = 0
        lives = grade.usesHearts ? 3 : 0
        result = QuizResult()
        appeared = false
        startDate = Date()
        nextQuestion()
    }

    private func nextQuestion() {
        guard index < roundLength else {
            finishRound()
            return
        }
        let problem = ArithmeticGen.makeProblem(grade: grade, avoid: usedTexts)
        usedTexts.insert(problem.text)
        current = problem
        remaining = ArithmeticProgressStore.effectiveTimeLimit(grade: grade.rawValue)
        feedback = nil
        tappedWrong = nil
        input = ""
    }

    /// 右上角刷新：换一道新题，不计对错
    private func refreshProblem() {
        guard let old = current else { return }
        usedTexts.insert(old.text)
        let problem = ArithmeticGen.makeProblem(grade: grade, avoid: usedTexts)
        usedTexts.insert(problem.text)
        current = problem
        remaining = ArithmeticProgressStore.effectiveTimeLimit(grade: grade.rawValue)
        feedback = nil
        tappedWrong = nil
        input = ""
    }

    private func tick() {
        guard phase == .playing, feedback == nil, let _ = current else { return }
        if remaining > 0 {
            remaining -= 1
        }
        if remaining == 0 {
            markWrong(my: "超时")
        }
    }

    private func submit(_ answer: String) {
        guard let problem = current, feedback == nil else { return }
        if answer == problem.answer {
            markCorrect()
        } else {
            markWrong(my: answer, tapped: answer)
        }
    }

    private func markCorrect() {
        result.correct += 1
        combo += 1
        result.bestCombo = max(result.bestCombo, combo)
        feedback = .correct
        scheduleAdvance(delay: 1.2) {
            index += 1
            nextQuestion()
        }
    }

    private func markWrong(my: String, tapped: String? = nil) {
        guard let problem = current else { return }
        result.mistakes.append(QuizMistake(text: problem.text, my: my,
                                           correct: problem.answer, hint: problem.hint))
        combo = 0
        tappedWrong = tapped
        feedback = .wrong(correctAnswer: problem.answer)
        if grade.usesHearts {
            lives -= 1
            if lives <= 0 {
                scheduleAdvance(delay: 1.8) { finishRound() }
                return
            }
        }
        scheduleAdvance(delay: 1.6) {
            index += 1
            nextQuestion()
        }
    }

    private func scheduleAdvance(delay: Double, _ action: @escaping () -> Void) {
        guard !advancing else { return }
        advancing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            advancing = false
            guard phase == .playing else { return }
            action()
        }
    }

    private func finishRound() {
        var r = result
        r.elapsed = Date().timeIntervalSince(startDate)
        result = r
        ArithmeticProgressStore.record(grade: grade.rawValue,
                                       stars: r.stars,
                                       seconds: Int(r.elapsed.rounded()))
        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .result
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            appeared = true
        }
    }

    // MARK: 答题页

    private var quizContent: some View {
        VStack(spacing: 0) {
            // 透明导航条（左返回 + 右刷新）
            ZStack {
                HStack {
                    GracefulBackButton(action: onExit)
                    Spacer()
                    Button {
                        refreshProblem()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(red: 74/255, green: 92/255, blue: 66/255))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.8), in: Circle())
                            .overlay(
                                Circle().strokeBorder(Color.white.opacity(0.7), lineWidth: 1)
                            )
                            .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 3, y: 1)
                    }
                    .buttonStyle(.plain)
                }
                Text("\(grade.name) · 座舱")
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 14)

            // 状态行：进度 + 计时
            HStack(spacing: 10) {
                Text("第 \(index + 1)/\(roundLength) 题")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .fixedSize()
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.75))
                            .overlay(Capsule().strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 1.5))
                        Capsule()
                            .fill(LinearGradient(colors: [Color(red: 126/255, green: 211/255, blue: 160/255), grade.color],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(6, geo.size.width * CGFloat(index) / CGFloat(roundLength)))
                    }
                }
                .frame(height: 10)
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(remaining)s")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundStyle(grade.color)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(grade.light)
                        .overlay(Capsule().strokeBorder(grade.color.opacity(0.35), lineWidth: 2))
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            // 连击 + 机会
            HStack {
                if feedback == nil {
                    Text("🔥 连击 ×\(combo)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 232/255, green: 106/255, blue: 158/255))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color(red: 255/255, green: 227/255, blue: 239/255))
                                .overlay(Capsule().strokeBorder(Color(red: 232/255, green: 106/255, blue: 158/255).opacity(0.4), lineWidth: 2))
                        )
                }
                Spacer()
                if grade.usesHearts {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { i in
                            Text(i < lives ? "❤️" : "🤍")
                                .font(.system(size: 12))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .frame(height: 22)

            // 题卡
            VStack(spacing: 0) {
                Text("\(grade.name) · \(typeName)")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(grade.color))
                    .shadow(color: grade.color.opacity(0.35), radius: 5, y: 2)
                    .padding(.top, -16)

                if let problem = current {
                    ProblemExprView(text: problem.text, size: expressionSize, accent: grade.color)
                        .frame(minHeight: 84)
                        .padding(.top, 10)
                        .padding(.bottom, 6)

                    Text(problem.hint)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.bottom, 12)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35), lineWidth: 3)
                    )
                    .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.12), radius: 10, y: 5)
            )
            .padding(.horizontal, 22)
            .padding(.top, 24)

            // 作答区
            if grade.usesKeypad {
                keypadArea
                    .padding(.top, 14)
            } else {
                choiceArea
                    .padding(.top, 18)
            }

            Spacer(minLength: 0)
        }
        .overlay {
            // 居中弹出反馈（自动消失，无需点击）
            if let fb = feedback {
                FeedbackPopView(feedback: fb)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: feedback != nil)
    }

    private var expressionSize: CGFloat {
        switch grade {
        case .one, .two:   return 52
        case .three, .four: return 42
        default:           return 36
        }
    }

    private var typeName: String {
        guard let problem = current else { return "口算" }
        if problem.text.contains("×") && !problem.text.contains("÷") { return "乘法" }
        if problem.text.contains("÷") { return "除法" }
        if problem.text.contains("+") && problem.text.contains("/") { return "分数加法" }
        if problem.text.contains("%") { return "百分数" }
        if problem.text.contains(":") { return "比例" }
        if problem.text.contains("x") { return "方程" }
        if problem.text.contains("+") { return "加法" }
        if problem.text.contains("−") { return "减法" }
        return "口算"
    }

    // MARK: 四选一（1-2 年级）

    private var choiceArea: some View {
        let problem = current
        return Group {
            if let problem, let options = problem.options {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        choiceButton(option, problem: problem)
                    }
                }
                .padding(.horizontal, 22)
            }
        }
    }

    private func choiceButton(_ option: String, problem: ArithmeticProblem) -> some View {
        let isCorrect = feedback != nil && option == problem.answer
        let isTappedWrong = option == tappedWrong

        return Button {
            submit(option)
        } label: {
            Text(option)
                .font(.system(size: 26, weight: .heavy, design: .serif))
                .foregroundStyle(
                    isCorrect ? Color(red: 76/255, green: 175/255, blue: 125/255)
                        : isTappedWrong ? Color(red: 232/255, green: 100/255, blue: 82/255)
                        : Color(red: 61/255, green: 74/255, blue: 54/255)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            isCorrect ? Color(red: 223/255, green: 245/255, blue: 231/255)
                                : isTappedWrong ? Color(red: 255/255, green: 227/255, blue: 222/255)
                                : Color.white.opacity(0.92)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(
                                    isCorrect ? Color(red: 76/255, green: 175/255, blue: 125/255)
                                        : isTappedWrong ? Color(red: 232/255, green: 100/255, blue: 82/255)
                                        : Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.32),
                                    lineWidth: 3
                                )
                        )
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 5, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(feedback != nil)
    }

    // MARK: 数字键盘（3-6 年级）

    private var keypadArea: some View {
        VStack(spacing: 10) {
            // 输入框
            HStack(spacing: 0) {
                Text(input.isEmpty ? "输入答案" : input)
                    .font(.system(size: 28, weight: .heavy, design: .serif))
                    .foregroundStyle(input.isEmpty ? Color(red: 155/255, green: 123/255, blue: 216/255).opacity(0.4)
                        : Color(red: 155/255, green: 123/255, blue: 216/255))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                input.isEmpty
                                    ? Color(red: 155/255, green: 123/255, blue: 216/255).opacity(0.5)
                                    : Color(red: 155/255, green: 123/255, blue: 216/255),
                                style: StrokeStyle(lineWidth: 3, dash: input.isEmpty ? [7, 5] : [])
                            )
                    )
            )
            .padding(.horizontal, 22)

            // 键盘
            let keys: [[String]] = [
                ["1", "2", "3"],
                ["4", "5", "6"],
                ["7", "8", "9"],
                ["0", "/", "⌫"],
                [".", "−", "确定"]
            ]
            VStack(spacing: 8) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(row, id: \.self) { key in
                            keyButton(key)
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
        }
    }

    @ViewBuilder
    private func keyButton(_ key: String) -> some View {
        let isOK = key == "确定"
        Button {
            handleKey(key)
        } label: {
            Group {
                if isOK {
                    Text("确定")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                } else if key == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                } else {
                    Text(key)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isOK
                            ? AnyShapeStyle(LinearGradient(colors: [Color(red: 126/255, green: 211/255, blue: 160/255), Color(red: 76/255, green: 175/255, blue: 125/255)],
                                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color.white.opacity(0.92))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                isOK ? Color(red: 76/255, green: 175/255, blue: 125/255)
                                    : Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3),
                                lineWidth: 2.5
                            )
                    )
            )
            .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(feedback != nil)
    }

    private func handleKey(_ key: String) {
        guard feedback == nil else { return }
        switch key {
        case "确定":
            guard !input.isEmpty else { return }
            submit(input)
        case "⌫":
            if !input.isEmpty { input.removeLast() }
        case "−":
            if !input.contains("−") { input += key }
        case "/":
            if !input.contains("/") { input += key }
        case ".":
            if !input.contains(".") { input += key }
        default:
            if input.count < 6 { input += key }
        }
    }

    // MARK: 结算页

    private var resultView: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    GracefulBackButton(action: onExit)
                    Spacer()
                }
                Text("本局结算")
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 星星
                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { i in
                            Text("⭐")
                                .font(.system(size: 40))
                                .opacity(i < result.stars ? 1 : 0.25)
                                .grayscale(i < result.stars ? 0 : 1)
                                .scaleEffect(appeared ? 1 : 0.2)
                                .animation(
                                    .spring(response: 0.55, dampingFraction: 0.55).delay(0.15 + Double(i) * 0.12),
                                    value: appeared
                                )
                        }
                    }
                    .padding(.top, 18)

                    Text(starsHeadline)
                        .font(.system(size: 22, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                        .padding(.top, 10)

                    Text("座舱 \(grade.rawValue) · \(grade.name) · 答对 \(result.correct)/\(result.total) 题")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                        .padding(.top, 6)

                    // 数据卡
                    HStack(spacing: 10) {
                        resultStat(value: "\(Int(result.accuracy * 100))%", label: "正确率", color: Color(red: 76/255, green: 175/255, blue: 125/255))
                        resultStat(value: fmtElapsed(result.elapsed), label: "用时", color: Color(red: 61/255, green: 74/255, blue: 54/255))
                        resultStat(value: "×\(result.bestCombo)", label: "最高连击", color: Color(red: 232/255, green: 106/255, blue: 158/255))
                    }
                    .padding(.top, 16)

                    // 徽章
                    if result.bestCombo >= 5 {
                        HStack(spacing: 10) {
                            Text("🎖")
                                .font(.system(size: 26))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("新徽章 · 神算手指")
                                    .font(.system(size: 12, weight: .heavy, design: .serif))
                                    .foregroundStyle(Color(red: 181/255, green: 118/255, blue: 10/255))
                                Text("单局连击达到 5 次即可获得")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                            }
                            Spacer()
                            Text("NEW")
                                .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color(red: 245/255, green: 166/255, blue: 35/255)))
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color(red: 245/255, green: 166/255, blue: 35/255).opacity(0.5), lineWidth: 2.5)
                                )
                        )
                        .padding(.top, 14)
                    }

                    // 错题回看
                    if !result.mistakes.isEmpty {
                        VStack(spacing: 0) {
                            HStack {
                                Text("错题回看")
                                    .font(.system(size: 12, weight: .heavy, design: .serif))
                                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                                Spacer()
                                Text("\(result.mistakes.count) 题")
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color(red: 232/255, green: 100/255, blue: 82/255))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(red: 255/255, green: 227/255, blue: 222/255)))
                            }
                            .padding(.bottom, 4)

                            ForEach(result.mistakes.prefix(3)) { mistake in
                                HStack(spacing: 8) {
                                    Text("✕")
                                        .font(.system(size: 10, weight: .heavy))
                                        .foregroundStyle(.white)
                                        .frame(width: 18, height: 18)
                                        .background(Circle().fill(Color(red: 232/255, green: 100/255, blue: 82/255)))
                                    Text(mistake.text)
                                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                    if mistake.my != "超时" {
                                        Text(mistake.my)
                                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                                            .foregroundStyle(Color(red: 232/255, green: 100/255, blue: 82/255))
                                            .strikethrough()
                                    } else {
                                        Text("超时")
                                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                                            .foregroundStyle(Color(red: 232/255, green: 100/255, blue: 82/255))
                                    }
                                    Text("✓ \(mistake.correct)")
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                                    Spacer(minLength: 0)
                                    Text(mistake.hint)
                                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                }
                                .padding(.vertical, 7)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2.5)
                                )
                        )
                        .padding(.top, 14)
                    }

                    // 按钮
                    VStack(spacing: 10) {
                        Button {
                            startRound()
                        } label: {
                            Text("🎡 再来一局")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(
                                    LinearGradient(colors: [Color(red: 126/255, green: 211/255, blue: 160/255), Color(red: 76/255, green: 175/255, blue: 125/255)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                )
                                .shadow(color: Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.4), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: 10) {
                            Button {
                                onBack()
                            } label: {
                                Text("换座舱")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        Color.white.opacity(0.92),
                                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.32), lineWidth: 2.5)
                                    )
                            }
                            .buttonStyle(.plain)

                            Button {
                                onExit()
                            } label: {
                                Text("回到益智")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        Color.white.opacity(0.92),
                                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.32), lineWidth: 2.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 18)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 24)
            }
        }
    }

    private var starsHeadline: String {
        switch result.stars {
        case 3: return "太棒了！3 星通关"
        case 2: return "做得真棒！2 星"
        case 1: return "继续加油！1 星"
        default: return "再练一练，争取拿星"
        }
    }

    private func resultStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 19, weight: .heavy, design: .serif))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2.5)
                )
        )
    }

    private func fmtElapsed(_ s: TimeInterval) -> String {
        let total = Int(s.rounded())
        let m = total / 60
        let r = total % 60
        return m > 0 ? "\(m):\(r < 10 ? "0\(r)" : "\(r)")" : "0:\(r < 10 ? "0\(r)" : "\(r)")"
    }
}

// MARK: - 表达式渲染（分数堆叠 / 未知数框）

private struct ProblemExprView: View {
    let text: String
    let size: CGFloat
    let accent: Color

    var body: some View {
        let tokens = text.split(separator: " ").map(String.init)
        HStack(spacing: size * 0.18) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                tokenView(token)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.55)
    }

    @ViewBuilder
    private func tokenView(_ token: String) -> some View {
        if token == "?" {
            Text(token)
                .font(.system(size: size, weight: .heavy, design: .serif))
                .foregroundStyle(accent)
        } else if token == "___" {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                    .strokeBorder(accent, style: StrokeStyle(lineWidth: 3, dash: [size * 0.18, size * 0.12]))
                    .frame(width: size * 1.1, height: size * 0.95)
                Text("?")
                    .font(.system(size: size * 0.62, weight: .heavy, design: .serif))
                    .foregroundStyle(accent)
            }
        } else if let (num, den) = fractionToken(token) {
            VStack(spacing: 2) {
                Text(num)
                Rectangle()
                    .fill(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .frame(height: 2.5)
                Text(den)
            }
            .font(.system(size: size * 0.55, weight: .heavy, design: .serif))
            .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
        } else {
            Text(token)
                .font(.system(size: size, weight: .heavy, design: .serif))
                .foregroundStyle(token == "□" ? accent : Color(red: 61/255, green: 74/255, blue: 54/255))
        }
    }

    private func fractionToken(_ token: String) -> (String, String)? {
        let parts = token.split(separator: "/").map(String.init)
        guard parts.count == 2,
              let _ = Int(parts[0]), let _ = Int(parts[1]) else { return nil }
        return (parts[0], parts[1])
    }
}

// MARK: - 居中反馈弹窗（花哨醒目 · 自动消失）

private struct FeedbackPopView: View {
    let feedback: QuizFeedback

    private var isCorrect: Bool {
        if case .correct = feedback { return true }
        return false
    }

    private var good: Color { Color(red: 76/255, green: 175/255, blue: 125/255) }
    private var bad: Color { Color(red: 232/255, green: 100/255, blue: 82/255) }
    private var main: Color { isCorrect ? good : bad }

    var body: some View {
        VStack(spacing: 12) {
            // 图标（弹跳入场）
            ZStack {
                Circle()
                    .fill(main.opacity(0.22))
                    .frame(width: 92, height: 92)
                    .modifier(PulseRing())
                Circle()
                    .fill(.white)
                    .frame(width: 66, height: 66)
                    .shadow(color: main.opacity(0.5), radius: 12, y: 4)
                Image(systemName: isCorrect ? "checkmark" : "xmark")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(main)
            }
            .modifier(PopBounce())

            VStack(spacing: 5) {
                Text(isCorrect ? "答对了，真棒！" : "答错了，再练练")
                    .font(.system(size: 19, weight: .heavy, design: .serif))
                    .foregroundStyle(.white)
                if isCorrect {
                    Text("🔥 连击 +1")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                } else if case .wrong(let answer) = feedback {
                    Text("正确答案：\(answer)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 34)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isCorrect
                            ? [Color(red: 126/255, green: 211/255, blue: 160/255), good]
                            : [Color(red: 244/255, green: 141/255, blue: 120/255), bad],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(.white.opacity(0.55), lineWidth: 2.5)
                )
                .shadow(color: main.opacity(0.5), radius: 20, y: 10)
        )
        .padding(.bottom, 60)
    }
}

/// 弹跳入场
private struct PopBounce: ViewModifier {
    @State private var scale: CGFloat = 0.4

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.5)) {
                    scale = 1
                }
            }
    }
}

/// 光圈脉冲
private struct PulseRing: ViewModifier {
    @State private var pulse = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pulse ? 1.25 : 1)
            .opacity(pulse ? 0 : 0.9)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7).repeatCount(2, autoreverses: false)) {
                    pulse = true
                }
            }
    }
}

#Preview {
    ArithmeticHomeView(onExit: {})
}
