import SwiftUI

// MARK: - 字块状态（文件级共享，供 ViewModifier 访问）
fileprivate enum TileState { case normal, correct, wrong }

// MARK: - 成语填空游戏（书野营地竹青风）
//
// 玩法：
//   - 顶部展示一个 4 字成语，其中 1 字被挖空（虚线方框）。
//   - 底部 6 个候选字（2×3 网格），其中只有 1 个是正确答案。
//   - 用户点击候选字 → 用 matchedGeometryEffect 让字"飞"到空位。
//   - 正确：成语整体放大 + 绿色高亮 + 撒花，1 秒后下一题。
//   - 错误：候选字震动 + 红框，挖空处显示正确答案（竹绿高亮），1.4 秒后下一题。

struct IdiomFillBlankGameView: View {
    let onExit: () -> Void

    @State private var questions: [IdiomCatalog.FillBlankQuestion] = []
    @State private var currentIndex = 0
    @State private var picked: Character? = nil      // 用户已点击的候选字
    @State private var isCorrect: Bool? = nil        // nil = 未作答，true/false = 已判定
    @State private var correctCount = 0
    @State private var startTime = Date()
    @State private var showResult = false
    @State private var showExplanation = false
    @State private var showDifficultyPicker = false
    @State private var difficulty: IdiomCatalog.Difficulty = .jinjie

    @Namespace private var animation                 // matchedGeometryEffect

    /// 竹青主色（书野营地竹青风，替代朱砂 palette）
    private let bamboo: (Color, Color) = (
        AppTheme.fieldMint,
        Color(red: 126/255, green: 211/255, blue: 160/255)
    )

    private let totalQuestions = 10
    private let kind: GameKind = .idiomFillBlank

    private var current: IdiomCatalog.FillBlankQuestion? {
        guard !questions.isEmpty, currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var body: some View {
        ZStack {
            // 蓝天草地背景（固定）
            FieldBackground()

            bambooSun
            bambooCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            bambooCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton(action: onExit)
                        Spacer()
                        if current != nil {
                            Button {
                                showExplanation = true
                            } label: {
                                Image(systemName: "book.pages.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(bamboo.0)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.9), in: Circle())
                                    .overlay(Circle().strokeBorder(AppTheme.fieldMint.opacity(0.35), lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    VStack(spacing: 2) {
                        Text(kind.title)
                            .font(.system(size: 16, weight: .heavy, design: .serif))
                            .foregroundStyle(AppTheme.fieldInk)
                        Text("第 \(min(currentIndex + 1, totalQuestions)) / \(totalQuestions) 题 · 答对 \(correctCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.fieldMoss)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                // 当前难度提示（点击弹框选择）
                HStack(spacing: 6) {
                    Button {
                        showDifficultyPicker = true
                    } label: {
                        HStack(spacing: 5) {
                            Text("⚡ \(difficulty.label)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                            Text(difficulty.subtitle)
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .opacity(0.8)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .heavy))
                        }
                        .foregroundStyle(bamboo.0)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(bamboo.0.opacity(0.12), in: Capsule())
                        .overlay(Capsule().strokeBorder(bamboo.0.opacity(0.4), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)

                    Text("点击可切换难度")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 8)

                if let q = current {
                    questionBody(q: q)
                        .id(q.id)               // 切题时整体重建，避免动画串味
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .tint(AppTheme.fieldMint)
                        .frame(maxHeight: .infinity)
                }
            }

            if showResult {
                GameResultSheet(
                    result: GameResult(
                        kind: kind,
                        correct: correctCount,
                        total: totalQuestions,
                        elapsed: Date().timeIntervalSince(startTime)
                    ),
                    onRetry: restart,
                    onExit: onExit
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            if questions.isEmpty {
                questions = IdiomCatalog.makeFillBlankQuestions(count: totalQuestions, difficulty: difficulty)
                startTime = Date()
            }
        }
        .sheet(isPresented: $showExplanation) {
            if let q = current {
                IdiomExplanationSheet(idiom: q.idiom, palette: bamboo)
            }
        }
        .sheet(isPresented: $showDifficultyPicker) {
            DifficultyPickerSheet(
                title: "成语填空 · 选择难度",
                current: difficulty,
                onPick: { diff in
                    showDifficultyPicker = false
                    withAnimation(.easeOut(duration: 0.18)) {
                        difficulty = diff
                        restart()
                    }
                }
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - 题目主体

    @ViewBuilder
    private func questionBody(q: IdiomCatalog.FillBlankQuestion) -> some View {
        VStack(spacing: 24) {
            promptCard(q: q)
                .padding(.horizontal, 18)
                .padding(.top, 14)

            hintLabel(q: q)

            Spacer().frame(height: 2)

            optionGrid(q: q)
                .padding(.horizontal, 18)

            Spacer()
        }
    }

    // 顶部成语卡：4 字 + 挖空
    private func promptCard(q: IdiomCatalog.FillBlankQuestion) -> some View {
        let chars = Array(q.idiom.text)
        return VStack(spacing: 14) {
            Text("📝 把空缺的字找出来")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(bamboo.0)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(AppTheme.fieldMint.opacity(0.12), in: Capsule())
                .overlay(Capsule().strokeBorder(AppTheme.fieldMint.opacity(0.35), lineWidth: 1.5))

            HStack(spacing: 10) {
                ForEach(0..<chars.count, id: \.self) { i in
                    if i == q.blankIndex {
                        blankSlot(q: q)
                    } else {
                        charTile(String(chars[i]), state: .normal)
                    }
                }
            }
            .scaleEffect(isCorrect == true ? 1.05 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.55), value: isCorrect)
        }
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            isCorrect == true ? bamboo.0 : AppTheme.fieldOlive.opacity(0.3),
                            lineWidth: 2
                        )
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.1), radius: 8, y: 4)
        )
    }

    // 空位：未答 / 已答（正确显示竹绿、错误显示红 + 正确字）
    @ViewBuilder
    private func blankSlot(q: IdiomCatalog.FillBlankQuestion) -> some View {
        if let p = picked {
            // 已点击：把候选字飞到这里
            let state: TileState = (isCorrect == true) ? .correct : .wrong
            charTile(String(p), state: state)
                .matchedGeometryEffect(id: p, in: animation)
                .overlay(alignment: .bottom) {
                    // 答错时把正确答案以小字显示在下方
                    if isCorrect == false {
                        Text("正确：\(String(q.answerChar))")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(bamboo.0)
                            .offset(y: 22)
                    }
                }
        } else {
            // 未答：虚线空框 + 闪烁问号
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
                    .foregroundStyle(bamboo.0.opacity(0.65))
                Image(systemName: "questionmark")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(bamboo.0.opacity(0.55))
            }
            .frame(width: 64, height: 64)
        }
    }

    // 提示文字
    private func hintLabel(q: IdiomCatalog.FillBlankQuestion) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isCorrect == true ? "checkmark.circle.fill"
                              : (isCorrect == false ? "xmark.circle.fill" : "hand.tap.fill"))
                .foregroundStyle(
                    isCorrect == true ? bamboo.0
                    : (isCorrect == false ? Color(red: 232/255, green: 100/255, blue: 82/255) : bamboo.0)
                )
            Text(
                isCorrect == true ? "答对了！"
                : (isCorrect == false ? "再接再厉" : "点击下方一个字填入空缺")
            )
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.fieldMoss)
        }
        .animation(.easeInOut(duration: 0.2), value: isCorrect)
    }

    // 候选字网格（2 行 3 列）
    private func optionGrid(q: IdiomCatalog.FillBlankQuestion) -> some View {
        let cols = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        return LazyVGrid(columns: cols, spacing: 12) {
            ForEach(q.options, id: \.self) { ch in
                optionTile(char: ch, q: q)
            }
        }
    }

    private func optionTile(char: Character, q: IdiomCatalog.FillBlankQuestion) -> some View {
        let isPicked = (picked == char)
        // 已被选走的候选字：在空位中通过 matchedGeometryEffect 展示，原位置隐藏占位
        return Group {
            if isPicked {
                // 占位（保留位置以保证网格不抖）
                Color.clear
                    .frame(height: 72)
            } else {
                Button {
                    handleTap(char: char, q: q)
                } label: {
                    candidateTile(String(char))
                }
                .buttonStyle(.plain)
                .matchedGeometryEffect(id: char, in: animation)
                .disabled(picked != nil)
            }
        }
    }

    private func candidateTile(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 30, weight: .heavy, design: .serif))
            .foregroundStyle(AppTheme.fieldInk)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 5, y: 3)
            )
    }

    // MARK: - 通用字块

    private func charTile(_ s: String, state: TileState) -> some View {
        let (fg, bgStart, bgEnd, border): (Color, Color, Color, Color) = {
            switch state {
            case .normal:
                return (AppTheme.fieldInk, Color.white, Color(red: 244/255, green: 248/255, blue: 238/255), bamboo.0.opacity(0.2))
            case .correct:
                return (.white, bamboo.1, bamboo.0, .clear)
            case .wrong:
                return (.white, Color(red: 232/255, green: 100/255, blue: 82/255), Color(red: 201/255, green: 100/255, blue: 66/255), .clear)
            }
        }()

        return Text(s)
            .font(.system(size: 36, weight: .heavy, design: .serif))
            .foregroundStyle(fg)
            .frame(width: 64, height: 64)
            .background(
                LinearGradient(
                    colors: [bgStart, bgEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(border, lineWidth: 2)
            )
            .modifier(ShakeIfWrong(state: state))
    }

    // MARK: - 交互

    private func handleTap(char: Character, q: IdiomCatalog.FillBlankQuestion) {
        guard picked == nil else { return }

        // 触发飞行动画
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            picked = char
        }

        // 等飞行落位，再判对错（让字先飞过去）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            let correct = (char == q.answerChar)
            withAnimation(.easeInOut(duration: 0.2)) {
                isCorrect = correct
            }
            if correct { correctCount += 1 }

            let dwell: Double = correct ? 0.9 : 1.4
            DispatchQueue.main.asyncAfter(deadline: .now() + dwell) {
                advance()
            }
        }
    }

    private func advance() {
        if currentIndex + 1 >= totalQuestions {
            GameBestScoreStore.update(kind, score: correctCount)
            withAnimation(.easeInOut(duration: 0.2)) {
                showResult = true
            }
            return
        }
        currentIndex += 1
        picked = nil
        isCorrect = nil
    }

    private func restart() {
        questions = IdiomCatalog.makeFillBlankQuestions(count: totalQuestions, difficulty: difficulty)
        currentIndex = 0
        picked = nil
        isCorrect = nil
        correctCount = 0
        startTime = Date()
        showResult = false
    }

    // MARK: - 背景装饰（太阳/云）

    private var bambooSun: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breathe = 1 + 0.03 * sin(t * 1.2)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 214/255, blue: 110/255).opacity(0.4),
                            Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.14),
                            .clear
                        ], center: .center, startRadius: 10, endRadius: 50)
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(breathe)
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 246/255, blue: 205/255),
                            Color(red: 255/255, green: 214/255, blue: 100/255),
                            Color(red: 247/255, green: 188/255, blue: 55/255)
                        ], center: .init(x: 0.38, y: 0.3), startRadius: 2, endRadius: 18)
                    )
                    .frame(width: 32, height: 32)
                    .scaleEffect(breathe)
                    .shadow(color: Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.8), radius: 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.trailing, 20)
            .padding(.top, 30)
        }
        .allowsHitTesting(false)
    }

    private func bambooCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate + delay
            let drift = 14 * sin(t * 0.42)
            let bob = 3 * sin(t * 0.85 + 1.2)
            ZStack {
                ZStack {
                    Capsule().fill(Color.white.opacity(0.95)).frame(width: 42, height: 15).offset(y: 4)
                    Circle().fill(Color.white.opacity(0.95)).frame(width: 25, height: 25).offset(x: -9, y: -6)
                    Circle().fill(Color.white.opacity(0.9)).frame(width: 21, height: 21).offset(x: 7, y: -4)
                    Circle().fill(Color.white.opacity(0.9)).frame(width: 15, height: 15).offset(x: 0, y: -10)
                }
                .frame(width: 52, height: 30)
                .scaleEffect(scale)
                .offset(x: drift, y: bob)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, 390 * x - 10)
            .padding(.top, 390 * y)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 错误时的横向抖动

private struct ShakeIfWrong: ViewModifier {
    let state: TileState
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: phase)
            .onChange(of: state) { _, new in
                guard new == .wrong else { return }
                let pattern: [CGFloat] = [-10, 10, -8, 8, -4, 4, 0]
                animatePattern(pattern, idx: 0)
            }
    }

    private func animatePattern(_ p: [CGFloat], idx: Int) {
        guard idx < p.count else { return }
        withAnimation(.linear(duration: 0.06)) { phase = p[idx] }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            animatePattern(p, idx: idx + 1)
        }
    }
}

// MARK: - 成语释义弹窗（书野竹青风）

struct IdiomExplanationSheet: View {
    let idiom: ChineseIdiom
    let palette: (Color, Color)
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                }
                .padding(16)
            }

            VStack(spacing: 20) {
                Text(idiom.text)
                    .font(.system(size: 44, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .tracking(2)
                    .padding(.bottom, 6)

                VStack(alignment: .leading, spacing: 14) {
                    if let exp = idiom.explanation, !exp.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "book.closed.fill")
                                    .foregroundStyle(palette.0)
                                Text("成语释义")
                                    .font(.system(size: 15, weight: .heavy, design: .serif))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                            Text(exp)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(Color(red: 85/255, green: 112/255, blue: 95/255))
                                .lineSpacing(6)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(palette.0.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(palette.0.opacity(0.3), lineWidth: 1.5)
                                )
                        )
                    }

                    if let example = idiom.example, !example.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "quote.opening")
                                    .foregroundStyle(palette.1)
                                Text("例句")
                                    .font(.system(size: 15, weight: .heavy, design: .serif))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                            Text(example)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(Color(red: 85/255, green: 112/255, blue: 95/255))
                                .lineSpacing(6)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(palette.1.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(palette.1.opacity(0.3), lineWidth: 1.5)
                                )
                        )
                    }

                    if (idiom.explanation ?? "").isEmpty && (idiom.example ?? "").isEmpty {
                        Text("暂无释义和例句哦")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .presentationDetents([.fraction(0.65), .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - 难度选择弹框（共享）

struct DifficultyPickerSheet: View {
    let title: String
    let current: IdiomCatalog.Difficulty
    let onPick: (IdiomCatalog.Difficulty) -> Void

    @Environment(\.dismiss) private var dismiss

    private var accent: Color {
        AppTheme.fieldMint
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.fieldMoss.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(IdiomCatalog.Difficulty.allCases) { diff in
                        let isCurrent = diff == current
                        Button {
                            onPick(diff)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(accent.opacity(isCurrent ? 0.15 : 0.08))
                                    Text(diff.emoji)
                                        .font(.system(size: 22))
                                }
                                .frame(width: 46, height: 46)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(accent.opacity(isCurrent ? 0.5 : 0.25), lineWidth: 1.5)
                                )

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(diff.label)
                                            .font(.system(size: 15, weight: .heavy, design: .serif))
                                            .foregroundStyle(AppTheme.fieldInk)
                                        if isCurrent {
                                            Text("当前")
                                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 2)
                                                .background(accent, in: Capsule())
                                        }
                                    }
                                    Text("\(diff.subtitle) · \(diff.desc)")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.fieldMoss)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(accent.opacity(isCurrent ? 0.8 : 0.3))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.94))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(isCurrent ? accent.opacity(0.5) : Color(red: 60/255, green: 80/255, blue: 110/255).opacity(0.12), lineWidth: isCurrent ? 2 : 1)
                                    )
                                    .shadow(color: AppTheme.fieldGrassShadow.opacity(isCurrent ? 0.12 : 0.04), radius: 6, y: 3)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

extension IdiomCatalog.Difficulty {
    var emoji: String {
        switch self {
        case .qimeng: return "🌱"
        case .rumen:  return "🌿"
        case .jinjie: return "🌳"
        case .kunnan: return "🔥"
        case .juesha: return "💀"
        }
    }

    var desc: String {
        switch self {
        case .qimeng: return "无限提示 · 自动候选"
        case .rumen:  return "无限提示"
        case .jinjie: return "5 次提示"
        case .kunnan: return "2 次提示"
        case .juesha: return "无提示 · 终极挑战"
        }
    }
}
