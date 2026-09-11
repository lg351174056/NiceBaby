import SwiftUI

// MARK: - 数阵方舟（益智 · 数理马戏团）

enum NumberArkDifficulty: String, CaseIterable, Identifiable {
    case qihang, jinjie, tiaozhan, dashi

    var id: String { rawValue }

    var name: String {
        switch self {
        case .qihang: return "启航"
        case .jinjie: return "进阶"
        case .tiaozhan: return "挑战"
        case .dashi: return "大师"
        }
    }

    var n: Int {
        switch self {
        case .qihang: return 3
        case .jinjie: return 4
        case .tiaozhan: return 6
        case .dashi: return 9
        }
    }

    var blanks: Int {
        switch self {
        case .qihang: return 4
        case .jinjie: return 8
        case .tiaozhan: return 14
        case .dashi: return 22
        }
    }

    var base: Int { n * 300 }
}

enum NumberArkStore {
    private static func key(_ id: String) -> String { "numberark.best.\(id)" }

    static func best(_ id: String) -> Int { UserDefaults.standard.integer(forKey: key(id)) }

    @discardableResult
    static func update(_ id: String, score: Int) -> Bool {
        let old = best(id)
        if score <= old { return false }
        UserDefaults.standard.set(score, forKey: key(id))
        return true
    }

    static func hasAny() -> Bool {
        NumberArkDifficulty.allCases.contains { best($0.rawValue) > 0 }
    }
}

struct NumberArkView: View {
    let onExit: () -> Void

    @State private var diff: NumberArkDifficulty = .qihang
    @State private var grid: [[Int]] = []
    @State private var given: [[Bool]] = []
    @State private var solution: [[Int]] = []
    @State private var selected: (r: Int, c: Int)? = nil
    @State private var solved = false
    @State private var mistakes = 0
    @State private var startDate = Date()
    @State private var showHelp = false
    @State private var toast: String? = nil
    @Namespace private var diffNS

    private let accent = Color(red: 0.13, green: 0.57, blue: 0.58)
    private let accentSoft = Color(red: 0.87, green: 0.95, blue: 0.93)

    var body: some View {
        GeometryReader { geo in
            let cs = cellSize(for: geo.size.width)
            ZStack {
                FieldBackground()
                decorations

                VStack(spacing: 0) {
                    navBar
                    difficultyBar
                    Spacer(minLength: 8)
                    gridView(cs: cs)
                    Spacer(minLength: 8)
                    trayArea
                    footArea
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack {
                    Spacer()
                    HStack {
                        Button { showHelp = true } label: {
                            Text("?").font(.system(size: 22, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 46, height: 46)
                                .background(Circle().fill(accent).shadow(color: accent.opacity(0.4), radius: 8, y: 4))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.leading, 18)
                    .padding(.bottom, 18)
                }

                if let toast {
                    VStack {
                        Spacer()
                        Text(toast)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20).padding(.vertical, 11)
                            .background(Capsule().fill(AppTheme.fieldInk.opacity(0.9)))
                            .padding(.bottom, 84)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .sheet(isPresented: $showHelp) { helpSheet }
        .onAppear { newGame() }
    }

    // MARK: 顶栏

    private var navBar: some View {
        HStack(spacing: 10) {
            GracefulBackButton(action: onExit)
            Text("数阵方舟")
                .font(.system(size: 16, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
                .frame(maxWidth: .infinity)
            bestChip
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 2)
    }

    private var bestChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(AppTheme.fieldGold)
            VStack(alignment: .leading, spacing: 0) {
                Text("最高分").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
                Text("\(NumberArkStore.best(diff.rawValue))")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.fieldInk)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(Color.white.opacity(0.9))
                .overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 1.5))
        )
    }

    // MARK: 难度

    private var difficultyBar: some View {
        HStack(spacing: 4) {
            ForEach(NumberArkDifficulty.allCases) { d in
                let on = d == diff
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { diff = d }
                    newGame()
                } label: {
                    Text(d.name)
                        .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(on ? .white : AppTheme.fieldOliveDeep)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if on {
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(LinearGradient(colors: [accent, accent.opacity(0.82)],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .shadow(color: accent.opacity(0.35), radius: 6, y: 3)
                                    .matchedGeometryEffect(id: "diffPill", in: diffNS)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Color.white.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.18), lineWidth: 1.5)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.06), radius: 5, y: 2)
        )
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    // MARK: 棋盘

    private func cellSize(for width: CGFloat) -> CGFloat {
        let spacing: CGFloat = 7
        let avail = max(120, width - 36)
        let cap: CGFloat = diff.n <= 3 ? 74 : (diff.n <= 4 ? 64 : (diff.n <= 6 ? 52 : 38))
        return max(28, min(cap, (avail - spacing * CGFloat(diff.n - 1)) / CGFloat(diff.n)))
    }

    private func gridView(cs: CGFloat) -> some View {
        let spacing: CGFloat = 7
        let total = cs * CGFloat(diff.n) + spacing * CGFloat(diff.n - 1)
        return LazyVGrid(columns: Array(repeating: GridItem(.fixed(cs), spacing: spacing), count: diff.n), spacing: spacing) {
            ForEach(0..<(diff.n * diff.n), id: \.self) { k in
                cellView(k / diff.n, k % diff.n, cs: cs)
            }
        }
        .frame(width: total)
        .frame(maxWidth: .infinity)
    }

    private func cellView(_ r: Int, _ c: Int, cs: CGFloat) -> some View {
        let value = grid.indices.contains(r) && grid[r].indices.contains(c) ? grid[r][c] : 0
        let isGiven = given.indices.contains(r) && given[r].indices.contains(c) ? given[r][c] : true
        let isSel = selected?.r == r && selected?.c == c
        let conflict = isConflict(r, c)
        return Button {
            tapCell(r, c)
        } label: {
            Text(value == 0 ? "" : "\(value)")
                .font(.system(size: cs * 0.5, weight: .heavy, design: .serif))
                .foregroundStyle(conflict ? Color(red: 0.78, green: 0.25, blue: 0.17)
                                          : (isGiven ? AppTheme.fieldInk : accent))
                .frame(width: cs, height: cs)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(conflict ? Color(red: 0.99, green: 0.90, blue: 0.88)
                                       : (isGiven ? Color(red: 0.91, green: 0.93, blue: 0.95)
                                                  : (value != 0 ? accentSoft : Color.white.opacity(0.92))))
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(conflict ? Color(red: 0.78, green: 0.25, blue: 0.17)
                                                       : (isSel ? accent : AppTheme.fieldOlive.opacity(0.25)),
                                              lineWidth: isSel || conflict ? 2.5 : 1.5)
                        )
                        .shadow(color: AppTheme.fieldGrassShadow.opacity(isSel ? 0.14 : 0.06), radius: isSel ? 6 : 3, y: 2)
                )
        }
        .buttonStyle(.plain)
        .disabled(isGiven)
    }

    private func isConflict(_ r: Int, _ c: Int) -> Bool {
        guard grid.indices.contains(r), grid[r].indices.contains(c) else { return false }
        let v = grid[r][c]
        guard v != 0 else { return false }
        let n = diff.n
        for k in 0..<n {
            if k != c, grid[r].indices.contains(k), grid[r][k] == v { return true }
            if k != r, grid.indices.contains(k), grid[k][c] == v { return true }
        }
        return false
    }

    // MARK: 数字托盘

    private var trayArea: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: min(diff.n, 5))
        return LazyVGrid(columns: cols, spacing: 8) {
            ForEach(1...diff.n, id: \.self) { v in
                Button { fill(v) } label: {
                    Text("\(v)")
                        .font(.system(size: 20, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(AppTheme.fieldOlive.opacity(0.28), lineWidth: 2)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            Button { fill(0) } label: {
                Text("擦除")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.78, green: 0.25, blue: 0.17))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(AppTheme.fieldOlive.opacity(0.22), lineWidth: 2)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var footArea: some View {
        HStack(spacing: 14) {
            Text(statusText)
                .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                .foregroundStyle(solved ? Color(red: 0.20, green: 0.62, blue: 0.38) : AppTheme.fieldOliveDeep)
            Button { newGame() } label: {
                Text("重开")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.fieldInk)
                    .padding(.horizontal, 20).padding(.vertical, 9)
                    .background(
                        Capsule().fill(Color.white.opacity(0.92))
                            .overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var statusText: String {
        if solved { return "🎉 完成！数阵已补全" }
        var empty = 0
        for r in 0..<diff.n { for c in 0..<diff.n where grid.indices.contains(r) && grid[r].indices.contains(c) && grid[r][c] == 0 { empty += 1 } }
        return "\(diff.n)×\(diff.n) 数阵：还剩 \(empty) 格"
    }

    // MARK: 逻辑

    private func newGame() {
        let (sol, g, gv) = Self.makePuzzle(diff.n, blanks: diff.blanks)
        solution = sol
        grid = g
        given = gv
        selected = nil
        solved = false
        mistakes = 0
        startDate = Date()
    }

    private func tapCell(_ r: Int, _ c: Int) {
        guard !solved, !given[r][c] else { return }
        if let s = selected, s.r == r, s.c == c { selected = nil }
        else { selected = (r, c) }
    }

    private func fill(_ v: Int) {
        guard !solved else { return }
        var target = selected
        if target == nil {
            loop: for r in 0..<diff.n {
                for c in 0..<diff.n where !given[r][c] && grid[r][c] == 0 { target = (r, c); break loop }
            }
        }
        guard let t = target, !given[t.r][t.c] else { return }
        grid[t.r][t.c] = v
        if v != 0 && v != solution[t.r][t.c] { mistakes += 1 }
        selected = (v == 0) ? nil : nextEditable(after: t)
        checkWin()
    }

    private func nextEditable(after t: (r: Int, c: Int)) -> (r: Int, c: Int)? {
        let n = diff.n
        var r = t.r, c = t.c
        for _ in 0..<(n * n) {
            c += 1
            if c >= n { c = 0; r += 1 }
            if r >= n { return nil }
            if !given[r][c] && grid[r][c] == 0 { return (r, c) }
        }
        return nil
    }

    private func checkWin() {
        let n = diff.n
        for r in 0..<n { for c in 0..<n where grid[r][c] == 0 { return } }
        for r in 0..<n { for c in 0..<n where isConflict(r, c) { return } }
        solved = true
        let sec = max(0, Int(Date().timeIntervalSince(startDate)))
        let score = max(0, diff.base - sec * 3 - mistakes * 12)
        NumberArkStore.update(diff.rawValue, score: score)
        toast = "完成！用时 \(sec)s，得分 \(score)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            if toast?.hasPrefix("完成") == true { toast = nil }
        }
    }

    // MARK: 生成（唯一解）

    private static func makeLatin(_ n: Int) -> [[Int]] {
        var out = Array(repeating: Array(repeating: 0, count: n), count: n)
        let base = (0..<n).map { r in (0..<n).map { c in (r + c) % n } }
        let rows = Array(0..<n).shuffled()
        let cols = Array(0..<n).shuffled()
        let sym = Array(1...n).shuffled()
        for r in 0..<n { for c in 0..<n { out[r][c] = sym[base[rows[r]][cols[c]]] } }
        return out
    }

    private static func countSolutions(_ g: inout [[Int]], _ n: Int, cap: Int) -> Int {
        var br = -1, bc = -1
        var best: [Int]? = nil
        outer: for r in 0..<n {
            for c in 0..<n {
                if g[r][c] != 0 { continue }
                var cs: [Int] = []
                for v in 1...n {
                    var ok = true
                    for k in 0..<n { if g[r][k] == v || g[k][c] == v { ok = false; break } }
                    if ok { cs.append(v) }
                }
                if cs.isEmpty { return 0 }
                if best == nil || cs.count < best!.count {
                    best = cs; br = r; bc = c
                    if cs.count == 1 { break outer }
                }
            }
        }
        guard let cands = best else { return 1 }
        var total = 0
        for v in cands {
            g[br][bc] = v
            total += countSolutions(&g, n, cap: cap)
            g[br][bc] = 0
            if total >= cap { break }
        }
        return total
    }

    private static func makePuzzle(_ n: Int, blanks: Int) -> ([[Int]], [[Int]], [[Bool]]) {
        let sol = makeLatin(n)
        var grid = sol
        var given = Array(repeating: Array(repeating: true, count: n), count: n)
        var cells: [(Int, Int)] = []
        for r in 0..<n { for c in 0..<n { cells.append((r, c)) } }
        cells.shuffle()
        var removed = 0
        for (r, c) in cells {
            if removed >= blanks { break }
            let keep = grid[r][c]
            grid[r][c] = 0
            var probe = grid
            if countSolutions(&probe, n, cap: 2) != 1 {
                grid[r][c] = keep
            } else {
                given[r][c] = false
                removed += 1
            }
        }
        return (sol, grid, given)
    }

    // MARK: 背景点缀

    private var decorations: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color(red: 1, green: 0.92, blue: 0.55), Color(red: 1, green: 0.78, blue: 0.30)],
                                         center: .center, startRadius: 0, endRadius: 32))
                    .frame(width: 62, height: 62).opacity(0.5)
                    .position(x: w * 0.85, y: h * 0.09)

                cloud.opacity(0.55).position(x: w * 0.16, y: h * 0.10)
                cloud.opacity(0.4).scaleEffect(0.7).position(x: w * 0.62, y: h * 0.05)

                ForEach(0..<10, id: \.self) { i in
                    Text("✨").font(.system(size: i % 3 == 0 ? 15 : 12)).opacity(0.30)
                        .position(x: w * Double((i * 71) % 100) / 100,
                                  y: h * Double((i * 37) % 90) / 100)
                }
                ForEach(0..<6, id: \.self) { i in
                    Text(i % 2 == 0 ? "🪷" : "🌿").font(.system(size: i % 3 == 0 ? 20 : 16)).opacity(0.40)
                        .position(x: w * Double(i + 1) / 7, y: h - 30 - Double((i * 13) % 16))
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
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Text("?").font(.system(size: 24, weight: .black))
                        .foregroundStyle(accent)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(accentSoft))
                    Text("数阵方舟怎么玩")
                        .font(.system(size: 22, weight: .black, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                }
                VStack(alignment: .leading, spacing: 12) {
                    helpStep("1", "目标：补完整张矩阵。")
                    helpStep("2", "点空格，再点数字填入。")
                    helpStep("3", "每一行、每一列都不能重复。")
                    helpStep("4", "优先看已经出现最多数字的行列，减少试错。")
                }
                Button { showHelp = false } label: {
                    Text("知道了")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Capsule().fill(accent))
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(24)
        }
        .presentationDetents([.medium])
    }

    private func helpStep(_ n: String, _ t: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n).font(.system(size: 15, weight: .black, design: .rounded)).foregroundStyle(accent)
            Text(t).font(.system(size: 15.5, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
