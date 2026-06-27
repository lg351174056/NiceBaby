import SwiftUI

// MARK: - 数据模型

struct IdiomLevel: Codable, Identifiable {
    let id: Int
    let word: String
    let blankIndex: Int
    let options: [String]
    let hint: String
    let pinyin: String
}

// MARK: - Store

@Observable
final class IdiomFillLevelStore {
    private(set) var levels: [IdiomLevel] = []
    private(set) var currentIndex: Int = 0
    private let progressKey = "idiom_fill_level_progress"

    var total: Int { levels.count }
    var current: IdiomLevel? { levels[safe: currentIndex] }
    var clearedCount: Int { currentIndex }

    init() { load() }

    private func load() {
        guard let url = Bundle.main.url(forResource: "idiom_fill_levels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([IdiomLevel].self, from: data)
        else { return }
        levels = decoded
        let saved = UserDefaults.standard.integer(forKey: progressKey)
        currentIndex = min(saved, levels.count - 1)
    }

    func advance() {
        guard currentIndex < levels.count - 1 else { return }
        currentIndex += 1
        UserDefaults.standard.set(currentIndex, forKey: progressKey)
    }

    func jump(to index: Int) {
        guard index >= 0, index < levels.count else { return }
        currentIndex = index
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 游戏主视图

struct IdiomFillLevelView: View {
    let onExit: () -> Void

    @State private var store = IdiomFillLevelStore()
    @State private var selectedChar: String? = nil
    @State private var phase: Phase = .playing   // playing / correct / wrong
    @State private var showHint = false
    @State private var cardScale: CGFloat = 1
    @State private var shakeOffset: CGFloat = 0
    @State private var confettiVisible = false
    @State private var wrongChar: String? = nil

    enum Phase { case playing, correct, wrong }

    private let accent = AppTheme.accentCinnabar
    private let accentYellow = AppTheme.accentYellow

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                progressStrip
                Spacer(minLength: 0)
                wordDisplay
                Spacer(minLength: 16)
                hintBox
                Spacer(minLength: 16)
                optionsGrid
                bottomBar
            }

            if confettiVisible {
                CorrectToastView()
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .id("correct_toast")
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Nav

    private var navBar: some View {
        HStack {
            Button(action: onExit) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.card, in: Circle())
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("成语填空(贰)")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                if let lv = store.current {
                    Text("第 \(lv.id) 关 · 共 \(store.total) 关")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()

            // 提示按钮
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showHint.toggle()
                }
            } label: {
                Image(systemName: showHint ? "lightbulb.fill" : "lightbulb")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(showHint ? accentYellow : AppTheme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.card, in: Circle())
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    // MARK: Progress

    private var progressStrip: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AppTheme.separator).frame(height: 4)
                Capsule()
                    .fill(LinearGradient(
                        colors: [accent, accentYellow],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(
                        width: store.total > 0
                            ? geo.size.width * CGFloat(store.currentIndex + 1) / CGFloat(store.total)
                            : 0,
                        height: 4)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.currentIndex)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: Word Display

    private var wordDisplay: some View {
        Group {
            if let lv = store.current {
                HStack(spacing: 12) {
                    ForEach(Array(lv.word.enumerated()), id: \.offset) { idx, ch in
                        charTile(
                            char: idx == lv.blankIndex
                                ? (selectedChar ?? "")
                                : String(ch),
                            isBlank: idx == lv.blankIndex,
                            isSelected: idx == lv.blankIndex && selectedChar != nil,
                            state: idx == lv.blankIndex ? phase : .playing
                        )
                    }
                }
                .scaleEffect(cardScale)
                .offset(x: shakeOffset)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(lv.id)
            }
        }
        .padding(.horizontal, 24)
    }

    private func charTile(char: String, isBlank: Bool, isSelected: Bool, state: Phase) -> some View {
        let size: CGFloat = 68
        let bg: Color = {
            if !isBlank { return AppTheme.card }
            switch state {
            case .playing: return isSelected ? accent.opacity(0.1) : AppTheme.background
            case .correct: return AppTheme.accentSage.opacity(0.15)
            case .wrong:   return AppTheme.accentCinnabar.opacity(0.12)
            }
        }()
        let border: Color = {
            if !isBlank { return AppTheme.separator }
            switch state {
            case .playing: return isSelected ? accent : AppTheme.textSecondary.opacity(0.3)
            case .correct: return AppTheme.accentSage
            case .wrong:   return AppTheme.accentCinnabar
            }
        }()

        return ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(bg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(border, lineWidth: isBlank ? 2 : 1)
                )

            if isBlank && !isSelected {
                // 空格虚线提示
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.25))
            }

            if !char.isEmpty {
                Text(char)
                    .font(.system(size: 28, weight: .heavy, design: .serif))
                    .foregroundStyle(
                        isBlank
                            ? (state == .correct ? AppTheme.accentSage : state == .wrong ? AppTheme.accentCinnabar : accent)
                            : AppTheme.textPrimary
                    )
            }

            // 正确打勾
            if isBlank && state == .correct {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.accentSage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(4)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: isBlank ? accent.opacity(0.08) : .clear, radius: 6, y: 3)
    }

    // MARK: Hint Box

    private var hintBox: some View {
        Group {
            if let lv = store.current {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(accentYellow)
                        Text("【提示】")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(accentYellow)
                        Spacer()
                        Text(lv.pinyin)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                    }

                    if showHint {
                        Text(lv.hint.isEmpty ? "暂无释义" : lv.hint)
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineSpacing(4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        Text("点击右上角灯泡查看提示")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accentYellow.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(accentYellow.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showHint)
            }
        }
    }

    // MARK: Options Grid

    private var optionsGrid: some View {
        Group {
            if let lv = store.current {
                let cols = [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ]
                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(lv.options, id: \.self) { ch in
                        optionButton(ch: ch, level: lv)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func optionButton(ch: String, level: IdiomLevel) -> some View {
        let isCorrectAnswer = ch == level.word[level.blankIndex]
        let isWrong = wrongChar == ch
        let isSelected = selectedChar == ch

        let bg: Color = {
            if phase == .correct && isCorrectAnswer { return AppTheme.accentSage }
            if isWrong { return AppTheme.accentCinnabar.opacity(0.12) }
            if isSelected { return accent.opacity(0.1) }
            return AppTheme.card
        }()

        let border: Color = {
            if phase == .correct && isCorrectAnswer { return AppTheme.accentSage }
            if isWrong { return AppTheme.accentCinnabar }
            if isSelected { return accent }
            return AppTheme.separator
        }()

        let textColor: Color = {
            if phase == .correct && isCorrectAnswer { return .white }
            if isWrong { return AppTheme.accentCinnabar }
            if isSelected { return accent }
            return AppTheme.textPrimary
        }()

        return Button {
            guard phase == .playing else { return }
            tap(ch: ch, level: level)
        } label: {
            Text(ch)
                .font(.system(size: 24, weight: .heavy, design: .serif))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(border, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected && phase == .playing ? 0.96 : 1)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
        .disabled(phase != .playing)
    }

    // MARK: Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            // 重置
            Button {
                resetLevel()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .bold))
                    Text("重置")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1))
            }

            // 下一关（答对后才亮）
            Button {
                guard phase == .correct else { return }
                nextLevel()
            } label: {
                HStack(spacing: 6) {
                    Text(phase == .correct ? "下一关" : "作答后继续")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(phase == .correct ? .white : AppTheme.textSecondary.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    phase == .correct ? accent : AppTheme.card,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        phase == .correct ? Color.clear : AppTheme.separator,
                        lineWidth: 1))
            }
            .disabled(phase != .correct)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: phase)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 24)
    }

    // MARK: Logic

    private func tap(ch: String, level: IdiomLevel) {
        selectedChar = ch
        let correct = level.word[level.blankIndex]

        if ch == correct {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                phase = .correct
                cardScale = 1.02
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation { cardScale = 1 }
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                confettiVisible = true
            }
            
            // 延长展示时间，让反馈更稳重
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    confettiVisible = false
                }
            }
        } else {
            wrongChar = ch
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                phase = .wrong
            }
            shake()
            // 1秒后恢复，让用户重试
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    phase = .playing
                    selectedChar = nil
                    wrongChar = nil
                }
            }
        }
    }

    private func shake() {
        let d: CGFloat = 7
        let steps: [(CGFloat, Double)] = [(d,0.06),(-d,0.12),(d,0.18),(-d,0.24),(0,0.30)]
        for (offset, delay) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.06)) { shakeOffset = offset }
            }
        }
    }

    private func resetLevel() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedChar = nil
            wrongChar = nil
            phase = .playing
            confettiVisible = false
            showHint = false
        }
    }

    private func nextLevel() {
        withAnimation(.easeInOut(duration: 0.22)) {
            store.advance()
            selectedChar = nil
            wrongChar = nil
            phase = .playing
            confettiVisible = false
            showHint = false
        }
    }
}

// MARK: - 字符串下标扩展

private extension String {
    subscript(_ index: Int) -> String {
        guard index >= 0, index < count else { return "" }
        return String(self[self.index(startIndex, offsetBy: index)])
    }
}

// MARK: - 答对庆祝动效 · 简洁吐司

private struct CorrectToastView: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentSage.opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(AppTheme.accentSage)
            }
            
            Text("答对了！")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .tracking(2)
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 40)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: .black.opacity(0.1), radius: 15, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(AppTheme.accentSage.opacity(0.2), lineWidth: 1)
        )
    }
}
