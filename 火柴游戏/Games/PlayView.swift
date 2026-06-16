import SwiftUI

// MARK: - 益智 Tab · 墨紫色

struct PlayView: View {
    @EnvironmentObject private var progress: AppProgressStore

    @State private var presentedGame: GameKind? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        Text("益智")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentInkPurple.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.accentInkPurple)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(AppTheme.background)

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

    // MARK: - 顶部摘要 · 深色卡

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentInkPurple, AppTheme.accentIndigo],
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
                    .font(.system(size: 18, weight: .heavy, design: .serif))
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
        .shadow(color: AppTheme.inkShadow, radius: 4, x: 0, y: 2)
    }

    // MARK: - 游戏网格 · 墨韵轻边框

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

// MARK: - 游戏入口卡片 · 墨韵风

private struct GameEntryCard: View {
    let kind: GameKind
    let bestScore: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                        .fill(kind.accent.opacity(0.1))
                        .frame(height: 80)
                    Image(systemName: kind.systemImage)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(kind.accent)
                }
                .overlay(alignment: .topTrailing) {
                    if bestScore > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill").font(.system(size: 10, weight: .bold))
                            Text("\(bestScore)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(kind.accent)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(kind.accent.opacity(0.08), in: Capsule())
                        .padding(8)
                    }
                }

                Text(kind.title)
                    .font(.system(size: 17, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(kind.subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
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
            .shadow(color: AppTheme.inkShadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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