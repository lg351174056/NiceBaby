import SwiftUI

// MARK: - 字块状态（文件级共享，供 ViewModifier 访问）
fileprivate enum TileState { case normal, correct, wrong }

// MARK: - 成语填空游戏
//
// 玩法：
//   - 顶部展示一个 4 字成语，其中 1 字被挖空（虚线方框）。
//   - 底部 6 个候选字（2×3 网格），其中只有 1 个是正确答案。
//   - 用户点击候选字 → 用 matchedGeometryEffect 让字"飞"到空位。
//   - 正确：成语整体放大 + 绿色高亮 + 撒花，1 秒后下一题。
//   - 错误：候选字震动 + 红框，挖空处显示正确答案（紫色高亮），1.4 秒后下一题。

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

    @Namespace private var animation                 // matchedGeometryEffect

    private let totalQuestions = 10
    private let kind: GameKind = .idiomFillBlank

    private var current: IdiomCatalog.FillBlankQuestion? {
        guard !questions.isEmpty, currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                GameTopBar(
                    title: kind.title,
                    progressText: "第 \(min(currentIndex + 1, totalQuestions)) / \(totalQuestions) 题 · 答对 \(correctCount)",
                    palette: kind.palette,
                    onExit: onExit
                ) {
                    if current != nil {
                        Button {
                            showExplanation = true
                        } label: {
                            Image(systemName: "book.pages.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(kind.palette.0)
                                .padding(8)
                                .background(kind.palette.0.opacity(0.15), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let q = current {
                    questionBody(q: q)
                        .id(q.id)               // 切题时整体重建，避免动画串味
                } else {
                    ProgressView().frame(maxHeight: .infinity)
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
                questions = IdiomCatalog.makeFillBlankQuestions(count: totalQuestions)
                startTime = Date()
            }
        }
        .sheet(isPresented: $showExplanation) {
            if let q = current {
                IdiomExplanationSheet(idiom: q.idiom, palette: kind.palette)
            }
        }
    }

    // MARK: - 题目主体

    @ViewBuilder
    private func questionBody(q: IdiomCatalog.FillBlankQuestion) -> some View {
        VStack(spacing: 28) {
            promptCard(q: q)
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 16)

            hintLabel(q: q)

            Spacer().frame(height: 4)

            optionGrid(q: q)
                .padding(.horizontal, AppTheme.paddingScreen)

            Spacer()
        }
    }

    // 顶部成语卡：4 字 + 挖空
    private func promptCard(q: IdiomCatalog.FillBlankQuestion) -> some View {
        let chars = Array(q.idiom.text)
        return VStack(spacing: 14) {
            Text("把空缺的字找出来")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(kind.palette.0.opacity(0.15), in: Capsule())
                .foregroundStyle(kind.palette.0)

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
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerLarge))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerLarge)
                .strokeBorder(
                    isCorrect == true ? AppTheme.accentSage : kind.palette.0.opacity(0.25),
                    lineWidth: 2
                )
        )
    }

    // 空位：未答 / 已答（正确显示绿、错误显示红 + 正确字）
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
                            .foregroundStyle(AppTheme.accentSage)
                            .offset(y: 22)
                    }
                }
        } else {
            // 未答：虚线空框 + 闪烁问号
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerSmall)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
                    .foregroundStyle(kind.palette.0.opacity(0.65))
                Image(systemName: "questionmark")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(kind.palette.0.opacity(0.55))
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
                    isCorrect == true ? AppTheme.accentSage
                    : (isCorrect == false ? AppTheme.accentPink : kind.palette.0)
                )
            Text(
                isCorrect == true ? "答对了！"
                : (isCorrect == false ? "再接再厉" : "点击下方一个字填入空缺")
            )
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.textSecondary)
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
            .font(.system(size: 30, weight: .heavy, design: .rounded))
            .foregroundStyle(AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerMedium))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                    .strokeBorder(kind.palette.0.opacity(0.25), lineWidth: 2)
            )
            .shadow(color: AppTheme.textPrimary.opacity(0.06), radius: 4, y: 2)
    }

    // MARK: - 通用字块

    private func charTile(_ s: String, state: TileState) -> some View {
        let (fg, bgStart, bgEnd, border): (Color, Color, Color, Color) = {
            switch state {
            case .normal:
                return (AppTheme.textPrimary, AppTheme.background, AppTheme.background, kind.palette.0.opacity(0.2))
            case .correct:
                return (.white, AppTheme.accentSage, AppTheme.accentMint, .clear)
            case .wrong:
                return (.white, AppTheme.accentPink, AppTheme.accentTerracotta, .clear)
            }
        }()

        return Text(s)
            .font(.system(size: 36, weight: .heavy, design: .rounded))
            .foregroundStyle(fg)
            .frame(width: 64, height: 64)
            .background(
                LinearGradient(
                    colors: [bgStart, bgEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: AppTheme.cornerSmall)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerSmall)
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
        questions = IdiomCatalog.makeFillBlankQuestions(count: totalQuestions)
        currentIndex = 0
        picked = nil
        isCorrect = nil
        correctCount = 0
        startTime = Date()
        showResult = false
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

// MARK: - 成语释义弹窗

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
                        .font(.title2)
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                }
                .padding(16)
            }
            
            VStack(spacing: 24) {
                Text(idiom.text)
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(palette.0)
                    .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 16) {
                    if let exp = idiom.explanation, !exp.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "book.closed.fill")
                                    .foregroundStyle(palette.0)
                                Text("成语释义")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                            Text(exp)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineSpacing(6)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(palette.0.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                    }
                    
                    if let example = idiom.example, !example.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "quote.opening")
                                    .foregroundStyle(palette.1)
                                Text("例句")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                            Text(example)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineSpacing(6)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(palette.1.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
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
