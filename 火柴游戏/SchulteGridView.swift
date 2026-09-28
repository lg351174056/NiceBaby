import SwiftUI
import Combine
import UIKit

// MARK: - 舒尔特方格（专注力训练 · 多题材）
//
// 玩法内核统一为「按分组顺序依次点击」：
//   · 满格顺序型（数字/字母/成语/唐诗）：每个格子是一个独立分组，按序点完即通关
//   · 提示寻找型（颜色/图形）：同色/同形为一组，按提示先点完一组再下一组
//
// 导航：题材页 → 难度页 → 游戏页，三个独立 View，push / pop（原生侧滑返回）。
// 对外接口保持不变：SchulteGridView(onExit:)

// MARK: - 题材定义

enum SchulteMode: String, CaseIterable, Identifiable, Hashable {
    case number, letter, color, shape, idiom, poem

    var id: String { rawValue }

    var title: String {
        switch self {
        case .number: return "数字"
        case .letter: return "字母"
        case .color:  return "颜色"
        case .shape:  return "图形"
        case .idiom:  return "成语"
        case .poem:   return "唐诗"
        }
    }

    var emoji: String {
        switch self {
        case .number: return "🔢"
        case .letter: return "🔤"
        case .color:  return "🎨"
        case .shape:  return "⭐️"
        case .idiom:  return "📖"
        case .poem:   return "🏮"
        }
    }

    var tagline: String {
        switch self {
        case .number: return "1 → N 依次点击，经典专注训练"
        case .letter: return "A → Z 依次点击，熟悉字母顺序"
        case .color:  return "按提示找颜色，认色不识字也能玩"
        case .shape:  return "按提示找图案，认识各种小事物"
        case .idiom:  return "按顺序点出成语，一局学好几个"
        case .poem:   return "按顺序点出诗句，边玩边背诗"
        }
    }

    var accent: Color {
        switch self {
        case .number: return AppTheme.accentJade
        case .letter: return AppTheme.accentBamboo
        case .color:  return AppTheme.accentPink
        case .shape:  return Color(red: 0.85, green: 0.60, blue: 0.15)
        case .idiom:  return AppTheme.accentInkPurple
        case .poem:   return AppTheme.accentCinnabar
        }
    }

    /// 该题材支持的方格边长
    var supportedSizes: [Int] {
        switch self {
        case .number, .color, .shape: return [3, 4, 5, 6]
        case .letter: return [3, 4, 5]          // 字母上限 26，5×5=25
        case .idiom:  return [4, 6]             // 每格 4 字成语，需被 4 整除
        case .poem:   return [4, 5, 6]
        }
    }

    /// 提示寻找型（同组多格）
    var usesHunt: Bool { self == .color || self == .shape }
    /// 文字词句型（成语/唐诗）
    var isPhrase: Bool { self == .idiom || self == .poem }
    /// 文字类（含数字/字母）——格子用彩色底 + 文字
    var isTextual: Bool { self == .number || self == .letter || isPhrase }
}

// MARK: - 格子内容

enum SchulteCellContent {
    case text(String)
    case color(Color)
    case emoji(String)          // 图形题材用 emoji
}

// MARK: - 棋盘（生成结果）

struct PhraseSegment {
    let title: String    // 成语文本 / 诗名
    let start: Int       // 起始步（含）
    let length: Int
}

struct SchulteBoard {
    let mode: SchulteMode
    let size: Int
    var cells: [SchulteCellContent]     // 每个格子位置的显示内容
    var groups: [[Int]]                 // 有序分组：先点完 groups[i] 再 groups[i+1]
    var cellGroup: [Int]                // 位置 -> 所属分组索引
    var textBG: [Color]                 // 文字类格子的柔和底色
    var segments: [PhraseSegment]       // 词句类的提示分段
    var groupLabels: [String]           // 寻找型的分组名称（颜色/图形名）

    var totalGroups: Int { groups.count }
}

// MARK: - 内容生成

enum SchulteBoardFactory {

    static func make(mode: SchulteMode, size: Int) -> SchulteBoard {
        switch mode {
        case .number: return makeSequential(mode: mode, size: size) { "\($0 + 1)" }
        case .letter: return makeSequential(mode: mode, size: size) { letterAt($0) }
        case .color:  return makeHuntColors(size: size)
        case .shape:  return makeHuntShapes(size: size)
        case .idiom:  return makePhrase(mode: mode, size: size)
        case .poem:   return makePhrase(mode: mode, size: size)
        }
    }

    // MARK: 满格顺序型（数字/字母）

    private static func makeSequential(mode: SchulteMode, size: Int, label: (Int) -> String) -> SchulteBoard {
        let count = size * size
        let positions = Array(0..<count).shuffled()   // positions[step] = 格子位置
        var cells = [SchulteCellContent](repeating: .text(""), count: count)
        var groups: [[Int]] = []
        var cellGroup = [Int](repeating: 0, count: count)
        for step in 0..<count {
            let pos = positions[step]
            cells[pos] = .text(label(step))
            groups.append([pos])
            cellGroup[pos] = step
        }
        return SchulteBoard(mode: mode, size: size, cells: cells, groups: groups,
                            cellGroup: cellGroup, textBG: pastelColors(count: count, grid: size),
                            segments: [], groupLabels: [])
    }

    // MARK: 词句型（成语/唐诗）

    private static func makePhrase(mode: SchulteMode, size: Int) -> SchulteBoard {
        let count = size * size
        var chars: [String] = []
        var segments: [PhraseSegment] = []

        if mode == .idiom {
            for idiom in idioms.shuffled() {
                if chars.count >= count { break }
                let start = chars.count
                let arr = idiom.map { String($0) }
                segments.append(PhraseSegment(title: idiom, start: start, length: arr.count))
                chars.append(contentsOf: arr)
            }
        } else {
            // 唐诗：选一首长度 >= count 的诗，取前 count 字（尽量少截断）
            let poem = poems.filter { $0.text.count >= count }
                .min(by: { $0.text.count < $1.text.count })
                ?? poems.max(by: { $0.text.count < $1.text.count })!
            let arr = poem.text.map { String($0) }
            chars = Array(arr.prefix(count))
            segments.append(PhraseSegment(title: poem.title, start: 0, length: min(count, arr.count)))
        }

        // 词库不足时循环补齐（极少发生）
        var i = 0
        while chars.count < count, !chars.isEmpty {
            chars.append(chars[i % chars.count]); i += 1
        }
        chars = Array(chars.prefix(count))
        // 修正末段越界
        segments = segments.compactMap { seg in
            guard seg.start < count else { return nil }
            return PhraseSegment(title: seg.title, start: seg.start, length: min(seg.length, count - seg.start))
        }

        let positions = Array(0..<count).shuffled()
        var cells = [SchulteCellContent](repeating: .text(""), count: count)
        var groups: [[Int]] = []
        var cellGroup = [Int](repeating: 0, count: count)
        for step in 0..<count {
            let pos = positions[step]
            cells[pos] = .text(chars[step])
            groups.append([pos])
            cellGroup[pos] = step
        }
        return SchulteBoard(mode: mode, size: size, cells: cells, groups: groups,
                            cellGroup: cellGroup, textBG: pastelColors(count: count, grid: size),
                            segments: segments, groupLabels: [])
    }

    // MARK: 寻找型（颜色 / 图形）

    private static func makeHuntColors(size: Int) -> SchulteBoard {
        let g = size
        let chosen = Array(colorSwatches.prefix(g))
        return makeHunt(mode: .color, size: size, groupCount: g,
                        contentFor: { .color(chosen[$0].color) },
                        labelFor: { chosen[$0].name })
    }

    private static func makeHuntShapes(size: Int) -> SchulteBoard {
        let g = size
        let chosen = Array(emojiItems.shuffled().prefix(g))   // 每局随机抽取
        return makeHunt(mode: .shape, size: size, groupCount: g,
                        contentFor: { .emoji(chosen[$0].emoji) },
                        labelFor: { chosen[$0].name })
    }

    private static func makeHunt(mode: SchulteMode, size: Int, groupCount g: Int,
                                 contentFor: (Int) -> SchulteCellContent,
                                 labelFor: (Int) -> String) -> SchulteBoard {
        let count = size * size
        let per = count / g
        var pool: [Int] = []
        for c in 0..<g { pool.append(contentsOf: Array(repeating: c, count: per)) }
        var extra = 0
        while pool.count < count { pool.append(extra % g); extra += 1 }
        pool.shuffle()

        var cells = [SchulteCellContent](repeating: .text(""), count: count)
        var cellGroup = [Int](repeating: 0, count: count)
        var groups = [[Int]](repeating: [], count: g)
        for pos in 0..<count {
            let group = pool[pos]
            cells[pos] = contentFor(group)
            cellGroup[pos] = group
            groups[group].append(pos)
        }
        return SchulteBoard(mode: mode, size: size, cells: cells, groups: groups,
                            cellGroup: cellGroup, textBG: [],
                            segments: [], groupLabels: (0..<g).map(labelFor))
    }

    // MARK: 柔和底色（文字类）

    static func pastelColors(count: Int, grid: Int) -> [Color] {
        let palette: [Color] = [
            Color(red: 0.78, green: 0.92, blue: 0.83), Color(red: 0.80, green: 0.94, blue: 0.68),
            Color(red: 0.72, green: 0.86, blue: 0.96), Color(red: 0.97, green: 0.84, blue: 0.50),
            Color(red: 0.97, green: 0.72, blue: 0.70), Color(red: 0.84, green: 0.72, blue: 0.96),
            Color(red: 0.98, green: 0.76, blue: 0.58), Color(red: 0.65, green: 0.89, blue: 0.85),
            Color(red: 0.79, green: 0.93, blue: 0.56), Color(red: 0.95, green: 0.91, blue: 0.54),
            Color(red: 0.70, green: 0.83, blue: 0.98), Color(red: 0.96, green: 0.79, blue: 0.87),
            Color(red: 0.66, green: 0.90, blue: 0.92), Color(red: 0.90, green: 0.85, blue: 0.66),
            Color(red: 0.80, green: 0.78, blue: 0.97), Color(red: 0.87, green: 0.92, blue: 0.73)
        ]
        if count <= palette.count { return palette.shuffled() }
        var indices: [Int] = []
        for i in 0..<count {
            let row = i / grid, col = i % grid
            var forbidden = Set<Int>()
            if col > 0 { forbidden.insert(indices[i - 1]) }
            if row > 0 { forbidden.insert(indices[i - grid]) }
            let candidates = (0..<palette.count).filter { !forbidden.contains($0) }
            let pool = candidates.isEmpty ? Array(0..<palette.count) : candidates
            indices.append(pool[Int.random(in: 0..<pool.count)])
        }
        return indices.map { palette[$0] }
    }

    private static func letterAt(_ i: Int) -> String {
        String(UnicodeScalar(65 + (i % 26))!)
    }

    // MARK: 词库

    static let idioms: [String] = [
        "一心一意", "画蛇添足", "亡羊补牢", "守株待兔", "掩耳盗铃", "对牛弹琴",
        "井底之蛙", "狐假虎威", "画龙点睛", "拔苗助长", "自相矛盾", "滥竽充数",
        "惊弓之鸟", "叶公好龙", "刻舟求剑", "南辕北辙", "买椟还珠", "杯弓蛇影"
    ]

    struct Poem { let title: String; let text: String }
    static let poems: [Poem] = [
        Poem(title: "静夜思", text: "床前明月光疑是地上霜举头望明月低头思故乡"),
        Poem(title: "春晓", text: "春眠不觉晓处处闻啼鸟夜来风雨声花落知多少"),
        Poem(title: "登鹳雀楼", text: "白日依山尽黄河入海流欲穷千里目更上一层楼"),
        Poem(title: "悯农", text: "锄禾日当午汗滴禾下土谁知盘中餐粒粒皆辛苦"),
        Poem(title: "望庐山瀑布", text: "日照香炉生紫烟遥看瀑布挂前川飞流直下三千尺疑是银河落九天"),
        Poem(title: "早发白帝城", text: "朝辞白帝彩云间千里江陵一日还两岸猿声啼不住轻舟已过万重山"),
        Poem(title: "春望", text: "国破山河在城春草木深感时花溅泪恨别鸟惊心烽火连三月家书抵万金白头搔更短浑欲不胜簪")
    ]

    struct ColorSwatch { let name: String; let color: Color }
    static let colorSwatches: [ColorSwatch] = [
        ColorSwatch(name: "红色", color: Color(red: 0.93, green: 0.35, blue: 0.35)),
        ColorSwatch(name: "橙色", color: Color(red: 0.98, green: 0.62, blue: 0.25)),
        ColorSwatch(name: "黄色", color: Color(red: 0.97, green: 0.82, blue: 0.30)),
        ColorSwatch(name: "绿色", color: Color(red: 0.40, green: 0.78, blue: 0.45)),
        ColorSwatch(name: "蓝色", color: Color(red: 0.35, green: 0.62, blue: 0.92)),
        ColorSwatch(name: "紫色", color: Color(red: 0.66, green: 0.48, blue: 0.86))
    ]

    struct EmojiItem { let name: String; let emoji: String }
    static let emojiItems: [EmojiItem] = [
        // 水果
        EmojiItem(name: "苹果", emoji: "🍎"), EmojiItem(name: "橙子", emoji: "🍊"),
        EmojiItem(name: "西瓜", emoji: "🍉"), EmojiItem(name: "葡萄", emoji: "🍇"),
        EmojiItem(name: "草莓", emoji: "🍓"), EmojiItem(name: "香蕉", emoji: "🍌"),
        // 动物
        EmojiItem(name: "小狗", emoji: "🐶"), EmojiItem(name: "小猫", emoji: "🐱"),
        EmojiItem(name: "兔子", emoji: "🐰"), EmojiItem(name: "狐狸", emoji: "🦊"),
        EmojiItem(name: "小熊", emoji: "🐻"), EmojiItem(name: "熊猫", emoji: "🐼"),
        EmojiItem(name: "老虎", emoji: "🐯"), EmojiItem(name: "青蛙", emoji: "🐸"),
        EmojiItem(name: "小猪", emoji: "🐷"), EmojiItem(name: "小鸡", emoji: "🐥"),
        // 自然 / 天空
        EmojiItem(name: "星星", emoji: "⭐️"), EmojiItem(name: "彩虹", emoji: "🌈"),
        EmojiItem(name: "太阳", emoji: "☀️"), EmojiItem(name: "月亮", emoji: "🌙"),
        EmojiItem(name: "雪花", emoji: "❄️"), EmojiItem(name: "樱花", emoji: "🌸"),
        EmojiItem(name: "向日葵", emoji: "🌻"), EmojiItem(name: "蝴蝶", emoji: "🦋"),
        // 物品
        EmojiItem(name: "小车", emoji: "🚗"), EmojiItem(name: "足球", emoji: "⚽️"),
        EmojiItem(name: "气球", emoji: "🎈"), EmojiItem(name: "礼物", emoji: "🎁"),
        EmojiItem(name: "皇冠", emoji: "👑"), EmojiItem(name: "爱心", emoji: "❤️")
    ]
}

// MARK: - 导航路由

enum SchulteRoute: Hashable {
    case size(SchulteMode)          // 选难度页
    case game(SchulteMode, Int)     // 游戏页
}

// MARK: - 一级：选题材（入口，onExit 承载）

struct SchulteGridView: View {
    let onExit: () -> Void

    var body: some View {
        ZStack {
            FieldBackground()

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    GracefulBackButton(action: onExit)
                    Spacer()
                    Text("舒尔特方格")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                    Spacer()
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Text("选择题材")
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .tracking(2)
                    .foregroundStyle(AppTheme.fieldInk)
                    .padding(.top, 18)

                Text("专注力训练 · 6 种玩法")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .padding(.top, 4)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14),
                                        GridItem(.flexible(), spacing: 14)], spacing: 14) {
                        ForEach(SchulteMode.allCases) { m in
                            NavigationLink(value: SchulteRoute.size(m)) {
                                modeCard(m)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: SchulteRoute.self) { route in
            switch route {
            case .size(let m):        SchulteSizeView(mode: m)
            case .game(let m, let s): SchulteGameView(mode: m, size: s)
            }
        }
    }

    private func modeCard(_ m: SchulteMode) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(m.emoji)
                .font(.system(size: 34))
                .frame(width: 60, height: 60)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(m.accent.opacity(0.14)))

            Text(m.title)
                .font(.system(size: 19, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)

            Text(m.tagline)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(AppTheme.fieldMoss)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(m.accent.opacity(0.25), lineWidth: 2))
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.1), radius: 8, y: 4)
        )
    }
}

// MARK: - 二级：选难度（push 页）

struct SchulteSizeView: View {
    let mode: SchulteMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            FieldBackground()

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    GracefulBackButton(action: { dismiss() })
                    Spacer()
                    Text("\(mode.emoji) \(mode.title)方格")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                    Spacer()
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                Text("选择难度")
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .padding(.bottom, 6)

                Text(mode.tagline)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .padding(.bottom, 30)
                    .padding(.horizontal, 30)
                    .multilineTextAlignment(.center)

                VStack(spacing: 14) {
                    ForEach(mode.supportedSizes, id: \.self) { s in
                        NavigationLink(value: SchulteRoute.game(mode, s)) {
                            sizeRow(s)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .enableSwipeBack()
    }

    private func sizeRow(_ s: Int) -> some View {
        HStack(spacing: 16) {
            Text("\(s)×\(s)")
                .font(.system(size: 22, weight: .black, design: .serif))
                .foregroundStyle(.white)
                .frame(width: 74, height: 74)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(mode.accent))
                .shadow(color: mode.accent.opacity(0.4), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(SchulteLayout.sizeName(s))
                    .font(.system(size: 18, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("\(s) 行 \(s) 列 · 共 \(s * s) 格")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.fieldMoss)
                if let best = SchulteBestStore.best(mode: mode, size: s) {
                    Text("最佳 \(String(format: "%.1f", best)) 秒")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(mode.accent.opacity(0.85))
                } else {
                    Text("还没玩过")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.fieldMossLight)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.fieldOlive.opacity(0.5))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.88))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 2))
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.1), radius: 8, y: 4)
        )
    }
}

// MARK: - 三级：游戏页（push 页，自持状态）

struct SchulteGameView: View {
    let mode: SchulteMode
    let size: Int
    @Environment(\.dismiss) private var dismiss

    @State private var board: SchulteBoard
    @State private var currentGroup = 0
    @State private var doneCells: Set<Int> = []
    @State private var started = false
    @State private var startDate: Date? = nil
    @State private var elapsed = 0.0
    @State private var finished = false
    @State private var wrongIndex: Int? = nil
    @State private var bestTime: Double? = nil
    @State private var newRecord = false

    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    init(mode: SchulteMode, size: Int) {
        self.mode = mode
        self.size = size
        _board = State(initialValue: SchulteBoardFactory.make(mode: mode, size: size))
        _bestTime = State(initialValue: SchulteBestStore.best(mode: mode, size: size))
    }

    var body: some View {
        ZStack {
            FieldBackground()

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    GracefulBackButton(action: { dismiss() })

                    Text("\(mode.title) · \(size)×\(size)")
                        .font(.system(size: 15, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 6) {
                        timerChip
                        resetButton
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 6)

                promptBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)

                Spacer(minLength: 8)

                grid

                Spacer(minLength: 12)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .enableSwipeBack()
        .overlay {
            if !started && !finished {
                startOverlay
            } else if finished {
                resultOverlay
            }
        }
        .onReceive(timer) { _ in
            guard started, !finished, let start = startDate else { return }
            elapsed = Date().timeIntervalSince(start)
        }
    }

    // MARK: 顶部信息

    private var timerChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "stopwatch.fill").font(.system(size: 11, weight: .bold))
            Text(String(format: "%.1fs", elapsed))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(AppTheme.fieldInk)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.8)))
        .overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.2), lineWidth: 1))
    }

    private var resetButton: some View {
        Button {
            newGame()
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.fieldMint)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.8), in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.7), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 提示条

    @ViewBuilder
    private var promptBar: some View {
        switch mode {
        case .color, .shape:
            huntPrompt
        case .idiom, .poem:
            phrasePrompt
        default:
            Text(mode == .letter ? "按 A → Z 依次点击" : "按 1 → \(board.totalGroups) 依次点击")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.fieldMoss)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var huntPrompt: some View {
        if currentGroup < board.groups.count {
            let label = board.groupLabels.indices.contains(currentGroup) ? board.groupLabels[currentGroup] : ""
            HStack(spacing: 10) {
                Text("找出全部")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.fieldMoss)
                huntSwatch(board.cells[board.groups[currentGroup].first ?? 0])
                Text(label)
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("(\(currentGroup + 1)/\(board.totalGroups))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMossLight)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.white.opacity(0.75)))
        }
    }

    @ViewBuilder
    private func huntSwatch(_ content: SchulteCellContent) -> some View {
        switch content {
        case .color(let c):
            Circle().fill(c).frame(width: 22, height: 22)
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))
        case .emoji(let e):
            Text(e).font(.system(size: 22))
        case .text(let t):
            Text(t)
        }
    }

    // 词句提示：单个可换行 Text（完成的字着色、待点的字高亮），不再溢出
    @ViewBuilder
    private var phrasePrompt: some View {
        let seg = board.segments.first(where: { currentGroup >= $0.start && currentGroup < $0.start + $0.length })
            ?? board.segments.last
        if let seg {
            VStack(spacing: 6) {
                Text(mode == .idiom ? "凑成成语（按顺序点字）" : "《\(seg.title)》")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.fieldMoss)
                Text(phraseAttributed(seg))
                    .font(.system(size: 19, weight: .heavy, design: .serif))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.75)))
        }
    }

    private func phraseAttributed(_ seg: PhraseSegment) -> AttributedString {
        var out = AttributedString()
        for step in seg.start..<(seg.start + seg.length) {
            var piece = AttributedString(cellText(board.groups[step].first ?? 0))
            if step < currentGroup {
                piece.foregroundColor = mode.accent.opacity(0.45)          // 已点
            } else if step == currentGroup {
                piece.foregroundColor = mode.accent                        // 待点（高亮）
            } else {
                piece.foregroundColor = AppTheme.fieldInk.opacity(0.8)     // 未点
            }
            out += piece
        }
        return out
    }

    // MARK: - 棋盘

    private var grid: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: SchulteLayout.spacing(size)), count: size)
        return LazyVGrid(columns: cols, spacing: SchulteLayout.spacing(size)) {
            ForEach(0..<board.cells.count, id: \.self) { pos in
                cellView(pos: pos)
            }
        }
        .padding(.vertical, 8)
    }

    private func cellView(pos: Int) -> some View {
        let done = doneCells.contains(pos)
        return Button {
            if started { tap(pos: pos) }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: SchulteLayout.corner(size), style: .continuous)
                    .fill(cellBackground(pos: pos, done: done))
                    .overlay(RoundedRectangle(cornerRadius: SchulteLayout.corner(size), style: .continuous)
                        .strokeBorder(wrongIndex == pos ? Color.red.opacity(0.85)
                                      : AppTheme.fieldOlive.opacity(0.14),
                                      lineWidth: wrongIndex == pos ? 2 : 1))
                    .shadow(color: AppTheme.fieldGrassShadow.opacity(0.07), radius: 4, y: 2)

                cellForeground(pos: pos, done: done)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .scaleEffect(wrongIndex == pos ? 0.94 : 1)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func cellForeground(pos: Int, done: Bool) -> some View {
        switch board.cells[pos] {
        case .text(let t):
            Text(t)
                .font(.system(size: SchulteLayout.fontSize(size), weight: .black, design: .serif))
                .foregroundStyle(done ? Color(red: 0.42, green: 0.46, blue: 0.45)
                                 : Color(red: 0.10, green: 0.28, blue: 0.18))
        case .color:
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: SchulteLayout.fontSize(size) * 0.7, weight: .black))
                    .foregroundStyle(.white)
            }
        case .emoji(let e):
            Text(e)
                .font(.system(size: SchulteLayout.fontSize(size) * 1.15))
                .opacity(done ? 0.3 : 1)
        }
    }

    private func cellBackground(pos: Int, done: Bool) -> Color {
        if wrongIndex == pos { return Color(red: 1.0, green: 0.76, blue: 0.76) }
        switch board.cells[pos] {
        case .color(let c):
            return done ? c.opacity(0.35) : c
        case .emoji:
            return done ? Color(red: 0.90, green: 0.91, blue: 0.90) : Color.white.opacity(0.92)
        case .text:
            if done { return Color(red: 0.72, green: 0.75, blue: 0.74) }
            return board.textBG.indices.contains(pos) ? board.textBG[pos] : Color.white.opacity(0.9)
        }
    }

    // MARK: - 完成弹窗

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.22).ignoresSafeArea()
            resultCard
        }
        .transition(.opacity)
    }

    private var resultCard: some View {
        VStack(spacing: 14) {
            Text(newRecord ? "🎉 新纪录！" : "🎉").font(.system(size: 48)).padding(.top, 6)
            Text("完成！")
                .font(.system(size: 26, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)

            VStack(spacing: 6) {
                Text("本局用时").font(.system(size: 12, weight: .bold)).foregroundStyle(AppTheme.fieldMoss)
                Text(String(format: "%.2f", elapsed) + " 秒")
                    .font(.system(size: 32, weight: .black, design: .serif))
                    .foregroundStyle(mode.accent)
            }

            VStack(spacing: 6) {
                Text("当前最高记录").font(.system(size: 12, weight: .bold)).foregroundStyle(AppTheme.fieldMoss)
                Text(bestTime.map { String(format: "%.2f", $0) + " 秒" } ?? "-")
                    .font(.system(size: 22, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
            }

            HStack(spacing: 12) {
                Button { newGame() } label: {
                    Text("再来一局")
                        .font(.system(size: 15, weight: .heavy)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 25, style: .continuous).fill(mode.accent))
                }
                .buttonStyle(.plain)

                Button { dismiss() } label: {
                    Text("换难度")
                        .font(.system(size: 15, weight: .heavy)).foregroundStyle(AppTheme.fieldInk)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .fill(Color.white.opacity(0.88))
                            .overlay(RoundedRectangle(cornerRadius: 25, style: .continuous)
                                .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 6)
        }
        .padding(22)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(mode.accent.opacity(0.35), lineWidth: 2))
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.14), radius: 12, y: 6)
        )
    }

    // MARK: - 开始遮罩

    private var startOverlay: some View {
        ZStack {
            Color.white.opacity(0.62).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(mode.emoji).font(.system(size: 58))
                Text("\(mode.title) · \(size)×\(size)")
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text(startHint)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .multilineTextAlignment(.center).lineSpacing(4)

                Button { startPlaying() } label: {
                    Text("开始训练")
                        .font(.system(size: 19, weight: .heavy)).foregroundStyle(.white)
                        .padding(.horizontal, 50).padding(.vertical, 16)
                        .background(Capsule().fill(
                            LinearGradient(colors: [Color(red: 0.35, green: 0.82, blue: 0.55),
                                                    Color(red: 0.18, green: 0.62, blue: 0.42)],
                                           startPoint: .leading, endPoint: .trailing)))
                        .shadow(color: Color(red: 0.18, green: 0.62, blue: 0.42).opacity(0.35), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 34).padding(.vertical, 38)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 0.99, green: 0.98, blue: 0.94),
                                                  Color(red: 0.88, green: 0.96, blue: 0.90),
                                                  Color(red: 0.85, green: 0.93, blue: 0.97)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(LinearGradient(colors: [Color.white.opacity(0.8), AppTheme.fieldMint.opacity(0.35)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2))
                    .shadow(color: AppTheme.fieldGrassShadow.opacity(0.16), radius: 18, y: 8)
            )
        }
    }

    private var startHint: String {
        switch mode {
        case .number: return "点击「开始」后计时启动\n按 1 到 \(size * size) 依次点击"
        case .letter: return "点击「开始」后计时启动\n按 A 到 Z 依次点击"
        case .color:  return "点击「开始」后计时启动\n按提示先点完一种颜色，再换下一种"
        case .shape:  return "点击「开始」后计时启动\n按提示先点完一种图案，再换下一种"
        case .idiom:  return "点击「开始」后计时启动\n按顺序点出每个成语的字"
        case .poem:   return "点击「开始」后计时启动\n按顺序点出诗句的每个字"
        }
    }

    // MARK: - 游戏逻辑

    private func newGame() {
        board = SchulteBoardFactory.make(mode: mode, size: size)
        currentGroup = 0
        doneCells = []
        started = false
        startDate = nil
        elapsed = 0
        finished = false
        wrongIndex = nil
        newRecord = false
        bestTime = SchulteBestStore.best(mode: mode, size: size)
    }

    private func startPlaying() {
        started = true
        startDate = Date()
        elapsed = 0
    }

    private func tap(pos: Int) {
        guard !finished, started else { return }

        // 寻找型（颜色/图形）：按分组判定，同组任意一格都可点
        // 文字类（数字/字母/成语/唐诗）：按显示内容判定，出现重复字时任意一个都可点
        let accepted: Bool
        if mode.usesHunt {
            accepted = board.cellGroup[pos] == currentGroup && !doneCells.contains(pos)
        } else {
            accepted = !doneCells.contains(pos) && cellText(pos) == requiredText
        }

        guard accepted else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.45)) { wrongIndex = pos }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 0.15)) {
                    if wrongIndex == pos { wrongIndex = nil }
                }
            }
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        doneCells.insert(pos)

        if mode.usesHunt {
            if board.groups[currentGroup].allSatisfy({ doneCells.contains($0) }) {
                currentGroup += 1
                if currentGroup >= board.groups.count { finish() }
            }
        } else {
            currentGroup += 1
            if currentGroup >= board.totalGroups { finish() }
        }
    }

    private func cellText(_ pos: Int) -> String {
        if case .text(let t) = board.cells[pos] { return t } else { return "" }
    }

    /// 当前这一步需要点的字（文字类）
    private var requiredText: String {
        guard currentGroup < board.groups.count, let pos = board.groups[currentGroup].first else { return "" }
        return cellText(pos)
    }

    private func finish() {
        let seconds = Date().timeIntervalSince(startDate ?? Date())
        elapsed = seconds
        withAnimation(.easeOut(duration: 0.2)) { finished = true }
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        if let old = SchulteBestStore.best(mode: mode, size: size) {
            newRecord = seconds < old
        } else {
            newRecord = true
        }
        bestTime = SchulteBestStore.update(mode: mode, size: size, seconds: seconds)
            ? seconds : SchulteBestStore.best(mode: mode, size: size)
    }
}

// MARK: - 尺寸布局（按边长）

enum SchulteLayout {
    static func spacing(_ size: Int) -> CGFloat {
        switch size {
        case 3: return 10
        case 4: return 9
        case 5: return 8
        default: return 6
        }
    }
    static func corner(_ size: Int) -> CGFloat {
        switch size {
        case 3: return 16
        case 4: return 14
        case 5: return 12
        default: return 10
        }
    }
    static func fontSize(_ size: Int) -> CGFloat {
        switch size {
        case 3: return 32
        case 4: return 27
        case 5: return 22
        default: return 19
        }
    }
    static func sizeName(_ s: Int) -> String {
        switch s {
        case 3: return "入门 3×3"
        case 4: return "标准 4×4"
        case 5: return "挑战 5×5"
        default: return "王者 6×6"
        }
    }
}

// MARK: - 最佳成绩（本地缓存 · 按题材 + 尺寸）

enum SchulteBestStore {
    private static func key(_ mode: SchulteMode, _ size: Int) -> String {
        "schulte.best.\(mode.rawValue).\(size)"
    }

    static func best(mode: SchulteMode, size: Int) -> Double? {
        let v = UserDefaults.standard.double(forKey: key(mode, size))
        return v > 0 ? v : nil
    }

    @discardableResult
    static func update(mode: SchulteMode, size: Int, seconds: Double) -> Bool {
        if let old = best(mode: mode, size: size), seconds >= old { return false }
        UserDefaults.standard.set(seconds, forKey: key(mode, size))
        return true
    }

    /// 是否玩过任意题材/难度（首页「玩过」标记用）
    static func hasAny() -> Bool {
        SchulteMode.allCases.contains { mode in
            mode.supportedSizes.contains { best(mode: mode, size: $0) != nil }
        }
    }
}
