import SwiftUI

// MARK: - N-Back 工作记忆训练（益智 · 专注力乐园）

enum NBackDifficulty: String, CaseIterable, Identifiable {
    case easy, medium, hard, fun, poker

    var id: String { rawValue }

    var name: String {
        switch self {
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        case .fun: return "趣味"
        case .poker: return "扑克"
        }
    }

    var desc: String {
        switch self {
        case .easy: return "数字 1-6，节奏慢，适合入门"
        case .medium: return "数字 1-9，节奏适中"
        case .hard: return "数字 1-9，节奏加快"
        case .fun: return "可爱图形，边玩边记"
        case .poker: return "扑克牌面，花色与点数"
        }
    }

    var stimulusLabel: String {
        switch self {
        case .easy, .medium, .hard: return "数字"
        case .fun: return "图形"
        case .poker: return "扑克"
        }
    }

    var paceLabel: String {
        switch self {
        case .easy: return "慢"
        case .medium: return "适中"
        case .hard: return "快"
        case .fun: return "适中"
        case .poker: return "稍快"
        }
    }

    /// 每格展示时长（秒）——越难越快
    var interval: Double {
        switch self {
        case .easy: return 3.2
        case .medium: return 2.5
        case .hard: return 1.9
        case .fun: return 2.5
        case .poker: return 2.2
        }
    }

    var trials: Int {
        switch self {
        case .easy: return 20
        case .medium: return 22
        case .hard: return 24
        case .fun: return 22
        case .poker: return 24
        }
    }

    var accent: Color {
        switch self {
        case .easy:   return Color(red: 0.30, green: 0.72, blue: 0.50)
        case .medium: return Color(red: 0.30, green: 0.55, blue: 0.82)
        case .hard:   return Color(red: 0.84, green: 0.42, blue: 0.30)
        case .fun:    return Color(red: 0.85, green: 0.45, blue: 0.62)
        case .poker:  return Color(red: 0.76, green: 0.60, blue: 0.24)
        }
    }
}

enum NBackSymbol: Hashable {
    case number(Int)
    case emoji(String)
    case card(suit: String, rank: String, red: Bool)
}

private enum NBackAnswer { case same, forgot, diff }

private struct NBackStats {
    var ok = 0
    var no = 0
    var fg = 0
}

enum NBackStore {
    private static func key(_ d: String, _ n: Int) -> String { "nback.best.\(d).\(n)" }

    static func best(_ d: String, _ n: Int) -> Int {
        UserDefaults.standard.integer(forKey: key(d, n))
    }

    @discardableResult
    static func update(_ d: String, _ n: Int, acc: Int) -> Bool {
        let old = best(d, n)
        if acc <= old { return false }
        UserDefaults.standard.set(acc, forKey: key(d, n))
        return true
    }

    static func hasAny() -> Bool {
        NBackDifficulty.allCases.contains { d in (1...4).contains { best(d.rawValue, $0) > 0 } }
    }
}

struct NBackView: View {
    let onExit: () -> Void

    private enum Phase { case setup, game, result }

    @State private var phase: Phase = .setup
    @State private var diff: NBackDifficulty = .easy
    @State private var n = 1

    @State private var symbols: [NBackSymbol] = []
    @State private var seq: [Int] = []
    @State private var idx = 0
    @State private var answered = false
    @State private var stats = NBackStats()
    @State private var feedback: Feedback? = nil
    @State private var barProgress: CGFloat = 1
    @State private var flow: Task<Void, Never>? = nil

    @State private var showHelp = false
    @State private var showStats = false
    @State private var accPct = 0

    private enum Feedback: Equatable {
        case correct, wrong, forgot(match: Bool)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            FieldBackground()
            decorations

            VStack(spacing: 0) {
                navBar
                switch phase {
                case .setup:  setupView
                case .game:   gameView
                case .result: resultView
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .sheet(isPresented: $showHelp) { helpSheet }
        .sheet(isPresented: $showStats) { statsSheet }
        .onDisappear { flow?.cancel() }
    }

    // MARK: - 顶栏

    private var navBar: some View {
        ZStack {
            HStack {
                GracefulBackButton(action: handleBack)
                Spacer()
            }
            Text("N-back 训练中心")
                .font(.system(size: 18, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }

    private func handleBack() {
        flow?.cancel()
        switch phase {
        case .setup:  onExit()
        case .game:   phase = .setup
        case .result: phase = .setup
        }
    }

    // MARK: - 首页 · 设置

    private var setupView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                titleBlock

                Text("选择难度")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .tracking(1)
                    .foregroundStyle(AppTheme.fieldInk)
                    .padding(.top, 22)
                    .padding(.bottom, 12)

                HStack(spacing: 8) {
                    ForEach(NBackDifficulty.allCases) { d in
                        difficultyChip(d)
                    }
                }

                Text(diff.desc)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .padding(.top, 12)

                badgeRow
                    .padding(.top, 10)

                Text("设置 n（当前 \(n)）")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .tracking(1)
                    .foregroundStyle(AppTheme.fieldInk)
                    .padding(.top, 24)
                    .padding(.bottom, 12)

                nStepper

                Button { startGame() } label: {
                    Text("开始挑战")
                        .font(.system(size: 19, weight: .heavy, design: .serif))
                        .tracking(3)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            LinearGradient(colors: [diff.accent, diff.accent.opacity(0.82)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: diff.accent.opacity(0.4), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
                .padding(.top, 26)

                HStack(spacing: 12) {
                    secondaryButton("查看成绩", "chart.bar.fill", Color(red: 0.25, green: 0.66, blue: 0.63)) {
                        showStats = true
                    }
                    secondaryButton("玩法说明", "questionmark.circle.fill", Color(red: 0.37, green: 0.56, blue: 0.82)) {
                        showHelp = true
                    }
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 30)
        }
    }

    private var titleBlock: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: 6) {
                Text("N-back 训练")
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .tracking(1)
                    .foregroundStyle(AppTheme.fieldInk)
                Text("工作记忆 · 抗干扰")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(red: 0.73, green: 0.63, blue: 0.95),
                                                  Color(red: 0.55, green: 0.44, blue: 0.90)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("🙂").font(.system(size: 30))
            }
            .frame(width: 72, height: 72)
            .shadow(color: Color(red: 0.55, green: 0.44, blue: 0.90).opacity(0.3), radius: 10, y: 4)
        }
        .padding(.top, 18)
    }

    private func difficultyChip(_ d: NBackDifficulty) -> some View {
        let on = d == diff
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { diff = d }
        } label: {
            Text(d.name)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(on ? .white : AppTheme.fieldOliveDeep)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(on ? AnyShapeStyle(LinearGradient(colors: [d.accent, d.accent.opacity(0.8)],
                                                                startPoint: .topLeading, endPoint: .bottomTrailing))
                                 : AnyShapeStyle(Color.white.opacity(0.88)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .strokeBorder(on ? d.accent : AppTheme.fieldOlive.opacity(0.28), lineWidth: 2)
                        )
                        .shadow(color: on ? d.accent.opacity(0.35) : .clear, radius: 7, y: 3)
                )
        }
        .buttonStyle(.plain)
    }

    private var badgeRow: some View {
        HStack(spacing: 8) {
            badge("刺激", diff.stimulusLabel, diff.accent)
            badge("节奏", diff.paceLabel, diff.accent)
            badge("题数", "\(diff.trials)", diff.accent)
        }
    }

    private func badge(_ k: String, _ v: String, _ c: Color) -> some View {
        HStack(spacing: 5) {
            Text(k)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.fieldMoss)
            Text(v)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(c)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(c.opacity(0.3), lineWidth: 1.5)
                )
        )
    }

    private var nStepper: some View {
        HStack(spacing: 12) {
            stepButton("−", enabled: n > 1) { if n > 1 { n -= 1 } }
            Text("\(n)")
                .font(.system(size: 26, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(AppTheme.fieldOlive.opacity(0.15), lineWidth: 2)
                        )
                )
            stepButton("+", enabled: n < 4) { if n < 4 { n += 1 } }
        }
    }

    private func stepButton(_ title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(
                        LinearGradient(colors: [Color(red: 0.95, green: 0.78, blue: 0.49),
                                                Color(red: 0.88, green: 0.66, blue: 0.31)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                )
                .shadow(color: Color(red: 0.88, green: 0.66, blue: 0.31).opacity(enabled ? 0.4 : 0), radius: 8, y: 4)
                .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func secondaryButton(_ title: String, _ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .bold))
                Text(title).font(.system(size: 15, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(LinearGradient(colors: [color, color.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .shadow(color: color.opacity(0.3), radius: 7, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 游戏

    private var gameView: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Text(diff.name)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                    Text("n=\(n)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(diff.accent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(hudPill(diff.accent))

                Spacer()

                Text("第 \(min(idx + 1, diff.trials)) / \(diff.trials) 题")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.fieldOliveDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(hudPill(AppTheme.fieldOlive))
            }
            .padding(.horizontal, 18)

            // 计时条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.fieldOlive.opacity(0.16))
                    Capsule()
                        .fill(LinearGradient(colors: [diff.accent.opacity(0.75), diff.accent],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, geo.size.width * barProgress))
                }
            }
            .frame(height: 7)
            .padding(.horizontal, 18)
            .padding(.top, 12)

            Spacer(minLength: 8)

            stimulusCard

            Spacer(minLength: 8)

            answerButtons
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
        }
    }

    private func hudPill(_ c: Color) -> some View {
        RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(Color.white.opacity(0.92))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(c.opacity(0.25), lineWidth: 2)
            )
    }

    private var stimulusCard: some View {
        let memo = idx < n
        return ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(feedbackBorderColor, lineWidth: 3)
                        .animation(.easeOut(duration: 0.15), value: feedback)   // 仅描边变色，不动布局
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.14), radius: 16, y: 8)

            VStack(spacing: 0) {
                // 顶部固定高度槽位：记忆提示出现/消失都不顶动数字
                ZStack {
                    if memo {
                        Text("先记住这个 · \(idx + 1)/\(n)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(diff.accent)
                    }
                }
                .frame(height: 22)

                ZStack {
                    if let sym = currentSymbol { symbolView(sym) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 底部固定高度槽位：反馈文字出现/消失都不顶动数字
                ZStack { feedbackText }
                    .frame(height: 22)
            }
            .padding(18)
        }
        .frame(height: 300)
        .padding(.horizontal, 18)
    }

    private var feedbackBorderColor: Color {
        switch feedback {
        case .correct: return Color(red: 0.30, green: 0.72, blue: 0.50)
        case .wrong: return Color(red: 0.86, green: 0.36, blue: 0.28)
        case .forgot: return Color(red: 0.88, green: 0.66, blue: 0.31)
        case .none: return AppTheme.fieldOlive.opacity(0.22)
        }
    }

    @ViewBuilder
    private var feedbackText: some View {
        switch feedback {
        case .correct:
            Text("✓ 答对").font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.30, green: 0.72, blue: 0.50))
        case .wrong:
            Text("✗ 答错了").font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.86, green: 0.36, blue: 0.28))
        case .forgot(let match):
            Text(match ? "其实是「一样」" : "其实是「不一样」")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.88, green: 0.66, blue: 0.31))
        case .none:
            Color.clear.frame(height: 18)
        }
    }

    private var currentSymbol: NBackSymbol? {
        guard seq.indices.contains(idx), symbols.indices.contains(seq[idx]) else { return nil }
        return symbols[seq[idx]]
    }

    @ViewBuilder
    private func symbolView(_ s: NBackSymbol) -> some View {
        switch s {
        case .number(let v):
            Text("\(v)")
                .font(.system(size: 130, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
        case .emoji(let e):
            Text(e).font(.system(size: 116))
        case .card(let suit, let rank, let red):
            VStack(spacing: -4) {
                Text(suit).font(.system(size: 78, weight: .black))
                Text(rank).font(.system(size: 68, weight: .black, design: .serif))
            }
            .foregroundStyle(red ? Color(red: 0.83, green: 0.27, blue: 0.27)
                                 : Color(red: 0.18, green: 0.18, blue: 0.18))
        }
    }

    private var answerButtons: some View {
        let disabled = idx < n || answered
        return HStack(spacing: 10) {
            answerButton("一样", "1", Color(red: 0.36, green: 0.75, blue: 0.55), disabled) { answer(.same) }
            answerButton("忘记了", "2", Color(red: 0.92, green: 0.72, blue: 0.35), disabled) { answer(.forgot) }
            answerButton("不一样", "3", Color(red: 0.88, green: 0.44, blue: 0.33), disabled) { answer(.diff) }
        }
    }

    private func answerButton(_ title: String, _ key: String, _ c: Color, _ disabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(title).font(.system(size: 16, weight: .heavy, design: .rounded))
                Text("按 \(key)").font(.system(size: 9, weight: .semibold, design: .rounded)).opacity(0.85)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [c, c.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .shadow(color: c.opacity(disabled ? 0 : 0.35), radius: 8, y: 4)
            .opacity(disabled ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    // MARK: - 结算

    private var resultView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.fieldOlive.opacity(0.15), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: CGFloat(accPct) / 100)
                        .stroke(
                            LinearGradient(colors: [diff.accent.opacity(0.75), diff.accent],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(accPct)%")
                            .font(.system(size: 30, weight: .black, design: .serif))
                            .foregroundStyle(diff.accent)
                        Text("正确率")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.fieldMoss)
                    }
                }
                .frame(width: 132, height: 132)
                .padding(.top, 20)

                Text(resultTitle)
                    .font(.system(size: 22, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .padding(.top, 14)
                Text(resultRank)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(diff.accent)
                    .padding(.top, 4)

                HStack(spacing: 10) {
                    statBox("答对", "\(stats.ok)", Color(red: 0.30, green: 0.72, blue: 0.50))
                    statBox("答错", "\(stats.no)", Color(red: 0.86, green: 0.36, blue: 0.28))
                    statBox("忘记", "\(stats.fg)", Color(red: 0.88, green: 0.66, blue: 0.31))
                }
                .padding(.top, 20)

                HStack(spacing: 12) {
                    Button { phase = .setup } label: {
                        Text("换难度")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.fieldInk)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.92))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    Button { startGame() } label: {
                        Text("再来一局")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(LinearGradient(colors: [diff.accent, diff.accent.opacity(0.82)],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                            )
                            .shadow(color: diff.accent.opacity(0.35), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 22)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 30)
        }
    }

    private func statBox(_ k: String, _ v: String, _ c: Color) -> some View {
        VStack(spacing: 3) {
            Text(v).font(.system(size: 20, weight: .black, design: .serif)).foregroundStyle(c)
            Text(k).font(.system(size: 10.5, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.18), lineWidth: 2)
                )
        )
    }

    private var resultTitle: String {
        switch accPct {
        case 90...: return "记忆超群！"
        case 75...: return "表现很棒！"
        case 60...: return "不错哦"
        case 40...: return "有点难吧"
        default:    return "继续加油"
        }
    }

    private var resultRank: String {
        switch accPct {
        case 90...: return "★★★★★ 大师级"
        case 75...: return "★★★★ 熟练"
        case 60...: return "★★★ 进阶"
        case 40...: return "★★ 入门"
        default:    return "★ 慢慢来"
        }
    }

    // MARK: - 弹窗

    private var helpSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("介绍")
                    .font(.system(size: 17, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 0.85, green: 0.45, blue: 0.62))
                Text("通过比较当前刺激与 n 步前刺激是否一致，训练工作记忆与反应控制。")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(AppTheme.fieldInk)
                    .lineSpacing(5)
                Text("玩法")
                    .font(.system(size: 17, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 0.85, green: 0.45, blue: 0.62))
                Text("看到图案后选择「一样 / 忘记了 / 不一样」，前 n 个先记忆，自动进入下一题。")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(AppTheme.fieldInk)
                    .lineSpacing(5)

                Button { showHelp = false } label: {
                    Text("知道了")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(LinearGradient(colors: [Color(red: 0.85, green: 0.45, blue: 0.62),
                                                              Color(red: 0.88, green: 0.36, blue: 0.55)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(24)
        }
        .presentationDetents([.medium])
    }

    private var statsSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("历史最好成绩")
                    .font(.system(size: 17, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .padding(.bottom, 4)

                let records = statsRecords()
                if records.isEmpty {
                    Text("暂无记录，先去挑战一局吧")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                        .padding(.vertical, 20)
                } else {
                    ForEach(records, id: \.key) { r in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(r.diff.name) · n=\(r.n)")
                                    .font(.system(size: 15, weight: .heavy, design: .serif))
                                    .foregroundStyle(AppTheme.fieldInk)
                                Text(r.diff.desc)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.fieldMoss)
                            }
                            Spacer()
                            Text("\(r.acc)%")
                                .font(.system(size: 22, weight: .black, design: .serif))
                                .foregroundStyle(r.diff.accent)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(r.diff.accent.opacity(0.25), lineWidth: 2)
                                )
                        )
                    }
                }

                Button { showStats = false } label: {
                    Text("返回")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.fieldInk)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)
                                )
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(24)
        }
    }

    private struct StatRecord { let key: String; let diff: NBackDifficulty; let n: Int; let acc: Int }

    private func statsRecords() -> [StatRecord] {
        var out: [StatRecord] = []
        for d in NBackDifficulty.allCases {
            for nn in 1...4 {
                let b = NBackStore.best(d.rawValue, nn)
                if b > 0 { out.append(StatRecord(key: "\(d.rawValue)-\(nn)", diff: d, n: nn, acc: b)) }
            }
        }
        return out
    }

    // MARK: - 流程

    private func startGame() {
        symbols = Self.symbols(for: diff)
        seq = Self.makeSequence(count: symbols.count, trials: diff.trials, n: n)
        idx = 0
        stats = NBackStats()
        feedback = nil
        phase = .game
        beginTrial()
    }

    private func beginTrial() {
        flow?.cancel()
        guard idx < diff.trials else { finish(); return }
        answered = false
        feedback = nil

        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) { barProgress = 1 }
        withAnimation(.linear(duration: diff.interval)) { barProgress = 0 }

        let trial = idx
        let interval = diff.interval
        let memo = trial < n
        flow = Task {
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            if Task.isCancelled { return }
            await MainActor.run {
                guard phase == .game, idx == trial else { return }
                if memo {
                    advance()
                } else if !answered {
                    answer(.forgot)
                }
            }
        }
    }

    private func answer(_ kind: NBackAnswer) {
        guard phase == .game, !answered, idx >= n else { return }
        answered = true
        flow?.cancel()

        let isMatch = seq[idx] == seq[idx - n]
        switch kind {
        case .same:
            if isMatch { stats.ok += 1; feedback = .correct } else { stats.no += 1; feedback = .wrong }
        case .diff:
            if !isMatch { stats.ok += 1; feedback = .correct } else { stats.no += 1; feedback = .wrong }
        case .forgot:
            stats.fg += 1
            feedback = .forgot(match: isMatch)
        }

        flow = Task {
            try? await Task.sleep(nanoseconds: 550_000_000)
            if Task.isCancelled { return }
            await MainActor.run { advance() }
        }
    }

    private func advance() {
        flow?.cancel()
        idx += 1
        if idx >= diff.trials { finish() } else { beginTrial() }
    }

    private func finish() {
        flow?.cancel()
        let graded = diff.trials - n
        accPct = graded > 0 ? Int((Double(stats.ok) / Double(graded) * 100).rounded()) : 0
        NBackStore.update(diff.rawValue, n, acc: accPct)
        phase = .result
    }

    // MARK: - 出题

    private static func symbols(for d: NBackDifficulty) -> [NBackSymbol] {
        switch d {
        case .easy:
            return (1...6).map { .number($0) }
        case .medium, .hard:
            return (1...9).map { .number($0) }
        case .fun:
            return ["🍎", "🐱", "⭐", "🎈", "🦋", "🍇", "🐶", "❤️"].map { .emoji($0) }
        case .poker:
            let suits = [("♠", false), ("♥", true), ("♦", true), ("♣", false)]
            let ranks = ["A", "2", "3", "4", "5", "6"]
            var out: [NBackSymbol] = []
            for (s, red) in suits {
                for r in ranks { out.append(.card(suit: s, rank: r, red: red)) }
            }
            return out
        }
    }

    private static func makeSequence(count: Int, trials: Int, n: Int) -> [Int] {
        var out: [Int] = []
        let matchRate = 0.35
        for i in 0..<trials {
            var v: Int
            if i < n {
                v = Int.random(in: 0..<count)
            } else if Double.random(in: 0..<1) < matchRate {
                v = out[i - n]
            } else {
                let forbid: Set<Int> = [out[i - n], out[i - 1]]
                repeat { v = Int.random(in: 0..<count) } while forbid.contains(v)
            }
            out.append(v)
        }
        return out
    }

    // MARK: - 背景点缀

    private var decorations: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color.white.opacity(0.5), .clear],
                                     center: .center, startRadius: 0, endRadius: 60))
                .frame(width: 120, height: 120)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 40)
                .padding(.top, 40)
        }
        .allowsHitTesting(false)
    }
}
