import SwiftUI

// MARK: - 数据模型

struct BrainTeaser: Codable, Identifiable {
    let id: Int
    let category: String
    let question: String
    let answer: String
}

// MARK: - ViewModel

@Observable
final class BrainTeaserStore {
    private(set) var teasers: [BrainTeaser] = []
    private(set) var current: BrainTeaser?
    private(set) var currentIndex: Int = 0

    // 进度持久化
    private let progressKey = "brainteaser_progress"
    private(set) var unlockedCount: Int = 0

    var total: Int { teasers.count }
    var progress: Double { total > 0 ? Double(currentIndex + 1) / Double(total) : 0 }

    init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "brain_teasers", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([BrainTeaser].self, from: data)
        else { return }
        teasers = decoded.shuffled()
        let saved = UserDefaults.standard.integer(forKey: progressKey)
        currentIndex = min(saved, teasers.count - 1)
        current = teasers[safe: currentIndex]
        unlockedCount = currentIndex
    }

    func next() {
        guard currentIndex < teasers.count - 1 else { return }
        currentIndex += 1
        if currentIndex > unlockedCount {
            unlockedCount = currentIndex
            UserDefaults.standard.set(unlockedCount, forKey: progressKey)
        }
        current = teasers[safe: currentIndex]
    }

    func previous() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        current = teasers[safe: currentIndex]
    }

    func jump(to index: Int) {
        guard index >= 0, index < teasers.count else { return }
        currentIndex = index
        current = teasers[safe: currentIndex]
    }

    func resetProgress() {
        UserDefaults.standard.removeObject(forKey: progressKey)
        teasers = teasers.shuffled()
        currentIndex = 0
        unlockedCount = 0
        current = teasers.first
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 入口视图（列表）

struct BrainTeaserHomeView: View {
    var onExit: (() -> Void)? = nil
    @State private var store = BrainTeaserStore()
    @State private var showGame = false
    @State private var selectedCategory: String = "全部"

    private var categories: [String] {
        ["全部"] + Array(Set(store.teasers.map(\.category))).sorted()
    }

    private var filtered: [BrainTeaser] {
        selectedCategory == "全部"
            ? store.teasers
            : store.teasers.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                // 自定义顶部栏（与其他游戏页一致）
                HStack {
                    Button(action: { onExit?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.card, in: Circle())
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    }
                    Spacer()
                    Text("脑筋急转弯")
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerCard
                        categoryPicker
                        questionList
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showGame) {
            BrainTeaserGameView(store: store, onExit: { showGame = false })
        }
    }

    // MARK: Header

    private var headerCard: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.accentInkPurple)
                    Text("BRAIN · 脑筋急转弯")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(AppTheme.accentInkPurple)
                }

                Text("急转弯")
                    .font(.system(size: 34, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("绕过常规思路，答案往往出人意料。")
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 12) {
                    statPill("\(store.total)", "共 \(store.total) 题", AppTheme.accentInkPurple)
                    statPill("\(store.unlockedCount + 1)", "已解锁", AppTheme.accentSage)
                    Spacer()
                    Button {
                        store.jump(to: store.currentIndex)
                        showGame = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("继续挑战")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(AppTheme.accentInkPurple, in: Capsule())
                    }
                }
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)

            // 装饰图案
            decorativeBulb
                .frame(width: 90, height: 90)
                .opacity(0.07)
                .padding(.trailing, 16)
                .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.accentInkPurple.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(AppTheme.accentInkPurple.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    private var decorativeBulb: some View {
        Canvas { ctx, size in
            let cx = size.width / 2, cy = size.height / 2
            let r = min(cx, cy) * 0.8
            let bulb = Path { p in
                p.addArc(center: .init(x: cx, y: cy - r * 0.2),
                         radius: r * 0.65, startAngle: .degrees(210),
                         endAngle: .degrees(330), clockwise: false)
                p.addLine(to: .init(x: cx + r * 0.22, y: cy + r * 0.55))
                p.addLine(to: .init(x: cx - r * 0.22, y: cy + r * 0.55))
                p.closeSubpath()
            }
            ctx.fill(bulb, with: .color(AppTheme.accentInkPurple))
            let base = Path { p in
                p.move(to: .init(x: cx - r * 0.2, y: cy + r * 0.55))
                p.addLine(to: .init(x: cx + r * 0.2, y: cy + r * 0.55))
                p.addLine(to: .init(x: cx + r * 0.15, y: cy + r * 0.75))
                p.addLine(to: .init(x: cx - r * 0.15, y: cy + r * 0.75))
                p.closeSubpath()
            }
            ctx.fill(base, with: .color(AppTheme.accentInkPurple))
        }
    }

    private func statPill(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    // MARK: Category Picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = cat
                        }
                    } label: {
                        Text(cat)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(selectedCategory == cat ? .white : AppTheme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                selectedCategory == cat
                                    ? AppTheme.accentInkPurple
                                    : AppTheme.card,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        selectedCategory == cat
                                            ? Color.clear
                                            : AppTheme.separator,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    // MARK: Question List

    private var questionList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, teaser in
                let globalIdx = store.teasers.firstIndex(where: { $0.id == teaser.id }) ?? 0
                let isUnlocked = globalIdx <= store.unlockedCount

                Button {
                    if isUnlocked {
                        store.jump(to: globalIdx)
                        showGame = true
                    }
                } label: {
                    listRow(teaser: teaser, index: globalIdx, isUnlocked: isUnlocked)
                }
                .buttonStyle(BrainTeaserRowButtonStyle())
                .disabled(!isUnlocked)

                if idx < filtered.count - 1 {
                    Divider()
                        .padding(.leading, 58)
                        .padding(.horizontal, 20)
                }
            }
        }
        .padding(.horizontal, 20)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.separator, lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private func listRow(teaser: BrainTeaser, index: Int, isUnlocked: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isUnlocked
                          ? AppTheme.accentInkPurple.opacity(0.12)
                          : AppTheme.textSecondary.opacity(0.06))
                if isUnlocked {
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.accentInkPurple)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
                }
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(teaser.question)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(isUnlocked ? AppTheme.textPrimary : AppTheme.textSecondary.opacity(0.5))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(teaser.category)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.accentInkPurple.opacity(isUnlocked ? 0.7 : 0.3))
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary.opacity(isUnlocked ? 0.4 : 0.2))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
}

private struct BrainTeaserRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? AppTheme.accentInkPurple.opacity(0.04) : Color.clear)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - 游戏主界面

struct BrainTeaserGameView: View {
    @Bindable var store: BrainTeaserStore
    var onExit: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var showAnswer = false
    @State private var userInput = ""
    @State private var answerResult: AnswerResult = .none
    @State private var cardOffset: CGFloat = 0
    @State private var cardOpacity: Double = 1
    @State private var shakeOffset: CGFloat = 0
    @FocusState private var inputFocused: Bool

    enum AnswerResult {
        case none, correct, wrong
        var color: Color {
            switch self {
            case .none: return AppTheme.accentInkPurple
            case .correct: return AppTheme.accentSage
            case .wrong: return AppTheme.accentCinnabar
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            progressBar
            Spacer(minLength: 0)
            questionCard
            Spacer(minLength: 0)
            inputArea
            bottomButtons
        }
        .background(AppTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onTapGesture { inputFocused = false }
    }

    // MARK: Nav

    private var navBar: some View {
        HStack(spacing: 14) {
            Button { onExit?() ?? dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.card, in: Circle())
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("脑筋急转弯")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("第 \(store.currentIndex + 1) 关 · 共 \(store.total) 关")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            // 类别标签
            if let teaser = store.current {
                Text(teaser.category)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accentInkPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.accentInkPurple.opacity(0.1), in: Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    // MARK: Progress

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.separator)
                    .frame(height: 4)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentInkPurple, AppTheme.accentInkPurple.opacity(0.6)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * store.progress, height: 4)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: Question Card

    private var questionCard: some View {
        VStack(spacing: 20) {
            // 题号装饰
            HStack(spacing: 8) {
                Rectangle()
                    .fill(AppTheme.accentInkPurple.opacity(0.3))
                    .frame(width: 24, height: 1.5)
                Text("第 \(store.currentIndex + 1) 题")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.accentInkPurple.opacity(0.7))
                Rectangle()
                    .fill(AppTheme.accentInkPurple.opacity(0.3))
                    .frame(width: 24, height: 1.5)
            }

            // 题目文字
            if let teaser = store.current {
                Text(teaser.question)
                    .font(.system(size: 22, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 8)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(teaser.id)
            }

            // 答案揭晓区
            if showAnswer, let teaser = store.current {
                VStack(spacing: 8) {
                    HStack {
                        Rectangle()
                            .fill(AppTheme.accentSage.opacity(0.4))
                            .frame(maxWidth: .infinity, maxHeight: 1)
                        Text("答案")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.accentSage.opacity(0.8))
                        Rectangle()
                            .fill(AppTheme.accentSage.opacity(0.4))
                            .frame(maxWidth: .infinity, maxHeight: 1)
                    }

                    Text(teaser.answer)
                        .font(.system(size: 20, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.accentSage)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
                .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: AppTheme.inkShadow, radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    answerResult == .correct
                        ? AppTheme.accentSage.opacity(0.5)
                        : answerResult == .wrong
                            ? AppTheme.accentCinnabar.opacity(0.5)
                            : AppTheme.separator,
                    lineWidth: answerResult == .none ? 1 : 2
                )
        )
        .padding(.horizontal, 20)
        .offset(x: shakeOffset)
        .offset(y: cardOffset)
        .opacity(cardOpacity)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showAnswer)
    }

    // MARK: Input

    private var inputArea: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                TextField("写下你的答案...", text: $userInput)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .focused($inputFocused)
                    .submitLabel(.done)
                    .onSubmit { checkAnswer() }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                inputFocused
                                    ? AppTheme.accentInkPurple.opacity(0.5)
                                    : AppTheme.separator,
                                lineWidth: 1.5
                            )
                    )

                if !userInput.isEmpty {
                    Button { checkAnswer() } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.accentInkPurple, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }

            if answerResult == .wrong {
                Text("再想想？还是直接看答案？")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.accentCinnabar.opacity(0.8))
                    .transition(.opacity)
            } else if answerResult == .correct {
                Text("太棒了，答对了！")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accentSage)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: answerResult)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: userInput.isEmpty)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: 12) {
            // 上一题
            Button {
                guard store.currentIndex > 0 else { return }
                transitionCard(direction: -1) { store.previous() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                    Text("上一题")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(store.currentIndex == 0
                                 ? AppTheme.textSecondary.opacity(0.3)
                                 : AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppTheme.separator, lineWidth: 1)
                )
            }
            .disabled(store.currentIndex == 0)

            // 查看答案
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    showAnswer.toggle()
                }
                if !showAnswer { userInput = "" }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showAnswer ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(showAnswer ? "隐藏答案" : "查看答案")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    showAnswer
                        ? AppTheme.accentSage
                        : AppTheme.accentInkPurple,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }

            // 下一题
            Button {
                guard store.currentIndex < store.total - 1 else { return }
                transitionCard(direction: 1) { store.next() }
            } label: {
                HStack(spacing: 6) {
                    Text("下一题")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(store.currentIndex == store.total - 1
                                 ? AppTheme.textSecondary.opacity(0.3)
                                 : AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppTheme.separator, lineWidth: 1)
                )
            }
            .disabled(store.currentIndex == store.total - 1)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: Logic

    private func checkAnswer() {
        inputFocused = false
        guard let teaser = store.current, !userInput.isEmpty else { return }
        let cleaned = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let correct = teaser.answer.contains(cleaned) || cleaned.contains(teaser.answer)
            || cleaned == teaser.answer

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            answerResult = correct ? .correct : .wrong
            if correct { showAnswer = true }
        }

        if !correct {
            shake()
        } else {
            // 答对后1.5秒自动跳下一题
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if store.currentIndex < store.total - 1 {
                    transitionCard(direction: 1) { store.next() }
                }
            }
        }
    }

    private func shake() {
        let times = 4
        let distance: CGFloat = 8
        for i in 0..<times {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.07) {
                withAnimation(.easeInOut(duration: 0.07)) {
                    shakeOffset = i % 2 == 0 ? distance : -distance
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(times) * 0.07) {
            withAnimation(.easeInOut(duration: 0.07)) { shakeOffset = 0 }
        }
    }

    private func transitionCard(direction: Int, action: @escaping () -> Void) {
        let slideOut: CGFloat = direction > 0 ? -30 : 30
        let slideIn: CGFloat = direction > 0 ? 30 : -30

        withAnimation(.easeIn(duration: 0.18)) {
            cardOffset = slideOut
            cardOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            action()
            showAnswer = false
            answerResult = .none
            userInput = ""
            cardOffset = slideIn
            withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                cardOffset = 0
                cardOpacity = 1
            }
        }
    }
}

// MARK: - Preview

#Preview("首页") {
    BrainTeaserHomeView()
}

#Preview("游戏") {
    BrainTeaserGameView(store: BrainTeaserStore())
}
