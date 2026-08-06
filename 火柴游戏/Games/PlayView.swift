import SwiftUI

// MARK: - 益智 Tab · 演武场 · 墨韵新风

struct PlayView: View {
    @EnvironmentObject private var progress: AppProgressStore
    @State private var path = NavigationPath()

    private var hideTabBar: Bool { !path.isEmpty }

    private var matchProgress: Double {
        let total = MatchstickProblemSet.count
        guard total > 0 else { return 0 }
        return min(Double(progress.totalMatchstickSolves) / Double(total), 1.0)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // 蓝天草地背景（固定）
                LinearGradient(
                    colors: [
                        Color(red: 190/255, green: 227/255, blue: 245/255),
                        Color(red: 220/255, green: 242/255, blue: 220/255),
                        Color(red: 207/255, green: 235/255, blue: 196/255)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                // 太阳 + 白云 + 风车
                fairSun
                fairCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
                fairCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)
                windmillDecor

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        yunvuHero
                        scrollBody
                    }
                }
                .scrollContentBackground(.hidden) // 隐藏系统默认白底，让自定义背景生效
            }
            .navigationDestination(for: GameKind.self) { kind in
                gameContainer(for: kind)
            }
            .toolbar(hideTabBar ? .hidden : .visible, for: .tabBar)
        }
    }

    private func pushGame(_ kind: GameKind) {
        path.append(kind)
    }

    private func popToRoot() {
        path = NavigationPath()
    }

    // MARK: - Hero · 演武场（墨紫夜空 + 武印 + 段位腰带）

    // MARK: - 背景装饰（太阳/云/风车）

    private var fairSun: some View {
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

    private func fairCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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

    // 风车（四叶旋转 + 塔身）
    private var windmillDecor: some View {
        ZStack {
            // 塔身
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        Color(red: 212/255, green: 168/255, blue: 126/255),
                        Color(red: 176/255, green: 138/255, blue: 94/255)
                    ], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 12, height: 40)
                .offset(y: 18)
            // 四叶（旋转）
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .overlay(Capsule().strokeBorder(Color(red: 176/255, green: 138/255, blue: 94/255), lineWidth: 1.5))
                        .frame(width: 40, height: 7)
                        .offset(x: 17)
                        .rotationEffect(.degrees(Double(i) * 90))
                }
            }
            .frame(width: 34, height: 34)
            .offset(y: -4)
            .modifier(WindmillSpin())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.trailing, 24)
        .padding(.top, 120)
        .allowsHitTesting(false)
        .opacity(0.92)
    }

    private struct WindmillSpin: ViewModifier {
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                content
                    .rotationEffect(.degrees((t * 60).truncatingRemainder(dividingBy: 360)))
            }
        }
    }

    // MARK: - 田野游乐园 · 头部 + 段位腰带

    private var yunvuHero: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text("FUN FAIR")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(Color(red: 110/255, green: 138/255, blue: 90/255))
                Text("益智")
                    .font(.system(size: 30, weight: .heavy, design: .serif))
                    .tracking(3)
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .padding(.top, 6)
                Text("每一道题，都是一座小游乐设施")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 122/255, green: 138/255, blue: 110/255))
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            .padding(.bottom, 16)

            fairBelt
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.bottom, 22)
    }

    // 段位腰带：旋转木马徽章 + 课业进度
    private var fairBelt: some View {
        HStack(spacing: 14) {
            // 金色旋转木马
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 233/255, blue: 168/255),
                            Color(red: 212/255, green: 168/255, blue: 75/255),
                            Color(red: 176/255, green: 138/255, blue: 62/255)
                        ], center: .init(x: 0.35, y: 0.3), startRadius: 4, endRadius: 28)
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: Color(red: 217/255, green: 164/255, blue: 91/255).opacity(0.6), radius: 10)
                Text("🎠")
                    .font(.system(size: 24))
                    .modifier(FairBob(delay: 0))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("小马骑士 · 课业 \(Int(beltProgress * 100))%")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .tracking(1)
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Text("再玩 3 个设施，可坐大转马")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.15))
                            .frame(height: 8)
                        Capsule()
                            .fill(
                                LinearGradient(colors: [
                                    Color(red: 217/255, green: 164/255, blue: 91/255),
                                    Color(red: 125/255, green: 249/255, blue: 255/255)
                                ], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * beltProgress, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                fairStat(value: "\(beltMedalCount)", label: "功课")
                fairStat(value: "\(beltMedalCount)", label: "勋章")
                fairStat(value: "\(progress.streakDays)", label: "连续")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.12), radius: 10, y: 5)
        )
    }

    private var beltProgress: Double {
        let done = allLessons.filter { lessonState($0.kind).done }.count
        guard !allLessons.isEmpty else { return 0 }
        return min(Double(done) / Double(allLessons.count), 1.0)
    }

    private var beltMedalCount: Int {
        allLessons.filter { lessonState($0.kind).done }.count
    }

    private func fairStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
        }
    }

    private struct FairBob: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(y: CGFloat(sin(t * 2.2) * 4.0))
            }
        }
    }

    // MARK: - 主体

    private var scrollBody: some View {
        VStack(spacing: 20) {
            arenaSection
            encyclopediaSection
            movesSection
            toolsSection
            colophon
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 18)
        .padding(.bottom, 30)
    }

    // MARK: - 今日功课（每日一题 · 火柴推理）

    private var arenaSection: some View {
        VStack(spacing: 12) {
            subjectHeader(seal: "课", title: "今 日 功 课")
            Button { pushGame(.matchstick) } label: {
                todayLessonCard
            }
            .buttonStyle(.bouncy)
        }
    }

    private var todayLessonCard: some View {
        HStack(spacing: 14) {
            Text("🎯")
                .font(.system(size: 28))
                .modifier(FairBob(delay: 0.3))

            VStack(alignment: .leading, spacing: 3) {
                Text("今日功课 · 每日一题")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("移动一根火柴，让等式成立")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                HStack(spacing: 14) {
                    todayStat(value: "\(MatchstickProblemSet.count)", label: "题")
                    todayStat(value: "\(progress.totalMatchstickSolves)", label: "已破")
                    todayStat(value: "\(progress.streakDays)", label: "连胜")
                }
                .padding(.top, 5)
            }
            Spacer()
            Text("去玩 ›")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        Color(red: 143/255, green: 227/255, blue: 192/255),
                        Color(red: 76/255, green: 175/255, blue: 125/255)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color(red: 61/255, green: 74/255, blue: 54/255), lineWidth: 3)
                )
                .shadow(color: Color(red: 60/255, green: 80/255, blue: 50/255).opacity(0.3), radius: 10, y: 5)
        )
    }

    private func todayStat(value: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // 分组标题（绿色竖条 + 名称 + 渐变线）
    private func subjectHeader(seal: String, title: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color(red: 76/255, green: 175/255, blue: 125/255))
                .frame(width: 6, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .serif))
                .tracking(2)
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            Rectangle()
                .fill(
                    LinearGradient(colors: [Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35), .clear], startPoint: .leading, endPoint: .trailing)
                )
                .frame(height: 2)
        }
        .padding(.horizontal, 2)
    }

    // MARK: - 万象 · 知识百科（入口卡片）

    private var encyclopediaSection: some View {
        VStack(spacing: 12) {
            subjectHeader(seal: "象", title: "万 象 书 库")
            Button { pushGame(.knowledgeWiki) } label: {
                ZStack(alignment: .topTrailing) {
                    LinearGradient(
                        colors: [
                            Color(red: 67/255, green: 70/255, blue: 142/255),
                            AppTheme.accentInkPurple,
                            AppTheme.accentJade
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 180, height: 180)
                        .offset(x: 48, y: -18)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("万 象")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.16)))

                        Text("知识百科")
                            .font(.system(size: 24, weight: .heavy, design: .serif))
                            .tracking(0.8)
                            .foregroundStyle(Color.white)
                            .padding(.top, 12)

                        Text("86 个门类 · 29166 题\n不是照着原页复刻，而是把题库做成一座更好逛的知识园。")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.84))
                            .lineSpacing(4)
                            .padding(.top, 6)

                        HStack(spacing: 10) {
                            atlasStat(value: "\(KnowledgeWikiService.snapshotStatus.wiki)", label: "百科")
                            atlasStat(value: "\(KnowledgeWikiService.snapshotStatus.iq)", label: "智力")
                            atlasStat(value: "\(KnowledgeWikiService.snapshotStatus.brain)", label: "急转")
                        }
                        .padding(.top, 16)

                        HStack(spacing: 6) {
                            Text("入 园")
                                .font(.system(size: 13, weight: .heavy, design: .serif))
                                .tracking(1)
                                .foregroundStyle(AppTheme.accentInkPurple)
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(AppTheme.accentInkPurple)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.95))
                        )
                        .padding(.top, 16)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 210)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.bouncy)
        }
    }

    private func atlasStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .serif))
                .foregroundStyle(Color.white)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .tracking(1)
                .foregroundStyle(Color.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    // MARK: - 课业模型

    private struct Lesson {
        let kind: GameKind
        let name: String
        let sub: String
        let icon: String
    }

    private struct Subject {
        let seal: String
        let icon: String
        let name: String
        let lessons: [Lesson]
    }

    private var allLessons: [Lesson] {
        subjects.flatMap { $0.lessons }
    }

    private var subjects: [Subject] {
        [
            Subject(seal: "数", icon: "🎪", name: "数理马戏团", lessons: [
                Lesson(kind: .matchstick,     name: "火柴推理", sub: "移一根火柴，让等式成立", icon: "🧡"),
                Lesson(kind: .sudoku,         name: "星云数独", sub: "4×4 · 6×6 · 9×9 宫格", icon: "🪐"),
                Lesson(kind: .maze,           name: "迷宫乐园", sub: "走出迷宫，找到草莓熊", icon: "🧩"),
            ]),
            Subject(seal: "文", icon: "🎨", name: "文学杂技团", lessons: [
                Lesson(kind: .poetryComplete, name: "诗词补全", sub: "古诗少一句 · 四选一", icon: "🍊"),
                Lesson(kind: .idiomFillBlank, name: "成语填空", sub: "缺个字，你来填", icon: "📝"),
                Lesson(kind: .antonymMatch,   name: "反义对对碰", sub: "找相反的好朋友", icon: "⚖️"),
                Lesson(kind: .sanzijing,      name: "三字经", sub: "人之初，性本善", icon: "📖"),
                Lesson(kind: .idiomFillLevel, name: "成语填字", sub: "500 关 · 看提示选对字", icon: "🀄"),
            ]),
            Subject(seal: "智", icon: "🎡", name: "脑力摩天轮", lessons: [
                Lesson(kind: .brainTeaser,    name: "脑筋急转弯", sub: "绕一绕，想一想", icon: "🤔"),
                Lesson(kind: .surnameMatch,   name: "百家姓闯关", sub: "看字选音 · 听音选字", icon: "👪"),
                Lesson(kind: .funQuiz,        name: "趣味答题", sub: "多主题 · 图片题与冷知识", icon: "🎯"),
            ]),
        ]
    }

    // MARK: - 课业清单（按科分组）

    private var movesSection: some View {
        VStack(spacing: 12) {
            ForEach(Array(subjects.enumerated()), id: \.offset) { _, subject in
                VStack(spacing: 10) {
                    subjectHeader(seal: subject.seal, title: subject.name)
                    subjectCard(subject)
                }
            }
        }
    }

    private func subjectCard(_ subject: Subject) -> some View {
        let doneCount = subject.lessons.filter { lessonState($0.kind).done }.count
        return VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(subject.icon).font(.system(size: 20))
                Text(subject.name)
                    .font(.system(size: 14, weight: .heavy, design: .serif))
                    .tracking(1)
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Rectangle()
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35),
                            .clear
                        ], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 2)
                Text("\(doneCount) / \(subject.lessons.count) 项")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 4)

            ForEach(Array(subject.lessons.enumerated()), id: \.offset) { index, lesson in
                Button {
                    pushGame(lesson.kind)
                } label: {
                    lessonRow(lesson, index: index)
                }
                .buttonStyle(LessonPressStyle())
                if index < subject.lessons.count - 1 {
                    Rectangle()
                        .fill(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.12))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.clear)
        )
    }

    private func lessonRow(_ lesson: Lesson, index: Int) -> some View {
        let state = lessonState(lesson.kind)
        return HStack(spacing: 12) {
            // 设施图标块
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(rideTint(lesson.icon))
                Text(lesson.icon)
                    .font(.system(size: 20))
            }
            .frame(width: 44, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(lesson.name)
                    .font(.system(size: 13, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Text(lesson.sub)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                    .lineLimit(1)
            }

            Spacer()

            // 星级
            if !state.stars.isEmpty {
                Text(state.stars)
                    .font(.system(size: 9))
                    .tracking(1)
            }

            // 状态
            Text(state.label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(state.done ? Color(red: 76/255, green: 175/255, blue: 125/255)
                    : state.now ? Color(red: 59/255, green: 142/255, blue: 165/255)
                    : Color(red: 168/255, green: 184/255, blue: 154/255))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.25), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 5, y: 3)
        )
        .padding(.horizontal, 10)
    }

    private func rideTint(_ icon: String) -> Color {
        switch icon {
        case "🧡": return Color(red: 255/255, green: 238/255, blue: 216/255)
        case "🪐": return Color(red: 227/255, green: 240/255, blue: 248/255)
        case "🧩", "🍊": return Color(red: 232/255, green: 245/255, blue: 224/255)
        case "📝", "⚖️", "🀄": return Color(red: 245/255, green: 232/255, blue: 245/255)
        case "📖": return Color(red: 248/255, green: 240/255, blue: 216/255)
        default: return Color(red: 227/255, green: 240/255, blue: 248/255)
        }
    }

    // 课程状态：已修(带星级) / 修习中 / 未修
    private struct LessonState {
        let done: Bool
        let now: Bool
        let stars: String
        let label: String
    }

    private func lessonState(_ kind: GameKind) -> LessonState {
        switch kind {
        case .matchstick:
            let done = progress.totalMatchstickSolves > 0
            return LessonState(done: done, now: false,
                               stars: done ? "⭐⭐" : "", label: done ? "已修" : "未修")
        case .maze:
            let done = (0..<20).contains { MazeProgressStore.stars(level: $0) > 0 }
            let stars = done ? "⭐" : ""
            return LessonState(done: done, now: !done, stars: stars, label: done ? "已修" : "修习中")
        case .sudoku:
            let done = [4, 6, 9].contains { SudokuProgressStore.clearCount(size: $0) > 0 }
            let stars = done ? "⭐" : ""
            return LessonState(done: done, now: !done, stars: stars, label: done ? "已修" : "修习中")
        default:
            let best = GameBestScoreStore.best(for: kind)
            if best > 0 {
                let stars: String
                if best >= 30 { stars = "⭐⭐⭐" }
                else if best >= 10 { stars = "⭐⭐" }
                else { stars = "⭐" }
                return LessonState(done: true, now: false, stars: stars, label: "已修")
            }
            return LessonState(done: false, now: false, stars: "", label: "未修")
        }
    }

    private func chineseNum(_ i: Int) -> String {
        let nums = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十",
                    "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十"]
        return i < nums.count ? nums[i] : "\(i + 1)"
    }

    private struct LessonPressStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .background(configuration.isPressed ? Color(red: 246/255, green: 241/255, blue: 231/255).opacity(0.9) : .clear)
                .scaleEffect(configuration.isPressed ? 0.99 : 1)
                .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
        }
    }

    // MARK: - 文房 · 词典三器

    private var toolsSection: some View {
        VStack(spacing: 12) {
            subjectHeader(seal: "房", title: "文 房 三 器")
            HStack(spacing: 10) {
                toolTower(no: "壹", kind: .idiomDictionary, name: "成语大全", sub: "5万+ 海量")
                toolTower(no: "贰", kind: .xiehouyuDictionary, name: "歇后语集", sub: "经典精选")
                toolTower(no: "叁", kind: .dictionary, name: "汉语词典", sub: "查音 · 听读")
            }
        }
    }

    private func toolTower(no: String, kind: GameKind, name: String, sub: String) -> some View {
        Button { pushGame(kind) } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(no)
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .tracking(0.8)
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                Text(name)
                    .font(.system(size: 12.5, weight: .bold, design: .serif))
                    .tracking(0.3)
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .lineLimit(1)
                Text(sub)
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 5, y: 3)
            )
        }
        .buttonStyle(.bouncy)
    }

    // MARK: - 题跋

    private var colophon: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("题 · 跋")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(3.4)
                .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
            Text("修学者，所以明理、益智、进德。每破一题则就一题之道，每成一课则进一阶之修。日拱一卒，功不唐捐。")
                .font(.system(size: 12, weight: .regular, design: .serif))
                .foregroundStyle(Color(red: 110/255, green: 138/255, blue: 98/255))
                .lineSpacing(4)
            Text("田野游乐园 · 谨题")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 176/255, green: 138/255, blue: 62/255))
                .rotationEffect(.degrees(-2))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.2), lineWidth: 1.5)
                )
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color(red: 76/255, green: 175/255, blue: 125/255))
                        .frame(width: 3)
                        .padding(.vertical, 8)
                        .padding(.leading, 6)
                }
        )
    }

    // MARK: - Game Container（保留原路由）

    @ViewBuilder
    private func gameContainer(for kind: GameKind) -> some View {
        // 所有二级游戏页均自带自定义 TopBar/返回按钮，push 进入 NavigationStack 后
        // 必须隐藏系统导航栏，否则会出现系统返回 + 自定义返回两个返回按钮。
        Group {
            switch kind {
            case .matchstick:
                MatchstickGameContainer(onExit: { popToRoot() })
                    .environmentObject(progress)
                    .environmentObject(PoemSpeechService.shared)
            case .poetryComplete:
                PoetryCompleteGameView(onExit: { popToRoot() })
            case .surnameMatch:
                SurnameMatchGameView(onExit: { popToRoot() })
            case .idiomFillBlank:
                IdiomFillBlankGameView(onExit: { popToRoot() })
            case .idiomDictionary:
                IdiomDictionaryView(onExit: { popToRoot() })
            case .xiehouyuDictionary:
                XiehouyuDictionaryView(onExit: { popToRoot() })
            case .sanzijing:
                SanzijingView(onExit: { popToRoot() })
            case .dictionary:
                DictionaryGameView(onExit: { popToRoot() })
            case .antonymMatch:
                AntonymMatchView(onExit: { popToRoot() })
            case .idiomFillLevel:
                IdiomFillLevelView(onExit: { popToRoot() })
            case .brainTeaser:
                BrainTeaserHomeView(onExit: { popToRoot() })
            case .knowledgeWiki:
                KnowledgeWikiHomeView()
            case .funQuiz:
                FunQuizHomeView()
            case .maze:
                MazeGameView(onExit: { popToRoot() })
            case .sudoku:
                SudokuHomeView(onExit: { popToRoot() })
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - 火柴游戏自由模式容器

private struct MatchstickGameContainer: View {
    let onExit: () -> Void

    var body: some View {
        ZStack {
            Image("bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
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
            .ignoresSafeArea()

            SWAnimatedMeshGradient(
                paletteA: MatchstickGameStyle.meshA,
                paletteB: MatchstickGameStyle.meshB,
                duration: 14
            )
            .opacity(0.1)
            .ignoresSafeArea()

            LandscapeContainer {
                MatchstickContentView(
                    onExit: onExit,
                    initialProblemIndex: nil,
                    isDailyChallenge: false
                )
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    PlayView()
}
