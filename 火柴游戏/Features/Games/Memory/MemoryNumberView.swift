import SwiftUI
import Combine

// MARK: - 记数训练（益智 · 专注力乐园）

struct MemoryNumberView: View {
    let onExit: () -> Void

    enum Difficulty: String, CaseIterable, Identifiable {
        case easy
        case normal
        case hard
        case hell

        var id: String { rawValue }

        var title: String {
            switch self {
            case .easy: return "简单"
            case .normal: return "中等"
            case .hard: return "困难"
            case .hell: return "炼狱"
            }
        }

        var time: Double {
            switch self {
            case .easy: return 10
            case .normal: return 8
            case .hard: return 6.5
            case .hell: return 5
            }
        }

        var startDigits: Int {
            switch self {
            case .easy: return 3
            case .normal: return 4
            case .hard: return 5
            case .hell: return 6
            }
        }

        var maxDigits: Int {
            switch self {
            case .easy: return 10
            case .normal: return 15
            case .hard: return 20
            case .hell: return 30
            }
        }

        var color: Color {
            switch self {
            case .easy: return Color(red: 0.28, green: 0.79, blue: 0.52)
            case .normal: return Color(red: 0.18, green: 0.62, blue: 0.43)
            case .hard: return Color(red: 0.85, green: 0.60, blue: 0.15)
            case .hell: return Color(red: 0.70, green: 0.30, blue: 0.30)
            }
        }

        var storeKey: String {
            rawValue
        }
    }

    private enum Phase {
        case idle
        case showing
        case input
    }

    @State private var difficulty: Difficulty? = nil
    @State private var digits = 3
    @State private var currentDigits = 3
    @State private var secret = ""
    @State private var input = ""
    @State private var round = 0
    @State private var score = 0
    @State private var phase: Phase = .idle
    @State private var displayTime = 0.0
    @State private var startDate = Date()
    @State private var remaining = 0.0
    @State private var showFail = false
    @State private var showSuccess = false
    @State private var failBest = 0
    @State private var feedback = ""

    private let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

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
            guard phase == .showing else { return }
            let left = displayTime - Date().timeIntervalSince(startDate)
            remaining = max(0, left)
            if remaining <= 0 {
                phase = .input
            }
        }
    }

    // MARK: - 背景点缀

    private var backgroundDecorations: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [Color(red: 1.0, green: 0.92, blue: 0.55),
                                                Color(red: 1.0, green: 0.78, blue: 0.30)],
                                       center: .center, startRadius: 0, endRadius: 34)
                    )
                    .frame(width: 68, height: 68)
                    .opacity(0.45)
                    .position(x: w * 0.15, y: h * 0.10)

                cloud
                    .opacity(0.5)
                    .position(x: w * 0.78, y: h * 0.12)
                cloud
                    .opacity(0.35)
                    .scaleEffect(0.7)
                    .position(x: w * 0.35, y: h * 0.22)

                ForEach(0..<12, id: \.self) { i in
                    Text("✨")
                        .font(.system(size: i % 3 == 0 ? 16 : 13))
                        .opacity(0.35)
                        .position(x: w * Double((i * 73) % 100) / 100,
                                  y: h * Double((i * 41) % 100) / 100)
                }

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
                Text("记数训练")
                    .font(.system(size: 18, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Text("🧠")
                .font(.system(size: 50))
                .padding(.top, 22)

            Text("记数训练")
                .font(.system(size: 34, weight: .black, design: .serif))
                .tracking(3)
                .foregroundStyle(AppTheme.fieldInk)
                .padding(.top, 10)

            Text("记住随机数字，倒计时后默写")
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
                            Text(level.iconText)
                                .font(.system(size: 28))
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
                                Text("记忆 \(Int(level.time))s · \(level.startDigits)~\(level.maxDigits) 位")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.fieldMoss)
                                let best = MemoryNumberStore.bestScore(for: level.storeKey)
                                Text(best > 0 ? "最佳 \(best) 轮" : "还没玩过")
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

            // 初始位数
            HStack(spacing: 18) {
                Button {
                    digits = max(1, digits - 1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.fieldInk)
                        .frame(width: 46, height: 46)
                        .background(Color.white.opacity(0.88), in: Circle())
                        .overlay(Circle().strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 1.5))
                }
                .buttonStyle(.plain)

                VStack(spacing: 2) {
                    Text("\(digits)")
                        .font(.system(size: 32, weight: .black, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                    Text("初始位数")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.fieldMoss)
                }
                .frame(minWidth: 60)

                Button {
                    digits = min(20, digits + 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.fieldInk)
                        .frame(width: 46, height: 46)
                        .background(Color.white.opacity(0.88), in: Circle())
                        .overlay(Circle().strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 22)

            Spacer()
        }
    }

    // MARK: - 游戏界面

    private var gameView: some View {
        VStack(spacing: 0) {
            header

            Spacer(minLength: 14)

            VStack(spacing: 0) {
                HStack {
                    Text("第 \(round) 轮 · \(currentDigits) 位")
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
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.fieldMoss)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)

            // 记忆数字展示区
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(AppTheme.fieldOlive.opacity(0.2), lineWidth: 1.5)
                    )
                    .frame(height: 130)

                if phase == .showing {
                    Text(secret)
                        .font(.system(size: numberFontSize, weight: .black, design: .monospaced))
                        .foregroundStyle(AppTheme.fieldInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                        .padding(.horizontal, 16)
                } else if phase == .input {
                    Text("? ? ?")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(AppTheme.fieldMossLight)
                }
            }
            .padding(.bottom, 10)

            // 进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.55))
                    Capsule()
                        .fill(LinearGradient(colors: [Color(red: 0.28, green: 0.79, blue: 0.52),
                                                      Color(red: 0.85, green: 0.60, blue: 0.15)],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progressRatio)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)

            // 输入槽
            inputBoxes
                .padding(.bottom, 12)

            keypad

            Text(feedback)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(feedback.contains("✅") ? Color(red: 0.16, green: 0.62, blue: 0.36)
                                  : feedback.contains("⚠️") ? Color(red: 0.75, green: 0.35, blue: 0.35)
                                  : AppTheme.fieldMoss)
                .frame(minHeight: 24)
                .padding(.bottom, 6)

                HStack(spacing: 8) {
                    buttonGhost("放弃") { giveUp() }
                    buttonGhost("重新开始") { restartRound() }
                }
            }

            Spacer(minLength: 14)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay {
            if showSuccess {
                successOverlay
            } else if showFail {
                failOverlay
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            GracefulBackButton(action: onExit)

            Text("记数训练 · \(difficulty?.title ?? "")")
                .font(.system(size: 15, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
                .frame(maxWidth: .infinity)

            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .bold))
                Text(String(format: "%.1fs", remaining))
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(AppTheme.fieldInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.8)))
            .overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.2), lineWidth: 1))
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var inputBoxes: some View {
        let count = currentDigits
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4),
                            count: count <= 6 ? count : 10)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0..<count, id: \.self) { i in
                Text(i < input.count ? String(input[input.index(input.startIndex, offsetBy: i)]) : "·")
                    .font(.system(size: count <= 6 ? 24 : 16, weight: .heavy, design: .monospaced))
                    .foregroundStyle(i < input.count ? AppTheme.fieldInk : AppTheme.fieldMossLight)
                    .frame(maxWidth: .infinity)
                    .frame(height: count <= 6 ? 48 : 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.92))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(AppTheme.fieldOlive.opacity(0.18), lineWidth: 1)
                    )
            }
        }
    }

    private var keypad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "确定"], id: \.self) { key in
                Button {
                    handleKey(key)
                } label: {
                    Text(key)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(key == "确定" ? .white : AppTheme.fieldInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(key == "确定"
                                      ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.28, green: 0.79, blue: 0.52),
                                                                                Color(red: 0.18, green: 0.62, blue: 0.43)],
                                                                     startPoint: .top, endPoint: .bottom))
                                      : AnyShapeStyle(Color.white.opacity(0.9)))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(key == "确定" ? Color.white.opacity(0.3)
                                            : AppTheme.fieldOlive.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var promptText: String {
        switch phase {
        case .showing: return "记住它！倒计时后开始输入"
        case .input: return "请默写刚才的数字："
        case .idle: return ""
        }
    }

    private var progressRatio: Double {
        guard displayTime > 0 else { return 0 }
        return max(0, min(1, remaining / displayTime))
    }

    private var numberFontSize: CGFloat {
        let n = CGFloat(currentDigits)
        return max(14, min(44, 300 / n))
    }

    // MARK: - 逻辑

    private func startGame(_ level: Difficulty) {
        difficulty = level
        round = 0
        score = 0
        input = ""
        showFail = false
        showSuccess = false
        feedback = ""
        currentDigits = min(max(level.startDigits, digits), level.maxDigits)
        nextRound()
    }

    private func nextRound() {
        guard let difficulty else { return }
        round += 1
        currentDigits = min(difficulty.maxDigits,
                           max(difficulty.startDigits, difficulty.startDigits + score))
        secret = generateNumber(currentDigits)
        input = ""
        phase = .showing
        displayTime = difficulty.time
        startDate = Date()
        remaining = displayTime
        feedback = ""
        showSuccess = false
    }

    private func restartRound() {
        guard let difficulty else { return }
        round = 0
        score = 0
        input = ""
        showFail = false
        showSuccess = false
        currentDigits = min(max(difficulty.startDigits, digits), difficulty.maxDigits)
        nextRound()
    }

    private func generateNumber(_ n: Int) -> String {
        var s = ""
        for _ in 0..<n {
            s += String(Int.random(in: 0...9))
        }
        return s
    }

    private func handleKey(_ key: String) {
        guard phase == .input else { return }
        if key == "⌫" {
            if !input.isEmpty { input.removeLast() }
        } else if key == "确定" {
            submit()
        } else if input.count < currentDigits {
            input += key
        }
    }

    private func submit() {
        guard phase == .input else { return }
        if input.count != currentDigits {
            feedback = "⚠️ 位数还没输满"
            return
        }
        if input == secret {
            score += 1
            feedback = ""
            showSuccess = true
        } else {
            fail()
        }
    }

    private func fail() {
        phase = .idle
        if let difficulty {
            _ = MemoryNumberStore.update(difficulty.storeKey, score: score)
            failBest = MemoryNumberStore.bestScore(for: difficulty.storeKey)
        }
        showFail = true
    }

    private func giveUp() {
        difficulty = nil
        showFail = false
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

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.22).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 56))
                Text("恭喜答对！")
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("下一轮将挑战 \(min(currentDigits + 1, difficulty?.maxDigits ?? currentDigits)) 位")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.fieldMoss)

                HStack(spacing: 18) {
                    VStack(spacing: 2) {
                        Text("当前得分")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.fieldMoss)
                        Text("\(score)")
                            .font(.system(size: 24, weight: .heavy, design: .serif))
                            .foregroundStyle(AppTheme.fieldInk)
                    }
                    VStack(spacing: 2) {
                        Text("本轮位数")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.fieldMoss)
                        Text("\(currentDigits)")
                            .font(.system(size: 24, weight: .heavy, design: .serif))
                            .foregroundStyle(Color(red: 0.85, green: 0.60, blue: 0.15))
                    }
                }

                Button {
                    showSuccess = false
                    nextRound()
                } label: {
                    Text("下一轮")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 25, style: .continuous)
                                .fill(LinearGradient(colors: [Color(red: 0.28, green: 0.79, blue: 0.52),
                                                              Color(red: 0.18, green: 0.62, blue: 0.43)],
                                                     startPoint: .top, endPoint: .bottom))
                        )
                }
                .buttonStyle(.plain)
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

    private var failOverlay: some View {
        ZStack {
            Color.black.opacity(0.22).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("💔")
                    .font(.system(size: 52))
                Text("挑战失败")
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)

                Text(secret)
                    .font(.system(size: numberFontSize, weight: .black, design: .monospaced))
                    .foregroundStyle(AppTheme.fieldInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .padding(.horizontal, 12)

                Text("正确答案")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.fieldMoss)

                HStack(spacing: 18) {
                    VStack(spacing: 2) {
                        Text("成功轮数")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.fieldMoss)
                        Text("\(score)")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(AppTheme.fieldInk)
                    }
                    VStack(spacing: 2) {
                        Text("历史最佳")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.fieldMoss)
                        Text("\(failBest)")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(Color(red: 0.85, green: 0.60, blue: 0.15))
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        showFail = false
                        restartRound()
                    } label: {
                        Text("再试一次")
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
                        giveUp()
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
}

// MARK: - Difficulty icon

extension MemoryNumberView.Difficulty {
    var iconText: String {
        switch self {
        case .easy: return "🌱"
        case .normal: return "⚡"
        case .hard: return "🔥"
        case .hell: return "👑"
        }
    }
}

// MARK: - 本地最佳成绩

enum MemoryNumberStore {
    private static func key(_ id: String) -> String {
        "memory.best.\(id)"
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
