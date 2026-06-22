import SwiftUI

// MARK: - 成语接龙
//
// 灵感：china-idiom（python 版成语工具）的接龙 API 集
//   - is_idioms_solitaire         → 出招裁判（同字接龙校验）
//   - next_idioms_solitaire       → 求助候选（按 next_count 排序）
//   - get_difficulty              → 头部难度量表
//   - counter_attack              → 困难模式 AI 绝杀反击
//   - auto_idioms_solitaire       → 自由演示整条链
//   - longest_solitaire_chain     → 挑战模式最长链
//   - get_idiom_info              → 详情卡（拼音/释义/出处/可接龙数）
//
// 数据全部来自本地 IdiomCatalog（idioms.json 约 2000 条；成语大全.json 富信息）。
// 视觉：墨韵新风 —— 宣纸底 #F7F5F0 + 益智·墨紫 + 思源宋体标题 + 轻框 Bento + 朱砂落款印。

struct IdiomSolitaireView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if let mode {
                GameContainer(mode: mode, onHome: { withAnimation(.easeInOut(duration: 0.22)) { self.mode = nil } })
            } else {
                ModeSelect(onBack: { dismiss() }, onPick: { picked in withAnimation(.easeInOut(duration: 0.22)) { self.mode = picked } })
            }
        }
        .preferredColorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
    }

    enum Mode: String, Hashable, Identifiable {
        case battle      // 对弈 AI
        case autoDemo    // 自动演示
        case challenge   // 最长挑战
        var id: String { rawValue }
    }
}

// MARK: - 模式选择

private struct ModeSelect: View {
    let onBack: () -> Void
    let onPick: (IdiomSolitaireView.Mode) -> Void

    private let horizontalPadding: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "成语接龙", subtitle: "首尾相接 · 墨韵连珠", onBack: onBack)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    heroCard

                    sectionLabel("玩法选择", en: "MODE")

                    bento(
                        BattleCard(onTap: { onPick(.battle) }),
                        AutoCard(onTap: { onPick(.autoDemo) }),
                        ChallengeCard(onTap: { onPick(.challenge) })
                    )

                    sectionLabel("规则", en: "RULES")
                    rulesCard
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 4)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: Hero
    private var heroCard: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Text("成语·接龙")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.22)
                    .foregroundStyle(AppTheme.accentInkPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.accentInkPurple.opacity(0.1), in: Capsule())

                Text("接续千年文脉")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("以尾字接首字，同字相承。和 AI 比拼绝杀，或独自追最长链。")
                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(3)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, alignment: .leading)

            // 朱砂落款印
            VStack(spacing: 1) {
                Text("接").font(.system(size: 15, weight: .bold, design: .serif)).foregroundStyle(.white)
                Text("龙").font(.system(size: 15, weight: .bold, design: .serif)).foregroundStyle(.white)
            }
            .frame(width: 38, height: 50)
            .background(AppTheme.accentCinnabar, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
    }

    private func sectionLabel(_ title: String, en: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(AppTheme.accentInkPurple)
                .frame(width: 3, height: 14)
            Text(title).font(.system(size: 15, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Text(en)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.18)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.leading, 2)
    }

    private func bento<B: View, A: View, C: View>(_ b: B, _ a: A, _ c: C) -> some View {
        VStack(spacing: 12) {
            b
            HStack(spacing: 12) { a; c }
        }
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ruleText("·", "前一个成语的尾字，须为下一个成语的首字")
            ruleText("·", "同字相承（谐音模式敬请期待）")
            ruleText("·", "已用过的成语不得重复")
            ruleText("·", "无路可接即为绝杀，对方获胜")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
    }

    private func ruleText(_ bullet: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(bullet).foregroundStyle(AppTheme.accentInkPurple).font(.system(size: 14, weight: .bold))
            Text(text).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(AppTheme.textPrimary)
        }
    }
}

// MARK: - 模式卡片

private struct BattleCard: View {
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("人机对弈")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(0.06)
                        .foregroundStyle(AppTheme.accentInkPurple)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(AppTheme.accentInkPurple.opacity(0.1), in: Capsule())

                    Text("挑战 AI · 绝杀封喉")
                        .font(.system(size: 19, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("普通 / 困难双档。困难档 AI 专挑 next_count 最少的尾字反杀。")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)

                Image(systemName: "knight.rook")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.accentInkPurple)
                    .padding(8)
                    .background(AppTheme.accentInkPurple.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .padding(14)
            }
            .frame(maxWidth: .infinity, minHeight: 168)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
        }
        .buttonStyle(BounceStyle())
    }
}

private struct AutoCard: View {
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                Text("自动演示")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.06)
                    .foregroundStyle(AppTheme.accentInkPurple)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(AppTheme.accentInkPurple.opacity(0.1), in: Capsule())

                Text("演示整链")
                    .font(.system(size: 17, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("一步步展开")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
        }
        .buttonStyle(BounceStyle())
    }
}

private struct ChallengeCard: View {
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                Text("最长挑战")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.06)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.18), in: Capsule())

                Text("追最长链")
                    .font(.system(size: 17, weight: .heavy, design: .serif))
                    .foregroundStyle(.white)

                Text("独自续航")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                LinearGradient(colors: [Color(red: 0.27, green: 0.22, blue: 0.40), Color(red: 0.20, green: 0.16, blue: 0.30)],
                                startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.black.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(BounceStyle())
    }
}

// MARK: - 游戏容器

private struct GameContainer: View {
    let mode: IdiomSolitaireView.Mode
    let onHome: () -> Void

    var body: some View {
        switch mode {
        case .battle:    BattleGame(onHome: onHome)
        case .autoDemo:  AutoDemoGame(onHome: onHome)
        case .challenge: ChallengeGame(onHome: onHome)
        }
    }
}

// MARK: - 顶部栏

private struct TopBar: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil
    var onBack: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.card, in: Circle())
                        .overlay(Circle().strokeBorder(AppTheme.separator, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 19, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.textPrimary)
                if let subtitle {
                    Text(subtitle).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer()
            if let trailing { trailing }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }
}

// MARK: - 通用子组件

private struct ChainRow: View {
    let text: String
    let isFirst: Bool
    let isAI: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isAI ? AppTheme.accentInkPurple : AppTheme.accentCinnabar)
                    .frame(width: 3, height: 26)

                Text(text)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(minHeight: 28)

                Spacer()

                Text(isFirst ? "开局" : (isAI ? "AI" : "你"))
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .tracking(0.06)
                    .foregroundStyle(isAI ? AppTheme.accentInkPurple : AppTheme.accentCinnabar)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((isAI ? AppTheme.accentInkPurple : AppTheme.accentCinnabar).opacity(0.1), in: Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct SealCard: View {
    let lastIdiom: String
    let requireChar: Character

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("当前接龙 · 尾字")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .tracking(0.18)
                    .foregroundStyle(AppTheme.textSecondary)

                Text(lastIdiom)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("须接")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.1)
                    .foregroundStyle(.white)
                Text(String(requireChar))
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .foregroundStyle(.white)
            }
            .frame(width: 60, height: 60)
            .background(AppTheme.accentCinnabar, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
    }
}

private struct DetailSheet: View {
    let idiom: ChineseIdiom
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let rich = IdiomCatalog.richInfo(for: idiom.text)
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(idiom.text)
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(AppTheme.background, in: Circle())
                }
                .buttonStyle(.plain)
            }

            if let pinyin = rich.pinyin, !pinyin.isEmpty {
                Text(pinyin)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .tracking(0.08)
                    .foregroundStyle(AppTheme.accentInkPurple)
            }

            infoBlock("释义", rich.explanation)
            if let derivation = rich.derivation, !derivation.isEmpty {
                infoBlock("出处", derivation)
            }
            if let example = rich.example, !example.isEmpty {
                infoBlock("例句", example)
            }

            HStack(spacing: 10) {
                statChip("可接龙数", value: "\(IdiomCatalog.nextCount(of: idiom.last))")
                statChip("首字", value: String(idiom.first))
                statChip("尾字", value: String(idiom.last))
            }

            Spacer()
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func infoBlock(_ title: String, _ content: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.18)
                .foregroundStyle(AppTheme.textSecondary)
            Text(content ?? "暂无")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statChip(_ title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(AppTheme.textSecondary)
            Text(value).font(.system(size: 16, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
    }
}

private struct HintSheet: View {
    let candidates: [ChineseIdiom]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("求助候选")
                    .font(.system(size: 22, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(AppTheme.card, in: Circle())
                }
                .buttonStyle(.plain)
            }

            Text("按可接龙数从少到多排序，少的更易绝杀对手")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)

            if candidates.isEmpty {
                Text("无路可接 · 此为绝杀封喉")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.accentCinnabar)
                    .padding(.top, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(candidates.enumerated()), id: \.element.text) { idx, item in
                            HStack {
                                Text(item.text)
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("尾字可接 \(IdiomCatalog.nextCount(of: item.last))")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Text(IdiomCatalog.difficultyLabel(for: item.last))
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.accentInkPurple)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
                        }
                    }
                    .padding(.bottom, 8)
                }
            }

            Spacer()
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.background.ignoresSafeArea())
    }
}

private struct ResultCard: View {
    let win: Bool
    let chainCount: Int
    let best: Int?
    let onRestart: () -> Void
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: win ? "crown.fill" : "flag.checkered")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(win ? AppTheme.accentCinnabar : AppTheme.textSecondary)
                .padding(20)
                .background((win ? AppTheme.accentCinnabar : AppTheme.textSecondary).opacity(0.1), in: Circle())

            Text(win ? "你赢了" : "AI 获胜")
                .font(.system(size: 26, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)

            Text("本局共 \(chainCount) 成语")
                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            if let best {
                Text("最长挑战纪录 \(best) 成语")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.accentInkPurple)
            }

            HStack(spacing: 12) {
                Button(action: onRestart) {
                    Text("再来一局")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accentInkPurple, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(BounceStyle())

                Button(action: onHome) {
                    Text("返回首页")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
                }
                .buttonStyle(BounceStyle())
            }
            .padding(.top, 4)
        }
        .padding(24)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
        .padding(.horizontal, 28)
    }
}

private struct Toast: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color(red: 0.15, green: 0.13, blue: 0.10).opacity(0.92), in: Capsule())
            .shadow(color: Color.black.opacity(0.15), radius: 10, y: 4)
    }
}

private struct BounceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - 对弈模式

private struct BattleGame: View {
    let onHome: () -> Void

    @State private var chain: [ChineseIdiom] = []
    @State private var used: Set<String> = []
    @State private var input: String = ""
    @State private var turn: Turn = .player
    @State private var status: Status = .playing
    @State private var aiHard: Bool = false
    @State private var toast: String?
    @State private var aiThinking: Bool = false
    @State private var showHint: Bool = false
    @State private var detailIdiom: ChineseIdiom?

    private enum Turn { case player, ai }
    private enum Status { case playing, playerWin, aiWin }

    private var lastIdiom: ChineseIdiom? { chain.last }
    private var requireChar: Character? { lastIdiom?.last }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "人机对弈", subtitle: subtitleText, trailing: AnyView(
                    Button {
                        restart()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.accentInkPurple)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.accentInkPurple.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                ), onBack: onHome)

            difficultyBar

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if let lastIdiom, let rc = requireChar {
                            SealCard(lastIdiom: lastIdiom.text, requireChar: rc)
                        }

                        sectionLabel("接龙链 · \(chain.count)")

                        VStack(spacing: 8) {
                            ForEach(Array(chain.enumerated()), id: \.offset) { idx, item in
                                ChainRow(text: item.text, isFirst: idx == 0, isAI: idx != 0 && turnForIndex(idx) == .ai, onTap: { detailIdiom = item })
                            }
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .onChange(of: chain.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }

            inputBar
        }
        .overlay(alignment: .center) {
            if status != .playing {
                ResultCard(win: status == .playerWin, chainCount: chain.count, best: nil, onRestart: restart, onHome: onHome)
            }
        }
        .overlay(alignment: .top) {
            if let toast {
                Toast(message: toast).padding(.top, 70).transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(item: $detailIdiom) { item in DetailSheet(idiom: item) }
        .sheet(isPresented: $showHint) {
            HintSheet(candidates: hintCandidates())
                .presentationDetents([.medium, .large])
        }
        .onAppear { if chain.isEmpty { restart() } }
    }

    private var subtitleText: String {
        switch status {
        case .playing: return turn == .player ? "轮到你出招" : "AI 思考中…"
        case .playerWin: return "你赢了"
        case .aiWin: return "AI 获胜"
        }
    }

    private var difficultyBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 3) {
                diffSegment("普通", on: !aiHard)
                diffSegment("困难", on: aiHard)
            }
            Spacer()
            if let rc = requireChar {
                Text("尾字「\(String(rc))」· \(IdiomCatalog.difficultyLabel(for: rc)) · 可接 \(IdiomCatalog.nextCount(of: rc))")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func diffSegment(_ title: String, on: Bool) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) { aiHard = (title == "困难") }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(on ? AppTheme.accentInkPurple : AppTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(on ? AppTheme.accentInkPurple.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ title: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous).fill(AppTheme.accentInkPurple).frame(width: 3, height: 14)
            Text(title).font(.system(size: 14, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.textPrimary)
            Spacer()
        }
        .padding(.leading, 2)
    }

    private var inputBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button { showHint = true } label: {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(AppTheme.accentCinnabar, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(BounceStyle())
                .disabled(status != .playing || turn != .player)

                TextField("", text: $input, prompt: Text("输入 4 字成语").foregroundColor(AppTheme.textSecondary))
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
                    .disabled(status != .playing || turn != .player)
                    .submitLabel(.done)
                    .onSubmit { submitPlayer() }

                Button { submitPlayer() } label: {
                    Text("出招")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 48)
                        .background(canSubmit ? AppTheme.accentInkPurple : AppTheme.textSecondary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(BounceStyle())
                .disabled(!canSubmit)
            }

            HStack(spacing: 10) {
                Spacer()
                Button { surrender() } label: {
                    Text("认输").font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(AppTheme.card, in: Capsule())
                        .overlay(Capsule().strokeBorder(AppTheme.separator, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(status != .playing || turn != .player)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(AppTheme.background)
    }

    private var canSubmit: Bool {
        status == .playing && turn == .player && input.count == 4
    }

    // MARK: 引擎
    private func turnForIndex(_ idx: Int) -> Turn { idx == 0 ? .player : (idx % 2 == 1 ? .ai : .player) }

    private func restart() {
        let starter = IdiomCatalog.randomStarter()
        chain = [starter]
        used = [starter.text]
        input = ""
        turn = .player
        status = .playing
        toast = nil
        detailIdiom = nil
    }

    private func submitPlayer() {
        guard canSubmit else { return }
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        defer { input = "" }

        guard IdiomCatalog.contains(text) else { showToast("“\(text)”不是已收录成语"); return }
        guard !used.contains(text) else { showToast("“\(text)”已经用过了"); return }
        guard let prev = lastIdiom, IdiomCatalog.chainable(prev.text, text) else {
            showToast("须以「\(String(requireChar ?? " "))」为首字"); return
        }

        appendIdiom(text)
        if checkDeadEnd() == .ai { status = .playerWin; return }
        turn = .ai
        runAI()
    }

    private func appendIdiom(_ text: String) {
        let idiom = ChineseIdiom(text: text, explanation: IdiomCatalog.all.first { $0.text == text }?.explanation, example: nil)
        chain.append(idiom)
        used.insert(text)
    }

    private func runAI() {
        aiThinking = true
        let delay = UInt64(0.55 * 1_000_000_000)
        Task {
            try? await Task.sleep(nanoseconds: delay)
            await MainActor.run {
                aiThinking = false
                guard status == .playing else { return }
                guard let rc = requireChar else { return }
                let pool = IdiomCatalog.idiomsStarting(with: rc).filter { !used.contains($0.text) }
                guard let pick = aiPick(from: pool) else {
                    status = .playerWin
                    return
                }
                chain.append(pick)
                used.insert(pick.text)
                if checkDeadEnd() == .player { status = .aiWin; return }
                turn = .player
            }
        }
    }

    private func aiPick(from pool: [ChineseIdiom]) -> ChineseIdiom? {
        guard !pool.isEmpty else { return nil }
        if aiHard {
            // 困难：选尾字可接数最少的，绝杀反击
            return pool.min { a, b in
                let na = IdiomCatalog.nextCount(of: a.last)
                let nb = IdiomCatalog.nextCount(of: b.last)
                if na != nb { return na < nb }
                return Bool.random()
            }
        } else {
            // 普通：偏向尾字可接数较多，给玩家留路
            return pool.max { a, b in
                let na = IdiomCatalog.nextCount(of: a.last)
                let nb = IdiomCatalog.nextCount(of: b.last)
                if na != nb { return na < nb }
                return Bool.random()
            }
        }
    }

    private enum DeadSide { case neither, player, ai }
    private func checkDeadEnd() -> DeadSide {
        guard let rc = requireChar else { return .neither }
        let follow = IdiomCatalog.idiomsStarting(with: rc).filter { !used.contains($0.text) }
        if follow.isEmpty {
            // 刚下的那一方让对手无路 → 刚下的方赢。当前 turn 已切到对手，故对手输。
            return turn == .player ? .ai : .player
        }
        return .neither
    }

    private func surrender() {
        guard status == .playing, turn == .player else { return }
        status = .aiWin
    }

    private func hintCandidates() -> [ChineseIdiom] {
        guard let rc = requireChar else { return [] }
        let pool = IdiomCatalog.idiomsStarting(with: rc).filter { !used.contains($0.text) }
        return pool.sorted { a, b in
            let na = IdiomCatalog.nextCount(of: a.last)
            let nb = IdiomCatalog.nextCount(of: b.last)
            return na == nb ? a.text < b.text : na < nb
        }
        .prefix(14)
        .map { $0 }
    }

    private func showToast(_ msg: String) {
        withAnimation(.easeOut(duration: 0.2)) { toast = msg }
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            await MainActor.run { withAnimation(.easeOut(duration: 0.2)) { toast = nil } }
        }
    }
}

// MARK: - 自动演示模式

private struct AutoDemoGame: View {
    let onHome: () -> Void

    @State private var chain: [ChineseIdiom] = []
    @State private var used: Set<String> = []
    @State private var auto: Bool = false
    @State private var ended: Bool = false
    @State private var detailIdiom: ChineseIdiom?

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "自动演示", subtitle: "逐链推演 · 同字相承", trailing: AnyView(
                    Button { restart() } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.accentInkPurple)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.accentInkPurple.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                ), onBack: onHome)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if let lastIdiom = chain.last {
                            SealCard(lastIdiom: lastIdiom.text, requireChar: lastIdiom.last)
                        }

                        sectionLabel("接龙链 · \(chain.count) \(ended ? "· 绝杀" : "")")

                        VStack(spacing: 8) {
                            ForEach(Array(chain.enumerated()), id: \.offset) { idx, item in
                                ChainRow(text: item.text, isFirst: idx == 0, isAI: idx != 0, onTap: { detailIdiom = item })
                            }
                            if chain.isEmpty {
                                Text("点击「下一步」开始推演接龙链")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .padding(.top, 30)
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .onChange(of: chain.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }

            controlBar
        }
        .sheet(item: $detailIdiom) { item in DetailSheet(idiom: item) }
        .onAppear { if chain.isEmpty { kickstart() } }
        .onDisappear { auto = false }
    }

    private var controlBar: some View {
        HStack(spacing: 12) {
            Button { stepNext() } label: {
                Label(ended ? "已绝杀" : (chain.isEmpty ? "开始" : "下一步"), systemImage: "play.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(ended ? AppTheme.textSecondary.opacity(0.4) : AppTheme.accentInkPurple, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(BounceStyle())
            .disabled(ended)

            Button { auto.toggle() } label: {
                Text(auto ? "停止" : "自动")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(auto ? AppTheme.accentInkPurple : AppTheme.textPrimary)
                    .frame(width: 86, height: 48)
                    .background(auto ? AppTheme.accentInkPurple.opacity(0.12) : AppTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
            }
            .buttonStyle(BounceStyle())
            .disabled(ended)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(AppTheme.background)
        .onChange(of: auto) { _, isOn in
            if isOn { autoLoop() }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous).fill(AppTheme.accentInkPurple).frame(width: 3, height: 14)
            Text(title).font(.system(size: 14, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.textPrimary)
            Spacer()
        }
        .padding(.leading, 2)
    }

    private func kickstart() {
        let starter = IdiomCatalog.randomStarter()
        chain = [starter]
        used = [starter.text]
    }

    private func restart() {
        auto = false
        ended = false
        kickstart()
    }

    private func stepNext() {
        guard !ended, let rc = chain.last?.last else { return }
        let pool = IdiomCatalog.idiomsStarting(with: rc).filter { !used.contains($0.text) }
        // 演示模式：选尾字可接数较多的，链尽量长
        guard let pick = pool.max(by: { IdiomCatalog.nextCount(of: $0.last) < IdiomCatalog.nextCount(of: $1.last) }) else {
            ended = true; auto = false; return
        }
        chain.append(pick)
        used.insert(pick.text)
        if IdiomCatalog.nextCount(of: pick.last) == 0 { ended = true; auto = false }
    }

    private func autoLoop() {
        guard auto, !ended else { return }
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run {
                stepNext()
                if auto && !ended { autoLoop() }
            }
        }
    }
}

// MARK: - 最长挑战模式

private struct ChallengeGame: View {
    let onHome: () -> Void
    private let bestKey = "idiom_solitaire_challenge_best"

    @State private var chain: [ChineseIdiom] = []
    @State private var used: Set<String> = []
    @State private var input: String = ""
    @State private var ended: Bool = false
    @State private var toast: String?
    @State private var showHint: Bool = false
    @State private var detailIdiom: ChineseIdiom?
    @State private var best: Int = UserDefaults.standard.integer(forKey: "idiom_solitaire_challenge_best")

    private var lastIdiom: ChineseIdiom? { chain.last }
    private var requireChar: Character? { lastIdiom?.last }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "最长挑战", subtitle: "独自续航 · 纪录 \(best)", trailing: AnyView(
                    Button { restart() } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.accentInkPurple)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.accentInkPurple.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                ), onBack: onHome)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if let lastIdiom, let rc = requireChar {
                            SealCard(lastIdiom: lastIdiom.text, requireChar: rc)
                        }

                        sectionLabel("当前链长 · \(chain.count)")

                        VStack(spacing: 8) {
                            ForEach(Array(chain.enumerated()), id: \.offset) { idx, item in
                                ChainRow(text: item.text, isFirst: idx == 0, isAI: false, onTap: { detailIdiom = item })
                            }
                            if chain.isEmpty {
                                Text("开局成语已为你选好，请以尾字接龙，尽量接长。")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .padding(.top, 20)
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .onChange(of: chain.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }

            inputBar
        }
        .overlay(alignment: .top) {
            if let toast { Toast(message: toast).padding(.top, 70).transition(.move(edge: .top).combined(with: .opacity)) }
        }
        .sheet(item: $detailIdiom) { item in DetailSheet(idiom: item) }
        .sheet(isPresented: $showHint) { HintSheet(candidates: hintCandidates()).presentationDetents([.medium, .large]) }
        .onAppear { if chain.isEmpty { restart() } }
    }

    private func sectionLabel(_ title: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous).fill(AppTheme.accentInkPurple).frame(width: 3, height: 14)
            Text(title).font(.system(size: 14, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.textPrimary)
            Spacer()
        }
        .padding(.leading, 2)
    }

    private var inputBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button { showHint = true } label: {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(AppTheme.accentCinnabar, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(BounceStyle())
                .disabled(ended)

                TextField("", text: $input, prompt: Text("接「\(String(requireChar ?? " "))」的成语").foregroundColor(AppTheme.textSecondary))
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
                    .disabled(ended)
                    .submitLabel(.done)
                    .onSubmit { submit() }

                Button { submit() } label: {
                    Text("接龙")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 48)
                        .background(canSubmit ? AppTheme.accentInkPurple : AppTheme.textSecondary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(BounceStyle())
                .disabled(!canSubmit)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(AppTheme.background)
    }

    private var canSubmit: Bool { !ended && input.count == 4 }

    private func restart() {
        let starter = IdiomCatalog.randomStarter()
        chain = [starter]
        used = [starter.text]
        input = ""
        ended = false
        toast = nil
        detailIdiom = nil
    }

    private func submit() {
        guard canSubmit else { return }
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        defer { input = "" }
        guard IdiomCatalog.contains(text) else { showToast("“\(text)”不是已收录成语"); return }
        guard !used.contains(text) else { showToast("“\(text)”已经用过了"); return }
        guard let prev = lastIdiom, IdiomCatalog.chainable(prev.text, text) else {
            showToast("须以「\(String(requireChar ?? " "))」为首字"); return
        }
        appendIdiom(text)
        // 绝杀判定：接下去没人能接
        if let rc = requireChar, IdiomCatalog.idiomsStarting(with: rc).filter({ !used.contains($0.text) }).isEmpty {
            ended = true
            finishChallenge()
        }
    }

    private func appendIdiom(_ text: String) {
        let idiom = ChineseIdiom(text: text, explanation: IdiomCatalog.all.first { $0.text == text }?.explanation, example: nil)
        chain.append(idiom)
        used.insert(text)
    }

    private func finishChallenge() {
        if chain.count > best {
            best = chain.count
            UserDefaults.standard.set(best, forKey: bestKey)
            showToast("新纪录！\(best) 成语")
        } else {
            showToast("绝杀封喉 · 本局 \(chain.count) 成语")
        }
    }

    private func hintCandidates() -> [ChineseIdiom] {
        guard let rc = requireChar else { return [] }
        let pool = IdiomCatalog.idiomsStarting(with: rc).filter { !used.contains($0.text) }
        return pool.sorted { a, b in
            let na = IdiomCatalog.nextCount(of: a.last)
            let nb = IdiomCatalog.nextCount(of: b.last)
            return na == nb ? a.text < b.text : na < nb
        }.prefix(14).map { $0 }
    }

    private func showToast(_ msg: String) {
        withAnimation(.easeOut(duration: 0.2)) { toast = msg }
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            await MainActor.run { withAnimation(.easeOut(duration: 0.2)) { toast = nil } }
        }
    }
}

#Preview {
    NavigationStack { IdiomSolitaireView() }
}