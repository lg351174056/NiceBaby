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

    var sizeText: String { "\(w)×\(h)" }
    var minPathLength: Int { Int(Double(w + h) * minPathRatio) }
}

private let MazeStageDefs: [(name: String, icon: String)] = [
    ("糖果花园", "🍬"), ("气球乐园", "🎈"), ("旋转木马", "🎠"),
    ("冰淇淋镇", "🍦"), ("星星剧场", "⭐"), ("彩虹小镇", "🌈"),
    ("月亮港湾", "🌙"), ("云朵森林", "☁️"), ("宝石山谷", "💎"),
    ("梦境城堡", "🏰"),
]
private let MazeStageSizes: [(w: Int, h: Int)] = [
    (9, 13), (10, 14), (11, 15), (12, 16), (13, 17),
    (14, 18), (15, 19), (16, 20), (17, 20), (17, 21),
]
private let MazeLevelsPerStage = 5

private func makeMazeLevels() -> [MazeLevelConfig] {
    var out: [MazeLevelConfig] = []
    for (si, stage) in MazeStageDefs.enumerated() {
        for li in 0..<MazeLevelsPerStage {
            let progress = Double(si) / Double(max(MazeStageDefs.count - 1, 1))
            let withinStage = Double(li) * 0.05
            out.append(MazeLevelConfig(
                stageIndex: si,
                levelInStage: li,
                stageName: stage.name, icon: stage.icon,
                w: MazeStageSizes[si].w, h: MazeStageSizes[si].h,
                minPathRatio: 1.35 + progress * 1.15 + withinStage,
                threeStarRatio: max(1.18, 1.55 - progress * 0.25),
                twoStarRatio: max(1.7, 2.25 - progress * 0.25),
                usesDynamicGoal: si >= 2
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

    mutating func generate() {
        var visited = [Bool](repeating: false, count: cols * rows)
        visited[0] = true
        var stack = [0]

        while let cur = stack.last {
            let cx = cur % cols, cy = cur / cols
            var opts: [(n: Int, dir: Int)] = []
            let dirs: [(dx: Int, dy: Int, dir: Int)] = [(0, -1, 0), (1, 0, 1), (0, 1, 2), (-1, 0, 3)]
            for d in dirs {
                let nx = cx + d.dx, ny = cy + d.dy
                guard nx >= 0, nx < cols, ny >= 0, ny < rows else { continue }
                let ni = idx(nx, ny)
                if !visited[ni] { opts.append((ni, d.dir)) }
            }
            if opts.isEmpty {
                stack.removeLast()
            } else {
                let pick = opts.randomElement()!
                walls[idx(cx, cy) * 4 + pick.dir] = false
                let nx = cx + (pick.dir == 1 ? 1 : pick.dir == 3 ? -1 : 0)
                let ny = cy + (pick.dir == 0 ? -1 : pick.dir == 2 ? 1 : 0)
                walls[idx(nx, ny) * 4 + (pick.dir + 2) % 4] = false
                visited[pick.n] = true
                stack.append(pick.n)
            }
        }
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

// MARK: - 方向键按压样式（点击下沉 + 阴影收缩）

private struct DPadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .offset(x: configuration.isPressed ? 3 : 0, y: configuration.isPressed ? 4 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
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
    @State private var lastDrag = CGSize.zero
    @State private var showLockedHint = false

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
                dpad
                bottomBar
            }

            if showWin {
                winOverlay
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
        .onAppear { startLevel(0) }
        .onReceive(timer) { _ in
            guard !won else { return }
            elapsed += 1
        }
        .sheet(isPresented: $showSheet) { levelSheet }
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

            ZStack {
                let frameW: CGFloat = cell >= 30 ? 3 : cell >= 22 ? 2 : 1.5
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(mazeInk, lineWidth: 3))
                    .shadow(color: mazeInk.opacity(0.3), radius: 5, y: 5)
                    .padding(4)

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
                            // 边界墙由圆角外框统一绘制，这里只画内部墙
                            if grid.walls[base + 0] && y > 0 {
                                var p = Path()
                                p.move(to: CGPoint(x: wx, y: wy))
                                p.addLine(to: CGPoint(x: wx + cell, y: wy))
                                ctx.stroke(p, with: .color(mazeInk), lineWidth: wallW)
                            }
                            if grid.walls[base + 1] && x < grid.cols - 1 {
                                var p = Path()
                                p.move(to: CGPoint(x: wx + cell, y: wy))
                                p.addLine(to: CGPoint(x: wx + cell, y: wy + cell))
                                ctx.stroke(p, with: .color(mazeInk), lineWidth: wallW)
                            }
                            if grid.walls[base + 2] && y < grid.rows - 1 {
                                var p = Path()
                                p.move(to: CGPoint(x: wx + cell, y: wy + cell))
                                p.addLine(to: CGPoint(x: wx, y: wy + cell))
                                ctx.stroke(p, with: .color(mazeInk), lineWidth: wallW)
                            }
                            if grid.walls[base + 3] && x > 0 {
                                var p = Path()
                                p.move(to: CGPoint(x: wx, y: wy + cell))
                                p.addLine(to: CGPoint(x: wx, y: wy))
                                ctx.stroke(p, with: .color(mazeInk), lineWidth: wallW)
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
                    .onEnded { _ in lastDrag = .zero }
            )
        }
        .padding(.horizontal, 10)
        .padding(.top, 2)
        .padding(.bottom, 4)
    }

    // MARK: - 滑动控制（增量判定，避免一次滑动触发多次）

    private func swipeOnChanged(_ value: DragGesture.Value, cell: CGFloat) {
        let dx = value.translation.width - lastDrag.width
        let dy = value.translation.height - lastDrag.height
        lastDrag = value.translation
        let th = max(16, cell * 0.35)
        if abs(dx) > th || abs(dy) > th {
            if abs(dx) > abs(dy) {
                move(dx: dx > 0 ? 1 : -1, dy: 0)
            } else {
                move(dx: 0, dy: dy > 0 ? 1 : -1)
            }
        }
    }

    // MARK: - 方向杆

    private var dpad: some View {
        HStack(spacing: 8) {
            dpadKey("◀", dx: -1, dy: 0).frame(width: 76, height: 128)
            VStack(spacing: 8) {
                dpadKey("▲", dx: 0, dy: -1).frame(width: 76, height: 60)
                dpadKey("▼", dx: 0, dy: 1).frame(width: 76, height: 60)
            }
            dpadKey("▶", dx: 1, dy: 0).frame(width: 76, height: 128)
        }
        .padding(.vertical, 4)
    }

    private func dpadKey(_ label: String, dx: Int, dy: Int) -> some View {
        Button {
            move(dx: dx, dy: dy)
        } label: {
            Text(label)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(Color(red: 232/255, green: 106/255, blue: 158/255))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(colors: [.white, Color(red: 255/255, green: 233/255, blue: 242/255)],
                                   startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(mazeInk, lineWidth: 3))
                .shadow(color: mazeInk.opacity(0.35), radius: 0, x: 4, y: 5)
        }
        .buttonStyle(DPadButtonStyle())
    }

    // MARK: - 底部（弱化）

    private var bottomBar: some View {
        HStack {
            miniBtn("↺") { startLevel(currentLevel) }
            Spacer()
            Text("滑动迷宫或按方向键")
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
        var selectedGrid = MazeGrid(cols: cfg.w, rows: cfg.h)
        var selectedGoal = (x: cfg.w - 1, y: cfg.h - 1, distance: 0)
        var selectedBest = 0
        var tries = 0
        let maxTries = cfg.usesDynamicGoal ? 70 : 40
        repeat {
            var g = MazeGrid(cols: cfg.w, rows: cfg.h)
            g.generate()
            let goal = g.farGoal(from: 0, 0, dynamic: cfg.usesDynamicGoal)
            if goal.distance > selectedBest {
                selectedGrid = g
                selectedGoal = goal
                selectedBest = goal.distance
            }
            tries += 1
        } while selectedBest < cfg.minPathLength && tries < maxTries

        grid = selectedGrid
        px = 0
        py = 0
        gx = selectedGoal.x
        gy = selectedGoal.y
        bestPathLen = selectedBest
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
