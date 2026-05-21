import SwiftUI

// MARK: - 益智 Tab 主页：游戏卡片网格
//
// 当前包含 4 个游戏：
// 1) 火柴游戏（已有，自由模式）
// 2) 诗词接龙
// 3) 百家姓配对
// 4) 成语接龙
//
// 火柴游戏使用横屏容器（沿用 HomeView 的 LandscapeContainer），
// 其他游戏直接竖屏展示。

struct PlayView: View {
    @EnvironmentObject private var progress: AppProgressStore

    @State private var presentedGame: GameKind? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 固定 header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        Text("益智")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentPurple.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.accentPurple)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(AppTheme.background)

                // 可滚动内容
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        headerCard
                        grid
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .background(AppTheme.background.ignoresSafeArea())
            }
        }
        .fullScreenCover(item: $presentedGame) { kind in
            gameContainer(for: kind)
        }
    }

    // MARK: - 顶部摘要

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text("今天玩点什么？")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("已通关火柴 \(progress.totalMatchstickSolves) 道 · 连续学习 \(progress.streakDays) 天")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerLarge))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerLarge)
                .strokeBorder(AppTheme.separator, lineWidth: 1)
        )
    }

    // MARK: - 卡片网格

    private var grid: some View {
        let cols = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
        return LazyVGrid(columns: cols, spacing: 14) {
            ForEach(GameKind.allCases) { kind in
                GameEntryCard(kind: kind, bestScore: GameBestScoreStore.best(for: kind)) {
                    presentedGame = kind
                }
            }
        }
    }

    // MARK: - 游戏容器

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

// MARK: - 单个游戏入口卡片

private struct GameEntryCard: View {
    let kind: GameKind
    let bestScore: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                        .fill(
                            LinearGradient(
                                colors: [kind.palette.0, kind.palette.1],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: kind.systemImage)
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundStyle(.white)
                }
                .frame(height: 100)
                .overlay(alignment: .topTrailing) {
                    if bestScore > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill").font(.system(size: 10, weight: .bold))
                            Text("\(bestScore)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.black.opacity(0.28), in: Capsule())
                        .padding(8)
                    }
                }

                Text(kind.title)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(kind.subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerLarge))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerLarge)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 火柴游戏自由模式容器
//
// 横屏 + 网格背景，复用 HomeView 中既有的 LandscapeContainer 与 SWAnimatedMeshGradient。
// 自由模式：不指定题号（沿用书签）、非每日挑战。

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
