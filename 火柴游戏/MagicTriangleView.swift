import SwiftUI

// MARK: - 魔三角（益智 · 数理马戏团）

enum MagicTriangleDifficulty: String, CaseIterable, Identifiable {
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

    var lo: Int {
        switch self {
        case .qihang: return 1
        case .jinjie: return 2
        case .tiaozhan: return 3
        case .dashi: return 4
        }
    }

    var prefill: Int {
        switch self {
        case .qihang: return 2
        case .jinjie: return 1
        case .tiaozhan, .dashi: return 0
        }
    }

    var hintTarget: Bool { self == .qihang }

    var base: Int {
        switch self {
        case .qihang: return 700
        case .jinjie: return 800
        case .tiaozhan: return 900
        case .dashi: return 1000
        }
    }
}

enum MagicTriangleStore {
    private static func key(_ id: String) -> String { "magictriangle.best.\(id)" }

    static func best(_ id: String) -> Int { UserDefaults.standard.integer(forKey: key(id)) }

    @discardableResult
    static func update(_ id: String, score: Int) -> Bool {
        let old = best(id)
        if score <= old { return false }
        UserDefaults.standard.set(score, forKey: key(id))
        return true
    }

    static func hasAny() -> Bool {
        MagicTriangleDifficulty.allCases.contains { best($0.rawValue) > 0 }
    }
}

struct MagicTriangleView: View {
    let onExit: () -> Void

    @State private var diff: MagicTriangleDifficulty = .qihang
    @State private var values: [Int?] = Array(repeating: nil, count: 6)
    @State private var locked: [Bool] = Array(repeating: false, count: 6)
    @State private var tray: [Int] = []
    @State private var selected: Int? = nil
    @State private var solved = false
    @State private var moves = 0
    @State private var startDate = Date()
    @State private var showHelp = false
    @State private var toast: String? = nil
    @Namespace private var diffNS

    private let accent = Color(red: 0.93, green: 0.44, blue: 0.20)
    private let accentSoft = Color(red: 0.99, green: 0.93, blue: 0.88)

    // 节点：0顶角 1左下 2右下 3左边中 4右边中 5底边中
    private let pos: [CGPoint] = [
        CGPoint(x: 0.50, y: 0.09),
        CGPoint(x: 0.11, y: 0.86),
        CGPoint(x: 0.89, y: 0.86),
        CGPoint(x: 0.305, y: 0.475),
        CGPoint(x: 0.695, y: 0.475),
        CGPoint(x: 0.50, y: 0.86),
    ]
    private let sides: [(name: String, idx: [Int], chip: CGPoint)] = [
        ("左", [0, 3, 1], CGPoint(x: 0.17, y: 0.65)),
        ("右", [0, 4, 2], CGPoint(x: 0.83, y: 0.65)),
        ("底", [1, 5, 2], CGPoint(x: 0.50, y: 0.98)),
    ]

    private var magicSum: Int { 3 * diff.lo + 6 }

    var body: some View {
        ZStack {
            FieldBackground()
            decorations

            VStack(spacing: 0) {
                navBar
                difficultyBar
                goalLine
                boardArea
                trayArea
                footArea
            }

            // 通关提示
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
                .transition(.opacity)
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
        HStack(spacing: 8) {
            GracefulBackButton(action: onExit)
            Text("魔三角")
                .font(.system(size: 16, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
                .frame(maxWidth: .infinity)
            HStack(spacing: 8) {
                bestChip
                helpButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 2)
    }

    private var helpButton: some View {
        Button { showHelp = true } label: {
            Text("?")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(accent)
                .frame(width: 34, height: 34)
                .background(Circle().fill(accentSoft))
                .overlay(Circle().strokeBorder(accent.opacity(0.35), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private var bestChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(AppTheme.fieldGold)
            VStack(alignment: .leading, spacing: 0) {
                Text("最高分").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
                Text("\(MagicTriangleStore.best(diff.rawValue))")
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
            ForEach(MagicTriangleDifficulty.allCases) { d in
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

    private var goalLine: some View {
        Text(diff.hintTarget
             ? "目标：三条边的和都等于 \(magicSum)"
             : "目标：让三条边的和相同")
            .font(.system(size: 12.5, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.fieldMoss)
            .padding(.top, 12)
    }

    // MARK: 棋盘

    private var boardArea: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                Path { p in
                    p.move(to: cg(pos[0], side))
                    p.addLine(to: cg(pos[1], side))
                    p.addLine(to: cg(pos[2], side))
                    p.closeSubpath()
                }
                .stroke(AppTheme.fieldOlive.opacity(0.45), style: StrokeStyle(lineWidth: 3, lineJoin: .round))

                ForEach(Array(sides.enumerated()), id: \.offset) { _, s in
                    sideSumChip(s, side: side)
                }

                ForEach(0..<6, id: \.self) { i in
                    nodeView(i, side: side)
                }
            }
            .frame(width: side, height: side)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
    }

    private func cg(_ p: CGPoint, _ side: CGFloat) -> CGPoint {
        CGPoint(x: p.x * side, y: p.y * side)
    }

    private func nodeView(_ i: Int, side: CGFloat) -> some View {
        let d = side * 0.155
        let isSel = selected == i
        let hasValue = values[i] != nil
        return Button {
            tapNode(i)
        } label: {
            Text(values[i].map(String.init) ?? "?")
                .font(.system(size: d * 0.42, weight: .heavy, design: .serif))
                .foregroundStyle(hasValue ? AppTheme.fieldInk : (isSel ? accent : AppTheme.fieldMoss))
                .frame(width: d, height: d)
                .background(
                    Circle()
                        .fill(locked[i] ? Color(red: 0.90, green: 0.92, blue: 0.88)
                                        : (isSel ? accentSoft : Color.white))
                        .overlay(
                            Circle().strokeBorder(isSel ? accent : AppTheme.fieldOlive.opacity(0.35), lineWidth: isSel ? 3 : 2.5)
                        )
                        .shadow(color: AppTheme.fieldGrassShadow.opacity(0.12), radius: 4, y: 2)
                )
        }
        .buttonStyle(.plain)
        .position(cg(pos[i], side))
    }

    private func sideSumChip(_ s: (name: String, idx: [Int], chip: CGPoint), side: CGFloat) -> some View {
        let sum = s.idx.reduce(0) { $0 + (values[$1] ?? 0) }
        let filled = s.idx.allSatisfy { values[$0] != nil }
        let ok = filled && sum == magicSum
        return Text("\(s.name) \(filled ? "\(sum)" : "?")")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(ok ? Color(red: 0.20, green: 0.62, blue: 0.38) : AppTheme.fieldMoss)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(ok ? Color(red: 0.91, green: 0.97, blue: 0.92) : Color.white.opacity(0.92))
                    .overlay(Capsule().strokeBorder(ok ? Color(red: 0.20, green: 0.62, blue: 0.38).opacity(0.4) : AppTheme.fieldOlive.opacity(0.25), lineWidth: 1.5))
            )
            .position(cg(s.chip, side))
    }

    // MARK: 数字托盘

    private var trayArea: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
        return LazyVGrid(columns: cols, spacing: 10) {
            ForEach(diff.lo...(diff.lo + 5), id: \.self) { v in
                let used = values.contains(v)
                Button {
                    tapNumber(v)
                } label: {
                    Text("\(v)")
                        .font(.system(size: 22, weight: .heavy, design: .serif))
                        .foregroundStyle(used ? AppTheme.fieldMossLight : AppTheme.fieldInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(used ? Color.white.opacity(0.5) : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .strokeBorder(used ? AppTheme.fieldOlive.opacity(0.18) : AppTheme.fieldOlive.opacity(0.35),
                                                      style: StrokeStyle(lineWidth: 2, dash: used ? [5, 4] : []))
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(used)
                .opacity(used ? 0.55 : 1)
            }
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
        if solved { return "🎉 通关！三边都是 \(magicSum)" }
        let remain = values.filter { $0 == nil }.count
        return remain > 0 ? "还差 \(remain) 格" : "三边还不相等，再调调"
    }

    // MARK: 逻辑

    private func solution() -> [Int] {
        let a = diff.lo
        return [a, a + 1, a + 2, a + 5, a + 4, a + 3]
    }

    private func newGame() {
        let sol = solution()
        values = Array(repeating: nil, count: 6)
        locked = Array(repeating: false, count: 6)
        for i in 0..<diff.prefill { locked[i] = true; values[i] = sol[i] }
        var rest: [Int] = []
        for i in 0..<6 where !locked[i] { rest.append(sol[i]) }
        tray = rest.shuffled()
        selected = nil
        solved = false
        moves = 0
        startDate = Date()
    }

    private func tapNode(_ i: Int) {
        guard !solved, !locked[i] else { return }
        if let v = values[i] {
            values[i] = nil
            tray.append(v)
            moves += 1
            selected = i
        } else {
            selected = (selected == i) ? nil : i
        }
    }

    private func tapNumber(_ v: Int) {
        guard !solved else { return }
        guard let idx = tray.firstIndex(of: v) else { return }
        let at: Int
        if let s = selected, values[s] == nil { at = s }
        else if let first = values.firstIndex(where: { $0 == nil }) { at = first }
        else { return }
        values[at] = v
        tray.remove(at: idx)
        selected = nil
        moves += 1
        checkWin()
    }

    private func checkWin() {
        guard values.allSatisfy({ $0 != nil }) else { return }
        let sums = sides.map { s in s.idx.reduce(0) { $0 + (values[$1] ?? 0) } }
        guard sums.allSatisfy({ $0 == sums[0] }) else { return }
        solved = true
        let sec = max(0, Int(Date().timeIntervalSince(startDate)))
        let score = max(0, diff.base - sec * 4 - max(0, moves - 6) * 8)
        MagicTriangleStore.update(diff.rawValue, score: score)
        showToast("三边都是 \(sums[0])，得分 \(score)")
    }

    private func showToast(_ msg: String) {
        toast = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            if toast == msg { toast = nil }
        }
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
                    Text("✨").font(.system(size: i % 3 == 0 ? 15 : 12)).opacity(0.32)
                        .position(x: w * Double((i * 67) % 100) / 100,
                                  y: h * Double((i * 43) % 90) / 100)
                }
                ForEach(0..<6, id: \.self) { i in
                    Text(i % 2 == 0 ? "🌸" : "🌼").font(.system(size: i % 3 == 0 ? 20 : 16)).opacity(0.42)
                        .position(x: w * Double(i + 1) / 7, y: h - 30 - Double((i * 11) % 16))
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
                    Text("魔三角怎么玩")
                        .font(.system(size: 22, weight: .black, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                }
                VStack(alignment: .leading, spacing: 12) {
                    helpStep("1", "目标：让三条边的和相同。")
                    helpStep("2", "点三角形空位，再点右侧数字填入。")
                    helpStep("3", "角上的数会同时影响两条边。")
                    helpStep("4", "先试角点，再微调边上的点。")
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
