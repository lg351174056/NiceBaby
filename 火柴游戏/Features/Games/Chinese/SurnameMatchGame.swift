import SwiftUI
import AVFoundation

// MARK: - 百家姓闯关（三模式 4 选 1）
//
// 模式 A「看字选音」：显示大号汉字，4 个拼音选 1
// 模式 B「听音选字」：TTS 朗读，4 个汉字选 1
// 模式 C「看音选字」：显示拼音，4 个汉字选 1
// 全部一把梭，120+ 姓氏不做进度解锁，每轮 10 题随机出。

// MARK: - 游戏模式

enum SurnameQuizMode: String, CaseIterable, Identifiable {
    case charToPin    // 看字选音
    case listenToChar // 听音选字
    case pinToChar    // 看音选字
    var id: String { rawValue }

    var label: String {
        switch self {
        case .charToPin:    return "看字选音"
        case .listenToChar: return "听音选字"
        case .pinToChar:    return "看音选字"
        }
    }

    var icon: String {
        switch self {
        case .charToPin:    return "character.textbox"
        case .listenToChar: return "speaker.wave.2.fill"
        case .pinToChar:    return "textformat.abc"
        }
    }
}

// MARK: - 单题

private struct SurnameQuestion: Identifiable {
    let id = UUID()
    let surname: ChineseSurname   // 正确答案
    let options: [String]          // 4 个选项（已打乱）
    let answer: String             // 正确选项文本
    let mode: SurnameQuizMode
}

// MARK: - TTS 服务

private final class SurnameTTS: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    static let shared = SurnameTTS()
    private let synth = AVSpeechSynthesizer()
    private let voice = AVSpeechSynthesisVoice(language: "zh-CN")
    private var onFinish: (() -> Void)?

    override init() {
        super.init()
        synth.delegate = self
    }

    func speak(_ text: String, onFinish: (() -> Void)? = nil) {
        synth.stopSpeaking(at: .immediate)
        self.onFinish = onFinish
        let u = AVSpeechUtterance(string: text)
        u.voice = voice
        u.rate = 0.38
        u.pitchMultiplier = 1.05
        u.preUtteranceDelay = 0.1
        synth.speak(u)
    }
    
    var isSpeaking: Bool { synth.isSpeaking }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let cb = onFinish
        onFinish = nil
        Task { @MainActor in cb?() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish = nil
    }
}

// MARK: - 出题引擎

private enum SurnameQuizEngine {

    /// 从全库随机出 N 道指定模式的题。
    static func makeQuestions(mode: SurnameQuizMode, count: Int) -> [SurnameQuestion] {
        let all = SurnameCatalog.all
        guard all.count >= 4 else { return [] }

        let sampled = Array(all.shuffled().prefix(count))
        return sampled.map { surname in
            let answer: String
            let optionPool: [String]

            switch mode {
            case .charToPin:
                // 题面=汉字，选项=拼音
                answer = surname.pinyin
                optionPool = all.filter { $0.character != surname.character }.map { $0.pinyin }
            case .listenToChar, .pinToChar:
                // 题面=拼音(或TTS)，选项=汉字
                answer = surname.character
                optionPool = all.filter { $0.character != surname.character }.map { $0.character }
            }

            // 抽 3 个干扰项（不重复、不等于 answer）
            var distractors: [String] = []
            var seen = Set<String>([answer])
            for item in optionPool.shuffled() {
                if seen.insert(item).inserted {
                    distractors.append(item)
                }
                if distractors.count == 3 { break }
            }

            var opts = distractors
            opts.append(answer)
            opts.shuffle()

            return SurnameQuestion(surname: surname, options: opts, answer: answer, mode: mode)
        }
    }
}

// MARK: - 主视图

struct SurnameMatchGameView: View {
    let onExit: () -> Void

    private let kind: GameKind = .surnameMatch
    private let totalQuestions = 10

    @State private var mode: SurnameQuizMode = .charToPin
    @State private var questions: [SurnameQuestion] = []
    @State private var currentIndex = 0
    @State private var picked: String? = nil
    @State private var isCorrect: Bool? = nil
    @State private var correctCount = 0
    @State private var combo = 0
    @State private var startTime = Date()
    @State private var showResult = false
    @State private var shakeWrong = false

    /// 竹青主色（书野营地竹青风）
    private let bamboo: (Color, Color) = (
        AppTheme.fieldMint,
        Color(red: 126/255, green: 211/255, blue: 160/255)
    )

    @Namespace private var flyNS

    private var current: SurnameQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var body: some View {
        ZStack {
            // 蓝天草地背景（书野营地竹青风）
            FieldBackground()

            bambooSun
            bambooCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            bambooCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton(action: onExit)
                        Spacer()
                    }
                    VStack(spacing: 2) {
                        Text(kind.title)
                            .font(.system(size: 16, weight: .heavy, design: .serif))
                            .foregroundStyle(AppTheme.fieldInk)
                        Text("第 \(min(currentIndex + 1, totalQuestions)) / \(totalQuestions) 题 · 答对 \(correctCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.fieldMoss)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                modeSelector
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                if let q = current {
                    questionArea(q: q)
                        .id(q.id)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else if questions.isEmpty {
                    emptyState
                }

                Spacer(minLength: 0)
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
            if questions.isEmpty { loadQuestions() }
        }
    }

    // MARK: - 背景装饰（太阳/云）

    private var bambooSun: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breathe = 1 + 0.03 * sin(t * 1.2)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 214/255, blue: 110/255).opacity(0.4),
                            Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.14),
                            .clear
                        ], center: .center, startRadius: 10, endRadius: 50)
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(breathe)
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 246/255, blue: 205/255),
                            Color(red: 255/255, green: 214/255, blue: 100/255),
                            Color(red: 247/255, green: 188/255, blue: 55/255)
                        ], center: .init(x: 0.38, y: 0.3), startRadius: 2, endRadius: 18)
                    )
                    .frame(width: 32, height: 32)
                    .scaleEffect(breathe)
                    .shadow(color: Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.8), radius: 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.trailing, 20)
            .padding(.top, 30)
        }
        .allowsHitTesting(false)
    }

    private func bambooCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate + delay
            let drift = 14 * sin(t * 0.42)
            let bob = 3 * sin(t * 0.85 + 1.2)
            ZStack {
                ZStack {
                    Capsule().fill(Color.white.opacity(0.95)).frame(width: 42, height: 15).offset(y: 4)
                    Circle().fill(Color.white.opacity(0.95)).frame(width: 25, height: 25).offset(x: -9, y: -6)
                    Circle().fill(Color.white.opacity(0.9)).frame(width: 21, height: 21).offset(x: 7, y: -4)
                    Circle().fill(Color.white.opacity(0.9)).frame(width: 15, height: 15).offset(x: 0, y: -10)
                }
                .frame(width: 52, height: 30)
                .scaleEffect(scale)
                .offset(x: drift, y: bob)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, 390 * x - 10)
            .padding(.top, 390 * y)
        }
        .allowsHitTesting(false)
    }

    // MARK: - 模式选择器

    private var modeSelector: some View {
        HStack(spacing: 8) {
            ForEach(SurnameQuizMode.allCases) { m in
                Button {
                    guard mode != m else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.18)) { mode = m }
                    loadQuestions()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: m.icon)
                            .font(.system(size: 12, weight: .heavy))
                        Text(m.label)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(mode == m ? .white : AppTheme.fieldOliveDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            mode == m
                            ? AnyShapeStyle(LinearGradient(colors: [bamboo.1, bamboo.0],
                                                           startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Color.white.opacity(0.88))
                        )
                    )
                    .overlay(
                        Capsule().strokeBorder(
                            mode == m
                            ? AppTheme.fieldInk
                            : AppTheme.fieldOlive.opacity(0.35),
                            lineWidth: 2
                        )
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - 题目区

    @ViewBuilder
    private func questionArea(q: SurnameQuestion) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                questionCard(q: q)
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.top, 16)

                comboLabel

                optionGrid(q: q)
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: 题面卡片

    private func questionCard(q: SurnameQuestion) -> some View {
        VStack(spacing: 14) {
            switch q.mode {
            case .charToPin:
                // 显示大汉字
                Text(q.surname.character)
                    .font(.system(size: 72, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                // 答对后显示拼音
                if isCorrect == true {
                    Text(q.surname.pinyin)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accentSage)
                        .transition(.scale.combined(with: .opacity))
                }

            case .listenToChar:
                // 喇叭图标 + 点击重播
                Button {
                    SurnameTTS.shared.speak(q.surname.character)
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 52, weight: .heavy))
                            .foregroundStyle(bamboo.0)
                            .symbolEffect(.variableColor.iterative, options: .repeating)
                        Text("点击重听")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                // 答对后显示汉字+拼音
                if isCorrect == true {
                    VStack(spacing: 4) {
                        Text(q.surname.character)
                            .font(.system(size: 36, weight: .heavy, design: .serif))
                        Text(q.surname.pinyin)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.accentSage)
                    .transition(.scale.combined(with: .opacity))
                }

            case .pinToChar:
                // 显示拼音
                Text(q.surname.pinyin)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                // 答对后显示汉字
                if isCorrect == true {
                    Text(q.surname.character)
                        .font(.system(size: 48, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.accentSage)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 160)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            isCorrect == true ? AppTheme.accentSage.opacity(0.8) : AppTheme.fieldOlive.opacity(0.3),
                            lineWidth: 2
                        )
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.1), radius: 8, y: 4)
        )
        .modifier(CardShake(trigger: shakeWrong))
    }

    // MARK: 连击提示

    private var comboLabel: some View {
        HStack(spacing: 6) {
            if let ic = isCorrect {
                Image(systemName: ic ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(ic ? AppTheme.accentSage : AppTheme.accentPink)
                Text(ic ? (combo > 1 ? "连击 ×\(combo)！" : "答对了！") : "再接再厉")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                Image(systemName: "hand.tap.fill")
                    .foregroundStyle(bamboo.0)
                Text("选出正确答案")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isCorrect)
    }

    // MARK: 选项区 2×2

    private func optionGrid(q: SurnameQuestion) -> some View {
        let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: cols, spacing: 12) {
            ForEach(Array(q.options.enumerated()), id: \.element) { (idx, opt) in
                optionCell(opt: opt, label: ["A", "B", "C", "D"][idx], q: q)
            }
        }
    }

    @ViewBuilder
    private func optionCell(opt: String, label: String, q: SurnameQuestion) -> some View {
        let isPicked = (picked == opt)
        let isAnswer = (opt == q.answer)
        let showFeedback = (picked != nil)

        let bgColor: Color = {
            if !showFeedback { return Color.white.opacity(0.92) }
            if isPicked && isCorrect == true { return AppTheme.accentSage.opacity(0.18) }
            if isPicked && isCorrect == false { return AppTheme.accentPink.opacity(0.15) }
            if showFeedback && isAnswer { return AppTheme.accentSage.opacity(0.12) }
            return Color.white.opacity(0.92)
        }()

        let borderColor: Color = {
            if !showFeedback { return AppTheme.fieldOlive.opacity(0.3) }
            if isPicked && isCorrect == true { return AppTheme.accentSage }
            if isPicked && isCorrect == false { return AppTheme.accentPink }
            if showFeedback && isAnswer { return AppTheme.accentSage.opacity(0.6) }
            return AppTheme.fieldOlive.opacity(0.15)
        }()

        let textColor: Color = {
            if !showFeedback { return AppTheme.textPrimary }
            if isPicked && isCorrect == true { return AppTheme.accentSage }
            if isPicked && isCorrect == false { return AppTheme.accentPink }
            if showFeedback && isAnswer { return AppTheme.accentSage }
            return AppTheme.textSecondary
        }()

        Button {
            handleTap(opt: opt, q: q)
        } label: {
            HStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(bamboo.0, in: Circle())

                Text(opt)
                    .font(.system(size: optFontSize(opt), weight: .heavy,
                                  design: q.mode == .charToPin ? .rounded : .serif))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Spacer(minLength: 0)

                if showFeedback && isAnswer {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accentSage)
                        .transition(.scale)
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(bgColor, in: RoundedRectangle(cornerRadius: AppTheme.cornerMedium))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                    .strokeBorder(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(picked != nil)
    }

    private func optFontSize(_ text: String) -> CGFloat {
        if text.count <= 2 { return 24 }
        if text.count <= 5 { return 18 }
        return 15
    }

    // MARK: - 空态

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
            Text("暂无题目")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - 交互逻辑

    private func handleTap(opt: String, q: SurnameQuestion) {
        guard picked == nil else { return }
        picked = opt
        let correct = (opt == q.answer)

        // Haptic
        if correct {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            isCorrect = correct
        }

        if correct {
            correctCount += 1
            combo += 1
            
            // 答对后朗读一遍加深记忆，等朗读完再切下一题
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                SurnameTTS.shared.speak(q.surname.character) {
                    advance()
                }
            }
        } else {
            combo = 0
            shakeWrong.toggle()
            
            // 答错不切题，1.2 秒后恢复让用户重试
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    picked = nil
                    isCorrect = nil
                }
            }
        }
    }

    private func advance() {
        if currentIndex + 1 >= totalQuestions {
            GameBestScoreStore.update(kind, score: correctCount)
            withAnimation(.easeInOut(duration: 0.2)) { showResult = true }
            return
        }
        withAnimation(.easeInOut(duration: 0.15)) {
            currentIndex += 1
            picked = nil
            isCorrect = nil
        }
        // 听音模式自动播放下一题
        if mode == .listenToChar, let next = questions[safe: currentIndex] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                SurnameTTS.shared.speak(next.surname.character)
            }
        }
    }

    private func loadQuestions() {
        questions = SurnameQuizEngine.makeQuestions(mode: mode, count: totalQuestions)
        currentIndex = 0
        picked = nil
        isCorrect = nil
        correctCount = 0
        combo = 0
        startTime = Date()
        showResult = false

        // 听音模式进入后自动播第一题
        if mode == .listenToChar, let first = questions.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                SurnameTTS.shared.speak(first.surname.character)
            }
        }
    }

    private func restart() {
        loadQuestions()
    }
}

// MARK: - 安全下标

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 答错抖动

private struct CardShake: ViewModifier {
    let trigger: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: phase)
            .onChange(of: trigger) { _, _ in
                let pattern: [CGFloat] = [-8, 8, -6, 6, -3, 3, 0]
                animatePattern(pattern, idx: 0)
            }
    }

    private func animatePattern(_ p: [CGFloat], idx: Int) {
        guard idx < p.count else { return }
        withAnimation(.linear(duration: 0.05)) { phase = p[idx] }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animatePattern(p, idx: idx + 1)
        }
    }
}
