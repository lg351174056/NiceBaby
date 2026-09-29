import SwiftUI
import Combine

// MARK: - 迷宫乐园 · 进度持久化

enum MazeProgressStore {
    private static func key(_ level: Int) -> String { "maze.stars.\(level)" }

    static func stars(level: Int) -> Int {
        UserDefaults.standard.integer(forKey: key(level))
    }

    /// 仅在新星级高于历史最佳时写入。
    @discardableResult
    static func update(level: Int, newStars: Int) -> Bool {
        let old = stars(level: level)
        guard newStars > old else { return false }
        UserDefaults.standard.set(newStars, forKey: key(level))
        return true
    }
}

// MARK: - 关卡配置（10 阶段 × 5 关 = 50 关）

private struct MazeLevelConfig {
    let stageIndex: Int
    let levelInStage: Int
    let stageName: String
    let icon: String
    let w: Int
    let h: Int
    let minPathRatio: Double
    let threeStarRatio: Double
    let twoStarRatio: Double
    let usesDynamicGoal: Bool
    /// 生成时的转弯偏置：越大通道越爱拐弯、越蜿蜒（0 = 原始均匀随机）
    let turnBias: Double
    /// 关卡要求的最短路最少拐弯次数（越往后越绕）
    let minTurns: Int
    /// 墙体波浪幅度（相对格子尺寸的比例，0 = 直墙；波浪迷宫章节 > 0）
    let waveAmp: Double
    /// 分支因子 0~1：0 = 长走廊少岔路(DFS)，越大岔路口/死胡同越多(Prim 式)
    let branching: Double

    var sizeText: String { "\(w)×\(h)" }
    var minPathLength: Int { Int(Double(w + h) * minPathRatio) }
}

private let MazeChapterStages = 10   // 每章阶段数

private let MazeStageDefs: [(name: String, icon: String)] = [
    // 第 1 章 · 经典迷宫（直墙）
    ("糖果花园", "🍬"), ("气球乐园", "🎈"), ("旋转木马", "🎠"),
    ("冰淇淋镇", "🍦"), ("星星剧场", "⭐"), ("彩虹小镇", "🌈"),
    ("月亮港湾", "🌙"), ("云朵森林", "☁️"), ("宝石山谷", "💎"),
    ("梦境城堡", "🏰"),
    // 第 2 章 · 波浪迷宫（波浪墙，第 51 关起）
    ("海浪湾", "🌊"), ("涟漪湖", "💧"), ("风铃谷", "🎐"),
    ("漩涡洞", "🌀"), ("海螺宫", "🐚"), ("泡泡海", "🫧"),
    ("缠绕林", "🪢"), ("摇曳竹", "🎋"), ("游龙涧", "🐉"),
    ("波光殿", "🌌"),
]
private let MazeStageSizes: [(w: Int, h: Int)] = [
    (9, 13), (10, 14), (11, 15), (12, 16), (13, 17),
    (14, 18), (15, 19), (16, 20), (17, 20), (17, 21),
    // 第 2 章尺寸
    (14, 18), (15, 18), (15, 19), (16, 19), (16, 20),
    (17, 20), (17, 21), (18, 21), (18, 22), (18, 22),
]
private let MazeLevelsPerStage = 5

private func makeMazeLevels() -> [MazeLevelConfig] {
    var out: [MazeLevelConfig] = []
    for (si, stage) in MazeStageDefs.enumerated() {
        let isWavy = si >= MazeChapterStages          // 第 2 章 = 波浪迷宫
        let localStage = si % MazeChapterStages        // 本章内的阶段序号 0..9
        let progress = Double(localStage) / Double(max(MazeChapterStages - 1, 1))
        for li in 0..<MazeLevelsPerStage {
            let withinStage = Double(li) * 0.05
            let w = MazeStageSizes[si].w, h = MazeStageSizes[si].h
            let minPathRatio = 1.35 + progress * 1.15 + withinStage
            let minPathLen = Int(Double(w + h) * minPathRatio)

            let turnBias: Double
            let turnRatio: Double
            let waveAmp: Double
            let branching: Double
            if isWavy {
                // 波浪迷宫：整体更绕 + 墙体波浪 + 更多岔路，随本章递增
                turnBias = 1.5 + progress * 2.0        // 1.5 → 3.5
                turnRatio = 0.30 + progress * 0.20     // 30% → 50%
                waveAmp = 0.10 + progress * 0.14       // 波幅(相对cell) 0.10 → 0.24
                branching = 0.45 + progress * 0.45     // 岔路密度 0.45 → 0.90
            } else {
                // 经典迷宫：早关偏好直行(更简单) → 末关强烈拐弯；岔路随关卡增多
                turnBias = -0.5 + progress * 3.5
                turnRatio = 0.10 + progress * 0.32
                waveAmp = 0
                branching = 0.25 + progress * 0.5      // 岔路密度 0.25 → 0.75
            }
            let minTurns = Int(Double(minPathLen) * turnRatio) + li
            out.append(MazeLevelConfig(
                stageIndex: si,
                levelInStage: li,
                stageName: stage.name, icon: stage.icon,
                w: w, h: h,
                minPathRatio: minPathRatio,
                threeStarRatio: max(1.18, 1.55 - progress * 0.25),
                twoStarRatio: max(1.7, 2.25 - progress * 0.25),
                usesDynamicGoal: isWavy || si >= 2,
                turnBias: turnBias,
                minTurns: minTurns,
                waveAmp: waveAmp,
                branching: branching
            ))
        }
    }
    return out
}

// MARK: - 迷宫生成器（递归回溯 + BFS 最短路径）

private struct MazeGrid {
    let cols: Int
    let rows: Int
    /// 上、右、下、左
    var walls: [Bool]

    init(cols: Int, rows: Int) {
        self.cols = cols
        self.rows = rows
        self.walls = [Bool](repeating: true, count: cols * rows * 4)
    }

    func idx(_ x: Int, _ y: Int) -> Int { y * cols + x }

    /// Growing Tree 生成。
    /// - turnBias > 0：挑邻居时倾向转弯，路径更蜿蜒。
    /// - branching 0~1：每步从活动列表里取格子的方式——0 总取最新(=递归回溯，长走廊少岔路)，
    ///   越大越倾向随机取(=Prim 式，岔路口与死胡同更多，玩家要多次选择/回头)。
    mutating func generate(turnBias: Double = 0, branching: Double = 0) {
        var visited = [Bool](repeating: false, count: cols * rows)
        var enterDir = [Int](repeating: -1, count: cols * rows)  // 进入每个格子时的方向
        visited[0] = true
        var active = [0]
        let dirs: [(dx: Int, dy: Int, dir: Int)] = [(0, -1, 0), (1, 0, 1), (0, 1, 2), (-1, 0, 3)]

        while !active.isEmpty {
            // 分支因子：按概率决定取"随机活动格"(制造岔路) 还是"最新格"(拉长走廊)
            let ai = (branching > 0 && Double.random(in: 0..<1) < branching)
                ? Int.random(in: 0..<active.count)
                : active.count - 1
            let cur = active[ai]
            let cx = cur % cols, cy = cur / cols
            var opts: [(n: Int, dir: Int)] = []
            for d in dirs {
                let nx = cx + d.dx, ny = cy + d.dy
                guard nx >= 0, nx < cols, ny >= 0, ny < rows else { continue }
                let ni = idx(nx, ny)
                if !visited[ni] { opts.append((ni, d.dir)) }
            }
            if opts.isEmpty {
                active.remove(at: ai)
            } else {
                let pick = Self.weightedPick(opts, straightDir: enterDir[cur], turnBias: turnBias)
                walls[idx(cx, cy) * 4 + pick.dir] = false
                let nx = cx + (pick.dir == 1 ? 1 : pick.dir == 3 ? -1 : 0)
                let ny = cy + (pick.dir == 0 ? -1 : pick.dir == 2 ? 1 : 0)
                walls[idx(nx, ny) * 4 + (pick.dir + 2) % 4] = false
                visited[pick.n] = true
                enterDir[pick.n] = pick.dir
                active.append(pick.n)
            }
        }
    }

    /// 加权挑选：与来向相同(直行)权重 1，转弯权重 1 + turnBias。
    private static func weightedPick(_ opts: [(n: Int, dir: Int)], straightDir: Int, turnBias: Double)
        -> (n: Int, dir: Int) {
        if turnBias <= 0 || straightDir < 0 { return opts.randomElement()! }
        let weights = opts.map { $0.dir == straightDir ? 1.0 : 1.0 + turnBias }
        let total = weights.reduce(0, +)
        var r = Double.random(in: 0..<total)
        for (i, w) in weights.enumerated() {
            if r < w { return opts[i] }
            r -= w
        }
        return opts.last!
    }

    /// BFS 距离表：用于挑选更绕的终点与星级评级。
    func distances(from sx: Int, _ sy: Int) -> [Int] {
        var dist = [Int](repeating: -1, count: cols * rows)
        dist[idx(sx, sy)] = 0
        var q = [idx(sx, sy)]
        var head = 0
        let dirs: [(dx: Int, dy: Int, dir: Int)] = [(0, -1, 0), (1, 0, 1), (0, 1, 2), (-1, 0, 3)]
        while head < q.count {
            let c = q[head]; head += 1
            let cx = c % cols, cy = c / cols
            for d in dirs {
                if walls[idx(cx, cy) * 4 + d.dir] { continue }
                let ni = idx(cx + d.dx, cy + d.dy)
                if dist[ni] < 0 {
                    dist[ni] = dist[c] + 1
                    q.append(ni)
                }
            }
        }
        return dist
    }

    /// BFS 最短路径长度（用于星级评级）。
    func shortestPath(from sx: Int, _ sy: Int, to gx: Int, _ gy: Int) -> Int {
        distances(from: sx, sy)[idx(gx, gy)]
    }

    /// 最短路的长度与拐弯次数（拐弯 = 相邻两步方向不同）。
    func pathInfo(from sx: Int, _ sy: Int, to gx: Int, _ gy: Int) -> (dist: Int, turns: Int) {
        let n = cols * rows
        var dist = [Int](repeating: -1, count: n)
        var prev = [Int](repeating: -1, count: n)
        var prevDir = [Int](repeating: -1, count: n)
        let start = idx(sx, sy), goal = idx(gx, gy)
        dist[start] = 0
        var q = [start]; var head = 0
        let dirs: [(dx: Int, dy: Int, dir: Int)] = [(0, -1, 0), (1, 0, 1), (0, 1, 2), (-1, 0, 3)]
        while head < q.count {
            let c = q[head]; head += 1
            let cx = c % cols, cy = c / cols
            for d in dirs {
                if walls[c * 4 + d.dir] { continue }
                let ni = idx(cx + d.dx, cy + d.dy)
                if dist[ni] < 0 {
                    dist[ni] = dist[c] + 1
                    prev[ni] = c
                    prevDir[ni] = d.dir
                    q.append(ni)
                }
            }
        }
        guard dist[goal] >= 0 else { return (-1, 0) }
        // 从终点回溯方向序列，统计方向变化次数
        var seq: [Int] = []
        var cur = goal
        while cur != start, prev[cur] >= 0 {
            seq.append(prevDir[cur])
            cur = prev[cur]
        }
        seq.reverse()
        var turns = 0
        if seq.count > 1 {
            for i in 1..<seq.count where seq[i] != seq[i - 1] { turns += 1 }
        }
        return (dist[goal], turns)
    }

    func farGoal(from sx: Int, _ sy: Int, dynamic: Bool) -> (x: Int, y: Int, distance: Int) {
        let dist = distances(from: sx, sy)
        if !dynamic {
            return (cols - 1, rows - 1, dist[idx(cols - 1, rows - 1)])
        }

        let minManhattan = max(cols, rows) / 2
        let candidates = dist.enumerated()
            .filter { item in
                let x = item.offset % cols
                let y = item.offset / cols
                return item.element > 0 && abs(x - sx) + abs(y - sy) >= minManhattan
            }
            .sorted { $0.element > $1.element }

        guard let best = candidates.first else {
            return (cols - 1, rows - 1, dist[idx(cols - 1, rows - 1)])
        }

        let poolSize = max(1, min(6, candidates.count / 8))
        let pick = candidates.prefix(poolSize).randomElement() ?? best
        return (pick.offset % cols, pick.offset / cols, pick.element)
    }
}

// MARK: - 波浪墙路径（amp = 0 时退化为直线）

private func mazeWavePath(from a: CGPoint, to b: CGPoint, amp: CGFloat) -> Path {
    var p = Path()
    guard amp > 0.3 else {
        p.move(to: a); p.addLine(to: b); return p
    }
    let steps = 12
    let dx = b.x - a.x, dy = b.y - a.y
    let len = max((dx * dx + dy * dy).squareRoot(), 0.0001)
    // 单位法向量，波浪沿墙的垂直方向摆动；两端偏移为 0（sin 0 与 sin 2π），保证接头对齐
    let nx = -dy / len, ny = dx / len
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps)
        let off = amp * sin(t * .pi * 2)
        let pt = CGPoint(x: a.x + dx * t + nx * off, y: a.y + dy * t + ny * off)
        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
    }
    return p
}

// MARK: - 主视图

struct MazeGameView: View {
    let onExit: () -> Void

    private let levels: [MazeLevelConfig] = makeMazeLevels()

    @State private var currentLevel = 0
    @State private var grid = MazeGrid(cols: 9, rows: 13)
    @State private var px = 0
    @State private var py = 0
    @State private var gx = 8
    @State private var gy = 12
    @State private var bestPathLen = 0
    @State private var stepCount = 0
    @State private var elapsed = 0
    @State private var won = false
    @State private var showWin = false
    @State private var showSheet = false
    @State private var confetti: [(CGFloat, CGFloat, String, Int)] = []
    @State private var didMoveThisDrag = false   // 一次拖拽只移动 1 格
    @State private var showLockedHint = false
    @State private var showIntro = false

    private let mazeInk = Color(red: 184/255, green: 90/255, blue: 126/255)
    private let floorColor = Color(red: 255/255, green: 233/255, blue: 242/255)

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 255/255, green: 228/255, blue: 239/255),
                    Color(red: 246/255, green: 224/255, blue: 240/255),
                    Color(red: 224/255, green: 236/255, blue: 244/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                deco("🎈", x: geo.size.width * 0.9, y: geo.size.height * 0.07, delay: 0)
                deco("🍭", x: geo.size.width * 0.03, y: geo.size.height * 0.3, delay: 0.5)
                deco("🎠", x: geo.size.width * 0.93, y: geo.size.height * 0.62, delay: 1.0)
            }
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                topBar
                mazeStage
                bottomBar
            }

            if showWin {
                winOverlay
                    .transition(.opacity)
            }

            if showIntro {
                introOverlay
                    .transition(.opacity)
            }

            // 未通关提示 Toast（浮层居中，不影响布局）
            if showLockedHint {
                Text("先走到草莓熊那里哦 🍓")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(mazeInk, in: Capsule())
                    .shadow(color: mazeInk.opacity(0.4), radius: 6, y: 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(false)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            startLevel(0)
            showIntro = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeOut(duration: 0.3)) { showIntro = false }
            }
        }
        .onReceive(timer) { _ in
            guard !won else { return }
            elapsed += 1
        }
        .sheet(isPresented: $showSheet) { levelSheet }
    }

    // MARK: - 进入提示（温馨小提示）

    private var introOverlay: some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("🍓").font(.system(size: 46))
                Text("怎么玩")
                    .font(.system(size: 19, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 138/255, green: 74/255, blue: 94/255))
                Text("用手指在迷宫里往上下左右滑动，\n带着 66 找到草莓熊就通关啦！\n路越走越绕，慢慢来别着急～")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(mazeInk.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                Text("👆 点击任意处开始")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(mazeInk.opacity(0.55))
                    .padding(.top, 2)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 26)
            .frame(maxWidth: 300)
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(mazeInk, lineWidth: 3))
            .shadow(color: mazeInk.opacity(0.35), radius: 8, y: 6)
            .padding(.horizontal, 40)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.25)) { showIntro = false }
        }
    }

    // MARK: - 漂浮装饰

    private func deco(_ emoji: String, x: CGFloat, y: CGFloat, delay: Double) -> some View {
        Text(emoji)
            .font(.system(size: 22))
            .opacity(0.65)
            .position(x: x, y: y)
            .allowsHitTesting(false)
            .modifier(FloatingModifier(delay: delay))
    }

    private struct FloatingModifier: ViewModifier {
        let delay: Double
        @State private var floating = false

        func body(content: Content) -> some View {
            content
                .offset(y: floating ? -6 : 0)
                .rotationEffect(.degrees(floating ? 4 : -4))
                .animation(
                    .easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(delay),
                    value: floating
                )
                .onAppear { floating = true }
        }
    }

    // MARK: - 顶部栏

    private var topBar: some View {
        HStack(spacing: 8) {
            Button(action: onExit) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(mazeInk)
                    .frame(width: 36, height: 36)
                    .background(.white, in: Circle())
                    .overlay(Circle().strokeBorder(mazeInk, lineWidth: 2))
                    .shadow(color: mazeInk.opacity(0.25), radius: 2, y: 2)
            }

            Button {
                showSheet = true
            } label: {
                HStack(spacing: 5) {
                    Text("🎀")
                    Text("第 \(currentLevel + 1) 关")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(mazeInk)
                    Text("▾")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(mazeInk)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white, in: Capsule())
                .overlay(Capsule().strokeBorder(mazeInk, lineWidth: 2))
                .shadow(color: mazeInk.opacity(0.25), radius: 2, y: 2)
            }

            Spacer()

            hudChip(icon: "⏱", value: fmtTime(elapsed))
            hudChip(icon: "👣", value: "\(stepCount)")
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private func hudChip(icon: String, value: String) -> some View {
        HStack(spacing: 3) {
            Text(icon).font(.system(size: 11))
            Text(value)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(mazeInk)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(mazeInk.opacity(0.6), lineWidth: 2))
    }

    private func fmtTime(_ s: Int) -> String {
        "\(s / 60):\(String(format: "%02d", s % 60))"
    }

    // MARK: - 迷宫舞台

    private var mazeStage: some View {
        GeometryReader { geo in
            let cell = min(geo.size.width / CGFloat(grid.cols), geo.size.height / CGFloat(grid.rows))
            let mw = cell * CGFloat(grid.cols)
            let mh = cell * CGFloat(grid.rows)
            let ox = (geo.size.width - mw) / 2
            let oy = (geo.size.height - mh) / 2
            let waveAmp = currentLevel < levels.count ? levels[currentLevel].waveAmp : 0
            let amp = waveAmp * cell

            ZStack {
                let frameW: CGFloat = cell >= 30 ? 3 : cell >= 22 ? 2 : 1.5
                // 白色卡片贴合迷宫大小（外留 8pt 白边）。不描边——外墙统一由内部的圆角外框画，避免双线
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: mazeInk.opacity(0.3), radius: 5, y: 5)
                    .frame(width: mw + 16, height: mh + 16)
                    .position(x: ox + mw / 2, y: oy + mh / 2)

                Canvas { ctx, _ in
                    let wallW: CGFloat = cell >= 30 ? 3 : cell >= 22 ? 2 : 1.5
                    // 地板圆角，与外框圆角一致，避免四角露出直角
                    ctx.fill(
                        Path(roundedRect: CGRect(x: ox, y: oy, width: mw, height: mh), cornerRadius: 14),
                        with: .color(floorColor)
                    )
                    for y in 0..<grid.rows {
                        for x in 0..<grid.cols {
                            let wx = ox + cell * CGFloat(x)
                            let wy = oy + cell * CGFloat(y)
                            let base = (y * grid.cols + x) * 4
                            let style = StrokeStyle(lineWidth: wallW, lineCap: .round, lineJoin: .round)
                            // 边界墙由圆角外框统一绘制，这里只画内部墙（波浪章节 amp>0 时画成波浪墙）
                            if grid.walls[base + 0] && y > 0 {
                                ctx.stroke(mazeWavePath(from: CGPoint(x: wx, y: wy),
                                                        to: CGPoint(x: wx + cell, y: wy), amp: amp),
                                           with: .color(mazeInk), style: style)
                            }
                            if grid.walls[base + 1] && x < grid.cols - 1 {
                                ctx.stroke(mazeWavePath(from: CGPoint(x: wx + cell, y: wy),
                                                        to: CGPoint(x: wx + cell, y: wy + cell), amp: amp),
                                           with: .color(mazeInk), style: style)
                            }
                            if grid.walls[base + 2] && y < grid.rows - 1 {
                                ctx.stroke(mazeWavePath(from: CGPoint(x: wx + cell, y: wy + cell),
                                                        to: CGPoint(x: wx, y: wy + cell), amp: amp),
                                           with: .color(mazeInk), style: style)
                            }
                            if grid.walls[base + 3] && x > 0 {
                                ctx.stroke(mazeWavePath(from: CGPoint(x: wx, y: wy + cell),
                                                        to: CGPoint(x: wx, y: wy), amp: amp),
                                           with: .color(mazeInk), style: style)
                            }
                        }
                    }
                }

                // 圆角外框（粗细与内部墙一致）
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(mazeInk, lineWidth: frameW)
                    .frame(width: mw, height: mh)
                    .position(x: ox + mw / 2, y: oy + mh / 2)
                    .allowsHitTesting(false)

                // 终点草莓熊
                Image("xiong")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cell * 0.72, height: cell * 0.72)
                    .position(x: ox + cell * CGFloat(gx) + cell / 2,
                              y: oy + cell * CGFloat(gy) + cell / 2)
                    .shadow(color: mazeInk.opacity(0.25), radius: 2, y: 2)
                    .allowsHitTesting(false)

                // 玩家
                Image("666")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cell * 0.78, height: cell * 0.78)
                    .position(x: ox + cell * CGFloat(px) + cell / 2,
                              y: oy + cell * CGFloat(py) + cell / 2)
                    .shadow(color: mazeInk.opacity(0.3), radius: 3, y: 3)
                    .animation(.easeInOut(duration: 0.11), value: px)
                    .animation(.easeInOut(duration: 0.11), value: py)
                    .allowsHitTesting(false)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        swipeOnChanged(value, cell: cell)
                    }
                    .onEnded { _ in didMoveThisDrag = false }
            )
        }
        .padding(.horizontal, 6)
        .padding(.top, 2)
        .padding(.bottom, 4)
    }

    // MARK: - 滑动控制（增量判定，避免一次滑动触发多次）

    private func swipeOnChanged(_ value: DragGesture.Value, cell: CGFloat) {
        // 一次拖拽只走 1 格：首次越过阈值即移动一格，之后忽略，直到手指抬起
        guard !didMoveThisDrag else { return }
        let dx = value.translation.width
        let dy = value.translation.height
        let th = max(16, cell * 0.35)
        guard abs(dx) > th || abs(dy) > th else { return }
        if abs(dx) > abs(dy) {
            move(dx: dx > 0 ? 1 : -1, dy: 0)
        } else {
            move(dx: 0, dy: dy > 0 ? 1 : -1)
        }
        didMoveThisDrag = true
    }

    // MARK: - 底部（弱化）

    private var bottomBar: some View {
        HStack {
            miniBtn("↺") { startLevel(currentLevel) }
            Spacer()
            Text("用手指滑动迷宫，带 66 找到草莓熊")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(mazeInk.opacity(0.55))
            Spacer()
            miniBtn("➜") {
                if won {
                    nextLevel()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showLockedHint = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showLockedHint = false
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 26)
        .padding(.top, 2)
    }

    private func miniBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(mazeInk)
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.75), in: Circle())
                .overlay(Circle().strokeBorder(mazeInk.opacity(0.5), lineWidth: 2))
        }
        .buttonStyle(MiniBtnStyle())
    }

    private struct MiniBtnStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.88 : 1)
                .opacity(configuration.isPressed ? 0.7 : 1)
                .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
        }
    }

    // MARK: - 游戏逻辑

    private func move(dx: Int, dy: Int) {
        guard !won else { return }
        let dir: Int
        if dx == 0 && dy == -1 { dir = 0 }
        else if dx == 1 && dy == 0 { dir = 1 }
        else if dx == 0 && dy == 1 { dir = 2 }
        else if dx == -1 && dy == 0 { dir = 3 }
        else { return }
        guard !grid.walls[(py * grid.cols + px) * 4 + dir] else { return }
        px += dx
        py += dy
        stepCount += 1
        if px == gx && py == gy {
            win()
        }
    }

    private func win() {
        guard !won else { return }
        won = true
        let ratio = Double(stepCount) / Double(max(bestPathLen, 1))
        let cfg = levels[currentLevel]
        let stars: Int
        if ratio > cfg.twoStarRatio { stars = 1 }
        else if ratio > cfg.threeStarRatio { stars = 2 }
        else { stars = 3 }
        MazeProgressStore.update(level: currentLevel, newStars: stars)

        let emojis = ["✨", "🎉", "🎀", "🎊", "🍓", "🧸"]
        confetti = (0..<10).map { i in
            (CGFloat.random(in: 0.08...0.92), CGFloat.random(in: 0.05...0.3), emojis[i % emojis.count], i)
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showWin = true
        }
    }

    private func nextLevel() {
        showWin = false
        if currentLevel < levels.count - 1 {
            startLevel(currentLevel + 1)
        } else {
            startLevel(0)
        }
    }

    private func startLevel(_ lv: Int) {
        currentLevel = lv
        won = false
        showWin = false
        elapsed = 0
        stepCount = 0
        confetti = []

        let cfg = levels[lv]
        // 选关时对"拐弯"的看重程度也随阶段递增（按章计算）：波浪章基线更高
        let localStage = cfg.stageIndex % MazeChapterStages
        let stageProgress = Double(localStage) / Double(max(MazeChapterStages - 1, 1))
        let turnWeight = (cfg.waveAmp > 0 ? 2.0 : 0.5) + stageProgress * 3.0
        var selectedGrid = MazeGrid(cols: cfg.w, rows: cfg.h)
        var selectedGX = cfg.w - 1, selectedGY = cfg.h - 1
        var selectedDist = 0
        var selectedTurns = 0
        var selectedScore = -1.0
        var tries = 0
        let maxTries = cfg.usesDynamicGoal ? 90 : 50
        repeat {
            var g = MazeGrid(cols: cfg.w, rows: cfg.h)
            g.generate(turnBias: cfg.turnBias, branching: cfg.branching)
            let goal = g.farGoal(from: 0, 0, dynamic: cfg.usesDynamicGoal)
            let info = g.pathInfo(from: 0, 0, to: goal.x, goal.y)
            let score = Double(info.dist) + turnWeight * Double(info.turns)
            if score > selectedScore {
                selectedGrid = g
                selectedGX = goal.x
                selectedGY = goal.y
                selectedDist = info.dist
                selectedTurns = info.turns
                selectedScore = score
            }
            tries += 1
        } while (selectedDist < cfg.minPathLength || selectedTurns < cfg.minTurns) && tries < maxTries

        grid = selectedGrid
        px = 0
        py = 0
        gx = selectedGX
        gy = selectedGY
        bestPathLen = selectedDist
    }

    // MARK: - 过关弹窗

    private var winOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            GeometryReader { geo in
                VStack(spacing: 16) {
                    ZStack {
                        ForEach(confetti, id: \.3) { c in
                            Text(c.2)
                                .font(.system(size: 22))
                                .position(x: c.0 * geo.size.width,
                                          y: c.1 * geo.size.height)
                        }
                    }
                    .frame(height: 60)

                VStack(spacing: 8) {
                    Text("🏆").font(.system(size: 52))
                    Text("66找到草莓熊啦！")
                        .font(.system(size: 20, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 138/255, green: 74/255, blue: 94/255))
                    Text("用时 \(fmtTime(elapsed)) · 走了 \(stepCount) 步 · 最短 \(bestPathLen) 步")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 74/255, blue: 94/255).opacity(0.65))
                        .padding(.top, 4)
                    Text(starRow())
                        .font(.system(size: 28))
                        .padding(.top, 6)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 26)
                .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(mazeInk, lineWidth: 3))
                .shadow(color: mazeInk.opacity(0.35), radius: 6, y: 6)
                .padding(.horizontal, 40)

                    Button {
                        nextLevel()
                    } label: {
                        Text(currentLevel < levels.count - 1 ? "下一关 ➜" : "全部通关 🎉")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 13)
                            .background(
                                LinearGradient(colors: [
                                    Color(red: 255/255, green: 165/255, blue: 196/255),
                                    Color(red: 232/255, green: 106/255, blue: 158/255)
                                ], startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                            )
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(mazeInk, lineWidth: 2))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func starRow() -> String {
        let stars = MazeProgressStore.stars(level: currentLevel)
        return String(repeating: "⭐", count: stars) + String(repeating: "☆", count: 3 - stars)
    }

    // MARK: - 关卡选择弹层

    private var levelSheet: some View {
        ZStack {
            Color(red: 255/255, green: 228/255, blue: 239/255).ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule()
                    .fill(mazeInk.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                Text("🎀 选择关卡")
                    .font(.system(size: 18, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 138/255, green: 74/255, blue: 94/255))
                    .padding(.top, 12)
                Text("一共 \(levels.count) 关 · 越往后路线越绕")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(mazeInk.opacity(0.6))
                    .padding(.top, 3)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(0..<MazeStageDefs.count, id: \.self) { si in
                            let stageLevel = levels[si * MazeLevelsPerStage]
                            HStack(spacing: 6) {
                                Text(stageLevel.icon)
                                Text("\(stageLevel.stageName) · \(stageLevel.sizeText)")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color(red: 232/255, green: 106/255, blue: 158/255))
                                Rectangle().fill(mazeInk.opacity(0.25)).frame(height: 2)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 8)

                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: MazeLevelsPerStage),
                                spacing: 8
                            ) {
                                ForEach(0..<MazeLevelsPerStage, id: \.self) { i in
                                    let lv = si * MazeLevelsPerStage + i
                                    levelCell(lv)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 20)
                }

                Button {
                    showSheet = false
                } label: {
                    Text("关闭")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 74/255, blue: 94/255))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(mazeInk, lineWidth: 2))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private func levelCell(_ lv: Int) -> some View {
        let stars = MazeProgressStore.stars(level: lv)
        let unlocked = lv == 0 || MazeProgressStore.stars(level: lv - 1) > 0
        return Button {
            guard unlocked else { return }
            showSheet = false
            startLevel(lv)
        } label: {
            VStack(spacing: 3) {
                Text("\(lv + 1)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 74/255, blue: 94/255))
                Text(stars > 0 ? String(repeating: "⭐", count: stars) : (unlocked ? "·" : "🔒"))
                    .font(.system(size: 9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(stars > 0 ? Color(red: 255/255, green: 217/255, blue: 138/255) : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        lv == currentLevel ? mazeInk : mazeInk.opacity(0.5),
                        lineWidth: lv == currentLevel ? 2.5 : 1.5
                    )
            )
            .shadow(color: mazeInk.opacity(0.2), radius: 0, x: 2, y: 2)
        }
        .buttonStyle(.plain)
        .opacity(unlocked ? 1 : 0.45)
    }
}
