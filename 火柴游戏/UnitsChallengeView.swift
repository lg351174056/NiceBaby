import SwiftUI
import Combine

// MARK: - 单位大闯关（探索 · 学问营地）

enum UnitCat: String, CaseIterable, Identifiable {
    case length, mass, time, money, capacity, area
    var id: String { rawValue }
    var name: String {
        switch self {
        case .length: return "长度"; case .mass: return "质量"; case .time: return "时间"
        case .money: return "钱币"; case .capacity: return "容量"; case .area: return "面积"
        }
    }
    var badge: String {
        switch self {
        case .length: return "📏"; case .mass: return "⚖️"; case .time: return "⏰"
        case .money: return "💰"; case .capacity: return "🥤"; case .area: return "🟦"
        }
    }
    var units: [String] {
        switch self {
        case .length: return ["毫米", "厘米", "米", "千米"]
        case .mass: return ["克", "千克", "吨"]
        case .time: return ["秒", "分", "时"]
        case .money: return ["分", "角", "元"]
        case .capacity: return ["毫升", "升"]
        case .area: return ["平方厘米", "平方米"]
        }
    }
    /// 换算表（基准值）
    var conv: [(String, Int)] {
        switch self {
        case .length: return [("毫米", 1), ("厘米", 10), ("米", 1000), ("千米", 1_000_000)]
        case .mass: return [("克", 1), ("千克", 1000), ("吨", 1_000_000)]
        case .time: return [("秒", 1), ("分", 60), ("时", 3600)]
        case .money: return [("分", 1), ("角", 10), ("元", 100)]
        case .capacity: return [("毫升", 1), ("升", 1000)]
        case .area: return [("平方厘米", 1), ("平方米", 10_000)]
        }
    }
    var convValue: (String) -> Int? {
        { u in self.conv.first(where: { $0.0 == u })?.1 }
    }
}

enum UnitTier: Int, CaseIterable, Identifiable {
    case qihang = 1, jinjie, tiaozhan, dashi
    var id: Int { rawValue }
    var name: String {
        switch self { case .qihang: return "启航"; case .jinjie: return "进阶"; case .tiaozhan: return "挑战"; case .dashi: return "大师" }
    }
}

enum UnitMode: String, CaseIterable, Identifiable {
    case choose, compare, judge, match, fill, sort, shop, rush, riddle
    var id: String { rawValue }
    var name: String {
        switch self {
        case .choose: return "情景快选"; case .compare: return "天平比大小"; case .judge: return "找茬小判官"
        case .match: return "单位连连看"; case .fill: return "单位填空"; case .sort: return "量感排序"
        case .shop: return "生活综合"; case .rush: return "抢答挑战"; case .riddle: return "猜猜乐"
        }
    }
    var icon: String {
        switch self {
        case .choose: return "🎯"; case .compare: return "⚖️"; case .judge: return "🔍"
        case .match: return "🔗"; case .fill: return "✏️"; case .sort: return "📶"
        case .shop: return "🛒"; case .rush: return "⚡"; case .riddle: return "🎁"
        }
    }
    var desc: String {
        switch self {
        case .choose: return "选最合适的单位"; case .compare: return "判断 ＞ ＜ ＝"; case .judge: return "判断对错"
        case .match: return "物品 ↔ 单位配对"; case .fill: return "句子填单位"; case .sort: return "从小到大排一排"
        case .shop: return "买东西算一算"; case .rush: return "亲子对战 · 限时"; case .riddle: return "猜猜是什么单位"
        }
    }
    var len: Int {
        switch self {
        case .match: return 3; case .sort, .shop: return 5; default: return 6
        }
    }
    var isBonus: Bool { self == .riddle }
}

// MARK: 题库

private struct UnitItem { let cat: UnitCat; let text: String; let unit: String; let exp: String; let lv: Int }
private struct JudgeItem { let text: String; let ok: Bool; let exp: String; let lv: Int }
private struct RiddleItem { let text: String; let unit: String; let exp: String; let lv: Int }
private struct ShopItem { let text: String; let cents: Int; let exp: String; let lv: Int }

private let kItems: [UnitItem] = [
    .init(cat: .length, text: "一支铅笔长 18 ___", unit: "厘米", exp: "铅笔大约 18 厘米长", lv: 1),
    .init(cat: .length, text: "课桌高约 70 ___", unit: "厘米", exp: "课桌约 70 厘米", lv: 1),
    .init(cat: .length, text: "教室的长约 8 ___", unit: "米", exp: "教室较长，用米", lv: 1),
    .init(cat: .length, text: "旗杆高约 10 ___", unit: "米", exp: "旗杆很高，用米", lv: 1),
    .init(cat: .length, text: "操场跑道一圈约 400 ___", unit: "米", exp: "跑道用米", lv: 1),
    .init(cat: .length, text: "数学书厚约 6 ___", unit: "毫米", exp: "很薄，用毫米", lv: 3),
    .init(cat: .length, text: "一枚硬币厚约 2 ___", unit: "毫米", exp: "硬币很薄，约 2 毫米", lv: 3),
    .init(cat: .length, text: "从家到学校约 1 ___", unit: "千米", exp: "路程较远，用千米", lv: 4),
    .init(cat: .mass, text: "一个鸡蛋约 50 ___", unit: "克", exp: "鸡蛋约 50 克", lv: 2),
    .init(cat: .mass, text: "一袋盐重 500 ___", unit: "克", exp: "一袋盐 500 克", lv: 2),
    .init(cat: .mass, text: "一袋大米重 25 ___", unit: "千克", exp: "大米较重，用千克", lv: 2),
    .init(cat: .mass, text: "爸爸体重约 70 ___", unit: "千克", exp: "体重用千克", lv: 2),
    .init(cat: .mass, text: "一头大象约重 5 ___", unit: "吨", exp: "大象很重，用吨", lv: 3),
    .init(cat: .time, text: "一节课 40 ___", unit: "分", exp: "一节课约 40 分钟", lv: 1),
    .init(cat: .time, text: "跑 50 米约 10 ___", unit: "秒", exp: "很短，用秒", lv: 1),
    .init(cat: .time, text: "睡觉大约 8 ___", unit: "时", exp: "睡眠用小时", lv: 1),
    .init(cat: .time, text: "眨一下眼约 1 ___", unit: "秒", exp: "眨眼很快，1 秒", lv: 1),
    .init(cat: .time, text: "吃一顿饭约 20 ___", unit: "分", exp: "吃饭用分钟", lv: 1),
    .init(cat: .money, text: "一支铅笔大约 2 ___", unit: "元", exp: "铅笔约 2 元", lv: 1),
    .init(cat: .money, text: "一块橡皮约 5 ___", unit: "角", exp: "橡皮约 5 角", lv: 1),
    .init(cat: .money, text: "一本书大约 20 ___", unit: "元", exp: "书约 20 元", lv: 1),
    .init(cat: .capacity, text: "一瓶矿泉水 500 ___", unit: "毫升", exp: "矿泉水 500 毫升", lv: 2),
    .init(cat: .capacity, text: "一杯水约 300 ___", unit: "毫升", exp: "水杯约 300 毫升", lv: 2),
    .init(cat: .capacity, text: "一壶水约 2 ___", unit: "升", exp: "水壶较大，用升", lv: 2),
    .init(cat: .capacity, text: "浴缸水约 200 ___", unit: "升", exp: "浴缸水很多，用升", lv: 3),
    .init(cat: .area, text: "指甲盖约 1 ___", unit: "平方厘米", exp: "指甲盖约 1 平方厘米", lv: 3),
    .init(cat: .area, text: "一块橡皮约 6 ___", unit: "平方厘米", exp: "橡皮面约 6 平方厘米", lv: 3),
    .init(cat: .area, text: "数学书封面约 300 ___", unit: "平方厘米", exp: "书封面约 300 平方厘米", lv: 3),
    .init(cat: .area, text: "教室地面约 50 ___", unit: "平方米", exp: "房间大，用平方米", lv: 3),
    .init(cat: .area, text: "你家客厅约 30 ___", unit: "平方米", exp: "客厅用平方米", lv: 3),
]

private let kJudge: [JudgeItem] = [
    .init(text: "一支铅笔长 20 米。", ok: false, exp: "太长了，应该是 20 厘米", lv: 1),
    .init(text: "课桌高约 70 厘米。", ok: true, exp: "正确，约 70 厘米", lv: 1),
    .init(text: "一袋盐重 500 千克。", ok: false, exp: "应是 500 克，千克太重了", lv: 2),
    .init(text: "洗脸水大约 2 升。", ok: true, exp: "正确，约 2 升", lv: 2),
    .init(text: "小明跑 50 米用了 10 分。", ok: false, exp: "应是 10 秒，10 分太久了", lv: 1),
    .init(text: "一瓶矿泉水 500 升。", ok: false, exp: "应是 500 毫升，升太多了", lv: 2),
    .init(text: "教室地面约 50 平方米。", ok: true, exp: "正确，教室约 50 平方米", lv: 3),
    .init(text: "一头大象重 5 千克。", ok: false, exp: "应是 5 吨（5000 千克）", lv: 3),
    .init(text: "妈妈买了 2 千克苹果。", ok: true, exp: "正确，2 千克很合理", lv: 2),
    .init(text: "一节课 40 秒。", ok: false, exp: "应是 40 分，40 秒太短", lv: 1),
    .init(text: "一块橡皮约 6 平方厘米。", ok: true, exp: "正确，橡皮面约 6 平方厘米", lv: 3),
]

private let kRiddle: [RiddleItem] = [
    .init(text: "计量液体多少，一瓶矿泉水 500 个它", unit: "毫升", exp: "毫升", lv: 2),
    .init(text: "计量房间大小，教室 50 个它", unit: "平方米", exp: "平方米", lv: 3),
    .init(text: "量很轻的东西，一个鸡蛋 50 个它", unit: "克", exp: "克", lv: 2),
    .init(text: "量比较重的东西，一袋大米 25 个它", unit: "千克", exp: "千克", lv: 2),
    .init(text: "量较短的长度，一支铅笔 18 个它", unit: "厘米", exp: "厘米", lv: 1),
    .init(text: "量时间，一节课 40 个它", unit: "分", exp: "分", lv: 1),
    .init(text: "量钱，一本书 20 个它", unit: "元", exp: "元", lv: 1),
    .init(text: "量较长的距离，跑道一圈 400 个它", unit: "米", exp: "米", lv: 1),
]

private let kShop: [ShopItem] = [
    .init(text: "苹果每 500 克 3 元 5 角，买 1 千克要多少钱？", cents: 70, exp: "1 千克 = 2 个 500 克，3元5角×2 = 7 元", lv: 3),
    .init(text: "香蕉每 500 克 2 元，买 2 千克要多少钱？", cents: 80, exp: "2 千克 = 4 个 500 克，2×4 = 8 元", lv: 3),
    .init(text: "大米每 1 千克 5 元，买 3 千克要多少钱？", cents: 150, exp: "5×3 = 15 元", lv: 3),
    .init(text: "饼干每 100 克 2 元，买 300 克要多少钱？", cents: 60, exp: "2×3 = 6 元", lv: 3),
]

private let kMatchPairs: [(String, String)] = [
    ("水杯", "毫升"), ("课本", "平方厘米"), ("卧室", "平方米"), ("鸡蛋", "克"),
    ("一节课", "分"), ("直尺", "厘米"), ("一袋大米", "千克"), ("一瓶矿泉水", "毫升"),
]

// MARK: 存储

struct UnitWrongItem: Codable, Identifiable {
    var id = UUID()
    let q: String
    let ans: String
    let exp: String
}

enum UnitsStore {
    private static func bk(_ m: String) -> String { "units.best.\(m)" }
    static func best(_ m: String) -> Int { UserDefaults.standard.integer(forKey: bk(m)) }
    @discardableResult static func updateBest(_ m: String, _ s: Int) -> Bool {
        let o = best(m); if s <= o { return false }
        UserDefaults.standard.set(s, forKey: bk(m)); return true
    }
    private static func ck(_ c: String) -> String { "units.badge.\(c)" }
    static func badgeCount(_ c: String) -> Int { UserDefaults.standard.integer(forKey: ck(c)) }
    static func addBadge(_ c: String) { UserDefaults.standard.set(badgeCount(c) + 1, forKey: ck(c)) }
    static func hasAllBadges() -> Bool { UnitCat.allCases.allSatisfy { badgeCount($0.rawValue) >= 5 } }

    private static let wrongKey = "units.wrong.v1"
    static func wrongs() -> [UnitWrongItem] {
        guard let d = UserDefaults.standard.data(forKey: wrongKey),
              let a = try? JSONDecoder().decode([UnitWrongItem].self, from: d) else { return [] }
        return a
    }
    static func addWrong(_ w: UnitWrongItem) {
        var a = wrongs(); a.insert(w, at: 0)
        if let d = try? JSONEncoder().encode(Array(a.prefix(50))) { UserDefaults.standard.set(d, forKey: wrongKey) }
    }
}

// MARK: 题目

private struct SortItem: Hashable { let text: String; let base: Int }
private struct MatchPair: Hashable { let left: String; let right: String }

private struct UnitQuestion {
    var kind: UnitMode
    var prompt = ""
    var options: [String] = []
    var answer = ""
    var exp = ""
    var cat: UnitCat? = nil
    var sortItems: [SortItem] = []
    var matchPairs: [MatchPair] = []
}

struct UnitsChallengeView: View {
    @State private var tier: UnitTier = .qihang
    @State private var phase: Phase = .home
    @State private var mode: UnitMode? = nil

    @State private var list: [UnitQuestion] = []
    @State private var qi = 0
    @State private var correct = 0
    @State private var wrongN = 0
    @State private var answered = false
    @State private var picked = ""
    @State private var fbText = ""
    @State private var fbOK = false
    @State private var nextVisible = false
    @State private var startDate = Date()
    @State private var elapsed = 0

    @State private var showHelp = false
    @State private var showResult = false
    @State private var showWrong = false
    @State private var showCert = false

    // sort
    @State private var sortPicked: [Int] = []
    // match
    @State private var matchLeftSel: Int? = nil
    @State private var matchDone: Set<Int> = []
    @State private var matchBad: Int? = nil
    @State private var matchRightOrder: [Int] = []
    // rush
    @State private var rushScores = [0, 0]
    @State private var rushCur = 0
    @State private var rushBar: CGFloat = 1
    @State private var rushTask: Task<Void, Never>? = nil

    @Namespace private var diffNS
    private let accent = Color(red: 0.18, green: 0.62, blue: 0.56)
    private let accentSoft = Color(red: 0.89, green: 0.96, blue: 0.94)
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private enum Phase { case home, play, wrong, cert }

    var body: some View {
        ZStack {
            FieldBackground()
            decorations
            VStack(spacing: 0) {
                navBar
                segBar
                Group {
                    switch phase {
                    case .home: homeView
                    case .play: playView
                    case .wrong: wrongView
                    case .cert: certView
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if showResult { resultOverlay }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .sheet(isPresented: $showHelp) { helpSheet }
        .onReceive(ticker) { _ in if phase == .play { elapsed = max(0, Int(Date().timeIntervalSince(startDate))) } }
        .onDisappear { rushTask?.cancel() }
    }

    // MARK: 顶栏

    private var navBar: some View {
        HStack(spacing: 8) {
            GracefulBackButton()
            VStack(alignment: .leading, spacing: 0) {
                Text("单位大闯关").font(.system(size: 16, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                Text("二年级 · 量感 · 单位").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
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
                Text("\(mode.map { UnitsStore.best($0.rawValue) } ?? 0)").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldInk)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Capsule().fill(Color.white.opacity(0.9)).overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 1.5)))
    }

    private var helpButton: some View {
        Button { showHelp = true } label: {
            Text("?").font(.system(size: 15, weight: .black)).foregroundStyle(accent)
                .frame(width: 34, height: 34).background(Circle().fill(accentSoft))
                .overlay(Circle().strokeBorder(accent.opacity(0.35), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private var segBar: some View {
        HStack(spacing: 4) {
            ForEach(UnitTier.allCases) { t in
                let on = t == tier
                Button { tier = t } label: {
                    Text(t.name).font(.system(size: 13.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(on ? .white : AppTheme.fieldOliveDeep)
                        .frame(maxWidth: .infinity).frame(height: 38)
                        .background {
                            if on {
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(LinearGradient(colors: [accent, accent.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .shadow(color: accent.opacity(0.35), radius: 6, y: 3)
                                    .matchedGeometryEffect(id: "unitsPill", in: diffNS)
                            }
                        }
                }.buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(Color.white.opacity(0.55))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder(AppTheme.fieldOlive.opacity(0.18), lineWidth: 1.5)))
        .padding(.horizontal, 16).padding(.top, 8)
    }

    // MARK: 首页

    private var homeView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                badgeWall
                Text("选个玩法").font(.system(size: 14, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                    .padding(.top, 16).padding(.bottom, 10)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 11), GridItem(.flexible(), spacing: 11)], spacing: 11) {
                    ForEach(UnitMode.allCases) { m in modeCard(m) }
                }
                HStack(spacing: 11) {
                    toolButton("错题本", "exclamationmark.bubble.fill", Color(red: 0.86, green: 0.42, blue: 0.32)) { showWrong = true }
                    toolButton("单位大师证书", "rosette", AppTheme.fieldGold) { showCert = true }
                        .opacity(UnitsStore.hasAllBadges() ? 1 : 0.5)
                        .disabled(!UnitsStore.hasAllBadges())
                }
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 16)
        }
    }

    private var badgeWall: some View {
        HStack(spacing: 8) {
            ForEach(UnitCat.allCases) { c in
                let on = UnitsStore.badgeCount(c.rawValue) >= 5
                VStack(spacing: 4) {
                    Text(c.badge).font(.system(size: 22)).grayscale(on ? 0 : 1).opacity(on ? 1 : 0.35)
                    Text(c.name).font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(on ? accent : AppTheme.fieldMoss)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(on ? Color.white : Color.white.opacity(0.6))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(on ? accent : AppTheme.fieldOlive.opacity(0.18), lineWidth: 2)))
            }
        }
        .padding(.top, 14)
    }

    private func modeCard(_ m: UnitMode) -> some View {
        Button { start(m) } label: {
            HStack(spacing: 11) {
                Text(m.icon).font(.system(size: 22)).frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(m.isBonus ? Color(red: 0.98, green: 0.95, blue: 0.86) : accentSoft))
                VStack(alignment: .leading, spacing: 2) {
                    Text(m.name).font(.system(size: 14.5, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                    Text(m.desc).font(.system(size: 10.5, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(13)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(m.isBonus ? AppTheme.fieldGold.opacity(0.6) : AppTheme.fieldOlive.opacity(0.22), lineWidth: 2)))
        }
        .buttonStyle(.plain)
    }

    private func toolButton(_ title: String, _ icon: String, _ c: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .bold))
                Text(title).font(.system(size: 14, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 50)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LinearGradient(colors: [c, c.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing)))
        }
        .buttonStyle(.plain)
    }

    // MARK: 游戏

    private var playView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                chip(mode?.name ?? "—")
                chip("第 \(min(qi + 1, mode?.len ?? 1))/\(mode?.len ?? 1) 题")
                chip("得分 \(correct * 100)")
            }
            .padding(.top, 12)
            stageView
            footView
        }
    }

    private func chip(_ t: String) -> some View {
        Text(t).font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldOliveDeep)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.9)).overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.2), lineWidth: 1.5)))
    }

    private var stageView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                Spacer(minLength: 0)
                if let q = current {
                    askCard(q)
                    content(q)
                    answerArea(q)
                }
                Spacer(minLength: 0)
            }
            .frame(minHeight: UIScreen.main.bounds.height - 300)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var current: UnitQuestion? { list.indices.contains(qi) ? list[qi] : nil }

    private func askCard(_ q: UnitQuestion) -> some View {
        Text(q.prompt).font(.system(size: 16, weight: .heavy, design: .serif))
            .foregroundStyle(AppTheme.fieldInk).multilineTextAlignment(.center).lineSpacing(4)
            .padding(.horizontal, 16).padding(.vertical, 13).frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(AppTheme.fieldOlive.opacity(0.22), lineWidth: 2)))
    }

    @ViewBuilder
    private func content(_ q: UnitQuestion) -> some View {
        switch q.kind {
        case .sort: sortContent(q)
        case .match: matchContent(q)
        default: EmptyView()
        }
    }

    @ViewBuilder
    private func answerArea(_ q: UnitQuestion) -> some View {
        switch q.kind {
        case .sort: EmptyView()
        case .match: EmptyView()
        case .rush: rushArea(q)
        default:
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(q.options, id: \.self) { opt in optionButton(q, opt) }
            }
        }
    }

    private func optionButton(_ q: UnitQuestion, _ opt: String) -> some View {
        let isRight = answered && opt == q.answer
        let isWrong = answered && picked == opt && opt != q.answer
        return Button { choose(q, opt) } label: {
            Text(opt).font(.system(size: 19, weight: .heavy, design: .serif))
                .foregroundStyle(isRight || isWrong ? .white : AppTheme.fieldInk)
                .frame(maxWidth: .infinity).frame(minHeight: 56)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isRight ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.49, green: 0.83, blue: 0.63), Color(red: 0.30, green: 0.69, blue: 0.49)], startPoint: .topLeading, endPoint: .bottomTrailing))
                          : isWrong ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.93, green: 0.54, blue: 0.45), Color(red: 0.80, green: 0.30, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(Color.white.opacity(0.92)))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder((isRight || isWrong) ? Color.clear : AppTheme.fieldOlive.opacity(0.28), lineWidth: 2)))
        }
        .buttonStyle(.plain).disabled(answered)
    }

    // MARK: 排序

    private func sortContent(_ q: UnitQuestion) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(Array(q.sortItems.enumerated()), id: \.offset) { i, it in
                    let pickOrder = sortPicked.firstIndex(of: i)
                    let done = answered
                    Button { sortPick(i, q) } label: {
                        VStack(spacing: 2) {
                            Text(it.text).font(.system(size: 17, weight: .heavy, design: .serif))
                            if let o = pickOrder { Text("第 \(o + 1)").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(accent) }
                        }
                        .foregroundStyle(done ? .white : AppTheme.fieldInk)
                        .frame(maxWidth: .infinity).frame(height: 66)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(done ? AnyShapeStyle(accent) : (pickOrder != nil ? AnyShapeStyle(accentSoft) : AnyShapeStyle(Color.white.opacity(0.92))))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(pickOrder != nil ? accent : AppTheme.fieldOlive.opacity(0.28), lineWidth: 2)))
                    }
                    .buttonStyle(.plain).disabled(answered || pickOrder != nil)
                }
            }
        }
    }

    // MARK: 连连看

    private func matchContent(_ q: UnitQuestion) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 10) {
                ForEach(Array(q.matchPairs.enumerated()), id: \.offset) { i, p in
                    matchCard(p.left, i, isLeft: true)
                }
            }
            VStack(spacing: 10) {
                ForEach(matchRightOrder, id: \.self) { i in
                    matchCard(q.matchPairs[i].right, i, isLeft: false)
                }
            }
        }
    }

    private func matchCard(_ text: String, _ i: Int, isLeft: Bool) -> some View {
        let done = matchDone.contains(i)
        let sel = isLeft && matchLeftSel == i
        let bad = matchBad == i
        return Button {
            matchTap(i, isLeft: isLeft)
        } label: {
            Text(text).font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(done ? .white : AppTheme.fieldInk)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(done ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.49, green: 0.83, blue: 0.63), Color(red: 0.30, green: 0.69, blue: 0.49)], startPoint: .topLeading, endPoint: .bottomTrailing))
                          : bad ? AnyShapeStyle(Color(red: 0.99, green: 0.91, blue: 0.88))
                          : sel ? AnyShapeStyle(accentSoft) : AnyShapeStyle(Color.white.opacity(0.92)))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(bad ? Color(red: 0.80, green: 0.30, blue: 0.22) : (sel || done ? accent : AppTheme.fieldOlive.opacity(0.28)), lineWidth: 2)))
        }
        .buttonStyle(.plain).disabled(done)
    }

    // MARK: 抢答

    private func rushArea(_ q: UnitQuestion) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                rushPlayer(0)
                rushPlayer(1)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.fieldOlive.opacity(0.16))
                    Capsule().fill(LinearGradient(colors: [Color(red: 0.49, green: 0.83, blue: 0.63), accent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, geo.size.width * rushBar))
                }
            }
            .frame(height: 8)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(q.options, id: \.self) { opt in rushOption(q, opt) }
            }
        }
    }

    private func rushPlayer(_ i: Int) -> some View {
        VStack(spacing: 2) {
            Text(i == 0 ? "🔵 玩家一" : "🔴 玩家二").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldOliveDeep)
            Text("\(rushScores[i])").font(.system(size: 20, weight: .black, design: .serif)).foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(rushCur == i ? Color.white : Color.white.opacity(0.6))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(rushCur == i ? accent : AppTheme.fieldOlive.opacity(0.2), lineWidth: 2)))
    }

    private func rushOption(_ q: UnitQuestion, _ opt: String) -> some View {
        let isRight = answered && opt == q.answer
        let isWrong = answered && picked == opt && opt != q.answer
        return Button { rushAnswer(q, opt) } label: {
            Text(opt).font(.system(size: 19, weight: .heavy, design: .serif))
                .foregroundStyle(isRight || isWrong ? .white : AppTheme.fieldInk)
                .frame(maxWidth: .infinity).frame(minHeight: 56)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isRight ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.49, green: 0.83, blue: 0.63), Color(red: 0.30, green: 0.69, blue: 0.49)], startPoint: .topLeading, endPoint: .bottomTrailing))
                          : isWrong ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.93, green: 0.54, blue: 0.45), Color(red: 0.80, green: 0.30, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(Color.white.opacity(0.92)))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder((isRight || isWrong) ? Color.clear : AppTheme.fieldOlive.opacity(0.28), lineWidth: 2)))
        }
        .buttonStyle(.plain).disabled(answered)
    }

    private var footView: some View {
        VStack(spacing: 10) {
            if !fbText.isEmpty {
                Text(fbText).font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(fbOK ? Color(red: 0.18, green: 0.56, blue: 0.32) : Color(red: 0.78, green: 0.25, blue: 0.17))
                    .multilineTextAlignment(.center)
            }
            if nextVisible {
                Button { next() } label: {
                    Text(qi >= (mode?.len ?? 1) - 1 ? "看看成绩" : "下一题")
                        .font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                        .frame(width: 200, height: 48)
                        .background(Capsule().fill(LinearGradient(colors: [Color(red: 0.49, green: 0.83, blue: 0.63), Color(red: 0.30, green: 0.69, blue: 0.49)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                        .shadow(color: Color(red: 0.30, green: 0.69, blue: 0.49).opacity(0.35), radius: 8, y: 4)
                }.buttonStyle(.plain)
            }
        }
        .frame(height: 72).padding(.horizontal, 20)
    }

    // MARK: 错题本 / 证书

    private var wrongView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                let ws = UnitsStore.wrongs()
                if ws.isEmpty {
                    Text("暂无错题，真棒！").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss).padding(.vertical, 24)
                } else {
                    ForEach(ws) { w in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(w.q).font(.system(size: 14, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                            Text("答案：\(w.ans)").font(.system(size: 12.5, weight: .heavy, design: .rounded)).foregroundStyle(accent)
                            if !w.exp.isEmpty { Text(w.exp).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.9))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(AppTheme.fieldOlive.opacity(0.2), lineWidth: 2)))
                    }
                }
                Button { phase = .home } label: {
                    Text("返回").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldInk)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Capsule().fill(Color.white.opacity(0.92)).overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)))
                }.buttonStyle(.plain).padding(.top, 8)
            }
            .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 30)
        }
    }

    private var certView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                VStack(spacing: 8) {
                    Text("CERTIFICATE OF UNITS").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(3).foregroundStyle(AppTheme.fieldMoss)
                    Text("单位大师证书").font(.system(size: 26, weight: .black, design: .serif)).foregroundStyle(AppTheme.fieldGold)
                    Text("恭喜你集齐\n长度 · 质量 · 时间 · 钱币 · 容量 · 面积\n六枚徽章，成为「单位大师」！")
                        .font(.system(size: 15, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                        .multilineTextAlignment(.center).lineSpacing(6).padding(.vertical, 10)
                    Text("单位大闯关 · 谨授").font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(AppTheme.fieldGold)
                }
                .padding(26).frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 1, green: 0.99, blue: 0.96), Color(red: 0.98, green: 0.95, blue: 0.87)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(AppTheme.fieldGold, lineWidth: 3)))
                Button { phase = .home } label: {
                    Text("返回").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Capsule().fill(accent))
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 30)
        }
    }

    // MARK: 结算

    private var resultOverlay: some View {
        let total = mode?.len ?? 1
        let acc = Int((Double(correct) / Double(total) * 100).rounded())
        let score = max(1, correct * 100 + max(0, 120 - elapsed) * 2)
        return ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 14) {
                if mode == .rush {
                    Text("抢答结果").font(.system(size: 20, weight: .black, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                    Text(rushScores[0] == rushScores[1] ? "平局！" : (rushScores[0] > rushScores[1] ? "🔵 玩家一获胜！" : "🔴 玩家二获胜！"))
                        .font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(accent)
                    HStack(spacing: 20) {
                        rstat("玩家一", "\(rushScores[0])", Color(red: 0.30, green: 0.55, blue: 0.85))
                        rstat("玩家二", "\(rushScores[1])", Color(red: 0.84, green: 0.34, blue: 0.34))
                    }
                } else {
                    ZStack {
                        Circle().stroke(AppTheme.fieldOlive.opacity(0.15), lineWidth: 12)
                        Circle().trim(from: 0, to: CGFloat(acc) / 100)
                            .stroke(LinearGradient(colors: [accent.opacity(0.75), accent], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)).rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Text("\(acc)%").font(.system(size: 28, weight: .black, design: .serif)).foregroundStyle(accent)
                            Text("正确率").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
                        }
                    }.frame(width: 128, height: 128)
                    Text(acc >= 90 ? "单位小达人！" : acc >= 75 ? "很棒！" : acc >= 60 ? "不错哦" : acc >= 40 ? "有点难吧" : "继续加油")
                        .font(.system(size: 20, weight: .black, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                    HStack(spacing: 10) {
                        rstat("答对", "\(correct)", Color(red: 0.18, green: 0.56, blue: 0.32))
                        rstat("答错", "\(wrongN)", Color(red: 0.78, green: 0.25, blue: 0.17))
                        rstat("用时", "\(elapsed)s", accent)
                    }
                    Text("得分 \(score)").font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
                }
                HStack(spacing: 12) {
                    Button { showResult = false; phase = .home } label: {
                        Text("换玩法").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldInk)
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .background(Capsule().fill(Color.white.opacity(0.92)).overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)))
                    }.buttonStyle(.plain)
                    Button { showResult = false; if let m = mode { start(m) } } label: {
                        Text("再来一局").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .background(Capsule().fill(LinearGradient(colors: [accent, accent.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    }.buttonStyle(.plain)
                }
            }
            .padding(24).frame(maxWidth: 360)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white))
        }
    }

    private func rstat(_ k: String, _ v: String, _ c: Color) -> some View {
        VStack(spacing: 3) {
            Text(v).font(.system(size: 19, weight: .black, design: .serif)).foregroundStyle(c)
            Text(k).font(.system(size: 10.5, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppTheme.fieldOlive.opacity(0.06)))
    }

    // MARK: 流程

    private func start(_ m: UnitMode) {
        mode = m
        qi = 0; correct = 0; wrongN = 0; answered = false; picked = ""; fbText = ""; fbOK = false; nextVisible = false
        sortPicked = []; matchLeftSel = nil; matchDone = []; matchBad = nil
        rushScores = [0, 0]; rushCur = 0; rushBar = 1
        startDate = Date(); elapsed = 0
        showResult = false
        list = buildList(m)
        if m == .match, let q = list.first { matchRightOrder = Array(0..<q.matchPairs.count).shuffled() }
        phase = .play
        if m == .rush { startRushTimer() }
    }

    private func next() {
        rushTask?.cancel()
        qi += 1
        if qi >= (mode?.len ?? 1) { finish(); return }
        answered = false; picked = ""; fbText = ""; fbOK = false; nextVisible = false
        sortPicked = []; matchLeftSel = nil; matchDone = []; matchBad = nil
        if mode == .match, let q = current { matchRightOrder = Array(0..<q.matchPairs.count).shuffled() }
        if mode == .rush { rushCur = 1 - rushCur; rushBar = 1; startRushTimer() }
    }

    private func finish() {
        let total = mode?.len ?? 1
        let score = max(1, correct * 100 + max(0, 120 - elapsed) * 2)
        if mode != .rush { UnitsStore.updateBest(mode!.rawValue, score) }
        _ = total
        showResult = true
    }

    private func markCorrect(_ cat: UnitCat?, exp: String) {
        correct += 1
        fbText = "✓ 答对了！"; fbOK = true
        if let c = cat { UnitsStore.addBadge(c.rawValue) }
        _ = exp
    }

    private func markWrong(_ q: String, _ ans: String, _ exp: String) {
        wrongN += 1
        fbText = "✗ 正确答案：\(ans)"; fbOK = false
        UnitsStore.addWrong(UnitWrongItem(q: q, ans: ans, exp: exp))
    }

    private func choose(_ q: UnitQuestion, _ opt: String) {
        guard !answered else { return }
        answered = true; picked = opt
        if opt == q.answer { markCorrect(q.cat, exp: q.exp) } else { markWrong(q.prompt, q.answer, q.exp) }
        nextVisible = true
    }

    private func sortPick(_ i: Int, _ q: UnitQuestion) {
        guard !answered, !sortPicked.contains(i) else { return }
        sortPicked.append(i)
        if sortPicked.count == 3 {
            answered = true
            let bases = sortPicked.map { q.sortItems[$0].base }
            let ok = bases[0] <= bases[1] && bases[1] <= bases[2]
            if ok { markCorrect(q.cat, exp: "") } else {
                markWrong("把 3 个量从小到大排序", q.sortItems.sorted { $0.base < $1.base }.map(\.text).joined(separator: " < "), "先化成同一单位再比")
            }
            nextVisible = true
        }
    }

    private func matchTap(_ i: Int, isLeft: Bool) {
        guard !answered, !matchDone.contains(i) else { return }
        if isLeft { matchLeftSel = i; return }
        guard let l = matchLeftSel else { return }
        if l == i {
            matchDone.insert(i); matchLeftSel = nil
            if matchDone.count == (current?.matchPairs.count ?? 0) {
                answered = true; correct += 1; fbText = "✓ 全部连对啦！"; fbOK = true; nextVisible = true
            }
        } else {
            matchBad = i
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { if matchBad == i { matchBad = nil } }
            matchLeftSel = nil
        }
    }

    private func rushAnswer(_ q: UnitQuestion, _ opt: String) {
        guard !answered else { return }
        answered = true; picked = opt; rushTask?.cancel()
        if opt == q.answer { rushScores[rushCur] += 1; markCorrect(q.cat, exp: q.exp) }
        else { markWrong(q.prompt, q.answer, q.exp) }
        nextVisible = true
    }

    private func startRushTimer() {
        rushTask?.cancel()
        rushBar = 1
        withAnimation(.linear(duration: 5)) { rushBar = 0 }
        rushTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                guard !answered else { return }
                answered = true; fbText = "⏰ 超时，对方抢分机会！"; fbOK = false
                nextVisible = true
            }
        }
    }

    // MARK: 出题

    private func pool<T>(_ arr: [T], _ lv: (T) -> Int) -> [T] {
        let p = arr.filter { lv($0) <= tier.rawValue }
        return p.isEmpty ? arr : p
    }

    private func unitOptions(_ cat: UnitCat, _ correct: String) -> [String] {
        var pool = cat.units.filter { $0 != correct }
        let others = ["米", "厘米", "克", "千克", "升", "毫升", "分", "秒", "元", "平方米"].filter { $0 != correct && !pool.contains($0) }
        var i = 0
        while pool.count < 3 && i < others.count { pool.append(others[i]); i += 1 }
        return ([correct] + pool.prefix(3)).shuffled()
    }

    private func buildList(_ m: UnitMode) -> [UnitQuestion] {
        (0..<m.len).map { _ in make(m) }
    }

    private func make(_ m: UnitMode) -> UnitQuestion {
        switch m {
        case .choose, .fill, .rush:
            let it = pool(kItems, { $0.lv }).randomElement()!
            let prompt = it.text.replacingOccurrences(of: "___", with: "（　）")
            return UnitQuestion(kind: m, prompt: prompt, options: unitOptions(it.cat, it.unit), answer: it.unit, exp: it.exp, cat: it.cat)
        case .judge:
            let it = pool(kJudge, { $0.lv }).randomElement()!
            return UnitQuestion(kind: .judge, prompt: "这句话对吗？「\(it.text)」", options: ["√", "×"], answer: it.ok ? "√" : "×", exp: it.exp, cat: nil)
        case .riddle:
            let it = pool(kRiddle, { $0.lv }).randomElement()!
            let cat = UnitCat.allCases.first { $0.units.contains(it.unit) } ?? .length
            return UnitQuestion(kind: .riddle, prompt: "猜一猜：\(it.text)（是什么单位？）", options: unitOptions(cat, it.unit), answer: it.unit, exp: it.exp, cat: cat)
        case .compare:
            let cat = UnitCat.allCases.randomElement()!
            let conv = cat.conv
            let units = conv.map { $0.0 }
            guard units.count >= 2 else { return make(.choose) }
            var ua = units.randomElement()!, ub = units.randomElement()!
            while ub == ua { ub = units.randomElement()! }
            let va = conv.first { $0.0 == ua }!.1, vb = conv.first { $0.0 == ub }!.1
            let na = Int.random(in: 1...9), nb = Int.random(in: 1...9)
            let A = na * va, B = nb * vb
            let ans = A > B ? "＞" : (A < B ? "＜" : "＝")
            return UnitQuestion(kind: .compare, prompt: "哪边更重 / 更长 / 更多？\n\(na) \(ua)　　\(nb) \(ub)", options: ["＞", "＜", "＝"], answer: ans, exp: "化成同一单位再比", cat: cat)
        case .sort:
            let cat = UnitCat.allCases.randomElement()!
            let conv = cat.conv
            let units = conv.map { $0.0 }
            var items: [SortItem] = []
            var guardCount = 0
            while items.count < 3 && guardCount < 60 {
                guardCount += 1
                let u = units.randomElement()!, m = conv.first { $0.0 == u }!.1, n = Int.random(in: 1...9)
                if !items.contains(where: { $0.base == n * m }) { items.append(SortItem(text: "\(n) \(u)", base: n * m)) }
            }
            return UnitQuestion(kind: .sort, prompt: "从小到大，依次点一点：", cat: cat, sortItems: items)
        case .shop:
            let it = pool(kShop, { $0.lv }).randomElement()!
            var opts = Set<String>()
            opts.insert(fmtCents(it.cents))
            for d in [10, -10, 50, -50, 5] { let v = it.cents + d; if v > 0 { opts.insert(fmtCents(v)) } }
            return UnitQuestion(kind: .shop, prompt: it.text, options: Array(opts.prefix(4)).shuffled(), answer: fmtCents(it.cents), exp: it.exp, cat: .money)
        case .match:
            let picks = kMatchPairs.shuffled().prefix(4).map { MatchPair(left: $0.0, right: $0.1) }
            return UnitQuestion(kind: .match, prompt: "把物品和单位连起来（点左边，再点右边）", matchPairs: Array(picks))
        }
    }

    private func fmtCents(_ v: Int) -> String {
        if v < 10 { return "\(v)分" }
        let y = v / 10, r = v % 10
        return r == 0 ? "\(y)元" : "\(y)元\(r)角"
    }

    // MARK: 背景

    private var decorations: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Circle().fill(RadialGradient(colors: [Color(red: 1, green: 0.92, blue: 0.55), Color(red: 1, green: 0.78, blue: 0.30)], center: .center, startRadius: 0, endRadius: 32))
                    .frame(width: 62, height: 62).opacity(0.5).position(x: w * 0.85, y: h * 0.08)
                cloud.opacity(0.55).position(x: w * 0.16, y: h * 0.09)
                cloud.opacity(0.4).scaleEffect(0.7).position(x: w * 0.62, y: h * 0.04)
                ForEach(0..<10, id: \.self) { i in
                    Text(["✨", "🌸", "🌼", "🍃"][i % 4]).font(.system(size: i % 3 == 0 ? 15 : 12)).opacity(0.26)
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
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Text("?").font(.system(size: 24, weight: .black)).foregroundStyle(accent)
                        .frame(width: 46, height: 46).background(Circle().fill(accentSoft))
                    Text("单位大闯关怎么玩").font(.system(size: 21, weight: .black, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                }
                VStack(alignment: .leading, spacing: 10) {
                    helpLine("情景快选 / 单位填空", "看句子，选出最合适的单位。")
                    helpLine("天平比大小", "判断 ＞ ＜ ＝（理解量级，不死背）。")
                    helpLine("找茬小判官", "判断句子里的单位对不对。")
                    helpLine("连连看 / 量感排序 / 生活综合", "配对、排序、算钱。")
                    helpLine("抢答挑战", "亲子同屏对战，限时抢答。")
                    helpLine("徽章", "长度 / 质量 / 时间 / 钱币 / 容量 / 面积，答对累计解锁。")
                }
                Button { showHelp = false } label: {
                    Text("知道了").font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50).background(Capsule().fill(accent))
                }.buttonStyle(.plain).padding(.top, 6)
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
    }

    private func helpLine(_ t: String, _ d: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(accent).frame(width: 6, height: 6).padding(.top, 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(t).font(.system(size: 14.5, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                Text(d).font(.system(size: 12.5, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
            }
        }
    }
}
