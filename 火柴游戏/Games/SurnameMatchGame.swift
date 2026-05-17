import SwiftUI

// MARK: - 百家姓配对游戏（翻牌找配对）
//
// 玩法：每关随机抽 8 个姓，洗成 16 张牌（8 张汉字 + 8 张拼音）；
// 玩家点击两张牌使之翻面，若汉字与拼音相匹配则保留翻开，否则盖回。
// 全部配对成功即通关，按用时计算星级。

struct SurnameMatchGameView: View {
    let onExit: () -> Void

    private let pairsPerRound = 8
    private let kind: GameKind = .surnameMatch

    @State private var cards: [SurnameCard] = []
    @State private var firstPickIndex: Int? = nil
    @State private var lockInteraction = false
    @State private var matchedCount = 0
    @State private var attempts = 0
    @State private var startTime = Date()
    @State private var showResult = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                GameTopBar(
                    title: kind.title,
                    progressText: "已配对 \(matchedCount) / \(pairsPerRound) 对 · 翻牌 \(attempts) 次",
                    palette: kind.palette,
                    onExit: onExit
                )

                infoStrip
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.vertical, 8)

                gridArea

                Spacer(minLength: 0)
            }

            if showResult {
                GameResultSheet(
                    result: GameResult(
                        kind: kind,
                        correct: matchedCount,
                        total: pairsPerRound,
                        elapsed: Date().timeIntervalSince(startTime)
                    ),
                    onRetry: restart,
                    onExit: onExit
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            if cards.isEmpty {
                setupRound()
            }
        }
    }

    // MARK: - 顶部说明条

    private var infoStrip: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(kind.palette.0)
            Text("翻开两张牌，让汉字与拼音对上号")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(kind.palette.0.opacity(0.08), in: RoundedRectangle(cornerRadius: AppTheme.cornerSmall))
    }

    // MARK: - 翻牌网格 4×4

    private var gridArea: some View {
        GeometryReader { proxy in
            let cols = 4
            let rows = (cards.count + cols - 1) / cols
            let spacing: CGFloat = 10
            let totalHSpacing = spacing * CGFloat(cols - 1)
            let availableW = proxy.size.width - AppTheme.paddingScreen * 2 - totalHSpacing
            let cardW = max(60, availableW / CGFloat(cols))
            // 卡片高度采用 1.2 倍，且不超出可用高度
            let availableH = proxy.size.height - spacing * CGFloat(rows - 1)
            let maxCardH = availableH / CGFloat(rows)
            let cardH = min(cardW * 1.2, maxCardH)

            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(0..<cols, id: \.self) { c in
                            let idx = r * cols + c
                            if idx < cards.count {
                                cardTile(idx: idx, w: cardW, h: cardH)
                            } else {
                                Color.clear.frame(width: cardW, height: cardH)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 4)
        }
    }

    private func cardTile(idx: Int, w: CGFloat, h: CGFloat) -> some View {
        let card = cards[idx]
        let isOpen = card.isFaceUp || card.isMatched

        return Button {
            handleTap(idx: idx)
        } label: {
            ZStack {
                // 背面
                if !isOpen {
                    RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [kind.palette.0, kind.palette.1],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "questionmark")
                                .font(.system(size: min(w, h) * 0.36, weight: .heavy))
                                .foregroundStyle(.white.opacity(0.85))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                                .strokeBorder(.white.opacity(0.3), lineWidth: 2)
                        )
                }

                // 正面
                if isOpen {
                    RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                        .fill(card.isMatched ? AppTheme.accentSage.opacity(0.18) : AppTheme.card)
                        .overlay(
                            VStack(spacing: 4) {
                                Text(card.face)
                                    .font(.system(size: cardFontSize(face: card.face, w: w),
                                                  weight: .heavy, design: .rounded))
                                    .foregroundStyle(card.isMatched ? AppTheme.accentSage : AppTheme.textPrimary)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            }
                            .padding(6)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                                .strokeBorder(
                                    card.isMatched ? AppTheme.accentSage : kind.palette.0.opacity(0.35),
                                    lineWidth: 2
                                )
                        )
                }
            }
            .frame(width: w, height: h)
            .rotation3DEffect(.degrees(isOpen ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            .animation(.easeInOut(duration: 0.25), value: isOpen)
        }
        .buttonStyle(.plain)
        .disabled(card.isMatched || lockInteraction)
    }

    private func cardFontSize(face: String, w: CGFloat) -> CGFloat {
        // 拼音通常较长，自动缩字号
        let count = face.count
        if count <= 2 { return w * 0.4 }
        if count <= 4 { return w * 0.28 }
        return w * 0.2
    }

    // MARK: - 交互逻辑

    private func handleTap(idx: Int) {
        guard !lockInteraction else { return }
        guard !cards[idx].isMatched, !cards[idx].isFaceUp else { return }

        cards[idx].isFaceUp = true

        if let first = firstPickIndex {
            attempts += 1
            // 比对
            if cards[first].pairKey == cards[idx].pairKey {
                cards[first].isMatched = true
                cards[idx].isMatched = true
                matchedCount += 1
                firstPickIndex = nil
                if matchedCount >= pairsPerRound {
                    // 通关
                    GameBestScoreStore.update(kind, score: pairsPerRound)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showResult = true
                        }
                    }
                }
            } else {
                // 不匹配，短暂展示后翻回
                lockInteraction = true
                let firstIdx = first
                let secondIdx = idx
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    cards[firstIdx].isFaceUp = false
                    cards[secondIdx].isFaceUp = false
                    firstPickIndex = nil
                    lockInteraction = false
                }
            }
        } else {
            firstPickIndex = idx
        }
    }

    private func setupRound() {
        let sample = SurnameCatalog.randomSample(count: pairsPerRound)
        var built: [SurnameCard] = []
        for s in sample {
            built.append(SurnameCard(face: s.character, pairKey: s.character))
            built.append(SurnameCard(face: s.pinyin, pairKey: s.character))
        }
        cards = built.shuffled()
        firstPickIndex = nil
        lockInteraction = false
        matchedCount = 0
        attempts = 0
        startTime = Date()
    }

    private func restart() {
        showResult = false
        setupRound()
    }
}

// MARK: - 数据

private struct SurnameCard: Identifiable {
    let id = UUID()
    let face: String
    /// 配对键：同一姓氏的"汉字卡"和"拼音卡"共用同一个 key。
    let pairKey: String
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}
