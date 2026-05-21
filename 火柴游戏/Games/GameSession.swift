import SwiftUI

// MARK: - 通用游戏元数据

/// 游戏类型枚举：用于持久化最佳成绩 key 与统计。
enum GameKind: String, CaseIterable, Identifiable {
    case matchstick      // 火柴游戏
    case poetryComplete  // 诗词补全（隐一句 + 4 选 1）
    case surnameMatch    // 百家姓配对
    case idiomFillBlank  // 成语填空（4 字挖 1）
    case idiomDictionary // 成语大全
    case xiehouyuDictionary // 歇后语大全
    case sanzijing          // 三字经
    case dictionary         // 汉语词典

    var id: String { rawValue }

    var title: String {
        switch self {
        case .matchstick:     return "火柴游戏"
        case .poetryComplete: return "诗词补全"
        case .surnameMatch:   return "百家姓闯关"
        case .idiomFillBlank: return "成语填空"
        case .idiomDictionary:return "成语大全"
        case .xiehouyuDictionary: return "歇后语大全"
        case .sanzijing:      return "三字经"
        case .dictionary:     return "汉语词典"
        }
    }

    var subtitle: String {
        switch self {
        case .matchstick:     return "移动一根火柴，让等式成立"
        case .poetryComplete: return "古诗少了一句，从四个选项中选出来"
        case .surnameMatch:   return "看字选音、听音选字、看音选字三种模式"
        case .idiomFillBlank: return "成语缺一字，从下方候选中选出来"
        case .idiomDictionary:return "海量成语词典，支持拼音索引"
        case .xiehouyuDictionary: return "经典歇后语，支持快速搜索"
        case .sanzijing:      return "人之初，性本善"
        case .dictionary:     return "查拼音、看部首、听发音"
        }
    }

    var systemImage: String {
        switch self {
        case .matchstick:     return "function"
        case .poetryComplete: return "scroll.fill"
        case .surnameMatch:   return "person.2.fill"
        case .idiomFillBlank: return "square.dashed"
        case .idiomDictionary:return "text.book.closed.fill"
        case .xiehouyuDictionary: return "quote.bubble.fill"
        case .sanzijing:      return "book.fill"
        case .dictionary:     return "character.book.closed.fill"
        }
    }

    var palette: (Color, Color) {
        switch self {
        case .matchstick:     return (AppTheme.accentBlue, AppTheme.accentIndigo)
        case .poetryComplete: return (AppTheme.accentBlue, AppTheme.accentIndigo)
        case .surnameMatch:   return (AppTheme.accentMint, AppTheme.accentSage)
        case .idiomFillBlank: return (AppTheme.accentPurple, AppTheme.accentPink)
        case .idiomDictionary:return (AppTheme.accentBlue, AppTheme.accentPink)
        case .xiehouyuDictionary: return (Color.orange, Color.red)
        case .sanzijing:      return (Color.teal, Color.cyan)
        case .dictionary:     return (Color(red: 180/255, green: 130/255, blue: 70/255), Color(red: 210/255, green: 160/255, blue: 100/255))
        }
    }
}

// MARK: - 单局结果

struct GameResult: Equatable {
    let kind: GameKind
    /// 答对题数 / 配对成功数。
    let correct: Int
    /// 题目总数 / 配对总数。
    let total: Int
    /// 用时（秒）。可为 nil 表示不计时。
    let elapsed: TimeInterval?

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    /// 三星评分。
    var stars: Int {
        switch accuracy {
        case 1.0:        return 3
        case 0.7...:     return 2
        case 0.4...:     return 1
        default:         return 0
        }
    }
}

// MARK: - 最佳成绩（UserDefaults）

enum GameBestScoreStore {
    private static let prefix = "game.best."

    static func best(for kind: GameKind) -> Int {
        UserDefaults.standard.integer(forKey: prefix + kind.rawValue)
    }

    /// 仅在 newScore 高于历史最佳时写入。返回是否刷新。
    @discardableResult
    static func update(_ kind: GameKind, score: Int) -> Bool {
        let key = prefix + kind.rawValue
        let old = UserDefaults.standard.integer(forKey: key)
        guard score > old else { return false }
        UserDefaults.standard.set(score, forKey: key)
        return true
    }
}

// MARK: - 结算弹窗

struct GameResultSheet: View {
    let result: GameResult
    let onRetry: () -> Void
    let onExit: () -> Void

    @State private var appeared = false

    private var headlineText: String {
        switch result.stars {
        case 3: return "完美通关！"
        case 2: return "做得真棒！"
        case 1: return "继续加油！"
        default: return "再来一局吧"
        }
    }

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [result.kind.palette.0.opacity(0.18), AppTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 撒花层
            if result.stars >= 2 {
                ConfettiBurstView()
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }

            VStack(spacing: 22) {
                Image(systemName: result.kind.systemImage)
                    .font(.system(size: 56, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 110, height: 110)
                    .background(
                        LinearGradient(
                            colors: [result.kind.palette.0, result.kind.palette.1],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                    .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 4))
                    .shadow(color: result.kind.palette.0.opacity(0.35), radius: 12, y: 6)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)

                Text(headlineText)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                // 三星
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < result.stars ? "star.fill" : "star")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundStyle(i < result.stars ? AppTheme.accentYellow : AppTheme.textSecondary.opacity(0.3))
                            .scaleEffect(appeared ? 1 : 0.4)
                            .animation(
                                .spring(response: 0.55, dampingFraction: 0.55).delay(0.15 + Double(i) * 0.12),
                                value: appeared
                            )
                    }
                }

                // 数据行
                HStack(spacing: 16) {
                    statBlock(title: "答对", value: "\(result.correct) / \(result.total)")
                    if let s = result.elapsed {
                        statBlock(title: "用时", value: formatTime(s))
                    }
                    statBlock(title: "正确率", value: "\(Int(result.accuracy * 100))%")
                }

                Spacer().frame(height: 4)

                // 操作按钮
                HStack(spacing: 14) {
                    Button(action: onExit) {
                        Text("返回")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerMedium))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                                    .strokeBorder(AppTheme.textSecondary.opacity(0.2), lineWidth: 2)
                            )
                    }
                    Button(action: onRetry) {
                        Text("再来一局")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [result.kind.palette.0, result.kind.palette.1],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                            )
                            .shadow(color: result.kind.palette.0.opacity(0.35), radius: 8, y: 4)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: 440)
            .padding(.horizontal, 24)
        }
        .onAppear { appeared = true }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerSmall))
    }

    private func formatTime(_ s: TimeInterval) -> String {
        let total = Int(s.rounded())
        let m = total / 60
        let r = total % 60
        return m > 0 ? "\(m)分\(r)秒" : "\(r)秒"
    }
}

// MARK: - 撒花动效

/// 简单的 SF Symbol 粒子撒花，无第三方依赖。
struct ConfettiBurstView: View {
    private let pieces: [ConfettiPiece] = (0..<28).map { _ in ConfettiPiece.random() }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(pieces) { p in
                    ConfettiPieceView(piece: p, canvas: proxy.size)
                }
            }
        }
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let symbol: String
    let color: Color
    let startXRatio: CGFloat   // 0..1
    let endXOffset: CGFloat
    let delay: Double
    let duration: Double
    let rotation: Double
    let size: CGFloat

    static func random() -> ConfettiPiece {
        let symbols = ["sparkle", "star.fill", "heart.fill", "leaf.fill", "snowflake"]
        let colors: [Color] = [
            AppTheme.accentBlue, AppTheme.accentTerracotta, AppTheme.accentYellow,
            AppTheme.accentMint, AppTheme.accentPink, AppTheme.accentPurple
        ]
        return ConfettiPiece(
            symbol: symbols.randomElement()!,
            color: colors.randomElement()!,
            startXRatio: CGFloat.random(in: 0.05...0.95),
            endXOffset: CGFloat.random(in: -80...80),
            delay: Double.random(in: 0...0.4),
            duration: Double.random(in: 1.6...2.6),
            rotation: Double.random(in: -180...360),
            size: CGFloat.random(in: 14...26)
        )
    }
}

private struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let canvas: CGSize
    @State private var animated = false

    var body: some View {
        Image(systemName: piece.symbol)
            .font(.system(size: piece.size, weight: .black))
            .foregroundStyle(piece.color)
            .position(
                x: piece.startXRatio * canvas.width + (animated ? piece.endXOffset : 0),
                y: animated ? canvas.height + 40 : -40
            )
            .rotationEffect(.degrees(animated ? piece.rotation : 0))
            .opacity(animated ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: piece.duration).delay(piece.delay)) {
                    animated = true
                }
            }
    }
}

// MARK: - 通用游戏顶栏（关卡进度 + 退出）

struct GameTopBar<Trailing: View>: View {
    let title: String
    let progressText: String
    let palette: (Color, Color)
    let onExit: () -> Void
    var trailing: Trailing? = nil
    
    var body: some View {
        HStack {
            Button(action: onExit) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(palette.0)
                    .padding(10)
                    .background(palette.0.opacity(0.15), in: Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text(progressText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.leading, 4)
            
            Spacer()
            
            if let trailing = trailing {
                trailing
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(AppTheme.background)
    }
}

// 提供一个默认扩展，让没有 trailing 的地方依然能正常编译
extension GameTopBar where Trailing == EmptyView {
    init(title: String, progressText: String, palette: (Color, Color), onExit: @escaping () -> Void) {
        self.title = title
        self.progressText = progressText
        self.palette = palette
        self.onExit = onExit
        self.trailing = nil
    }
}
