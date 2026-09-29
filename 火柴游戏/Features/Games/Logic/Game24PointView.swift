import SwiftUI
import Combine

// MARK: - 24点速算（益智 · 数理马戏团）

struct Game24PointView: View {
    let onExit: () -> Void

    enum Difficulty: String, CaseIterable, Identifiable {
        case easy
        case standard
        case hard

        var id: String { rawValue }

        var title: String {
            switch self {
            case .easy: return "简单练习"
            case .standard: return "标准速算"
            case .hard: return "王者挑战"
            }
        }

        var desc: String {
            switch self {
            case .easy: return "数字 1-6 · 适合初学"
            case .standard: return "数字 1-10 · 常规挑战"
            case .hard: return "数字 1-13 · 带大数更难"
            }
        }

        var range: ClosedRange<Int> {
            switch self {
            case .easy: return 1...6
            case .standard: return 1...10
            case .hard: return 1...13
            }
        }

        var total: Int { 10 }

        var color: Color {
            switch self {
            case .easy: return Color(red: 0.28, green: 0.79, blue: 0.52)
            case .standard: return Color(red: 0.18, green: 0.62, blue: 0.43)
            case .hard: return Color(red: 0.85, green: 0.60, blue: 0.15)
            }
        }

        var storeKey: String {
            switch self {
            case .easy: return "easy"
            case .standard: return "normal"
            case .hard: return "hard"
            }
        }
    }

    @State private var difficulty: Difficulty? = nil
    @State private var cards: [Double] = []
    @State private var originalCards: [Double] = []
    @State private var selected: [Int] = []
    @State private var pendingOp: String? = nil
    @State private var steps: [String] = []
    @State private var qIndex = 1
    @State private var score = 0
    @State private var streak = 0
    @State private var maxStreak = 0
    @State private var roundStart = Date()
    @State private var elapsed = 0.0
    @State private var solved = false
    @State private var feedback = ""
    @State private var showSuccess = false
    @State private var showResult = false
    @State private var showRef = false
    @State private var refSolutions: [[String]] = []
    @State private var bestScore = 0
    @State private var newRecord = false

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            FieldBackground()
            backgroundDecorations

            if difficulty == nil {
                menuView
            } else {
                gameView
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(timer) { _ in
            guard difficulty != nil, !showResult else { return }
            elapsed = Date().timeIntervalSince(roundStart)
        }
    }

    // MARK: - 儿童背景点缀

    private var backgroundDecorations: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // 小太阳
                Circle()
                    .fill(
                        RadialGradient(colors: [Color(red: 1.0, green: 0.92, blue: 0.55),
                                                Color(red: 1.0, green: 0.78, blue: 0.30)],
                                       center: .center, startRadius: 0, endRadius: 34)
                    )
                    .frame(width: 68, height: 68)
                    .opacity(0.45)
                    .position(x: w * 0.15, y: h * 0.10)

                // 云朵
                cloud
                    .opacity(0.5)
                    .position(x: w * 0.78, y: h * 0.12)
                cloud
                    .opacity(0.35)
                    .scaleEffect(0.7)
                    .position(x: w * 0.35, y: h * 0.22)

                // 小星星
                ForEach(0..<12, id: \.self) { i in
                    Text("✨")
                        .font(.system(size: i % 3 == 0 ? 16 : 13))
                        .opacity(0.35)
                        .position(x: w * Double((i * 73) % 100) / 100,
                                  y: h * Double((i * 41) % 100) / 100)
                }

                // 底部花草
                ForEach(0..<7, id: \.self) { i in
                    Text(i % 2 == 0 ? "🌸" : "🌼")
                        .font(.system(size: i % 3 == 0 ? 22 : 18))
                        .opacity(0.45)
                        .position(x: w * Double(i + 1) / 8,
                                  y: h - 34 - Double((i * 13) % 20))
                }
            }
            .allowsHitTesting(false)
        }
    }

    private var cloud: some View {
        HStack(spacing: -6) {
            Circle().fill(Color.white.opacity(0.6)).frame(width: 30, height: 30)
            Circle().fill(Color.white.opacity(0.5)).frame(width: 38, height: 38)
            Circle().fill(Color.white.opacity(0.45)).frame(width: 26, height: 26)
        }
    }

    // MARK: - 菜单

    private var menuView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                GracefulBackButton(action: onExit)
                Spacer()
                Text("24点速算")
                    .font(.system(size: 18, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Text("🧮")
                .font(.system(size: 50))
                .padding(.top, 22)

            Text("24 点速算")
                .font(.system(size: 34, weight: .black, design: .serif))
                .tracking(3)
                .foregroundStyle(AppTheme.fieldInk)
                .padding(.top, 10)

            Text("4 张数字牌，加减乘除两两合并凑 24")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.fieldMoss)
                .padding(.top, 6)
                .padding(.bottom, 28)

            VStack(spacing: 14) {
                ForEach(Difficulty.allCases) { level in
                    Button {
                        startGame(level)
                    } label: {
                        HStack(spacing: 16) {
                            Text(level.color == Color(red: 0.85, green: 0.60, blue: 0.15) ? "👑" : "⚡")
                                .font(.system(size: 30))
                                .frame(width: 62, height: 62)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(level.color)
                                )
                                .shadow(color: level.color.opacity(0.4), radius: 8, y: 4)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.title)
                                    .font(.system(size: 18, weight: .heavy, design: .serif))
                                    .foregroundStyle(AppTheme.fieldInk)
                                Text(level.desc)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.fieldMoss)
                                let best = Game24PointStore.bestScore(for: level.storeKey)
                                Text(best > 0 ? "最佳 \(best) 分" : "还没玩过")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(best > 0 ? level.color : AppTheme.fieldMossLight)
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .strokeBorder(AppTheme.fieldOlive.opacity(0.22), lineWidth: 2)
                                )
                                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.1), radius: 8, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 6) {
                Text("玩法")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(AppTheme.fieldMoss)
                Text("先选 2 个数字，再点运算符得到新数字继续合并；最终合并成 24 即成功。")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.fieldMoss)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(AppTheme.fieldOlive.opacity(0.18), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
            .padding(.top, 18)

            Spacer()
        }
    }

    // MARK: - 游戏界面

    private var gameView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                GracefulBackButton(action: onExit)

                Text("24点速算 · \(difficulty?.title ?? "")")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .frame(maxWidth: .infinity)

                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "stopwatch.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(String(format: "%.1fs", elapsed))
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.fieldInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.8)))
                    .overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.2), lineWidth: 1))
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Spacer(minLength: 14)

            VStack(spacing: 0) {
                HStack {
                    Text("第 \(qIndex)/\(difficulty?.total ?? 10) 题")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(AppTheme.fieldInk)
                    Spacer()
                    Text("\(score) 分")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Color(red: 0.85, green: 0.60, blue: 0.15))
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 8)

            Text(promptText)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.fieldMoss)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)

            // 数字卡
            HStack(spacing: 10) {
                ForEach(Array(cards.enumerated()), id: \.offset) { idx, v in
                    Button {
                        selectCard(idx)
                    } label: {
                        Text(fmt(v))
                            .font(.system(size: cardFontSize, weight: .black, design: .serif))
                            .foregroundStyle(AppTheme.fieldInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: cardSize)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(selected.contains(idx)
                                          ? Color(red: 1.0, green: 0.95, blue: 0.78)
                                          : Color.white.opacity(0.92))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(selected.contains(idx)
                                                  ? Color(red: 0.85, green: 0.60, blue: 0.15)
                                                  : AppTheme.fieldOlive.opacity(0.2),
                                                  lineWidth: selected.contains(idx) ? 3 : 1.5)
                            )
                            .shadow(color: AppTheme.fieldGrassShadow.opacity(0.1), radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 12)

            // 运算符
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(["+", "-", "×", "÷"], id: \.self) { op in
                    Button {
                        chooseOperator(op)
                    } label: {
                        let isDisabled = selected.isEmpty
                        Text(op)
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(isDisabled
                                             ? Color(red: 0.62, green: 0.68, blue: 0.65)
                                             : pendingOp == op
                                             ? Color(red: 0.85, green: 0.60, blue: 0.15)
                                             : AppTheme.fieldInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isDisabled
                                          ? Color(red: 0.86, green: 0.89, blue: 0.88)
                                          : pendingOp == op
                                          ? Color(red: 1.0, green: 0.95, blue: 0.78)
                                          : Color.white.opacity(0.92))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(isDisabled
                                                  ? Color(red: 0.68, green: 0.73, blue: 0.71)
                                                  : pendingOp == op
                                                  ? Color(red: 0.85, green: 0.60, blue: 0.15)
                                                  : AppTheme.fieldOlive.opacity(0.2),
                                                  lineWidth: isDisabled ? 1 : (pendingOp == op ? 2 : 1))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(selected.isEmpty)
                }
            }
            .padding(.bottom, 10)

            // 操作行
            HStack(spacing: 8) {
                buttonGhost("重置本题") { setupQuestion() }
                buttonGhost("换一组") { advance() }
                buttonYellow("参考答案") { openReference() }
            }
            .padding(.bottom, 10)

            Text(feedback)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(feedbackColor)
                .frame(minHeight: 26)
                .padding(.bottom, 6)

            // 步骤历史
            VStack(alignment: .leading, spacing: 4) {
                if steps.isEmpty {
                    Text("操作步骤会记录在这里")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.fieldMossLight)
                } else {
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                        Text("\(i + 1). \(step)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.fieldInk)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(AppTheme.fieldOlive.opacity(0.16), lineWidth: 1)
                    )
            )
            }

            Spacer(minLength: 14)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay {
            if showSuccess {
                successOverlay
            } else if showRef {
                referenceOverlay
            } else if showResult {
                resultOverlay
            }
        }
    }

    private func buttonGhost(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(AppTheme.fieldInk)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.93, green: 0.96, blue: 0.93))
                )
        }
        .buttonStyle(.plain)
    }

    private func buttonYellow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.85, green: 0.60, blue: 0.15))
                )
        }
        .buttonStyle(.plain)
    }

    private var promptText: String {
        if selected.isEmpty { return "请选择两个数字" }
        if selected.count == 1 {
            if let op = pendingOp {
                return "已选 \(fmt(cards[selected[0]])) \(op)，请再选一个数字"
            }
            return "已选一个数字，请选运算符或再选一个数字"
        }
        return "请选择运算符"
    }

    private var feedbackColor: Color {
        if feedback.contains("⚠️") || feedback.contains("不是 24") {
            return Color(red: 0.75, green: 0.35, blue: 0.35)
        }
        if feedback.contains("🎉") || feedback.contains("成功") {
            return Color(red: 0.16, green: 0.62, blue: 0.36)
        }
        return AppTheme.fieldMoss
    }

    private var cardFontSize: CGFloat {
        switch cards.count {
        case 3: return 30
        case 2: return 34
        default: return 26
        }
    }

    private var cardSize: CGFloat {
        switch cards.count {
        case 3: return 70
        case 2: return 80
        default: return 76
        }
    }

    // MARK: - 游戏逻辑

    private func startGame(_ level: Difficulty) {
        difficulty = level
        score = 0
        streak = 0
        maxStreak = 0
        qIndex = 1
        roundStart = Date()
        elapsed = 0
        bestScore = Game24PointStore.bestScore(for: level.storeKey)
        showResult = false
        showRef = false
        showSuccess = false
        newRecord = false
        setupQuestion()
    }

    private func setupQuestion() {
        guard let difficulty else { return }
        let preferSimple = difficulty != .hard
        var arr: [Double] = []
        var tryCount = 0
        repeat {
            arr = (0..<4).map { _ in Double(Int.random(in: difficulty.range)) }
            tryCount += 1
            if preferSimple {
                if !collectSolutions(arr, max: 1, simpleOnly: true).isEmpty { break }
                if tryCount >= 40 && !collectSolutions(arr, max: 1, simpleOnly: false).isEmpty { break }
            } else if !collectSolutions(arr, max: 1, simpleOnly: false).isEmpty {
                break
            }
        } while tryCount < 100
        if collectSolutions(arr, max: 1, simpleOnly: false).isEmpty {
            arr = [1, 1, 8, 8]
        }

        cards = arr
        originalCards = arr
        selected = []
        pendingOp = nil
        steps = []
        solved = false
        feedback = ""
        showSuccess = false
        refSolutions = []
    }

    private func selectCard(_ i: Int) {
        guard !solved else { return }
        if let idx = selected.firstIndex(of: i) {
            selected.remove(at: idx)
            if selected.isEmpty { pendingOp = nil }
            return
        }
        if pendingOp != nil {
            if selected.count == 1 {
                selected.append(i)
                let op = pendingOp!
                pendingOp = nil
                combineAndMerge(op)
                return
            }
            return
        }
        if selected.count < 2 {
            selected.append(i)
        }
    }

    private func chooseOperator(_ op: String) {
        guard !solved else { return }
        if selected.count == 2 {
            pendingOp = nil
            combineAndMerge(op)
        } else if selected.count == 1 {
            pendingOp = op
        }
    }

    private func combineAndMerge(_ op: String) {
        guard !solved, selected.count == 2 else { return }
        let a = cards[selected[0]]
        let b = cards[selected[1]]
        var val: Double = 0
        switch op {
        case "+": val = a + b
        case "-": val = a - b
        case "×": val = a * b
        default:
            if abs(b) < 1e-9 {
                feedback = "⚠️ 不能除以 0"
                return
            }
            val = a / b
        }

        var newCards: [Double] = []
        for (i, c) in cards.enumerated() where !selected.contains(i) {
            newCards.append(c)
        }
        newCards.append(val)
        cards = newCards
        steps.append("\(fmt(a)) \(op) \(fmt(b)) = \(fmt(val))")
        selected = []
        pendingOp = nil

        if cards.count == 1 {
            if abs(cards[0] - 24) < 1e-6 {
                solved = true
                score += 1
                streak += 1
                maxStreak = max(maxStreak, streak)
                feedback = "🎉 成功得到 24！"
                checkBest()
                showSuccess = true
            } else {
                feedback = "⚠️ 最终结果是 \(fmt(cards[0]))，不是 24"
            }
        }
    }

    private func advance() {
        guard let difficulty else { return }
        qIndex += 1
        if qIndex > difficulty.total {
            finish()
        } else {
            setupQuestion()
        }
    }

    private func checkBest() {
        guard let difficulty else { return }
        let old = Game24PointStore.bestScore(for: difficulty.storeKey)
        if score > old {
            Game24PointStore.update(difficulty.storeKey, score: score)
            newRecord = true
        }
        bestScore = max(old, score)
    }

    private func finish() {
        guard let difficulty else { return }
        if score > bestScore {
            Game24PointStore.update(difficulty.storeKey, score: score)
            bestScore = score
            newRecord = true
        }
        showResult = true
    }

    private func openReference() {
        guard !solved else { return }
        refSolutions = collectSolutions(originalCards, max: 4, simpleOnly: false)
        showRef = true
    }

    // MARK: - 恭喜过关弹窗

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.22).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 58))
                Text("恭喜答对！")
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("下一题是 \(qIndex + 1 <= (difficulty?.total ?? 10) ? "第 \(qIndex + 1) 关" : "最终结算")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.fieldMoss)
                HStack(spacing: 14) {
                    VStack(spacing: 2) {
                        Text("当前得分")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.fieldMoss)
                        Text("\(score)")
                            .font(.system(size: 24, weight: .heavy, design: .serif))
                            .foregroundStyle(AppTheme.fieldInk)
                    }
                    VStack(spacing: 2) {
                        Text("连对")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.fieldMoss)
                        Text("\(streak)")
                            .font(.system(size: 24, weight: .heavy, design: .serif))
                            .foregroundStyle(Color(red: 0.85, green: 0.60, blue: 0.15))
                    }
                }
                Button {
                    showSuccess = false
                    advance()
                } label: {
                    Text("下一关")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 25, style: .continuous)
                                .fill(
                                    LinearGradient(colors: [Color(red: 0.28, green: 0.79, blue: 0.52),
                                                            Color(red: 0.18, green: 0.62, blue: 0.43)],
                                                   startPoint: .top, endPoint: .bottom)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(AppTheme.fieldMint.opacity(0.35), lineWidth: 2)
                    )
                    .shadow(color: AppTheme.fieldGrassShadow.opacity(0.14), radius: 12, y: 6)
            )
        }
    }

    // MARK: - 弹窗

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.22).ignoresSafeArea()
            VStack(spacing: 12) {
                Text(newRecord ? "🏆 新纪录！" : "🎉")
                    .font(.system(size: 48))
                Text("挑战完成")
                    .font(.system(size: 24, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("本次共 \(difficulty?.total ?? 10) 题")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.fieldMoss)
                resultLine("得分", "\(score)")
                resultLine("连对最高", "\(maxStreak)")
                resultLine("总用时", String(format: "%.1fs", elapsed))
                resultLine("历史最佳", "\(bestScore)")
                HStack(spacing: 12) {
                    Button {
                        if let difficulty { startGame(difficulty) }
                    } label: {
                        Text("再来一局")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25, style: .continuous)
                                    .fill(AppTheme.fieldMint)
                            )
                    }
                    .buttonStyle(.plain)
                    Button {
                        onExit()
                    } label: {
                        Text("返回首页")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(AppTheme.fieldInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25, style: .continuous)
                                    .fill(Color.white.opacity(0.88))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                                            .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(AppTheme.fieldMint.opacity(0.35), lineWidth: 2)
                    )
                    .shadow(color: AppTheme.fieldGrassShadow.opacity(0.14), radius: 12, y: 6)
            )
        }
    }

    private var referenceOverlay: some View {
        ZStack {
            Color.black.opacity(0.22).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("📖 参考答案")
                    .font(.system(size: 20, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                if refSolutions.isEmpty {
                    Text("未找到解法，请换一组")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.fieldMoss)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Array(refSolutions.enumerated()), id: \.offset) { i, sol in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("解法 \(i + 1)")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundStyle(AppTheme.fieldMint)
                                    ForEach(Array(sol.enumerated()), id: \.offset) { j, step in
                                        Text("第\(j + 1)步  \(step)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppTheme.fieldInk)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color(red: 0.95, green: 0.98, blue: 0.95))
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                Button {
                    showRef = false
                } label: {
                    Text("关闭")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(AppTheme.fieldInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(red: 0.93, green: 0.96, blue: 0.93))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(AppTheme.fieldMint.opacity(0.35), lineWidth: 2)
                    )
                    .shadow(color: AppTheme.fieldGrassShadow.opacity(0.14), radius: 12, y: 6)
            )
        }
    }

    private func resultLine(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.fieldMoss)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(AppTheme.fieldInk)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - 求解器

    private func collectSolutions(_ input: [Double], max: Int, simpleOnly: Bool) -> [[String]] {
        struct Node {
            let value: Double
            let expr: String
        }
        let nodes = input.map { Node(value: $0, expr: fmt($0)) }
        var results: [[String]] = []
        var seen = Set<String>()

        func dfs(_ list: [Node], _ steps: [String]) {
            if results.count >= max { return }
            if list.count == 1 {
                if abs(list[0].value - 24) < 1e-6 {
                    let key = steps.joined(separator: "|")
                    if !seen.contains(key) {
                        seen.insert(key)
                        results.append(steps)
                    }
                }
                return
            }
            for i in 0..<list.count {
                for j in (i + 1)..<list.count {
                    let a = list[i]
                    let b = list[j]
                    var rest = list
                    rest.remove(at: j)
                    rest.remove(at: i)
                    let ops = opCombinations(a.value, b.value, simpleOnly: simpleOnly)
                    for op in ops {
                        let shouldSwap = (op.symbol == "+" || op.symbol == "×") && b.expr.count > a.expr.count
                        let left = shouldSwap ? b : a
                        let right = shouldSwap ? a : b
                        let step = "\(fmt(left.value)) \(op.symbol) \(fmt(right.value)) = \(fmt(op.value))"
                        let newNode = Node(value: op.value, expr: "(\(left.expr) \(op.symbol) \(right.expr))")
                        dfs(rest + [newNode], steps + [step])
                    }
                }
            }
        }

        dfs(nodes, [])
        return results
    }

    private func opCombinations(_ a: Double, _ b: Double, simpleOnly: Bool) -> [(symbol: String, value: Double)] {
        var out: [(String, Double)] = [("+", a + b), ("×", a * b)]
        if !simpleOnly {
            out.append(("-", a - b))
            out.append(("-", b - a))
            if abs(b) > 1e-9 { out.append(("÷", a / b)) }
            if abs(a) > 1e-9 { out.append(("÷", b / a)) }
        }
        return out
    }

    private func fmt(_ v: Double) -> String {
        if abs(v - v.rounded()) < 1e-6 {
            return String(Int(v.rounded()))
        }
        return String(format: "%.2f", v)
    }
}

// MARK: - 本地最佳成绩

enum Game24PointStore {
    private static func key(_ id: String) -> String {
        "game24.best.\(id)"
    }

    static func bestScore(for id: String) -> Int {
        UserDefaults.standard.integer(forKey: key(id))
    }

    @discardableResult
    static func update(_ id: String, score: Int) -> Bool {
        let old = bestScore(for: id)
        if score <= old { return false }
        UserDefaults.standard.set(score, forKey: key(id))
        return true
    }
}
