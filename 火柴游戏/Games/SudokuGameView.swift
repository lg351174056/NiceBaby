import SwiftUI
import Combine

// MARK: - 星云数独 · 进度持久化

enum SudokuProgressStore {
    private static func key(_ size: Int) -> String { "sudoku.best.\(size)" }

    static func bestTime(size: Int) -> Int {
        UserDefaults.standard.integer(forKey: key(size))
    }

    static func clearCount(size: Int) -> Int {
        UserDefaults.standard.integer(forKey: "sudoku.cleared.\(size)")
    }

    @discardableResult
    static func record(size: Int, seconds: Int) -> Bool {
        let old = bestTime(size: size)
        let isNew = old == 0 || seconds < old
        if isNew { UserDefaults.standard.set(seconds, forKey: key(size)) }
        UserDefaults.standard.set(clearCount(size: size) + 1, forKey: "sudoku.cleared.\(size)")
        return isNew
    }
}

// MARK: - 数独生成器（回溯 + 唯一解校验 + 对称挖空）

enum SudokuGen {
    static func makePuzzle(n: Int, boxR: Int, boxC: Int, empty: Int) -> (puzzle: [[Int]], sol: [[Int]]) {
        for _ in 0..<80 {
            let sol = generateSolution(n: n, boxR: boxR, boxC: boxC)
            var puzzle = sol
            let pairs = min(empty / 2, (n * n - 4) / 2)
            var cells: [(Int, Int)] = []
            for r in 0..<n {
                for c in 0..<n {
                    let rr = n - 1 - r, cc = n - 1 - c
                    if r < rr || (r == rr && c < cc) { cells.append((r, c)) }
                }
            }
            cells.shuffle()
            for (r, c) in cells.prefix(pairs) {
                puzzle[r][c] = 0
                puzzle[n - 1 - r][n - 1 - c] = 0
            }
            if countSolutions(board: puzzle, boxR: boxR, boxC: boxC, limit: 2) == 1 {
                return (puzzle, sol)
            }
        }
        // 兜底：少挖 2 个
        let sol = generateSolution(n: n, boxR: boxR, boxC: boxC)
        var puzzle = sol
        let pairs = max(0, empty / 2 - 1)
        var cells: [(Int, Int)] = []
        for r in 0..<n {
            for c in 0..<n {
                let rr = n - 1 - r, cc = n - 1 - c
                if r < rr || (r == rr && c < cc) { cells.append((r, c)) }
            }
        }
        cells.shuffle()
        for (r, c) in cells.prefix(pairs) {
            puzzle[r][c] = 0
            puzzle[n - 1 - r][n - 1 - c] = 0
        }
        return (puzzle, sol)
    }

    private static func generateSolution(n: Int, boxR: Int, boxC: Int) -> [[Int]] {
        var board = Array(repeating: Array(repeating: 0, count: n), count: n)
        func ok(_ r: Int, _ c: Int, _ v: Int) -> Bool {
            for i in 0..<n {
                if board[r][i] == v || board[i][c] == v { return false }
            }
            let r0 = (r / boxR) * boxR, c0 = (c / boxC) * boxC
            for i in r0..<(r0 + boxR) {
                for j in c0..<(c0 + boxC) {
                    if board[i][j] == v { return false }
                }
            }
            return true
        }
        func fill(_ pos: Int) -> Bool {
            if pos == n * n { return true }
            let r = pos / n, c = pos % n
            let nums = Array(1...n).shuffled()
            for v in nums {
                if ok(r, c, v) {
                    board[r][c] = v
                    if fill(pos + 1) { return true }
                    board[r][c] = 0
                }
            }
            return false
        }
        _ = fill(0)
        return board
    }

    private static func countSolutions(board: [[Int]], boxR: Int, boxC: Int, limit: Int) -> Int {
        let n = board.count
        var b = board
        var count = 0
        func ok(_ r: Int, _ c: Int, _ v: Int) -> Bool {
            for i in 0..<n {
                if b[r][i] == v || b[i][c] == v { return false }
            }
            let r0 = (r / boxR) * boxR, c0 = (c / boxC) * boxC
            for i in r0..<(r0 + boxR) {
                for j in c0..<(c0 + boxC) {
                    if b[i][j] == v { return false }
                }
            }
            return true
        }
        func solve() {
            if count >= limit { return }
            var er = -1, ec = -1
            outer: for r in 0..<n {
                for c in 0..<n where b[r][c] == 0 {
                    er = r; ec = c
                    break outer
                }
            }
            if er < 0 { count += 1; return }
            for v in 1...n {
                if ok(er, ec, v) {
                    b[er][ec] = v
                    solve()
                    b[er][ec] = 0
                    if count >= limit { return }
                }
            }
        }
        solve()
        return count
    }
}

// MARK: - 星云主题

private enum SudokuTheme {
    static let ink = Color(red: 237/255, green: 232/255, blue: 255/255)
    static let gold = Color(red: 245/255, green: 214/255, blue: 123/255)
    static let cyan = Color(red: 125/255, green: 249/255, blue: 255/255)
    static let purple = Color(red: 155/255, green: 126/255, blue: 222/255)
    static let err = Color(red: 255/255, green: 107/255, blue: 122/255)
    static let stroke = Color(red: 110/255, green: 95/255, blue: 168/255)
    static let cellBg = Color(red: 34/255, green: 30/255, blue: 74/255)
    static let cellHl = Color(red: 58/255, green: 52/255, blue: 112/255)
    static let cellPeer = Color(red: 46/255, green: 42/255, blue: 92/255)
    static let cellSame = Color(red: 74/255, green: 63/255, blue: 138/255)
    static let cellSel = Color(red: 85/255, green: 74/255, blue: 158/255)
    static let thickLine = Color(red: 90/255, green: 78/255, blue: 150/255)
    static let thinLine = Color(red: 55/255, green: 49/255, blue: 107/255)

    static let bgGradient = LinearGradient(
        colors: [
            Color(red: 20/255, green: 18/255, blue: 48/255),
            Color(red: 27/255, green: 24/255, blue: 64/255),
            Color(red: 34/255, green: 31/255, blue: 78/255)
        ],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - 星野闪烁背景

private struct StarField: View {
    @State private var twinkle = false
    private let stars: [(CGFloat, CGFloat, CGFloat)] = {
        var out: [(CGFloat, CGFloat, CGFloat)] = []
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<36 {
            out.append((CGFloat.random(in: 0.02...0.98), CGFloat.random(in: 0.02...0.98), CGFloat.random(in: 0.8...2.2)))
        }
        return out
    }()

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, _ in
                for (x, y, s) in stars {
                    let rect = CGRect(x: x * geo.size.width - s / 2, y: y * geo.size.height - s / 2, width: s, height: s)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(twinkle ? 0.9 : 0.35)))
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                    twinkle = true
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 二级页 · 难度选择（还原 home.html）

struct SudokuHomeView: View {
    let onExit: () -> Void

    @State private var selectedSize: Int?
    @State private var orbitAngle: Double = 0

    var body: some View {
        ZStack {
            SudokuTheme.bgGradient.ignoresSafeArea()
            StarField()

            if let size = selectedSize {
                SudokuGameView(size: size, onExit: { selectedSize = nil })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                content
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.28), value: selectedSize)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var content: some View {
        VStack(spacing: 0) {
            // 顶栏
            HStack(spacing: 8) {
                Button(action: onExit) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SudokuTheme.cyan)
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.08), in: Circle())
                        .overlay(Circle().strokeBorder(SudokuTheme.stroke, lineWidth: 2))
                }
                Spacer()
                Text("🌙 星云数独")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(SudokuTheme.ink.opacity(0.85))
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // 标题 + 轨道
            VStack(spacing: 6) {
                Text("NEBULA SUDOKU")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(6)
                    .foregroundStyle(SudokuTheme.cyan.opacity(0.7))
                Text("星云数独")
                    .font(.system(size: 34, weight: .heavy, design: .serif))
                    .tracking(4)
                    .foregroundStyle(SudokuTheme.ink)
                    .shadow(color: SudokuTheme.gold.opacity(0.35), radius: 14)
                Text("在星海深处，破解数字的奥秘")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(SudokuTheme.ink.opacity(0.6))
            }
            .padding(.top, 18)

            orbitingPlanet
                .frame(height: 54)
                .padding(.top, 8)

            // 难度卡
            VStack(spacing: 14) {
                levelCard(icon: "🪐", name: "星尘启蒙 · 4×4",
                          desc: "适合 5 岁+ · 数字 1-4",
                          meta: "已完成 \(SudokuProgressStore.clearCount(size: 4)) 局" + best(4),
                          colors: (Color(red: 143/255, green: 227/255, blue: 192/255), Color(red: 76/255, green: 175/255, blue: 125/255)),
                          size: 4)
                levelCard(icon: "🌠", name: "流星进阶 · 6×6",
                          desc: "适合 7 岁+ · 数字 1-6",
                          meta: "已完成 \(SudokuProgressStore.clearCount(size: 6)) 局" + best(6),
                          colors: (Color(red: 125/255, green: 249/255, blue: 255/255), Color(red: 74/255, green: 159/255, blue: 216/255)),
                          size: 6)
                levelCard(icon: "🌀", name: "黑洞大师 · 9×9",
                          desc: "适合 10 岁+ · 数字 1-9",
                          meta: "已完成 \(SudokuProgressStore.clearCount(size: 9)) 局" + best(9),
                          colors: (Color(red: 255/255, green: 178/255, blue: 107/255), Color(red: 232/255, green: 106/255, blue: 158/255)),
                          size: 9)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // 每日星题
            Button {
                selectedSize = 9
            } label: {
                HStack(spacing: 14) {
                    Text("✨").font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("每日星题")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(SudokuTheme.gold)
                        Text("今天的 9×9 挑战 · 答对有星尘奖励")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(SudokuTheme.ink.opacity(0.6))
                    }
                    Spacer()
                    Text("去挑战 ›").font(.system(size: 13, weight: .heavy)).foregroundStyle(SudokuTheme.gold)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(LinearGradient(colors: [
                            SudokuTheme.gold.opacity(0.14), SudokuTheme.cyan.opacity(0.1)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(SudokuTheme.gold.opacity(0.45), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        )
                )
            }
            .buttonStyle(SudokuPressStyle())
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Spacer(minLength: 8)
        }
    }

    private func best(_ size: Int) -> String {
        let t = SudokuProgressStore.bestTime(size: size)
        guard t > 0 else { return "" }
        return " · 最快 \(t / 60):\(String(format: "%02d", t % 60))"
    }

    private var orbitingPlanet: some View {
        ZStack {
            Circle()
                .strokeBorder(SudokuTheme.gold.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [3, 5]))
                .frame(width: 140, height: 44)
                .rotationEffect(.degrees(orbitAngle))
            Circle()
                .strokeBorder(SudokuTheme.gold.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [3, 5]))
                .frame(width: 100, height: 30)
                .rotationEffect(.degrees(-orbitAngle))
            Circle()
                .fill(RadialGradient(colors: [SudokuTheme.gold.opacity(0.35), SudokuTheme.gold], center: .init(x: 0.35, y: 0.3), startRadius: 2, endRadius: 17))
                .frame(width: 34, height: 34)
                .shadow(color: SudokuTheme.gold.opacity(0.6), radius: 12)
                .modifier(FloatUp(delay: 0))
        }
        .onAppear {
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                orbitAngle = 360
            }
        }
    }

    private struct FloatUp: ViewModifier {
        let delay: Double
        @State private var up = false
        func body(content: Content) -> some View {
            content
                .offset(y: up ? -5 : 0)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(delay), value: up)
                .onAppear { up = true }
        }
    }

    private func levelCard(icon: String, name: String, desc: String, meta: String,
                           colors: (Color, Color), size: Int) -> some View {
        Button {
            selectedSize = size
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: [colors.0, colors.1], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(SudokuTheme.ink, lineWidth: 3))
                        .shadow(color: .black.opacity(0.35), radius: 0, x: 3, y: 3)
                    Text(icon).font(.system(size: 24))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(SudokuTheme.ink)
                    Text(desc)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(SudokuTheme.ink.opacity(0.55))
                    Text(meta)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(SudokuTheme.gold)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SudokuTheme.cyan)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(SudokuTheme.stroke, lineWidth: 3))
                    .shadow(color: .black.opacity(0.45), radius: 0, x: 5, y: 6)
            )
        }
        .buttonStyle(SudokuPressStyle())
    }

}

// MARK: - 三级页 · 游戏盘面（还原 game.html）

struct SudokuGameView: View {
    let size: Int
    let onExit: () -> Void

    private var boxR: Int { size == 4 ? 2 : size == 6 ? 2 : 3 }
    private var boxC: Int { size == 4 ? 2 : size == 6 ? 3 : 3 }
    private var emptyCount: Int { size == 4 ? 6 : size == 6 ? 18 : 40 }
    private var levelName: String {
        size == 4 ? "星尘启蒙 · 4×4" : size == 6 ? "流星进阶 · 6×6" : "黑洞大师 · 9×9"
    }

    @State private var board: [[Int]]
    @State private var given: [[Bool]]
    @State private var notes: [Set<Int>]
    @State private var solution: [[Int]]
    @State private var selected: Int? = nil
    @State private var mode: Mode = .pick
    @State private var errors = 0
    @State private var hintsUsed = 0
    @State private var elapsed = 0
    @State private var won = false
    @State private var showWin = false
    @State private var errorCell: Int? = nil
    @State private var tipText = ""
    @State private var shootingStars: [(CGFloat, CGFloat, Double)] = []

    private enum Mode { case pick, note, erase }

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(size: Int, onExit: @escaping () -> Void) {
        self.size = size
        self.onExit = onExit
        let br = size == 4 ? 2 : size == 6 ? 2 : 3
        let bc = size == 4 ? 2 : size == 6 ? 3 : 3
        let empty = size == 4 ? 6 : size == 6 ? 18 : 40
        let (p, sol) = SudokuGen.makePuzzle(n: size, boxR: br, boxC: bc, empty: empty)
        _board = State(initialValue: p)
        _given = State(initialValue: p.map { $0.map { $0 != 0 } })
        _solution = State(initialValue: sol)
        _notes = State(initialValue: Array(repeating: Set<Int>(), count: size * size))
    }

    var body: some View {
        ZStack {
            SudokuTheme.bgGradient.ignoresSafeArea()
            StarField()

            VStack(spacing: 0) {
                topBar
                tipLine
                boardArea
                toolsRow
                keypadRow
                hintLine
            }

            if showWin {
                winOverlay
                    .transition(.opacity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(timer) { _ in
            guard !won else { return }
            elapsed += 1
        }
    }

    // MARK: - 新局

    private func newGame() {
        let (p, s) = SudokuGen.makePuzzle(n: size, boxR: boxR, boxC: boxC, empty: emptyCount)
        board = p
        given = p.map { row in row.map { $0 != 0 } }
        solution = s
        notes = Array(repeating: Set<Int>(), count: size * size)
        selected = nil
        errors = 0
        hintsUsed = 0
        elapsed = 0
        won = false
        showWin = false
        tipText = "每一行、每一列、每个宫格，1-\(size) 只能出现一次"
    }

    // MARK: - 顶栏

    private var topBar: some View {
        HStack(spacing: 10) {
            Button(action: onExit) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SudokuTheme.cyan)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.08), in: Circle())
                    .overlay(Circle().strokeBorder(SudokuTheme.stroke, lineWidth: 2))
            }
            Text(levelName)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(SudokuTheme.ink)
                .frame(maxWidth: .infinity)
            HStack(spacing: 8) {
                hudChip("⏱", fmtTime(elapsed), warn: false)
                hudChip("✕", "\(errors)/3", warn: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
    }

    private func hudChip(_ icon: String, _ value: String, warn: Bool) -> some View {
        HStack(spacing: 3) {
            Text(icon).font(.system(size: 11))
            Text(value)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(warn ? SudokuTheme.err : SudokuTheme.cyan)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(SudokuTheme.stroke.opacity(0.7), lineWidth: 2))
    }

    private func fmtTime(_ s: Int) -> String {
        "\(s / 60):\(String(format: "%02d", s % 60))"
    }

    // MARK: - 提示行

    private var tipLine: some View {
        Text("💡 \(tipText)")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(tipHighlight ? SudokuTheme.gold : SudokuTheme.ink.opacity(0.55))
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    @State private var tipHighlight = false

    private func flashTip(_ text: String) {
        tipText = text
        tipHighlight = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            tipHighlight = false
            tipText = "每一行、每一列、每个宫格，1-\(size) 只能出现一次"
        }
    }

    // MARK: - 盘面

    private var boardArea: some View {
        GeometryReader { geo in
            let usable = min(geo.size.width - 8, geo.size.height - 8)
            let cell = usable / CGFloat(size)
            let boardSide = cell * CGFloat(size)

            VStack(spacing: 0) {
                ForEach(0..<size, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<size, id: \.self) { c in
                            sudokuCell(r: r, c: c, cell: cell)
                        }
                    }
                }
            }
            .frame(width: boardSide, height: boardSide)
            .background(Color(red: 42/255, green: 36/255, blue: 80/255))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(SudokuTheme.stroke, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.45), radius: 0, x: 5, y: 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 12)
    }

    private func sudokuCell(r: Int, c: Int, cell: CGFloat) -> some View {
        let i = r * size + c
        let value = board[r][c]
        let isGiven = given[r][c]
        let isSelected = selected == i
        let isPeer: Bool = {
            guard let sel = selected else { return false }
            let sr = sel / size, sc = sel % size
            return r == sr || c == sc || boxOf(r, c) == boxOf(sr, sc)
        }()
        let isSame: Bool = {
            guard let sel = selected, value != 0, i != sel else { return false }
            let sr = sel / size, sc = sel % size
            return board[sr][sc] == value
        }()

        let bg: Color = {
            if isSelected { return SudokuTheme.cellSel }
            if isSame { return SudokuTheme.cellSame }
            if isPeer { return SudokuTheme.cellPeer }
            return SudokuTheme.cellBg
        }()

        return ZStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(bg)
                .overlay(alignment: .top) {
                    if isSelected {
                        Rectangle().fill(SudokuTheme.cyan).frame(height: 2)
                    }
                }
            // 宫格粗线（用边框实现）
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .strokeBorder(lineColor(r: r, c: c), lineWidth: lineWidth(r: r, c: c))
            )

            // 笔记
            if value == 0, !notes[i].isEmpty {
                VStack(spacing: 0) {
                    ForEach(0..<boxR, id: \.self) { nr in
                        HStack(spacing: 0) {
                            ForEach(0..<boxC, id: \.self) { nc in
                                let v = nr * boxC + nc + 1
                                Text(notes[i].contains(v) ? "\(v)" : " ")
                                    .font(.system(size: cell * 0.16, weight: .bold, design: .rounded))
                                    .foregroundStyle(SudokuTheme.cyan.opacity(0.75))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                }
                .padding(2)
            }

            // 数字
            if value != 0 {
                Text("\(value)")
                    .font(.system(size: cell * 0.46, weight: .heavy, design: .serif))
                    .foregroundStyle(isGiven ? SudokuTheme.gold : SudokuTheme.ink)
                    .shadow(color: isGiven ? SudokuTheme.gold.opacity(0.35) : .clear, radius: 8)
                    .scaleEffect(popCell == i ? 1.15 : 1)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: popCell)
            }
        }
        .frame(width: cell, height: cell)
        .offset(x: errorCell == i ? shakeOffset : 0)
        .animation(.easeInOut(duration: 0.05), value: shakeOffset)
        .contentShape(Rectangle())
        .onTapGesture {
            selected = i
            if mode == .erase {
                eraseCell(i)
            }
        }
    }

    @State private var popCell: Int? = nil
    @State private var shakeOffset: CGFloat = 0

    private func boxOf(_ r: Int, _ c: Int) -> Int {
        (r / boxR) * boxR + (c / boxC)
    }

    private func lineColor(r: Int, c: Int) -> Color {
        (r % boxR == 0 || c % boxC == 0 || r == size - 1 || c == size - 1)
            ? SudokuTheme.thickLine : SudokuTheme.thinLine
    }

    private func lineWidth(r: Int, c: Int) -> CGFloat {
        (r % boxR == 0 || c % boxC == 0) ? 2.5 : 1
    }

    // MARK: - 工具行

    private var toolsRow: some View {
        HStack(spacing: 14) {
            toolBtn("✏️", mode: .pick, on: mode == .pick)
            toolBtn("📝", mode: .note, on: mode == .note)
            toolBtn("🧽", mode: .erase, on: mode == .erase, warnOn: mode == .erase)
            toolBtn("💡", mode: nil, on: false) { useHint() }
        }
        .padding(.top, 8)
    }

    private func toolBtn(_ icon: String, mode: Mode?, on: Bool, warnOn: Bool = false,
                         action: (() -> Void)? = nil) -> some View {
        Button {
            if let m = mode {
                self.mode = m
            }
            action?()
        } label: {
            Text(icon)
                .font(.system(size: 17))
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.07), in: Circle())
                .overlay(
                    Circle().strokeBorder(
                        on ? (warnOn ? SudokuTheme.err : SudokuTheme.cyan) : SudokuTheme.stroke.opacity(0.8),
                        lineWidth: on ? 2.5 : 2
                    )
                )
                .shadow(color: on ? SudokuTheme.cyan.opacity(0.35) : .clear, radius: 8)
        }
        .buttonStyle(SudokuPressStyle())
    }

    // MARK: - 数字键盘

    private var keypadRow: some View {
        HStack(spacing: 8) {
            ForEach(1...9, id: \.self) { v in
                Button {
                    inputNumber(v)
                } label: {
                    Text("\(v)")
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundStyle(v <= size ? SudokuTheme.ink : SudokuTheme.ink.opacity(0.3))
                        .frame(width: 40, height: 44)
                        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(SudokuTheme.stroke.opacity(0.8), lineWidth: 2.5))
                        .shadow(color: .black.opacity(0.35), radius: 0, x: 2, y: 2)
                }
                .buttonStyle(SudokuPressStyle())
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 14)
    }

    // MARK: - 底部提示

    private var hintLine: some View {
        Text("长按格子可记笔记 · 提示会扣除星尘")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(SudokuTheme.ink.opacity(0.45))
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            .padding(.bottom, 24)
    }

    // MARK: - 逻辑

    private func eraseCell(_ i: Int) {
        guard !given[i / size][i % size] else { return }
        board[i / size][i % size] = 0
        notes[i] = []
        withAnimation(.easeOut(duration: 0.12)) { popCell = nil }
    }

    private func inputNumber(_ v: Int) {
        guard !won, v <= size, let sel = selected else { return }
        let r = sel / size, c = sel % size
        guard !given[r][c] else { return }

        if mode == .note {
            if notes[sel].contains(v) { notes[sel].remove(v) } else { notes[sel].insert(v) }
            return
        }

        // 冲突检测
        var conflict = false
        for i in 0..<size {
            if board[r][i] == v || board[i][c] == v { conflict = true }
            let br = (r / boxR) * boxR + i / boxR
            let bc = (c / boxC) * boxC + i % boxC
            if board[br][bc] == v { conflict = true }
        }
        if conflict {
            errors += 1
            errorCell = sel
            shakeOffset = 6
            withAnimation(.easeInOut(duration: 0.1)) { shakeOffset = -6 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) { shakeOffset = 4 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.1)) { shakeOffset = 0 }
                errorCell = nil
            }
            return
        }

        board[r][c] = v
        notes[sel] = []
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            popCell = sel
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            popCell = nil
        }
        checkWin()
    }

    private func useHint() {
        guard let sel = selected else { flashTip("先选中一个空格哦"); return }
        let r = sel / size, c = sel % size
        guard !given[r][c] else { return }
        guard board[r][c] != solution[r][c] else { flashTip("这一格已经正确啦"); return }
        board[r][c] = solution[r][c]
        notes[sel] = []
        hintsUsed += 1
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { popCell = sel }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { popCell = nil }
        checkWin()
    }

    private func checkWin() {
        for row in board where row.contains(0) { return }
        won = true
        SudokuProgressStore.record(size: size, seconds: elapsed)
        shootingStars = (0..<6).map { _ in
            (CGFloat.random(in: 0.25...0.85), CGFloat.random(in: 0.08...0.45), Double.random(in: 0...0.6))
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showWin = true
        }
    }

    // MARK: - 过关弹窗

    private var winOverlay: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.75).ignoresSafeArea()
                    .overlay(.ultraThinMaterial.opacity(0.2))
                VStack(spacing: 14) {
                    // 流星
                    ZStack {
                        ForEach(Array(shootingStars.enumerated()), id: \.offset) { _, s in
                            Capsule()
                                .fill(LinearGradient(colors: [.white, .clear], startPoint: .leading, endPoint: .trailing))
                                .frame(width: 70, height: 2)
                                .position(x: s.0 * geo.size.width, y: s.1 * geo.size.height)
                                .rotationEffect(.degrees(-35))
                                .offset(x: -30, y: 20)
                                .opacity(0.9)
                        }
                    }
                    .frame(height: 40)

                    VStack(spacing: 8) {
                        Text("🌠").font(.system(size: 52))
                        Text("星图补全！")
                            .font(.system(size: 21, weight: .heavy, design: .serif))
                            .foregroundStyle(SudokuTheme.ink)
                        Text("用时 \(fmtTime(elapsed)) · \(errors) 次错误 · \(hintsUsed) 次提示")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(SudokuTheme.ink.opacity(0.6))
                        let stars = errors == 0 && hintsUsed == 0 ? 3 : (errors <= 1 ? 2 : 1)
                        Text(String(repeating: "⭐", count: stars) + String(repeating: "☆", count: 3 - stars))
                            .font(.system(size: 28))
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                    .background(
                        LinearGradient(colors: [Color(red: 42/255, green: 36/255, blue: 80/255), Color(red: 30/255, green: 27/255, blue: 66/255)],
                                       startPoint: .top, endPoint: .bottom),
                        in: RoundedRectangle(cornerRadius: 26, style: .continuous)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(SudokuTheme.stroke, lineWidth: 3))
                    .shadow(color: .black.opacity(0.45), radius: 0, x: 5, y: 6)
                    .padding(.horizontal, 40)

                    HStack(spacing: 10) {
                        Button {
                            newGame()
                            withAnimation { showWin = false }
                        } label: {
                            Text("再来一局 ↺")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(SudokuTheme.ink)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(SudokuTheme.stroke, lineWidth: 2))
                        }
                        .buttonStyle(SudokuPressStyle())

                        Button {
                            onExit()
                        } label: {
                            Text("返回选择 ➜")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color(red: 27/255, green: 24/255, blue: 64/255))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(colors: [SudokuTheme.gold, Color(red: 212/255, green: 168/255, blue: 75/255)],
                                                   startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(SudokuTheme.ink, lineWidth: 2.5))
                        }
                        .buttonStyle(SudokuPressStyle())
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - 按压样式

private struct SudokuPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .offset(x: configuration.isPressed ? 2 : 0, y: configuration.isPressed ? 3 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
