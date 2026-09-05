import XCTest
@testable import 火柴游戏

final class PatternBankTests: XCTestCase {

    func testBankCounts() {
        let all = PatternBankGenerator.generate()
        XCTAssertEqual(all.count, 500, "内置题库应为 500 关")
        XCTAssertEqual(all.filter { $0.mode == .kanTu }.count, 200, "看图应 200 关")
        XCTAssertEqual(all.filter { $0.mode == .shuZi }.count, 300, "数字应 300 关")
    }

    func testLevelsAreContinuous() {
        let all = PatternBankGenerator.generate()
        for mode in PatternMode.allCases {
            let levels = all.filter { $0.mode == mode }.map(\.lv).sorted()
            XCTAssertEqual(levels, Array(1...levels.count), "\(mode) 关卡号应连续")
        }
    }

    func testValidatorReportsNoIssues() {
        let all = PatternBankGenerator.generate()
        let issues = PatternBankGenerator.debugValidate(all)
        XCTAssertTrue(issues.isEmpty, "题库校验应通过，发现：\n" + issues.joined(separator: "\n"))
    }

    func testOptionsAreValid() {
        let all = PatternBankGenerator.generate()
        for q in all {
            if q.options.isEmpty { continue }
            XCTAssertEqual(q.options.count, 4, "\(q.identity) 应 4 个选项")
            XCTAssertEqual(Set(q.options).count, q.options.count, "\(q.identity) 选项不互斥")
            for a in q.answer {
                XCTAssertTrue(q.options.contains(a), "\(q.identity) 答案 \(a) 不在选项中")
            }
        }
    }

    func testLowGradeNumbersUseKeyboard() {
        let all = PatternBankGenerator.generate()
        let low = all.filter { $0.mode == .shuZi && $0.lv <= 50 }
        XCTAssertFalse(low.isEmpty)
        for q in low {
            XCTAssertTrue(q.options.isEmpty, "低年级数字题 \(q.identity) 应保留键盘输入")
        }
    }

    func testRulesAreTagged() {
        let all = PatternBankGenerator.generate()
        for q in all {
            XCTAssertFalse(q.rule.isEmpty, "\(q.identity) 缺少规律标签")
        }
        let rules = Set(all.map(\.rule))
        let expectedCore = ["等差", "差链", "隔项", "循环", "平方", "斐波那契", "倍增", "乘加", "减半",
                            "拆数", "数位", "分组和", "蝴蝶数", "幻方", "宫格",
                            "数量增减", "旋转", "双规则", "组合", "镜像", "轮转", "交替", "成对"]
        for r in expectedCore {
            XCTAssertTrue(rules.contains(r), "题库应覆盖规律类型「\(r)」，实际：\(rules.sorted())")
        }
    }

    func testNewProblemTypesRepresented() {
        let all = PatternBankGenerator.generate()
        let rules = all.map(\.rule)
        XCTAssertTrue(rules.contains("拆数"))
        XCTAssertTrue(rules.contains("数位"))
        XCTAssertTrue(rules.contains("分组和"))
        XCTAssertTrue(rules.contains("蝴蝶数"))
        XCTAssertTrue(rules.contains("幻方"))
        XCTAssertTrue(rules.contains("乘加"))
        XCTAssertTrue(rules.contains("减半"))
        XCTAssertTrue(rules.contains("数量增减"))
        XCTAssertTrue(rules.contains("旋转"))
        XCTAssertTrue(rules.contains("组合"))
        XCTAssertTrue(rules.contains("双规则"))
    }

    func testFigEncodingParses() {
        XCTAssertEqual(FigParser.parts("11:3").map(\.count), [3])
        XCTAssertEqual(FigParser.parts("17:r90").first?.rotation, 90)
        XCTAssertEqual(FigParser.parts("3:s2").first?.scale, 2)
        XCTAssertEqual(FigParser.ids("11:2+12:1"), ["11", "12"])
        XCTAssertEqual(FigParser.parts("11:2+12:1").map(\.count), [2, 1])
    }

    func testGeneratorIsDeterministic() {
        let a = PatternBankGenerator.generate()
        let b = PatternBankGenerator.generate()
        XCTAssertEqual(a, b, "同一关应永远生成同一题")
    }

    func testDoubleBlankRatio() {
        let all = PatternBankGenerator.generate()
        let high = all.filter { $0.mode == .shuZi && $0.lv > 100 }
        let double = high.filter { $0.blankCount == 2 }
        XCTAssertFalse(double.isEmpty, "高年级应有双空题")
        XCTAssertGreaterThanOrEqual(Double(double.count), Double(high.count) * 0.28, "高年级双空题占比应接近 30%，实际 \(double.count)/\(high.count)")
    }
}
