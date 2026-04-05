import SwiftUI
import Combine
import UIKit

/// 横屏容器内 `GeometryReader` 的 safeArea 常为 0（尤其父级 `ignoresSafeArea` 时），与窗口真实安全区取较大值。
enum MatchstickSafeArea {
    static var windowInsets: UIEdgeInsets {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else {
            return .zero
        }
        return window.safeAreaInsets
    }

    static func landscapeLogicalInsets(isPortrait: Bool) -> EdgeInsets {
        let w = windowInsets
        if isPortrait {
            return EdgeInsets(
                top: w.right,
                leading: w.top,
                bottom: w.left,
                trailing: w.bottom
            )
        } else {
            return EdgeInsets(
                top: w.top,
                leading: w.left,
                bottom: w.bottom,
                trailing: w.right
            )
        }
    }
}

// MARK: - 1. 核心模型定义

/// 火柴的摆放方向
enum SegmentOrientation { case horizontal, vertical }

/// 万能火柴插槽网格位置 (数字与计算符号的融合位置)
enum SegmentType: Hashable, CaseIterable {
    // 经典7段数码管 (用于数字0-9与减号)
    case top, topLeft, topRight, middle, bottomLeft, bottomRight, bottom
    // 扩展段 (加号的竖杠)
    case verticalMiddle
    // 扩展段 (等于号的两横)
    case equalTop, equalBottom
    
    var orientation: SegmentOrientation {
        switch self {
        case .top, .middle, .bottom, .equalTop, .equalBottom: return .horizontal
        case .topLeft, .topRight, .bottomLeft, .bottomRight, .verticalMiddle: return .vertical
        }
    }
}

/// 独立的单根火柴实体
struct Matchstick: Identifiable {
    let id = UUID()
    var slotIndex: Int          // 在第几个字符位置
    var segment: SegmentType    // 当前字符网格的具体方位
    
    // 拖拽互动专属属性
    var isDragging: Bool = false
    var currentPosition: CGPoint? = nil
    var isLocked: Bool = false  // 锁定状态 (如等号)
}

// MARK: - 2. 数学逻辑与火柴题库解析

class MathEngine {
    /// 题库: 格式为 A+B=C 或 A-B=C
    let problemBank = [
        "3-2=9", // 1. S: 3+2=5
        "1+1=6", // 2. S: 7-1=6
        "6+4=4", // 3. S: 0+4=4
        "9+4=4", // 4. S: 0+4=4
        "5+7=2", // 5. S: 9-7=2
        "6+4=5", // 6. S: 5+4=9
        "9-4=9", // 7. S: 5+4=9
        "3+1=3", // 8. S: 2+1=3
        "2+1=5", // 9. S: 2+1=3
        "3-6=4", // 10. S: 9-5=4
        "6+3=5", // 11. S: 8-3=5
        "6+2=1", // 12. S: 5+2=7
        "9-4=7", // 13. S: 3+4=7
        "2+4=7", // 14. S: 3+4=7
        "5+4=7", // 15. S: 3+4=7
        "5+5=1", // 16. S: 6-5=1
        "5-5=7", // 17. S: 6-5=1
        "9-2=8", // 18. S: 8-2=6
        "9+2=6", // 19. S: 8-2=6
        "2-8=8", // 20. S: 2+6=8
        "2+9=8", // 21. S: 2+6=8
        "5+5=4", // 22. S: 9-5=4
        "9-3=4", // 23. S: 9-5=4
        "7+6=9", // 24. S: 1+8=9
        "7-8=9", // 25. S: 1+8=9
        "1+8=0", // 26. S: 1+8=9
        "4-6=9", // 27. S: 4+5=9
        "4+6=5", // 28. S: 4+5=9
        "4+3=9", // 29. S: 4+5=9
        "9-7=7", // 30. S: 8-7=1
        
        "1+2=8", // 31. S: 7+2=9
        "7-2=8", // 32. S: 7+2=9
        "5+9=9", // 33. S: 6+3=9
        "6-3=8", // 34. S: 6+3=9
        "0+3=9", // 35. S: 6+3=9
        "9+5=3", // 36. S: 8-5=3
        "6+5=3", // 37. S: 8-5=3
        "9-5=9", // 38. S: 8-5=3
        "5+6=3", // 39. S: 9-6=3
        "3-6=9", // 40. S: 9-6=3
        "9-0=3", // 41. S: 9-6=3
        "3+3=8", // 42. S: 5+3=8
        "9+1=7", // 43. S: 8-1=7
        "1+2=5", // 44. S: 7-2=5
        "7-2=3", // 45. S: 7-2=5
        "2+5=8", // 46. S: 3+5=8
        "9-5=8", // 47. S: 3+5=8
        "3+6=0", // 48. S: 3+5=8
        "9+7=1", // 49. S: 8-7=1
        "6+7=1"  // 50. S: 8-7=1
    ]
    
    /// 火柴摆放与字符的映射关系
    let digitMap: [Set<SegmentType>: String] = [
        [.top, .topLeft, .topRight, .bottomLeft, .bottomRight, .bottom]: "0",
        [.topRight, .bottomRight]: "1",
        [.top, .topRight, .middle, .bottomLeft, .bottom]: "2",
        [.top, .topRight, .middle, .bottomRight, .bottom]: "3",
        [.topLeft, .topRight, .middle, .bottomRight]: "4",
        [.top, .topLeft, .middle, .bottomRight, .bottom]: "5",
        [.top, .topLeft, .middle, .bottomLeft, .bottomRight, .bottom]: "6",
        [.top, .topRight, .bottomRight]: "7",
        [.top, .topLeft, .topRight, .middle, .bottomLeft, .bottomRight, .bottom]: "8",
        [.top, .topLeft, .topRight, .middle, .bottomRight, .bottom]: "9",
        [.middle]: "-",
        [.middle, .verticalMiddle]: "+",
        [.equalTop, .equalBottom]: "="
    ]
    
    var reverseMap: [String: Set<SegmentType>] {
        var map = [String: Set<SegmentType>]()
        for (k, v) in digitMap { map[v] = k }
        return map
    }
    
    /// 验证逻辑 (带减号和加号的安全数学求值)
    func checkSuccess(matchsticks: [Matchstick], charCount: Int) -> (String, Bool)? {
        var slotsData = Array(repeating: Set<SegmentType>(), count: charCount)
        for s in matchsticks {
            slotsData[s.slotIndex].insert(s.segment)
        }
        
        var parsedEquation = ""
        for segs in slotsData {
            if let char = digitMap[segs] {
                parsedEquation.append(char)
            } else {
                return nil // 火柴随意摆放，未拼凑成合法字符
            }
        }
        
        let parts = parsedEquation.split(separator: "=")
        guard parts.count == 2 else { return nil } // 等于号丢失或者位置不对
        
        guard let leftRes = evaluateMath(mathString: String(parts[0])),
              let rightRes = evaluateMath(mathString: String(parts[1])) else {
            return nil
        }
        
        return (parsedEquation, leftRes == rightRes)
    }
    
    // 安全地计算基础的 A+B 或 A-B 的结果
    private func evaluateMath(mathString: String) -> Int? {
        let cleanMatch = mathString.replacingOccurrences(of: " ", with: "")
        if cleanMatch.contains("+") {
            let p = cleanMatch.components(separatedBy: "+")
            if p.count == 2, let l = Int(p[0]), let r = Int(p[1]) { return l + r }
        } else if cleanMatch.contains("-") {
            let p = cleanMatch.components(separatedBy: "-")
            if p.count == 2, let l = Int(p[0]), let r = Int(p[1]) { return l - r }
        } else {
            return Int(cleanMatch) // 纯数字场景
        }
        return nil
    }
}

/// 与 `MathEngine.problemBank` 长度一致，供首页「每日一题」等使用。
enum MatchstickProblemSet {
    static var count: Int { MathEngine().problemBank.count }
}

// MARK: - 3. UI视图实现 (逼真设计与动效)

struct MatchstickView: View {
    let orientation: SegmentOrientation
    let length: CGFloat
    let thickness: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.88, green: 0.72, blue: 0.48),
                            Color(red: 0.62, green: 0.44, blue: 0.26)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.78, green: 0.22, blue: 0.2), Color(red: 0.55, green: 0.12, blue: 0.12)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(Capsule().stroke(Color.black.opacity(0.12), lineWidth: 0.5))
                .frame(
                    width: orientation == .horizontal ? thickness * 1.45 : thickness,
                    height: orientation == .vertical ? thickness * 1.45 : thickness
                )
                .position(
                    x: orientation == .horizontal ? length - thickness / 1.4 : thickness / 2,
                    y: orientation == .vertical ? thickness / 1.35 : thickness / 2
                )
        }
        .frame(width: orientation == .horizontal ? length : thickness, height: orientation == .vertical ? length : thickness)
        .shadow(color: .black.opacity(0.22), radius: 2, x: 1, y: 2)
    }
}

/// 由**当前画布**尺寸推导，避免与 `UIScreen` 不一致导致算式竖排、吸附错位。
private struct BoardMetrics {
    let slotWidth: CGFloat
    let slotHeight: CGFloat
    let slotSpacing: CGFloat
    let stickThickness: CGFloat

    static func compute(canvas: CGSize, charCount: Int) -> BoardMetrics {
        let n = CGFloat(max(5, charCount))
        let usableW = max(0, canvas.width)
        let spacingRatio: CGFloat = 0.38
        let denom = n + spacingRatio * max(0, n - 1)
        // 略提高上限，让核心棋盘在同样宽度下火柴更大
        let sw = min(92, max(26, usableW / max(denom, 1)))
        let ss = sw * spacingRatio
        let sh = sw * 2
        let st = sw * 0.21
        return BoardMetrics(slotWidth: sw, slotHeight: sh, slotSpacing: ss, stickThickness: st)
    }
}

/// 柔和暖色 Mesh，避免喧宾夺主（作为背景全局常量，供外层使用）
enum MatchstickGameStyle {
    static let meshA: [Color] = [
        Color(red: 0.90, green: 0.88, blue: 0.95), Color(red: 0.85, green: 0.90, blue: 0.96), Color(red: 0.88, green: 0.92, blue: 0.94),
        Color(red: 0.87, green: 0.89, blue: 0.93), Color(red: 0.91, green: 0.90, blue: 0.96), Color(red: 0.86, green: 0.91, blue: 0.95),
        Color(red: 0.89, green: 0.88, blue: 0.94), Color(red: 0.84, green: 0.89, blue: 0.93), Color(red: 0.90, green: 0.91, blue: 0.97)
    ]
    static let meshB: [Color] = [
        Color(red: 0.84, green: 0.90, blue: 0.96), Color(red: 0.90, green: 0.87, blue: 0.94), Color(red: 0.87, green: 0.91, blue: 0.95),
        Color(red: 0.89, green: 0.90, blue: 0.97), Color(red: 0.85, green: 0.88, blue: 0.93), Color(red: 0.88, green: 0.92, blue: 0.96),
        Color(red: 0.86, green: 0.89, blue: 0.94), Color(red: 0.91, green: 0.91, blue: 0.98), Color(red: 0.83, green: 0.88, blue: 0.92)
    ]
}

struct MatchstickContentView: View {
    let engine = MathEngine()
    @EnvironmentObject private var progress: AppProgressStore

    var onExit: (() -> Void)? = nil
    var initialProblemIndex: Int? = nil
    var isDailyChallenge: Bool = false

    @State private var dailyTargetIndex: Int = -1

    @State private var matchsticks: [Matchstick] = []
    @State private var currentProblemIndex: Int = 0
    @State private var problemCharCount: Int = 5

    @State private var shakeAmount: CGFloat = 0
    @State private var isSuccessAlert: Bool = false
    @State private var isFailureAlert: Bool = false
    @State private var isBoardLocked: Bool = false

    @State private var activeDragId: UUID? = nil
    @State private var hoverSegment: SegmentType? = nil

    @State private var timeRemaining: Int = 120
    @State private var problemStatus: [Int: Bool] = [:]
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var correctCount: Int { problemStatus.values.filter { $0 == true }.count }
    private var wrongCount: Int { problemStatus.values.filter { $0 == false }.count }

    var body: some View {
        GeometryReader { geo in
            let w = MatchstickSafeArea.windowInsets
            let g = geo.safeAreaInsets
            let topSafe = max(g.top, w.top)
            let bottomSafe = max(g.bottom, w.bottom)
            
            // 三段式布局：精确计算每段实际占用空间
            let topBarContentHeight: CGFloat = 56
            let topBarTotalHeight = topBarContentHeight + max(2, topSafe + 2)
            
            let bottomBarContentHeight: CGFloat = 60  // 按钮实际需要高度
            let bottomBarBottomPadding = max(10, bottomSafe + 10)
            let bottomBarTotalHeight = bottomBarContentHeight + bottomBarBottomPadding
            
            let boardHeight = max(120, geo.size.height - topBarTotalHeight - bottomBarTotalHeight)

            VStack(spacing: 0) {
                // 1. 顶栏
                VStack(spacing: 0) {
                    topBarCompact()
                        .frame(height: topBarContentHeight)
                        .padding(.horizontal, 12)
                }
                .padding(.top, max(2, topSafe + 2))

                // 2. 棋盘区（占满剩余高度）
                GeometryReader { boardGeo in
                    boardLayer(canvasSize: boardGeo.size)
                }
                .frame(height: boardHeight)
                .padding(.horizontal, 8)

                // 3. 底栏
                VStack(spacing: 0) {
                    bottomToolbarUnified
                        .frame(height: bottomBarContentHeight)
                        .padding(.horizontal, 8)
                }
                .padding(.bottom, bottomBarBottomPadding)
            }
        }
        .onAppear {
            let total = engine.problemBank.count
            if isDailyChallenge {
                dailyTargetIndex = initialProblemIndex ?? progress.dailyMatchstickProblemIndex(totalProblems: total)
                if initialProblemIndex == nil {
                    currentProblemIndex = dailyTargetIndex
                }
            } else {
                dailyTargetIndex = -1
            }
            if let idx = initialProblemIndex {
                currentProblemIndex = idx
            } else if !isDailyChallenge {
                let saved = progress.matchstickBookmarkIndex
                currentProblemIndex = min(max(0, saved), max(0, total - 1))
            }
            loadProblem(index: currentProblemIndex)
        }
        .onDisappear {
            progress.saveMatchstickBookmark(index: currentProblemIndex, totalProblems: engine.problemBank.count)
        }
        .onReceive(timer) { _ in
            guard !isBoardLocked else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                handleTimeOut()
            }
        }
    }

    // MARK: - 子视图

    private var timerCapsuleCompact: some View {
        Text(String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60))
            .font(.system(size: 20, design: .monospaced).weight(.bold))
            .foregroundStyle(timeRemaining <= 10 ? Color.red.opacity(0.95) : AppTheme.matchControlTint)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
    }

    /// 顶栏：返回键、统计与倒计时（平铺不加卡片背景）
    private func topBarCompact() -> some View {
        HStack(alignment: .center, spacing: 10) {
            if let exit = onExit {
                Button(action: exit) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppTheme.matchInk)
                        .frame(width: 46, height: 46)
                        .background(.ultraThinMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if isDailyChallenge, currentProblemIndex == dailyTargetIndex, dailyTargetIndex >= 0 {
                        Text("每日")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.accentBlue.opacity(0.22), AppTheme.accentIndigo.opacity(0.14)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: Capsule()
                            )
                            .foregroundStyle(AppTheme.accentBlue)
                    }
                    Text("移动一根火柴，使等式成立")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Text("\(correctCount) 对 · \(wrongCount) 错  ·  第 \(currentProblemIndex + 1) / \(engine.problemBank.count) 题")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                if timeRemaining <= 15 {
                    SWShimmer(duration: 1.1, delay: 0.3) { timerCapsuleCompact }
                } else {
                    timerCapsuleCompact
                }
            }
        }
    }

    private func boardLayer(canvasSize: CGSize) -> some View {
        let metrics = BoardMetrics.compute(canvas: canvasSize, charCount: problemCharCount)
        let rects = calculateRects(canvasSize: canvasSize, metrics: metrics)
        return ZStack {
            ForEach($matchsticks) { $stick in
                let targetCenter = centerPoint(segment: stick.segment, in: rects[stick.slotIndex])
                let isHovering = stick.isDragging && activeDragId == stick.id && hoverSegment != nil
                let displayOrientation: SegmentOrientation = {
                    if isHovering, let h = hoverSegment { return h.orientation }
                    return stick.segment.orientation
                }()

                MatchstickView(
                    orientation: displayOrientation,
                    length: metrics.slotWidth,
                    thickness: metrics.stickThickness
                )
                .position(stick.isDragging ? (stick.currentPosition ?? targetCenter) : targetCenter)
                .scaleEffect(stick.isDragging ? 1.12 : 1.0)
                .rotationEffect(.degrees(stick.isDragging && hoverSegment == nil ? -3 : 0))
                .shadow(color: .black.opacity(stick.isDragging ? 0.35 : 0.2), radius: stick.isDragging ? 6 : 2, x: 0, y: 2)
                .zIndex(stick.isDragging ? 10 : (stick.isLocked ? 0 : 1))
                .gesture(
                    DragGesture(coordinateSpace: .named("Board"))
                        .onChanged { value in
                            guard !isBoardLocked, !stick.isLocked else { return }
                            stick.isDragging = true
                            activeDragId = stick.id
                            let x = min(max(value.location.x, -50), canvasSize.width + 50)
                            let y = min(max(value.location.y, -50), canvasSize.height + 50)
                            stick.currentPosition = CGPoint(x: x, y: y)

                            var bestDist = metrics.slotWidth * 0.68
                            var hover: SegmentType?
                            let occupied = Set(matchsticks.filter { $0.id != stick.id }.map { "\($0.slotIndex)-\($0.segment)" })

                            for i in 0..<rects.count {
                                for seg in allowedSegments(for: i) {
                                    if occupied.contains("\(i)-\(seg)") { continue }
                                    let c = centerPoint(segment: seg, in: rects[i])
                                    let d = hypot(c.x - value.location.x, c.y - value.location.y)
                                    if d < bestDist {
                                        bestDist = d
                                        hover = seg
                                    }
                                }
                            }
                            withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.72)) {
                                hoverSegment = hover
                            }
                        }
                        .onEnded { value in
                            guard !isBoardLocked, !stick.isLocked else { return }
                            stick.isDragging = false
                            stick.currentPosition = nil
                            activeDragId = nil
                            hoverSegment = nil
                            handleDrop(for: stick, at: value.location, in: rects, metrics: metrics)
                        }
                )
                .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.65), value: stick.isDragging)
                .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.6), value: stick.segment)
                .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.6), value: stick.slotIndex)
            }

            if isSuccessAlert {
                SWShimmer(duration: 1.8, delay: 0.4) {
                    Text("等式成立")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 18)
                        .background(AppTheme.accentSage, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: AppTheme.accentSage.opacity(0.45), radius: 12, y: 4)
                }
                .zIndex(100)
                .transition(.scale(scale: 0.88).combined(with: .opacity))
            } else if isFailureAlert {
                Text("时间到")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 18)
                    .background(AppTheme.accentTerracotta.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .zIndex(100)
                    .transition(.scale(scale: 0.88).combined(with: .opacity))
            }
        }
        .offset(x: shakeAmount)
        .coordinateSpace(name: "Board")
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private var bottomToolbarUnified: some View {
        HStack(spacing: 18) {
            barButton(icon: "chevron.left", label: "上题", action: { changeProblem(offset: -1) })
            barButton(icon: "arrow.uturn.backward", label: "重开", action: resetCurrentProblem)
            barButton(icon: "shuffle", label: "随机", action: pickRandomProblem)
            barButton(icon: "chevron.right", label: "下题", action: { changeProblem(offset: 1) })
        }
    }

    private func barButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundStyle(AppTheme.matchControlTint)
            .frame(minWidth: 54, minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 逻辑控制方法

    private func handleTimeOut() {
        isBoardLocked = true
        withAnimation { isFailureAlert = true }
        
        // 记录失败
        if problemStatus[currentProblemIndex] == nil {
            problemStatus[currentProblemIndex] = false
        }
        
        // 错误震动
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if isFailureAlert { // 如果没有强行被用户划走切题
                withAnimation { changeProblem(offset: 1) }
            }
        }
    }
    
    private func loadProblem(index: Int) {
        let problemStr = engine.problemBank[index]
        problemCharCount = problemStr.count
        matchsticks.removeAll()
        isSuccessAlert = false
        isFailureAlert = false
        isBoardLocked = false // 重新加载题目时解除面板锁定
        timeRemaining = 120   // 重置倒计时
        
        for (i, char) in problemStr.enumerated() {
            if let segments = engine.reverseMap[String(char)] {
                let locked = (char == "=")
                for seg in segments {
                    matchsticks.append(Matchstick(slotIndex: i, segment: seg, isLocked: locked))
                }
            }
        }
        progress.saveMatchstickBookmark(index: index, totalProblems: engine.problemBank.count)
    }

    private func resetCurrentProblem() { loadProblem(index: currentProblemIndex) }
    
    private func changeProblem(offset: Int) {
        let total = engine.problemBank.count
        currentProblemIndex = (currentProblemIndex + offset + total) % total
        loadProblem(index: currentProblemIndex)
    }
    
    private func pickRandomProblem() {
        var newIndex = Int.random(in: 0..<engine.problemBank.count)
        while newIndex == currentProblemIndex && engine.problemBank.count > 1 {
            newIndex = Int.random(in: 0..<engine.problemBank.count)
        }
        currentProblemIndex = newIndex
        loadProblem(index: currentProblemIndex)
    }
    
    // MARK: - 拖拽与吸附逻辑
    
    // 通过题库的绝对规律严格限定不同「坑位/插槽」能放的火柴形状
    private func allowedSegments(for slotIndex: Int) -> [SegmentType] {
        // 索引为1的位置必定是 加号或减号
        if slotIndex == 1 {
            return [.middle, .verticalMiddle] // 只能拼成 + 或 -
        }
        // 索引为3的位置必定是 等于号
        else if slotIndex == 3 {
            return [] // 等于号本身已被锁定不可拔出，且此区域绝对不允许再放置其他外来火柴
        }
        // 剩下的 0, 2, 4 必定是数字
        else {
            return [.top, .topLeft, .topRight, .middle, .bottomLeft, .bottomRight, .bottom]
        }
    }
    
    private func handleDrop(for droppedStick: Matchstick, at dropLocation: CGPoint, in rects: [CGRect], metrics: BoardMetrics) {
        var bestMatch: (slot: Int, segment: SegmentType)? = nil
        var minDistance: CGFloat = metrics.slotWidth * 0.68
        
        let occupied = Set(matchsticks.filter { $0.id != droppedStick.id }.map { "\($0.slotIndex)-\($0.segment)" })
        
        for slotIndex in 0..<rects.count {
            // 利用严格校验器筛选这个坑位允许的形状，杜绝加减号变成等号等离谱拼凑
            let validSegments = allowedSegments(for: slotIndex)
            
            for seg in validSegments {
                if occupied.contains("\(slotIndex)-\(seg)") { continue }
                
                let cnt = centerPoint(segment: seg, in: rects[slotIndex])
                let dist = hypot(cnt.x - dropLocation.x, cnt.y - dropLocation.y)
                if dist < minDistance {
                    minDistance = dist
                    bestMatch = (slotIndex, seg)
                }
            }
        }
        
        // 【新增】备份原属位置，用于后续“如果导致算盘变成乱码形状时强制还原”
        let originalSlot = droppedStick.slotIndex
        let originalSegment = droppedStick.segment
        
        if let match = bestMatch {
            if let stickIdx = matchsticks.firstIndex(where: { $0.id == droppedStick.id }) {
                matchsticks[stickIdx].slotIndex = match.slot
                matchsticks[stickIdx].segment = match.segment
            }
        } else {
            // 连合法坑位都找不着（直接扔飞了），什么都不改，它会自动缩回去
            return
        }
        
        if let result = engine.checkSuccess(matchsticks: matchsticks, charCount: problemCharCount) {
            if result.1 == true {
                // 记录正确
                if problemStatus[currentProblemIndex] == nil {
                    problemStatus[currentProblemIndex] = true
                }

                let countsAsDaily = isDailyChallenge && dailyTargetIndex >= 0 && currentProblemIndex == dailyTargetIndex
                progress.recordMatchstickSuccess(isDailyChallenge: countsAsDaily)

                withAnimation {
                    isSuccessAlert = true
                    isBoardLocked = true // 成功后立刻锁死棋盘不可再操作
                }
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // 自动跳下一题 (延时 2.0 秒)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    // 如果用户等不及自己按了下一题，我们就不打断他的节奏
                    if isSuccessAlert {
                        withAnimation { changeProblem(offset: 1) }
                    }
                }
            } else { 
                // 【核心修复】如果拼出来的算式合乎规矩，但是等式不成立：
                // 触发错误抖动，同时也将它【立刻还原回它原本的位置】，不让它弄脏黑板
                if let stickIdx = matchsticks.firstIndex(where: { $0.id == droppedStick.id }) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        matchsticks[stickIdx].slotIndex = originalSlot
                        matchsticks[stickIdx].segment = originalSegment
                    }
                }
                triggerFailureShake()
            }
        } else {
            // 被放到不正确位置导致乱码字形：
            // 此时必须还原初始位置，避免满盘皆毁
            if let stickIdx = matchsticks.firstIndex(where: { $0.id == droppedStick.id }) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    matchsticks[stickIdx].slotIndex = originalSlot
                    matchsticks[stickIdx].segment = originalSegment
                }
            }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning) // 轻微震动代表操作被驳回
        }
    }
    
    private func triggerFailureShake() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        withAnimation(.linear(duration: 0.1)) { shakeAmount = -10 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 0.1)) { shakeAmount = 10 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.linear(duration: 0.1)) { shakeAmount = 0 }
        }
    }
    
    // MARK: - 坐标自动计算 (数学与几何系算法)
    
    private func calculateRects(canvasSize: CGSize, metrics: BoardMetrics) -> [CGRect] {
        let totalWidth = CGFloat(problemCharCount) * metrics.slotWidth + CGFloat(problemCharCount - 1) * metrics.slotSpacing
        let startX = (canvasSize.width - totalWidth) / 2
        let startY = (canvasSize.height - metrics.slotHeight) / 2

        return (0..<problemCharCount).map { i in
            CGRect(
                x: startX + CGFloat(i) * (metrics.slotWidth + metrics.slotSpacing),
                y: startY,
                width: metrics.slotWidth,
                height: metrics.slotHeight
            )
        }
    }
    
    private func centerPoint(segment: SegmentType, in rect: CGRect) -> CGPoint {
        let w = rect.width; let h = rect.height; let x = rect.minX; let y = rect.minY
        switch segment {
        case .top:          return CGPoint(x: x + w/2, y: y)
        case .middle:       return CGPoint(x: x + w/2, y: y + h/2)
        case .bottom:       return CGPoint(x: x + w/2, y: y + h)
        case .topLeft:      return CGPoint(x: x,       y: y + h/4)
        case .topRight:     return CGPoint(x: x + w,   y: y + h/4)
        case .bottomLeft:   return CGPoint(x: x,       y: y + h * 3/4)
        case .bottomRight:  return CGPoint(x: x + w,   y: y + h * 3/4)
        case .verticalMiddle: return CGPoint(x: x + w/2, y: y + h/2)
        case .equalTop:     return CGPoint(x: x + w/2, y: y + h/2 - h * 0.12) 
        case .equalBottom:  return CGPoint(x: x + w/2, y: y + h/2 + h * 0.12) 
        }
    }
}

struct MatchstickBackgroundView: View {
    var body: some View {
        ZStack {
            Image("bg")
                .resizable()
                .scaledToFill()
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

            SWAnimatedMeshGradient(
                paletteA: MatchstickGameStyle.meshA,
                paletteB: MatchstickGameStyle.meshB,
                duration: 14
            )
            .opacity(0.1)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
