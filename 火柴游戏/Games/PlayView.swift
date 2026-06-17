import SwiftUI

// MARK: - 益智 Tab · 墨紫色 · 灵感游戏台

struct PlayView: View {
    @EnvironmentObject private var progress: AppProgressStore
    @State private var presentedGame: GameKind? = nil

    private var matchProgress: Double {
        let total = MatchstickProblemSet.count
        guard total > 0 else { return 0 }
        return min(Double(progress.totalMatchstickSolves) / Double(total), 1.0)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text("益智乐园")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.gradientPlay)
                    Spacer()
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(AppTheme.background)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 18) {
                        statsHeroCard

                        sectionHeader(title: "热门挑战", action: "查看全部")

                        featuredGameCard

                        sectionHeader(title: "挑战乐园", action: nil)

                        gameBentoGrid

                        sectionHeader(title: "工具箱", action: "更多")

                        toolboxScroll
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                .background(AppTheme.background.ignoresSafeArea())
            }
        }
        .fullScreenCover(item: $presentedGame) { kind in
            gameContainer(for: kind)
        }
    }

    // MARK: - Stats Hero Card (深紫渐变)

    private var statsHeroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cornerXL, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 74/255, green: 59/255, blue: 107/255),
                            AppTheme.accentInkPurple,
                            Color(red: 110/255, green: 93/255, blue: 160/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        RingProgressView(progress: matchProgress, lineWidth: 4, size: 56, color: Color(red: 184/255, green: 169/255, blue: 212/255))
                        Text("\(Int(matchProgress * 100))%")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("今天玩点什么？")
                            .font(.system(size: 18, weight: .heavy, design: .serif))
                            .foregroundStyle(.white)
                        Text("已通关火柴 \(progress.totalMatchstickSolves) 道 · 连续学习 \(progress.streakDays) 天")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                }

                HStack(spacing: 10) {
                    statChip(value: Text("\(progress.totalMatchstickSolves)").font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundStyle(.white), label: "火柴通关")
                    statChip(
                        value: {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(red: 255/255, green: 184/255, blue: 77/255))
                                Text("\(progress.streakDays)")
                                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                        }(),
                        label: "连续打卡"
                    )
                    statChip(value: Text("\(progress.totalMatchstickSolves + progress.openedPoemIds.count)").font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundStyle(.white), label: "今日活跃")
                }
            }
            .padding(20)
        }
    }

    private func statChip(value: some View, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            value
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, action: String?) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            if let action {
                Button {} label: {
                    Text(action)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.accentInkPurple)
                }
            }
        }
    }

    // MARK: - Featured Game Card (Hero)

    private var featuredGameCard: some View {
        Button { presentedGame = .matchstick } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    LinearGradient(
                        colors: [AppTheme.accentCinnabar, Color(red: 232/255, green: 130/255, blue: 94/255), Color(red: 242/255, green: 168/255, blue: 122/255)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 120)

                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 64, height: 64)
                        Image(systemName: "function")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 20)

                    Text("主推")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.25), in: Capsule())
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 14)
                        .padding(.leading, 16)
                }
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: AppTheme.cornerLarge, topTrailingRadius: AppTheme.cornerLarge))

                VStack(alignment: .leading, spacing: 6) {
                    Text("火柴游戏")
                        .font(.system(size: 20, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("移动一根火柴，让等式成立")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: 6) {
                        tagPill(text: "311 道题", accent: AppTheme.accentCinnabar)
                        tagPill(text: "逻辑推理", accent: AppTheme.accentCinnabar)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(AppTheme.card)
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: AppTheme.cornerLarge, bottomTrailingRadius: AppTheme.cornerLarge))
                .overlay(
                    UnevenRoundedRectangle(bottomLeadingRadius: AppTheme.cornerLarge, bottomTrailingRadius: AppTheme.cornerLarge)
                        .strokeBorder(AppTheme.separator, lineWidth: 1)
                )
            }
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.bouncy)
        .drawingGroup()
    }

    private func tagPill(text: String, accent: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(accent.opacity(0.08), in: Capsule())
    }

    // MARK: - Game Bento Grid

    private var gameBentoGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        let games: [(GameKind, Bool)] = [
            (.poetryComplete, true),
            (.surnameMatch, false),
            (.idiomFillBlank, false),
            (.sanzijing, false)
        ]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(games.enumerated()), id: \.element.0) { _, pair in
                let (kind, isTall) = pair
                GameBentoCard(
                    kind: kind,
                    bestScore: GameBestScoreStore.best(for: kind),
                    isTall: isTall
                ) {
                    presentedGame = kind
                }
            }
        }
    }

    // MARK: - Toolbox Horizontal Scroll

    private var toolboxScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                toolChip(kind: .idiomDictionary, accent: AppTheme.accentInkPurple, sub: "收录 5 万+")
                toolChip(kind: .xiehouyuDictionary, accent: AppTheme.accentBamboo, sub: "经典精选")
                toolChip(kind: .dictionary, accent: AppTheme.accentYellow, sub: "查拼音 · 听发音")
            }
            .padding(.bottom, 4)
        }
    }

    private func toolChip(kind: GameKind, accent: Color, sub: String) -> some View {
        Button { presentedGame = kind } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: kind.systemImage)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(accent)
                }

                Text(kind.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(sub)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(width: 100)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.bouncy)
    }

    // MARK: - Game Container

    @ViewBuilder
    private func gameContainer(for kind: GameKind) -> some View {
        switch kind {
        case .matchstick:
            MatchstickGameContainer(onExit: { presentedGame = nil })
                .environmentObject(progress)
                .environmentObject(PoemSpeechService.shared)
        case .poetryComplete:
            PoetryCompleteGameView(onExit: { presentedGame = nil })
        case .surnameMatch:
            SurnameMatchGameView(onExit: { presentedGame = nil })
        case .idiomFillBlank:
            IdiomFillBlankGameView(onExit: { presentedGame = nil })
        case .idiomDictionary:
            IdiomDictionaryView(onExit: { presentedGame = nil })
        case .xiehouyuDictionary:
            XiehouyuDictionaryView(onExit: { presentedGame = nil })
        case .sanzijing:
            SanzijingView(onExit: { presentedGame = nil })
        case .dictionary:
            DictionaryGameView(onExit: { presentedGame = nil })
        }
    }
}

// MARK: - Game Bento Card · 墨韵风

private struct GameBentoCard: View {
    let kind: GameKind
    let bestScore: Int
    let isTall: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [kind.accent.opacity(0.10), kind.accent.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: isTall ? 110 : 80)

                    ZStack {
                        RoundedRectangle(cornerRadius: isTall ? 18 : 14, style: .continuous)
                            .fill(kind.accent.opacity(0.12))
                            .frame(width: isTall ? 48 : 40, height: isTall ? 48 : 40)
                        Image(systemName: kind.systemImage)
                            .font(.system(size: isTall ? 24 : 20, weight: .medium))
                            .foregroundStyle(kind.accent)
                    }

                    Image(systemName: kind.systemImage)
                        .font(.system(size: isTall ? 42 : 32))
                        .foregroundStyle(kind.accent.opacity(0.06))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .offset(x: -6, y: 6)
                }
                .frame(height: isTall ? 110 : 80)

                VStack(alignment: .leading, spacing: 4) {
                    Text(kind.title)
                        .font(.system(size: isTall ? 17 : 16, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    Text(kind.subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if bestScore > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(bestScore)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(kind.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(kind.accent.opacity(0.08), in: Capsule())
                    .padding(10)
                }
            }
        }
        .buttonStyle(.plain)
        .drawingGroup()
    }
}

// MARK: - 火柴游戏自由模式容器

private struct MatchstickGameContainer: View {
    let onExit: () -> Void

    var body: some View {
        ZStack {
            Image("bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .accessibilityHidden(true)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.38),
                    Color.white.opacity(0.14),
                    Color(red: 0.94, green: 0.95, blue: 0.97).opacity(0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            SWAnimatedMeshGradient(
                paletteA: MatchstickGameStyle.meshA,
                paletteB: MatchstickGameStyle.meshB,
                duration: 14
            )
            .opacity(0.1)
            .ignoresSafeArea()

            LandscapeContainer {
                MatchstickContentView(
                    onExit: onExit,
                    initialProblemIndex: nil,
                    isDailyChallenge: false
                )
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    PlayView()
}