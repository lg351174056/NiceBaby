import SwiftUI
import Combine

// MARK: - 舒尔特方格（专注力训练）

struct SchulteGridView: View {
    let onExit: () -> Void

    private let sizes = [3, 4, 5, 6]

    @State private var size: Int? = nil
    @State private var numbers: [Int] = []
    @State private var cellColors: [Color] = []
    @State private var current = 1
    @State private var started = false
    @State private var startDate: Date? = nil
    @State private var elapsed = 0.0
    @State private var finished = false
    @State private var wrongIndex: Int? = nil
    @State private var bestTime: Double? = nil
    @State private var newRecord = false

    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    private var maxNumber: Int {
        guard let size else { return 36 }
        return size * size
    }

    var body: some View {
        ZStack {
            background

            if size == nil {
                menuView
            } else {
                gameView
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(timer) { _ in
            guard started, !finished, let start = startDate else { return }
            elapsed = Date().timeIntervalSince(start)
        }
    }

    // MARK: - 背景（App 统一田园风）

    private var background: some View {
        FieldBackground()
    }

    // MARK: - 模式选择

    private var menuView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                GracefulBackButton(action: onExit)
                Spacer()
                Text("舒尔特方格")
                    .font(.system(size: 18, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer()

            Text("舒尔特方格")
                .font(.system(size: 34, weight: .black, design: .serif))
                .tracking(3)
                .foregroundStyle(AppTheme.fieldInk)
                .padding(.bottom, 8)

            Text("按 1 → N 依次点击，越快越专注")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.fieldMoss)
                .padding(.bottom, 34)

            VStack(spacing: 14) {
                ForEach(sizes, id: \.self) { size in
                    Button {
                        startGame(size)
                    } label: {
                        HStack(spacing: 16) {
                            Text("\(size)×\(size)")
                                .font(.system(size: 24, weight: .black, design: .serif))
                                .foregroundStyle(.white)
                                .frame(width: 74, height: 74)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(sizeColor(size))
                                )
                                .shadow(color: sizeColor(size).opacity(0.4), radius: 8, y: 4)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(sizeName(size))
                                    .font(.system(size: 18, weight: .heavy, design: .serif))
                                    .foregroundStyle(AppTheme.fieldInk)
                                Text("1 ~ \(size * size) · \(size) 行 \(size) 列")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.fieldMoss)
                                if let best = SchulteBestStore.best(for: size) {
                                    Text("最佳 \(String(format: "%.1f", best)) 秒")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(sizeColor(size).opacity(0.8))
                                } else {
                                    Text("还没玩过")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(AppTheme.fieldMossLight)
                                }
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
                                        .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 2)
                                )
                                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.1), radius: 8, y: 4)
                        )
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
            HStack(spacing: 10) {
                GracefulBackButton(action: onExit)

                Text("舒尔特 · \(size.map { "\($0)×\($0)" } ?? "")")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .frame(maxWidth: .infinity)

                HStack(spacing: 6) {
                    timerChip
                    resetButton
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Spacer(minLength: 12)

            grid

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay {
            if !started && !finished {
                startOverlay
            } else if finished {
                resultOverlay
            }
        }
    }

    private var timerChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: 11, weight: .bold))
            Text(String(format: "%.1fs", elapsed))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(AppTheme.fieldInk)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.8)))
        .overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.2), lineWidth: 1))
    }

    private var resetButton: some View {
        Button {
            startGame(size!)
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.fieldMint)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.8), in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.7), lineWidth: 1))
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 棋盘

    private var grid: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: size ?? 5)
        return LazyVGrid(columns: cols, spacing: gridSpacing) {
            ForEach(Array(numbers.enumerated()), id: \.offset) { idx, n in
                Button {
                    if started { tap(idx, n) }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(cellBackground(idx, n))
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .strokeBorder(
                                        wrongIndex == idx ? Color.red.opacity(0.85)
                                            : AppTheme.fieldOlive.opacity(0.14),
                                        lineWidth: wrongIndex == idx ? 2 : 1
                                    )
                            )
                            .shadow(color: AppTheme.fieldGrassShadow.opacity(0.07), radius: 4, y: 2)

                        Text("\(n)")
                            .font(.system(size: cellFontSize, weight: .black, design: .serif))
                            .foregroundStyle(isDone(n)
                                             ? Color(red: 0.42, green: 0.46, blue: 0.45)
                                             : Color(red: 0.10, green: 0.28, blue: 0.18))
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .scaleEffect(wrongIndex == idx ? 0.94 : 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
    }

    private func cellBackground(_ idx: Int, _ n: Int) -> Color {
        if wrongIndex == idx {
            return Color(red: 1.0, green: 0.76, blue: 0.76)
        }
        if isDone(n) {
            return Color(red: 0.72, green: 0.75, blue: 0.74)
        }
        if cellColors.indices.contains(idx) {
            return cellColors[idx]
        }
        return Color.white.opacity(0.9)
    }

    private func isDone(_ n: Int) -> Bool {
        n < current
    }

    // MARK: - 完成弹窗

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()

            resultCard
        }
        .transition(.opacity)
    }

    private var resultCard: some View {
        VStack(spacing: 14) {
            Text(newRecord ? "🎉 新纪录！" : "🎉")
                .font(.system(size: 48))
                .padding(.top, 6)

            Text("完成！")
                .font(.system(size: 26, weight: .black, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)

            VStack(spacing: 6) {
                Text("本局用时")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.fieldMoss)
                Text(String(format: "%.2f", elapsed) + " 秒")
                    .font(.system(size: 32, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.fieldMint)
            }

            VStack(spacing: 6) {
                Text("当前最高记录")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.fieldMoss)
                Text(bestTime.map { String(format: "%.2f", $0) + " 秒" } ?? "-")
                    .font(.system(size: 22, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
            }

            HStack(spacing: 12) {
                Button {
                    startGame(size!)
                } label: {
                    Text("继续挑战")
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
                    onExit()
                } label: {
                    Text("放弃")
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
            .padding(.bottom, 6)
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

    // MARK: - 开始遮罩

    private var startOverlay: some View {
        ZStack {
            Color.white.opacity(0.62)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("🧠")
                    .font(.system(size: 58))

                Text("舒尔特 · \(size.map { "\($0)×\($0)" } ?? "")")
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)

                Text("点击「开始」后计时启动\n按 1 到 \(maxNumber) 依次点击")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Button {
                    startPlaying()
                } label: {
                    Text("开始训练")
                        .font(.system(size: 19, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 16)
                        .background(
                            Capsule().fill(
                                LinearGradient(colors: [Color(red: 0.35, green: 0.82, blue: 0.55),
                                                        Color(red: 0.18, green: 0.62, blue: 0.42)],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                        )
                        .shadow(color: Color(red: 0.18, green: 0.62, blue: 0.42).opacity(0.35), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 34)
            .padding(.vertical, 38)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.99, green: 0.98, blue: 0.94),
                                Color(red: 0.88, green: 0.96, blue: 0.90),
                                Color(red: 0.85, green: 0.93, blue: 0.97)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(
                                LinearGradient(colors: [Color.white.opacity(0.8), AppTheme.fieldMint.opacity(0.35)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: AppTheme.fieldGrassShadow.opacity(0.16), radius: 18, y: 8)
            )
        }
    }

    // MARK: - 游戏逻辑

    private func startGame(_ newSize: Int) {
        size = newSize
        let count = newSize * newSize
        numbers = Array(1...count).shuffled()
        cellColors = makeCellColors(count: count, grid: newSize)
        current = 1
        started = false
        startDate = nil
        elapsed = 0
        finished = false
        wrongIndex = nil
        newRecord = false
        bestTime = SchulteBestStore.best(for: newSize)
    }

    private func tap(_ idx: Int, _ n: Int) {
        guard !finished else { return }
        guard n == current else {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.45)) {
                wrongIndex = idx
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 0.15)) {
                    if wrongIndex == idx { wrongIndex = nil }
                }
            }
            return
        }

        if startDate == nil {
            startDate = Date()
        }

        current += 1

        if current > maxNumber {
            let seconds = Date().timeIntervalSince(startDate ?? Date())
            elapsed = seconds
            finished = true
            if let old = SchulteBestStore.best(for: size!) {
                newRecord = seconds < old
            } else {
                newRecord = true
            }
            bestTime = SchulteBestStore.update(size!, seconds: seconds)
                ? seconds : SchulteBestStore.best(for: size!)
        }
    }

    // MARK: - 辅助

    private func startPlaying() {
        started = true
        startDate = Date()
    }

    private var gridSpacing: CGFloat {
        switch size {
        case 3: return 10
        case 4: return 9
        case 5: return 8
        default: return 6
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case 3: return 16
        case 4: return 14
        case 5: return 12
        default: return 10
        }
    }

    private var cellFontSize: CGFloat {
        switch size {
        case 3: return 32
        case 4: return 27
        case 5: return 22
        default: return 19
        }
    }

    private func makeCellColors(count: Int, grid: Int) -> [Color] {
        let palette: [Color] = [
            Color(red: 0.78, green: 0.92, blue: 0.83),
            Color(red: 0.80, green: 0.94, blue: 0.68),
            Color(red: 0.72, green: 0.86, blue: 0.96),
            Color(red: 0.97, green: 0.84, blue: 0.50),
            Color(red: 0.97, green: 0.72, blue: 0.70),
            Color(red: 0.84, green: 0.72, blue: 0.96),
            Color(red: 0.98, green: 0.76, blue: 0.58),
            Color(red: 0.65, green: 0.89, blue: 0.85),
            Color(red: 0.79, green: 0.93, blue: 0.56),
            Color(red: 0.95, green: 0.91, blue: 0.54),
            Color(red: 0.70, green: 0.83, blue: 0.98),
            Color(red: 0.96, green: 0.79, blue: 0.87),
            Color(red: 0.66, green: 0.90, blue: 0.92),
            Color(red: 0.90, green: 0.85, blue: 0.66),
            Color(red: 0.80, green: 0.78, blue: 0.97),
            Color(red: 0.87, green: 0.92, blue: 0.73)
        ]

        // 小棋盘（3×3 / 4×4 / 5×5）尽量不重复颜色
        if count <= palette.count {
            return palette.shuffled()
        }

        // 6×6 等超出调色板时，保证相邻格子不撞色
        var indices: [Int] = []
        for i in 0..<count {
            let row = i / grid, col = i % grid
            var forbidden = Set<Int>()
            if col > 0 { forbidden.insert(indices[i - 1]) }
            if row > 0 { forbidden.insert(indices[i - grid]) }
            let candidates = (0..<palette.count).filter { !forbidden.contains($0) }
            let pool = candidates.isEmpty ? Array(0..<palette.count) : candidates
            indices.append(pool[Int.random(in: 0..<pool.count)])
        }
        return indices.map { palette[$0] }
    }

    private func sizeName(_ size: Int) -> String {
        switch size {
        case 3: return "入门 3×3"
        case 4: return "标准 4×4"
        case 5: return "挑战 5×5"
        default: return "王者 6×6"
        }
    }

    private func sizeColor(_ size: Int) -> Color {
        switch size {
        case 3: return AppTheme.accentJade
        case 4: return AppTheme.accentBamboo
        case 5: return AppTheme.accentInkPurple
        default: return Color(red: 0.85, green: 0.60, blue: 0.15)
        }
    }
}

// MARK: - 最佳成绩（本地缓存）

enum SchulteBestStore {
    private static func key(_ size: Int) -> String {
        "schulte.best.\(size)"
    }

    static func best(for size: Int) -> Double? {
        let v = UserDefaults.standard.double(forKey: key(size))
        return v > 0 ? v : nil
    }

    @discardableResult
    static func update(_ size: Int, seconds: Double) -> Bool {
        if let old = best(for: size), seconds >= old { return false }
        UserDefaults.standard.set(seconds, forKey: key(size))
        return true
    }

    static func hasAny() -> Bool {
        [3, 4, 5, 6].contains { best(for: $0) != nil }
    }
}
