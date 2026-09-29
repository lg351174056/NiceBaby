import SwiftUI
import Combine

// MARK: - 乘法星球（益智 · 数理马戏团）

struct MultiplicationPlanetView: View {
    let onExit: () -> Void

    enum Mode: String, CaseIterable, Identifiable {
        case start
        case standard
        case challenge

        var id: String { rawValue }

        var title: String {
            switch self {
            case .start: return "启蒙"
            case .standard: return "标准"
            case .challenge: return "挑战"
            }
        }

        var desc: String {
            switch self {
            case .start: return "2 ~ 5 的乘法"
            case .standard: return "2 ~ 9 的乘法"
            case .challenge: return "2 ~ 12 的乘法"
            }
        }

        var seconds: Double {
            switch self {
            case .start: return 12
            case .standard: return 9
            case .challenge: return 7
            }
        }

        var minFactor: Int {
            switch self {
            case .start: return 2
            case .standard: return 2
            case .challenge: return 2
            }
        }

        var maxFactor: Int {
            switch self {
            case .start: return 5
            case .standard: return 9
            case .challenge: return 12
            }
        }

        var color: Color {
            switch self {
            case .start: return Color(red: 1.0, green: 0.55, blue: 0.45)
            case .standard: return Color(red: 0.35, green: 0.62, blue: 0.98)
            case .challenge: return Color(red: 0.68, green: 0.55, blue: 0.98)
            }
        }

        var icon: String {
            switch self {
            case .start: return "🌱"
            case .standard: return "🚀"
            case .challenge: return "☄️"
            }
        }
    }

    @State private var mode: Mode? = nil
    @State private var a = 3
    @State private var b = 7
    @State private var input = ""
    @State private var score = 0
    @State private var timerRemaining: Double = 12
    @State private var balloonY: CGFloat = -170
    @State private var locked = false
    @State private var projectile = 0.0
    @State private var launcherRecoil = false
    @State private var explosionText: String? = nil
    @State private var explosionScale: CGFloat = 0
    @State private var explosionOpacity: Double = 0
    @State private var feedbackText: String? = nil
    @State private var balloonOpacity: Double = 1
    @State private var skyH: CGFloat = 300

    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    private var correctAnswer: Int { a * b }
    private var balloonH: CGFloat { 190 }
    private var balloonW: CGFloat { 132 }

    var body: some View {
        ZStack {
            spaceBackground

            if mode == nil {
                menuView
            } else {
                gameView
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(timer) { _ in tick() }
    }

    // MARK: - 背景

    private var spaceBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.08, blue: 0.18),
                         Color(red: 0.12, green: 0.12, blue: 0.30),
                         Color(red: 0.03, green: 0.04, blue: 0.10)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // 闪烁星星 + 星球点缀
            TimelineView(.animation) { ctx in
                GeometryReader { geo in
                    let t = ctx.date.timeIntervalSinceReferenceDate

                    // 星星
                    ForEach(0..<30, id: \.self) { i in
                        let x = geo.size.width * CGFloat(0.05 + Double((i * 79) % 92) / 100.0)
                        let y = geo.size.height * CGFloat(0.05 + Double((i * 37) % 90) / 100.0)
                        let size = CGFloat(1 + (i % 3))
                        let o = 0.25 + 0.6 * (0.5 + 0.5 * sin(t * 1.8 + Double(i) * 0.9))
                        Circle()
                            .fill(Color.white.opacity(o))
                            .frame(width: size * 1.7, height: size * 1.7)
                            .position(x: x, y: y)
                    }

                    // 带环大行星
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [Color(red: 0.55, green: 0.75, blue: 0.95),
                                                          Color(red: 0.25, green: 0.45, blue: 0.75)],
                                                 center: .init(x: 0.35, y: 0.3), startRadius: 0, endRadius: 50))
                            .frame(width: 100, height: 100)
                        Ellipse()
                            .stroke(Color.white.opacity(0.4), lineWidth: 3)
                            .frame(width: 142, height: 36)
                            .rotationEffect(.degrees(-18))
                    }
                    .opacity(0.35)
                    .position(x: geo.size.width * 0.85, y: geo.size.height * 0.85)

                    // 小红星
                    Circle()
                        .fill(RadialGradient(colors: [Color(red: 1.0, green: 0.58, blue: 0.46),
                                                      Color(red: 0.80, green: 0.32, blue: 0.30)],
                                             center: .init(x: 0.3, y: 0.3), startRadius: 0, endRadius: 30))
                        .frame(width: 60, height: 60)
                        .opacity(0.30)
                        .position(x: geo.size.width * 0.12, y: geo.size.height * 0.28)

                    // 弯月
                    ZStack {
                        Circle().fill(Color.white.opacity(0.5)).frame(width: 44, height: 44)
                        Circle().fill(Color(red: 0.07, green: 0.08, blue: 0.18)).frame(width: 38, height: 38).offset(x: 10)
                    }
                    .opacity(0.35)
                    .position(x: geo.size.width * 0.22, y: geo.size.height * 0.72)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }

    // MARK: - 菜单

    private var menuView: some View {
        VStack(spacing: 0) {
            // 返回栏
            HStack {
                Button(action: onExit) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)

            Spacer()

            Text("乘法星球")
                .font(.system(size: 38, weight: .black, design: .serif))
                .tracking(4)
                .foregroundStyle(
                    LinearGradient(colors: [Color(red: 1.0, green: 0.82, blue: 0.25),
                                            Color(red: 1.0, green: 0.52, blue: 0.30),
                                            Color(red: 1.0, green: 0.35, blue: 0.38)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                .padding(.bottom, 8)

            Text("乘着气球，在数字星球间穿梭吧！")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.65))
                .padding(.bottom, 36)

            VStack(spacing: 14) {
                ForEach(Mode.allCases) { mode in
                    Button {
                        startGame(mode)
                    } label: {
                        HStack(spacing: 16) {
                            Text(mode.icon)
                                .font(.system(size: 30))
                                .frame(width: 62, height: 62)
                                .background(
                                    Circle().fill(
                                        LinearGradient(colors: [mode.color.opacity(0.9), mode.color.opacity(0.6)],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                )
                                .shadow(color: .black.opacity(0.35), radius: 8, y: 4)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.title)
                                    .font(.system(size: 20, weight: .heavy, design: .serif))
                                    .foregroundStyle(.white)
                                Text(mode.desc)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.7))
                                Text("⏱ \(Int(mode.seconds)) 秒")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.25))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                        .background(.ultraThinMaterial.opacity(0.2))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
    }

    // MARK: - 游戏界面

    private var gameView: some View {
        VStack(spacing: 0) {
            // HUD
            HStack {
                Button(action: onExit) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                Spacer()
                Text(mode?.title ?? "")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(score) 分")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.25))
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // 天空区域
            GeometryReader { geo in
                let midX = geo.size.width / 2
                let ballPos = CGPoint(x: midX, y: balloonY + balloonH / 2)
                let cannonPos = CGPoint(x: midX, y: geo.size.height - 86)
                let launchPos = CGPoint(x: midX, y: cannonPos.y - 34)
                let projPos = CGPoint(
                    x: midX,
                    y: launchPos.y + (ballPos.y - launchPos.y) * CGFloat(projectile)
                )

                ZStack {
                    // 倒计时条
                    VStack {
                        GeometryReader { bar in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.12))
                                Capsule()
                                    .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.82, blue: 0.25),
                                                                   Color(red: 1.0, green: 0.35, blue: 0.38)],
                                                          startPoint: .leading, endPoint: .trailing))
                                    .frame(width: bar.size.width * timerProgress)
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)

                        HStack {
                            Text(String(format: "%.1fs", max(0, timerRemaining)))
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.25))
                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        Spacer()
                    }

                    // 小行星装饰
                    Circle()
                        .fill(
                            RadialGradient(colors: [Color(red: 1.0, green: 0.55, blue: 0.45),
                                                    Color(red: 0.75, green: 0.22, blue: 0.25)],
                                           center: .init(x: 0.3, y: 0.3), startRadius: 0, endRadius: 45)
                        )
                        .frame(width: 90, height: 90)
                        .opacity(0.45)
                        .position(x: geo.size.width - 30, y: geo.size.height - 30)

                    // 气球
                    balloonView
                        .opacity(balloonOpacity)
                        .position(x: midX, y: balloonY)

                    // 炮弹
                    if projectile > 0 {
                        Circle()
                            .fill(RadialGradient(colors: [.white, Color(red: 0.55, green: 0.6, blue: 1.0),
                                                          Color(red: 0.25, green: 0.3, blue: 0.9)],
                                                 center: .init(x: 0.35, y: 0.3), startRadius: 0, endRadius: 16))
                            .frame(width: 30, height: 30)
                            .shadow(color: Color(red: 0.4, green: 0.5, blue: 1.0), radius: 16)
                            .position(projPos)
                    }

                    // 弹弓
                    slingshotView
                        .offset(y: launcherRecoil ? 5 : 0)
                        .position(cannonPos)

                    // 爆炸
                    if let explosionText {
                        Text(explosionText == "💥" ? "💥" : "💔")
                            .font(.system(size: 62))
                            .scaleEffect(explosionScale)
                            .opacity(explosionOpacity)
                            .position(ballPos)
                    }
                }
                .onAppear {
                    skyH = geo.size.height
                }
                .onChange(of: geo.size.height) { _, newH in
                    skyH = newH
                }
            }
            .frame(minHeight: 240)
            .padding(.horizontal, 0)

            // 底部控制区
            controlView
        }
    }

    // MARK: - 气球

    private var balloonView: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(colors: [Color(red: 1.0, green: 0.88, blue: 0.55),
                                            Color(red: 1.0, green: 0.58, blue: 0.38),
                                            Color(red: 1.0, green: 0.35, blue: 0.42),
                                            Color(red: 0.72, green: 0.22, blue: 0.30)],
                                   center: .init(x: 0.3, y: 0.22), startRadius: 4, endRadius: 76)
                )
                .frame(width: balloonW, height: 158)
                .shadow(color: Color(red: 1.0, green: 0.35, blue: 0.42).opacity(0.4), radius: 18, y: 8)
                .overlay(
                    Ellipse()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )

            Ellipse()
                .fill(Color.white.opacity(0.35))
                .frame(width: 28, height: 44)
                .blur(radius: 4)
                .offset(x: -34, y: -42)
                .rotationEffect(.degrees(-16))

            Text("\(a) × \(b)")
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.45), radius: 6, y: 2)
                .padding(10)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                Triangle()
                    .fill(Color(red: 0.72, green: 0.22, blue: 0.30))
                    .frame(width: 18, height: 13)
                Rectangle()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 2, height: 24)
            }
            .offset(y: 4)
        }
        .frame(width: balloonW, height: balloonH)
    }

    // MARK: - 太空弹弓

    private var slingshotView: some View {
        ZStack {
            // 弹弓主体（光滑 Y 形）
            SlingshotBodyShape()
                .stroke(
                    LinearGradient(colors: [Color(red: 0.66, green: 0.88, blue: 1.0),
                                            Color(red: 0.20, green: 0.42, blue: 0.85)],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 106, height: 88)
                .shadow(color: Color(red: 0.4, green: 0.75, blue: 1.0).opacity(0.45), radius: 12, y: 5)

            // 内侧高光
            SlingshotBodyShape()
                .stroke(Color.white.opacity(0.35),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .frame(width: 106, height: 88)
                .offset(x: -1, y: -2)

            // 皮筋
            SlingshotBandShape()
                .stroke(Color(red: 1.0, green: 0.82, blue: 0.35).opacity(0.95),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .frame(width: 106, height: 88)
                .shadow(color: Color(red: 1.0, green: 0.82, blue: 0.35).opacity(0.4), radius: 4)

            // 皮兜 + 小星星
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.88, blue: 0.62))
                    .frame(width: 22, height: 22)
                    .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.4).opacity(0.5), radius: 8)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.45), lineWidth: 1.5))
                Text("⭐")
                    .font(.system(size: 12))
            }
            .offset(y: -18)

            // 发射闪光
            if launcherRecoil {
                Circle()
                    .fill(RadialGradient(colors: [.white, Color(red: 1.0, green: 0.82, blue: 0.25),
                                                  Color(red: 1.0, green: 0.82, blue: 0.25).opacity(0)],
                                         center: .center, startRadius: 0, endRadius: 34))
                    .frame(width: 68, height: 68)
                    .offset(y: -40)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 118, height: 100)
    }

    // MARK: - 控制区

    private var controlView: some View {
        VStack(spacing: 8) {
            Text(input.isEmpty ? "请输入答案" : input)
                .font(.system(size: 23, weight: .black, design: .serif))
                .tracking(3)
                .foregroundStyle(input.isEmpty ? Color.white.opacity(0.35) : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 14)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(["1","2","3","4","5","6","7","8","9","0","⌫","确定"], id: \.self) { key in
                    Button {
                        handleKey(key)
                    } label: {
                        Text(key)
                            .font(key == "⌫" ? .system(size: 16, weight: .bold)
                                 : key == "确定" ? .system(size: 16, weight: .heavy)
                                 : .system(size: 20, weight: .heavy, design: .serif))
                            .foregroundStyle(key == "⌫" ? Color(red: 1.0, green: 0.82, blue: 0.25)
                                             : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(key == "确定"
                                          ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.42, green: 0.5, blue: 1.0),
                                                                                  Color(red: 0.24, green: 0.30, blue: 0.88)],
                                                                           startPoint: .top, endPoint: .bottom))
                                          : AnyShapeStyle(Color.white.opacity(0.1)))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(key == "确定" ? Color.white.opacity(0.3)
                                                : Color.white.opacity(0.14), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .padding(.top, 8)
        .background(
            LinearGradient(colors: [Color.white.opacity(0.04), Color.black.opacity(0.2)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private var timerProgress: Double {
        guard let mode else { return 1 }
        return max(0, min(1, timerRemaining / mode.seconds))
    }

    // MARK: - 游戏逻辑

    private func startGame(_ newMode: Mode) {
        mode = newMode
        score = 0
        newQuestion()
    }

    private func newQuestion() {
        guard let mode else { return }
        a = Int.random(in: mode.minFactor...mode.maxFactor)
        b = Int.random(in: mode.minFactor...mode.maxFactor)
        input = ""
        locked = false
        balloonY = -170
        balloonOpacity = 1
        projectile = 0
        launcherRecoil = false
        explosionText = nil
        explosionOpacity = 0
        explosionScale = 0
        feedbackText = nil
        timerRemaining = mode.seconds
    }

    private func tick() {
        guard mode != nil, !locked, balloonOpacity > 0 else { return }
        timerRemaining = max(0, timerRemaining - 0.016)
        let duration = mode!.seconds
        let progress = 1 - timerRemaining / duration
        let eased: Double
        if progress < 0.5 {
            eased = 2 * progress * progress
        } else {
            eased = 1 - pow(-2 * progress + 2, 2) / 2
        }
        let maxY = max(60, skyH - balloonH / 2 - 95)
        withAnimation(.linear(duration: 0.016)) {
            balloonY = -170 + CGFloat(eased) * (maxY + 170)
        }
        if timerRemaining <= 0 {
            popBalloon(correct: false, timeout: true)
        }
    }

    private func handleKey(_ key: String) {
        guard !locked else { return }
        if key == "⌫" {
            if !input.isEmpty { input.removeLast() }
        } else if key == "确定" {
            submitAnswer()
        } else if input.count < 4 {
            input += key
        }
    }

    private func submitAnswer() {
        guard !locked else { return }
        guard !input.isEmpty else {
            withAnimation(.easeOut(duration: 0.2)) { feedbackText = "✋" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { feedbackText = nil }
            return
        }
        locked = true
        let ok = Int(input) == correctAnswer
        if ok {
            score += 1
            GameBestScoreStore.update(.multiplicationPlanet, score: score)
            fireCannon()
        } else {
            popBalloon(correct: false, timeout: false)
        }
    }

    private func fireCannon() {
        withAnimation(.easeOut(duration: 0.4)) { launcherRecoil = true }
        withAnimation(.easeOut(duration: 0.3)) { projectile = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.15)) { launcherRecoil = false }
            projectile = 0
            popBalloon(correct: true, timeout: false)
        }
    }

    private func popBalloon(correct: Bool, timeout: Bool) {
        locked = true
        if timeout { timerRemaining = 0 }
        explosionText = correct ? "💥" : "💔"
        explosionOpacity = 1
        explosionScale = 1.3
        feedbackText = correct ? "+1" : (timeout ? "⏰" : "✗")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            explosionScale = correct ? 1.0 : 1.25
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.2)) {
                explosionOpacity = 0
                balloonOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            explosionText = nil
            feedbackText = nil
            newQuestion()
        }
    }
}

// MARK: - 气球结三角形

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - 弹弓形状

private struct SlingshotBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let bottom = CGPoint(x: rect.midX, y: rect.maxY - 4)
        let fork = CGPoint(x: rect.midX, y: rect.maxY * 0.48)
        let leftTip = CGPoint(x: rect.minX + 30, y: rect.minY + 4)
        let rightTip = CGPoint(x: rect.maxX - 30, y: rect.minY + 4)
        p.move(to: bottom)
        p.addLine(to: fork)
        p.addLine(to: leftTip)
        p.move(to: fork)
        p.addLine(to: rightTip)
        return p
    }
}

private struct SlingshotBandShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let leftTip = CGPoint(x: rect.minX + 30, y: rect.minY + 4)
        let rightTip = CGPoint(x: rect.maxX - 30, y: rect.minY + 4)
        let pouch = CGPoint(x: rect.midX, y: rect.minY + 26)
        p.move(to: leftTip)
        p.addLine(to: pouch)
        p.move(to: rightTip)
        p.addLine(to: pouch)
        return p
    }
}
