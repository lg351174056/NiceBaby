import SwiftUI
import Combine

// MARK: - 汉诺塔（益智 · 数理马戏团）

enum HanoiDifficulty: String, CaseIterable, Identifiable {
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

    var disks: Int {
        switch self {
        case .qihang: return 3
        case .jinjie: return 4
        case .tiaozhan: return 5
        case .dashi: return 6
        }
    }

    var minMoves: Int { (1 << disks) - 1 }
}

enum HanoiStore {
    private static func key(_ id: String) -> String { "hanoi.best.\(id)" }

    static func best(_ id: String) -> Int { UserDefaults.standard.integer(forKey: key(id)) }

    @discardableResult
    static func update(_ id: String, score: Int) -> Bool {
        let old = best(id)
        if score <= old { return false }
        UserDefaults.standard.set(score, forKey: key(id))
        return true
    }

    static func hasAny() -> Bool {
        HanoiDifficulty.allCases.contains { best($0.rawValue) > 0 }
    }
}

struct HanoiTowerView: View {
    let onExit: () -> Void

    @State private var diff: HanoiDifficulty = .qihang
    @State private var pegs: [[Int]] = [[], [], []]      // 由底到顶
    @State private var selectedPeg: Int? = nil
    @State private var invalidPeg: Int? = nil
    @State private var moves = 0
    @State private var solved = false
    @State private var startDate = Date()
    @State private var elapsed = 0
    @State private var history: [(from: Int, to: Int)] = []
    @State private var showHelp = false
    @State private var toast: String? = nil
    @Namespace private var diffNS

    private let accent = Color(red: 0.48, green: 0.36, blue: 0.88)
    private let accentSoft = Color(red: 0.94, green: 0.92, blue: 0.99)

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            FieldBackground()
            decorations

            VStack(spacing: 0) {
                navBar
                difficultyBar
                statBar
                boardArea
                footArea
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

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
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .sheet(isPresented: $showHelp) { helpSheet }
        .onAppear { newGame() }
        .onReceive(ticker) { _ in
            if !solved { elapsed = max(0, Int(Date().timeIntervalSince(startDate))) }
        }
    }

    // MARK: 顶栏

    private var navBar: some View {
        HStack(spacing: 8) {
            GracefulBackButton(action: onExit)
            Text("汉诺塔")
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
                Text("\(HanoiStore.best(diff.rawValue))")
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
            ForEach(HanoiDifficulty.allCases) { d in
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

    // MARK: 状态

    private var statBar: some View {
        HStack(spacing: 12) {
            statChip("步数", "\(moves)")
            statChip("最少", "\(diff.minMoves)")
            statChip("用时", "\(elapsed)s")
        }
        .padding(.top, 14)
    }

    private func statChip(_ k: String, _ v: String) -> some View {
        HStack(spacing: 5) {
            Text(k).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
            Text(v).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(accent)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(
            Capsule().fill(Color.white.opacity(0.9))
                .overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.2), lineWidth: 1.5))
        )
    }

    // MARK: 棋盘

    private var boardArea: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height
            let pegW = W / 3
            let baseH: CGFloat = 18
            let poleH = H * 0.50
            let diskH = min(26, max(14, (poleH * 0.9) / CGFloat(diff.disks)))
            let gap: CGFloat = 3

            ZStack(alignment: .topLeading) {
                // 底座 + 立柱 + 顶帽
                ForEach(0..<3, id: \.self) { i in
                    let cx = pegW * (CGFloat(i) + 0.5)
                    let hot = invalidPeg == i
                    let armed = selectedPeg == i

                    // 底座
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(LinearGradient(colors: [Color(red: 0.72, green: 0.76, blue: 0.79),
                                                      Color(red: 0.55, green: 0.60, blue: 0.64)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: pegW * 0.84, height: baseH)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(hot ? Color.red.opacity(0.7) : Color.white.opacity(0.25), lineWidth: 1.5)
                        )
                        .shadow(color: AppTheme.fieldGrassShadow.opacity(0.18), radius: 6, y: 4)
                        .position(x: cx, y: H - baseH / 2)

                    // 立柱
                    Capsule()
                        .fill(LinearGradient(colors: [Color(red: 0.80, green: 0.84, blue: 0.87),
                                                      Color(red: 0.60, green: 0.65, blue: 0.69)],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: 16, height: poleH)
                        .overlay(
                            Capsule().fill(Color.white.opacity(0.35)).frame(width: 4).offset(x: -3)
                        )
                        .position(x: cx, y: H - baseH - poleH / 2)

                    // 顶帽
                    Circle()
                        .fill(armed ? accent : Color(red: 0.72, green: 0.77, blue: 0.80))
                        .frame(width: 24, height: 24)
                        .shadow(color: AppTheme.fieldGrassShadow.opacity(0.2), radius: 3, y: 2)
                        .position(x: cx, y: H - baseH - poleH)

                    // 柱子点按热区
                    Color.clear
                        .frame(width: pegW * 0.96, height: H)
                        .contentShape(Rectangle())
                        .position(x: cx, y: H / 2)
                        .onTapGesture { tapPeg(i) }
                }

                // 圆盘（每个盘只渲染一次，位置变化自动弹簧动画）
                ForEach(1...diff.disks, id: \.self) { s in
                    if let loc = locate(s) {
                        let cx = pegW * (CGFloat(loc.peg) + 0.5)
                        let cy = H - baseH - CGFloat(loc.index) * (diskH + gap) - diskH / 2
                        let lifted = (selectedPeg == loc.peg && loc.index == pegs[loc.peg].count - 1)
                        diskView(s, diskH: diskH)
                            .frame(width: diskWidth(s, pegW: pegW))
                            .position(x: cx, y: cy - (lifted ? diskH * 0.75 : 0))
                            .shadow(color: diskTheme(s).2.opacity(lifted ? 0.5 : 0.28),
                                    radius: lifted ? 10 : 4, y: lifted ? 8 : 3)
                            .zIndex(lifted ? 10 : Double(s))
                    }
                }
            }
            .animation(.spring(response: 0.34, dampingFraction: 0.74), value: pegs)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: selectedPeg)
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 立体光泽圆盘
    private func diskView(_ s: Int, diskH: CGFloat) -> some View {
        let c = diskTheme(s)
        return ZStack {
            RoundedRectangle(cornerRadius: diskH / 2, style: .continuous)
                .fill(LinearGradient(colors: [c.0, c.1, c.2], startPoint: .top, endPoint: .bottom))
                .overlay(
                    // 顶部高光
                    RoundedRectangle(cornerRadius: diskH / 2, style: .continuous)
                        .fill(LinearGradient(colors: [Color.white.opacity(0.65), .clear],
                                             startPoint: .top, endPoint: .center))
                        .padding(.horizontal, 5)
                        .padding(.top, 2.5)
                        .frame(height: diskH * 0.5)
                        .frame(maxHeight: .infinity, alignment: .top)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: diskH / 2, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                )
            Text("\(s)")
                .font(.system(size: diskH * 0.5, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .shadow(color: c.2.opacity(0.6), radius: 1, y: 1)
        }
        .frame(height: diskH)
    }

    private func pegIndexOf(_ s: Int) -> Int? { locate(s)?.peg }
    private func locate(_ s: Int) -> (peg: Int, index: Int)? {
        for p in 0..<3 {
            if let idx = pegs[p].firstIndex(of: s) { return (p, idx) }
        }
        return nil
    }

    private func diskWidth(_ s: Int, pegW: CGFloat) -> CGFloat {
        let n = diff.disks
        let minW = pegW * 0.34
        let maxW = pegW * 0.90
        guard n > 1 else { return maxW }
        let t = CGFloat(s - 1) / CGFloat(n - 1)
        return minW + (maxW - minW) * t
    }

    private func diskTheme(_ s: Int) -> (Color, Color, Color) {
        switch (s - 1) % 7 {
        case 0: return (Color(red: 0.77, green: 0.71, blue: 0.99), Color(red: 0.65, green: 0.54, blue: 0.98), Color(red: 0.49, green: 0.23, blue: 0.93))
        case 1: return (Color(red: 0.58, green: 0.77, blue: 0.99), Color(red: 0.38, green: 0.65, blue: 0.98), Color(red: 0.15, green: 0.39, blue: 0.92))
        case 2: return (Color(red: 0.43, green: 0.91, blue: 0.72), Color(red: 0.20, green: 0.83, blue: 0.60), Color(red: 0.02, green: 0.59, blue: 0.41))
        case 3: return (Color(red: 0.99, green: 0.83, blue: 0.30), Color(red: 0.98, green: 0.75, blue: 0.14), Color(red: 0.85, green: 0.47, blue: 0.02))
        case 4: return (Color(red: 0.99, green: 0.65, blue: 0.65), Color(red: 0.97, green: 0.44, blue: 0.44), Color(red: 0.86, green: 0.15, blue: 0.15))
        case 5: return (Color(red: 0.98, green: 0.66, blue: 0.83), Color(red: 0.96, green: 0.45, blue: 0.71), Color(red: 0.86, green: 0.15, blue: 0.47))
        default: return (Color(red: 0.65, green: 0.95, blue: 0.99), Color(red: 0.13, green: 0.83, blue: 0.93), Color(red: 0.03, green: 0.57, blue: 0.70))
        }
    }

    private var footArea: some View {
        VStack(spacing: 12) {
            Text(statusText)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(solved ? Color(red: 0.20, green: 0.62, blue: 0.38) : AppTheme.fieldOliveDeep)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: 14) {
                Button { undo() } label: {
                    Text("撤销")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(history.isEmpty ? AppTheme.fieldMossLight : AppTheme.fieldInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Capsule().fill(Color.white.opacity(0.92))
                                .overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.28), lineWidth: 2))
                        )
                }
                .buttonStyle(.plain)
                .disabled(history.isEmpty)

                Button { newGame() } label: {
                    Text("重开")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Capsule().fill(LinearGradient(colors: [accent, accent.opacity(0.82)],
                                                          startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .shadow(color: accent.opacity(0.3), radius: 7, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 18)
    }

    private var statusText: String {
        if solved { return "🎉 完成！\(moves) 步（最少 \(diff.minMoves)）" }
        if selectedPeg != nil { return "已选中，点另一根柱子放下" }
        return "把所有盘移到最右「目标」柱"
    }

    // MARK: 逻辑

    private func newGame() {
        let n = diff.disks
        pegs = [Array((1...n).reversed()), [], []]
        selectedPeg = nil
        invalidPeg = nil
        moves = 0
        history = []
        solved = false
        startDate = Date()
        elapsed = 0
    }

    private func tapPeg(_ i: Int) {
        guard !solved else { return }
        if let sel = selectedPeg {
            if sel == i { selectedPeg = nil; return }
            guard let disk = pegs[sel].last else { selectedPeg = nil; return }
            let top = pegs[i].last
            if top == nil || disk < top! {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.74)) {
                    pegs[sel].removeLast()
                    pegs[i].append(disk)
                }
                history.append((sel, i))
                moves += 1
                selectedPeg = nil
                checkWin()
            } else {
                invalidFlash(i)
                selectedPeg = nil
                showToast("大盘不能压在小盘上")
            }
        } else {
            if pegs[i].isEmpty {
                invalidFlash(i)
                showToast("这根柱子是空的")
            } else {
                selectedPeg = i
            }
        }
    }

    private func undo() {
        guard !solved, let last = history.popLast() else { return }
        guard let disk = pegs[last.to].last else { return }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.74)) {
            pegs[last.to].removeLast()
            pegs[last.from].append(disk)
        }
        moves = max(0, moves - 1)
        selectedPeg = nil
    }

    private func invalidFlash(_ i: Int) {
        invalidPeg = i
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if invalidPeg == i { invalidPeg = nil }
        }
    }

    private func checkWin() {
        guard pegs[2].count == diff.disks else { return }
        solved = true
        let extra = max(0, moves - diff.minMoves)
        let score = max(1, diff.minMoves * 100 - extra * 30 - elapsed * 2)
        HanoiStore.update(diff.rawValue, score: score)
        showToast("完成！\(moves) 步 · 得分 \(score)")
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
                    Text("✨").font(.system(size: i % 3 == 0 ? 15 : 12)).opacity(0.30)
                        .position(x: w * Double((i * 73) % 100) / 100,
                                  y: h * Double((i * 41) % 90) / 100)
                }
                ForEach(0..<6, id: \.self) { i in
                    Text(i % 2 == 0 ? "🌼" : "🌿").font(.system(size: i % 3 == 0 ? 20 : 16)).opacity(0.40)
                        .position(x: w * Double(i + 1) / 7, y: h - 30 - Double((i * 17) % 16))
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
                    Text("汉诺塔怎么玩")
                        .font(.system(size: 22, weight: .black, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                }
                VStack(alignment: .leading, spacing: 12) {
                    helpStep("1", "目标：把所有盘移动到目标柱。")
                    helpStep("2", "点一个柱子选中最上面的盘。")
                    helpStep("3", "再点目标柱移动。")
                    helpStep("4", "大盘不能压在小盘上，先把小盘当成一个整体搬开。")
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
