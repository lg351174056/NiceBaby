import SwiftUI

// MARK: - 成语接龙
//
// 数据全部来自本地 IdiomCatalog（idioms.json 约 2000 条；成语大全.json 富信息）。
// 视觉：墨韵新风 —— 宣纸底 #F7F5F0 + 竹青/朱砂/琥珀金 + 宋体标题 + 龙珠链。
// 交互：输入实时联想候选、龙珠链对战记录、点击龙珠看详情一键接龙。

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

// MARK: - L0 模式选择（龙珠链重设计）

private struct ModeSelect: View {
    let onBack: () -> Void
    let onPick: (IdiomSolitaireView.Mode) -> Void

    private let horizontalPadding: CGFloat = 18

    var body: some View {
        VStack(spacing: 0) {
            // 透明导航条
            ZStack {
                HStack {
                    GracefulBackButton(action: onBack)
                    Spacer()
                }
                Text("成语接龙")
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    heroCard
                    modesCard
                    rulesCard
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: Hero（🐉 统计）
    private var heroCard: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                Text("IDIOM SOLITAIRE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(Color(red: 184/255, green: 162/255, blue: 94/255))

                Text("成语接龙")
                    .font(.system(size: 26, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .tracking(4)

                Text("首尾相接 · 墨韵连珠")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 24) {
                    stat("\(IdiomCatalog.all.count)", "成语库")
                    stat("\(IdiomBestStore.challengeBest)", "最长纪录")
                    stat("\(IdiomBestStore.todayCount)", "今日已连")
                }
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 16)

            Text("🐉")
                .font(.system(size: 34))
                .modifier(FieldBob(delay: 0))
                .padding(.top, 10)
                .padding(.trailing, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppTheme.separator, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
        )
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.accentCinnabar)
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 138/255, blue: 128/255))
        }
    }

    // MARK: 三模式卡
    private var modesCard: some View {
        VStack(spacing: 12) {
            modeRow(icon: "🤖", tint: AppTheme.accentCinnabar,
                    soft: Color(red: 253/255, green: 240/255, blue: 238/255),
                    border: Color(red: 201/255, green: 100/255, blue: 66/255),
                    title: "人机对弈", desc: "和 AI 轮流接龙，把它逼入绝境", tag: "普通 / 困难 双档") {
                onPick(.battle)
            }
            modeRow(icon: "🏆", tint: Color(red: 176/255, green: 130/255, blue: 50/255),
                    soft: Color(red: 253/255, green: 246/255, blue: 227/255),
                    border: Color(red: 217/255, green: 190/255, blue: 112/255),
                    title: "最长挑战", desc: "独自续航，冲击历史最长链", tag: "纪录 \(IdiomBestStore.challengeBest) 个") {
                onPick(.challenge)
            }
            modeRow(icon: "🎬", tint: AppTheme.accentBamboo,
                    soft: Color(red: 238/255, green: 247/255, blue: 238/255),
                    border: AppTheme.fieldMint,
                    title: "自动演示", desc: "看 AI 自己表演一条完整龙链", tag: nil) {
                onPick(.autoDemo)
            }
        }
    }

    private func modeRow(icon: String, tint: Color, soft: Color, border: Color,
                         title: String, desc: String, tag: String?,
                         onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(soft)
                    Text(icon)
                        .font(.system(size: 26))
                        .modifier(FieldBob(delay: 0.2))
                }
                .frame(width: 54, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(border.opacity(0.4), lineWidth: 2)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(desc)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    if let tag {
                        Text(tag)
                            .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(tint.opacity(0.1), in: Capsule())
                            .overlay(Capsule().strokeBorder(tint.opacity(0.3), lineWidth: 1))
                            .padding(.top, 3)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(red: 160/255, green: 160/255, blue: 152/255))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(AppTheme.separator, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
            )
        }
        .buttonStyle(BounceStyle())
    }

    // MARK: 规则
    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("— 规则 —")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(Color(red: 184/255, green: 162/255, blue: 94/255))
                .frame(maxWidth: .infinity)
            ruleRow("前一个成语的尾字，须为下一个成语的首字")
            ruleRow("已用过的成语不得重复")
            ruleRow("无路可接即为绝杀，对方获胜")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppTheme.separator, lineWidth: 1)
                )
        )
    }

    private func ruleRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(Color(red: 194/255, green: 162/255, blue: 72/255))
                .frame(width: 6, height: 6)
                .padding(.top, 5)
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
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

// MARK: - 顶部栏（透明导航条）

private struct TopBar: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil
    var onBack: (() -> Void)? = nil

    var body: some View {
        ZStack {
            HStack(spacing: 12) {
                if let onBack {
                    GracefulBackButton(action: onBack)
                }
                Spacer()
                if let trailing { trailing }
            }
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }
}

// MARK: - 通用组件

// 回合状态条
private struct TurnBar: View {
    let isAI: Bool
    let isThinking: Bool
    let chainCount: Int
    let requireText: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isAI
                        ? LinearGradient(colors: [Color(red: 238/255, green: 247/255, blue: 238/255), Color(red: 223/255, green: 242/255, blue: 228/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color(red: 253/255, green: 240/255, blue: 238/255), Color(red: 251/255, green: 224/255, blue: 218/255)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(isAI ? "🤖" : "🧒")
                    .font(.system(size: 18))
            }
            .frame(width: 38, height: 38)
            .overlay(Circle().strokeBorder((isAI ? AppTheme.accentBamboo : AppTheme.accentCinnabar).opacity(0.35), lineWidth: 2))

            VStack(alignment: .leading, spacing: 2) {
                Text(isThinking ? "AI 思考中…" : (isAI ? "AI 出招了" : "轮到你出招"))
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("已连 \(chainCount) 个 · \(requireText)")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Text(isAI ? "● AI 回合" : "● 你的回合")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(colors: isAI
                        ? [Color(red: 126/255, green: 211/255, blue: 160/255), AppTheme.fieldMint]
                        : [Color(red: 224/255, green: 122/255, blue: 98/255), Color(red: 201/255, green: 100/255, blue: 66/255)],
                        startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Capsule()
                )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppTheme.separator, lineWidth: 1)
                )
        )
    }
}

// AI 思考气泡
private struct ThinkingBubble: View {
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(AppTheme.accentBamboo)
                    .frame(width: 7, height: 7)
                    .modifier(PulseDot(delay: Double(i) * 0.2))
            }
            Text("AI 正在翻成语库…")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.accentBamboo)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppTheme.accentBamboo.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                )
        )
    }

    private struct PulseDot: ViewModifier {
        let delay: Double
        @State private var on = false
        func body(content: Content) -> some View {
            content
                .opacity(on ? 0.3 : 1)
                .scaleEffect(on ? 0.85 : 1)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(delay), value: on)
                .onAppear { on = true }
        }
    }
}

// 印章卡（当前尾字 + 须接字）
private struct SealCard: View {
    let lastIdiom: String
    let requireChar: Character

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("当前接龙 · 尾字")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color(red: 176/255, green: 120/255, blue: 48/255))

                Text(attributedLast)
                    .font(.system(size: 20, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
            }
            Spacer()

            VStack(spacing: 2) {
                Text("须接")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 255/255, green: 233/255, blue: 196/255))
                Text(String(requireChar))
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .foregroundStyle(.white)
            }
            .frame(width: 64, height: 64)
            .background(
                LinearGradient(colors: [Color(red: 232/255, green: 106/255, blue: 82/255), Color(red: 176/255, green: 64/255, blue: 44/255)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(red: 255/255, green: 233/255, blue: 196/255), lineWidth: 2.5)
            )
            .shadow(color: Color(red: 176/255, green: 64/255, blue: 44/255).opacity(0.4), radius: 8, y: 3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(colors: [Color(red: 255/255, green: 253/255, blue: 246/255), Color(red: 251/255, green: 243/255, blue: 224/255)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(red: 217/255, green: 164/255, blue: 91/255).opacity(0.45), lineWidth: 2)
        )
        .shadow(color: Color(red: 140/255, green: 105/255, blue: 55/255).opacity(0.1), radius: 8, y: 4)
    }

    private var attributedLast: AttributedString {
        var s = AttributedString(lastIdiom)
        if let last = lastIdiom.last {
            let range = s.range(of: String(last)) ?? s.startIndex..<s.endIndex
            s[range].foregroundColor = Color(red: 176/255, green: 64/255, blue: 44/255)
            s[range].font = .system(size: 20, weight: .heavy, design: .serif)
        }
        return s
    }
}

// 龙珠链（对战记录）
private struct ChainSection: View {
    let chain: [ChineseIdiom]
    let isAI: (Int) -> Bool
    let isLast: (Int) -> Bool
    let onTap: (ChineseIdiom) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color(red: 194/255, green: 162/255, blue: 72/255))
                    .frame(width: 6, height: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                Text("龙珠链")
                    .font(.system(size: 14, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(chain.count) 珠")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(chain.enumerated()), id: \.offset) { idx, item in
                    ChainNode(
                        idiom: item,
                        isFirst: idx == 0,
                        isMine: !isAI(idx),
                        isCurrent: isLast(idx),
                        onTap: { onTap(item) }
                    )
                }
            }
        }
        .padding(.horizontal, 2)
    }
}

// 单颗龙珠
private struct ChainNode: View {
    let idiom: ChineseIdiom
    let isFirst: Bool
    let isMine: Bool
    let isCurrent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: beadColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Text(isFirst ? "🐉" : "🔗")
                        .font(.system(size: 12))
                }
                .frame(width: 30, height: 30)
                .overlay(Circle().strokeBorder(Color(red: 255/255, green: 246/255, blue: 224/255), lineWidth: 2))
                .shadow(color: Color(red: 160/255, green: 120/255, blue: 40/255).opacity(0.3), radius: 3, y: 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(idiom.text)
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                        .tracking(1)
                    Text(isFirst ? "开局 · 系统" : (isMine ? "你" : "AI"))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                if isCurrent {
                    Text("★ 当前")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.accentCinnabar)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.accentBamboo)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isCurrent
                        ? AnyShapeStyle(LinearGradient(colors: [Color(red: 255/255, green: 248/255, blue: 244/255), Color(red: 253/255, green: 235/255, blue: 228/255)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color.white.opacity(0.94)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isCurrent
                                ? AppTheme.accentCinnabar
                                : AppTheme.separator,
                                lineWidth: isCurrent ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var beadColors: [Color] {
        if isFirst {
            return [Color(red: 201/255, green: 160/255, blue: 80/255), Color(red: 168/255, green: 122/255, blue: 48/255)]
        }
        if isMine {
            return [Color(red: 240/255, green: 200/255, blue: 122/255), Color(red: 217/255, green: 162/255, blue: 78/255)]
        }
        return [Color(red: 143/255, green: 212/255, blue: 168/255), AppTheme.fieldMint]
    }
}

// 底部工具条
private struct BottomToolbar: View {
    let onHint: (() -> Void)?
    let onRestart: () -> Void
    let onSurrender: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            if let onHint {
                toolBtn("💡 提示", action: onHint)
            } else {
                toolBtn("💡 提示", action: {}, disabled: true)
            }
            toolBtn("🔁 重开", action: onRestart)
            if let onSurrender {
                toolBtn("🏳️ 认输", action: onSurrender)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
    }

    private func toolBtn(_ title: String, action: @escaping () -> Void, disabled: Bool = false) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                .foregroundStyle(disabled ? AppTheme.textSecondary.opacity(0.4) : AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(AppTheme.separator, lineWidth: 1)
                        )
                )
        }
        .disabled(disabled)
        .buttonStyle(BounceStyle())
    }
}

// 输入坞（safeAreaInset 底部 · 键盘自动上浮）
private struct InputDock: View {
    @Binding var input: String
    let requireChar: Character?
    let canSubmit: Bool
    let disabled: Bool
    let onSend: () -> Void
    let onHint: (() -> Void)?
    @FocusState.Binding var focused: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button(action: { onHint?() }) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(onHint != nil ? Color(red: 176/255, green: 130/255, blue: 50/255) : Color(red: 176/255, green: 130/255, blue: 50/255).opacity(0.4))
                        .frame(width: 42, height: 42)
                        .background(
                            LinearGradient(colors: [Color(red: 247/255, green: 227/255, blue: 168/255), Color(red: 232/255, green: 201/255, blue: 127/255)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color(red: 217/255, green: 162/255, blue: 78/255), lineWidth: 2)
                        )
                }
                .buttonStyle(BounceStyle())
                .disabled(disabled || onHint == nil)

                HStack(spacing: 8) {
                    TextField("", text: $input, prompt: Text(promptText).foregroundColor(Color(red: 160/255, green: 154/255, blue: 136/255)))
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                        .focused($focused)
                        .disabled(disabled)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .onSubmit { if canSubmit { onSend() } }
                        .onTapGesture { focused = true }

                    if !input.isEmpty {
                        Button {
                            input = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(red: 160/255, green: 154/255, blue: 136/255))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(
                    Color(red: 247/255, green: 243/255, blue: 232/255),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(red: 160/255, green: 120/255, blue: 60/255).opacity(0.4), lineWidth: 2)
                )

                Button(action: onSend) {
                    Text("接龙")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 68, height: 42)
                        .background(
                            canSubmit && !disabled
                                ? LinearGradient(colors: [Color(red: 232/255, green: 106/255, blue: 82/255), Color(red: 201/255, green: 100/255, blue: 66/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color(red: 200/255, green: 196/255, blue: 188/255), Color(red: 180/255, green: 176/255, blue: 168/255)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(canSubmit && !disabled ? Color(red: 138/255, green: 58/255, blue: 36/255) : Color.clear, lineWidth: 2)
                        )
                        .shadow(color: canSubmit && !disabled ? Color(red: 201/255, green: 100/255, blue: 66/255).opacity(0.35) : .clear, radius: 6, y: 3)
                }
                .buttonStyle(BounceStyle())
                .disabled(!canSubmit || disabled)
            }

            // 温和提示（不展示候选答案，让孩子自己回忆）
            if !disabled, let requireChar {
                HStack(spacing: 6) {
                    Text("请说出一个「\(String(requireChar))」开头的成语")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 138/255, blue: 128/255))
                    Spacer()
                    Text(IdiomCatalog.difficultyLabel(for: requireChar))
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(difficultyColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(difficultyColor.opacity(0.1), in: Capsule())
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(
            LinearGradient(colors: [Color(red: 255/255, green: 255/255, blue: 252/255), Color(red: 248/255, green: 245/255, blue: 238/255)],
                           startPoint: .top, endPoint: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.separator)
                .frame(height: 1)
        }
    }

    private var promptText: String {
        if let requireChar {
            return "输入「\(requireChar)」开头的成语…"
        }
        return "输入 4 字成语…"
    }

    private var difficultyColor: Color {
        guard let requireChar else { return AppTheme.textSecondary }
        switch IdiomCatalog.nextCount(of: requireChar) {
        case 0: return Color(red: 232/255, green: 100/255, blue: 82/255)
        case 1...2: return Color(red: 176/255, green: 130/255, blue: 50/255)
        default: return AppTheme.accentBamboo
        }
    }
}

// 详情弹层（龙珠详情 · 一键接龙）
private struct DetailSheet: View {
    let idiom: ChineseIdiom
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let rich = IdiomCatalog.richInfo(for: idiom.text)
        let candidates = IdiomCatalog.idiomsStarting(with: idiom.last).prefix(3).map { $0 }
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text(idiom.text)
                    .font(.system(size: 24, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .tracking(2)
                Text(verbatim: "尾「\(idiom.last)」")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.accentCinnabar, in: Capsule())
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
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(0.08)
                    .foregroundStyle(Color(red: 176/255, green: 120/255, blue: 48/255))
            }

            infoBlock("释义", rich.explanation)
            if let derivation = rich.derivation, !derivation.isEmpty {
                infoBlock("出处", derivation)
            }

            if !candidates.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("可接龙")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    HStack(spacing: 6) {
                        ForEach(candidates) { c in
                            Text(verbatim: "\(c.text) · 尾「\(c.last)」")
                                .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color(red: 176/255, green: 120/255, blue: 48/255))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color(red: 251/255, green: 243/255, blue: 224/255), in: Capsule())
                                .overlay(Capsule().strokeBorder(Color(red: 217/255, green: 164/255, blue: 91/255).opacity(0.4), lineWidth: 1.5))
                        }
                    }
                }
            }

            Button {
                dismiss()
            } label: {
                Text("知道了")
                    .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(colors: [Color(red: 126/255, green: 211/255, blue: 160/255), AppTheme.fieldMint], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(AppTheme.fieldInk, lineWidth: 2))
            }
            .buttonStyle(BounceStyle())

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(red: 255/255, green: 253/255, blue: 246/255)
                .ignoresSafeArea()
        )
    }

    private func infoBlock(_ title: String, _ content: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundStyle(AppTheme.textSecondary)
            Text(content ?? "暂无")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 74/255, green: 74/255, blue: 64/255))
                .lineSpacing(4)
                .lineLimit(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 求助候选弹层
private struct HintSheet: View {
    let candidates: [ChineseIdiom]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("求助候选")
                    .font(.system(size: 20, weight: .heavy, design: .serif))
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
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)

            if candidates.isEmpty {
                Text("无路可接 · 此为绝杀封喉")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.accentCinnabar)
                    .padding(.top, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(candidates.enumerated()), id: \.element.text) { idx, item in
                            HStack {
                                Text("\(idx + 1)")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 22, height: 22)
                                    .background(
                                        LinearGradient(colors: [Color(red: 240/255, green: 200/255, blue: 122/255), Color(red: 217/255, green: 162/255, blue: 78/255)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        in: Circle()
                                    )
                                Text(item.text)
                                    .font(.system(size: 17, weight: .heavy, design: .serif))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("尾字可接 \(IdiomCatalog.nextCount(of: item.last))")
                                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Text(IdiomCatalog.difficultyLabel(for: item.last))
                                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                                        .foregroundStyle(AppTheme.accentBamboo)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
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

// 结算卡
private struct ResultCard: View {
    let win: Bool
    let chainCount: Int
    let best: Int?
    let onRestart: () -> Void
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: win ? "crown.fill" : "flag.checkered")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(win ? AppTheme.accentCinnabar : AppTheme.textSecondary)
                .padding(18)
                .background((win ? AppTheme.accentCinnabar : AppTheme.textSecondary).opacity(0.1), in: Circle())

            Text(win ? "你赢了" : "AI 获胜")
                .font(.system(size: 24, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)

            Text("本局共 \(chainCount) 成语")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            if let best {
                Text("最长挑战纪录 \(best) 成语")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.accentBamboo)
            }

            HStack(spacing: 10) {
                Button(action: onRestart) {
                    Text("再来一局")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(AppTheme.accentCinnabar, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(BounceStyle())

                Button(action: onHome) {
                    Text("返回首页")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
                }
                .buttonStyle(BounceStyle())
            }
            .padding(.top, 2)
        }
        .padding(22)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: 18, y: 8)
        .padding(.horizontal, 28)
    }
}

// Toast
private struct Toast: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
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

// MARK: - 浮动动效
// MARK: - 对弈模式（龙珠链 + 联想输入）

private struct BattleGame: View {
    let onHome: () -> Void

    @State private var chain: [ChineseIdiom] = []
    @State private var used: Set<String> = []
    @State private var input: String = ""
    @State private var turn: Turn = .player
    @State private var status: Status = .playing
    @State private var difficulty: IdiomCatalog.Difficulty = .jinjie
    @State private var toast: String?
    @State private var aiThinking: Bool = false
    @State private var showHint: Bool = false
    @State private var detailIdiom: ChineseIdiom?
    @State private var hintUsed: Int = 0
    @State private var showDifficultyPicker = false
    @FocusState private var inputFocused: Bool

    private enum Turn { case player, ai }
    private enum Status { case playing, playerWin, aiWin }

    private var lastIdiom: ChineseIdiom? { chain.last }
    private var requireChar: Character? { lastIdiom?.last }

    private var canSubmit: Bool {
        status == .playing && turn == .player && input.count == 4
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "人机对弈", subtitle: subtitleText, trailing: AnyView(
                    Button {
                        restart()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.accentCinnabar)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.9), in: Circle())
                            .overlay(Circle().strokeBorder(AppTheme.separator, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                ), onBack: onHome)

            difficultyBar

            // 对战记录（龙珠链）—— 键盘弹出时自动收缩，始终可见
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if let lastIdiom, let rc = requireChar {
                            SealCard(lastIdiom: lastIdiom.text, requireChar: rc)
                        }

                        if aiThinking {
                            ThinkingBubble()
                        }

                        ChainSection(
                            chain: chain,
                            isAI: { idx in idx != 0 && turnForIndex(idx) == .ai },
                            isLast: { idx in idx == chain.count - 1 },
                            onTap: { detailIdiom = $0 }
                        )

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: chain.count) { _, _ in
                    // 链增长后滚到底部，避免键盘挡住最新对战记录
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: aiThinking) { _, thinking in
                    if thinking {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }
            }

            autoHintBar

            BottomToolbar(
                onHint: canShowHint ? { hintUsed += 1; showHint = true } : nil,
                onRestart: restart,
                onSurrender: status == .playing && turn == .player ? { surrender() } : nil
            )

            // 输入坞：safeAreaInset 效果（VStack 底部，键盘弹出自动上浮）
            InputDock(
                input: $input,
                requireChar: requireChar,
                canSubmit: canSubmit,
                disabled: status != .playing || turn != .player || aiThinking,
                onSend: submitPlayer,
                onHint: canShowHint ? { hintUsed += 1; showHint = true } : nil,
                focused: $inputFocused
            )
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
        .sheet(item: $detailIdiom) { item in
            DetailSheet(idiom: item)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showHint) {
            HintSheet(candidates: hintCandidates())
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDifficultyPicker) {
            DifficultyPickerSheet(
                title: "成语接龙 · 选择难度",
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
        HStack(spacing: 8) {
            // 当前难度提示（点击弹框选择）
            Button {
                showDifficultyPicker = true
            } label: {
                HStack(spacing: 5) {
                    Text("\(difficulty.emoji) \(difficulty.label)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                    Text(difficulty.subtitle)
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .opacity(0.8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .heavy))
                }
                .foregroundStyle(AppTheme.accentCinnabar)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.accentCinnabar.opacity(0.12), in: Capsule())
                .overlay(Capsule().strokeBorder(AppTheme.accentCinnabar.opacity(0.4), lineWidth: 1.5))
            }
            .buttonStyle(.plain)

            Spacer()

            if let rc = requireChar {
                HStack(spacing: 4) {
                    Text("尾字「\(String(rc))」· \(IdiomCatalog.difficultyLabel(for: rc))")
                    if let limit = difficulty.hintLimit {
                        Text("· 提示 \(max(0, limit - hintUsed))/\(limit)")
                    }
                }
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    /// 启蒙档：自动展示候选供点选
    @ViewBuilder
    private var autoHintBar: some View {
        if difficulty.showAutoHints, status == .playing, turn == .player, let rc = requireChar {
            let candidates = difficulty.poolByFirstChar[rc]?.filter { !used.contains($0.text) }.prefix(3) ?? []
            if !candidates.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(candidates), id: \.text) { idiom in
                        Button {
                            input = idiom.text
                            submitPlayer()
                        } label: {
                            Text(idiom.text)
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .foregroundStyle(AppTheme.accentBamboo)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.accentBamboo.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(AppTheme.accentBamboo.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 6)
            }
        }
    }

    // MARK: 引擎

    private func turnForIndex(_ idx: Int) -> Turn { idx == 0 ? .player : (idx % 2 == 1 ? .ai : .player) }

    private func restart() {
        let starter = IdiomCatalog.randomStarter(difficulty: difficulty)
        chain = [starter]
        used = [starter.text]
        input = ""
        turn = .player
        status = .playing
        toast = nil
        detailIdiom = nil
        aiThinking = false
        hintUsed = 0
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
        // 启蒙/入门档：玩家输入也须在识字集内
        if difficulty.restrictPlayerInput {
            let poolSet = Set(difficulty.pool.map { $0.text })
            if !poolSet.contains(text) {
                showToast("这个成语超出当前难度的识字范围，换一个试试"); return
            }
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
        inputFocused = false
        let delay = UInt64(0.55 * 1_000_000_000)
        Task {
            try? await Task.sleep(nanoseconds: delay)
            await MainActor.run {
                aiThinking = false
                guard status == .playing else { return }
                guard let rc = requireChar else { return }
                // AI 从当前难度词池中选词
                let pool = (difficulty.poolByFirstChar[rc] ?? []).filter { !used.contains($0.text) }
                guard let pick = difficulty.aiPick(from: pool) else {
                    // 词池内无路，尝试全量库 fallback（避免低档位AI卡死）
                    let fallback = IdiomCatalog.idiomsStarting(with: rc).filter { !used.contains($0.text) }
                    guard let fb = fallback.first else { status = .playerWin; return }
                    chain.append(fb)
                    used.insert(fb.text)
                    if checkDeadEnd() == .player { status = .aiWin; return }
                    turn = .player
                    return
                }
                chain.append(pick)
                used.insert(pick.text)
                if checkDeadEnd() == .player { status = .aiWin; return }
                turn = .player
            }
        }
    }

    private enum DeadSide { case neither, player, ai }
    private func checkDeadEnd() -> DeadSide {
        guard let rc = requireChar else { return .neither }
        // 用当前难度词池判断是否死路（对AI而言）
        let follow = (difficulty.poolByFirstChar[rc] ?? []).filter { !used.contains($0.text) }
        if follow.isEmpty {
            return turn == .player ? .ai : .player
        }
        return .neither
    }

    private func surrender() {
        guard status == .playing, turn == .player else { return }
        status = .aiWin
    }

    private var canShowHint: Bool {
        guard let limit = difficulty.hintLimit else { return true } // nil = 无限
        return hintUsed < limit
    }

    private func hintCandidates() -> [ChineseIdiom] {
        guard let rc = requireChar else { return [] }
        let pool = (difficulty.poolByFirstChar[rc] ?? []).filter { !used.contains($0.text) }
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
                            .foregroundStyle(AppTheme.accentCinnabar)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.9), in: Circle())
                            .overlay(Circle().strokeBorder(AppTheme.separator, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                ), onBack: onHome)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if let lastIdiom = chain.last {
                            SealCard(lastIdiom: lastIdiom.text, requireChar: lastIdiom.last)
                        }

                        ChainSection(
                            chain: chain,
                            isAI: { idx in idx != 0 },
                            isLast: { idx in idx == chain.count - 1 },
                            onTap: { detailIdiom = $0 }
                        )

                        if chain.isEmpty {
                            Text("点击「开始」推演接龙链")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .padding(.top, 24)
                        }
                        if ended {
                            Text("🏁 已绝杀 · 本链 \(chain.count) 珠")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.accentCinnabar)
                                .padding(.top, 6)
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
                }
                .scrollDismissesKeyboard(.interactively)
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
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(ended ? AppTheme.textSecondary.opacity(0.4) : AppTheme.accentCinnabar, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(BounceStyle())
            .disabled(ended)

            Button { auto.toggle() } label: {
                Text(auto ? "停止" : "自动")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(auto ? AppTheme.accentCinnabar : AppTheme.textPrimary)
                    .frame(width: 86, height: 46)
                    .background(auto ? AppTheme.accentCinnabar.opacity(0.12) : Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(auto ? AppTheme.accentCinnabar.opacity(0.4) : AppTheme.separator, lineWidth: 1))
            }
            .buttonStyle(BounceStyle())
            .disabled(ended)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 14)
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
    @FocusState private var inputFocused: Bool

    private var lastIdiom: ChineseIdiom? { chain.last }
    private var requireChar: Character? { lastIdiom?.last }

    private var canSubmit: Bool { !ended && input.count == 4 }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "最长挑战", subtitle: "独自续航 · 纪录 \(best)", trailing: AnyView(
                    Button { restart() } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.accentCinnabar)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.9), in: Circle())
                            .overlay(Circle().strokeBorder(AppTheme.separator, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                ), onBack: onHome)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if let lastIdiom, let rc = requireChar {
                            SealCard(lastIdiom: lastIdiom.text, requireChar: rc)
                        }

                        ChainSection(
                            chain: chain,
                            isAI: { _ in false },
                            isLast: { idx in idx == chain.count - 1 },
                            onTap: { detailIdiom = $0 }
                        )

                        if chain.isEmpty {
                            Text("开局成语已为你选好，请以尾字接龙，尽量接长。")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .padding(.top, 20)
                        }
                        if ended {
                            Text("🏁 绝杀封喉 · 本局 \(chain.count) 成语")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.accentCinnabar)
                                .padding(.top, 6)
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: chain.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            BottomToolbar(
                onHint: { showHint = true },
                onRestart: restart,
                onSurrender: nil
            )

            InputDock(
                input: $input,
                requireChar: requireChar,
                canSubmit: canSubmit,
                disabled: ended,
                onSend: submit,
                onHint: { showHint = true },
                focused: $inputFocused
            )
        }
        .overlay(alignment: .top) {
            if let toast { Toast(message: toast).padding(.top, 70).transition(.move(edge: .top).combined(with: .opacity)) }
        }
        .sheet(item: $detailIdiom) { item in DetailSheet(idiom: item) }
        .sheet(isPresented: $showHint) { HintSheet(candidates: hintCandidates()).presentationDetents([.medium, .large]) }
        .onAppear { if chain.isEmpty { restart() } }
    }

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

// MARK: - 统计数据（轻量持久化）

enum IdiomBestStore {
    static let challengeKey = "idiom_solitaire_challenge_best"
    static let todayKey = "idiom_solitaire_today_count"
    static let todayDateKey = "idiom_solitaire_today_date"

    static var challengeBest: Int {
        UserDefaults.standard.integer(forKey: challengeKey)
    }

    static var todayCount: Int {
        let dateKey = UserDefaults.standard.string(forKey: todayDateKey) ?? ""
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        guard dateKey == today else { return 0 }
        return UserDefaults.standard.integer(forKey: todayKey)
    }
}

#Preview {
    NavigationStack { IdiomSolitaireView() }
}
