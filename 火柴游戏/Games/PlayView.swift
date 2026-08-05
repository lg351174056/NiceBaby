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
        ZStack {
            // 底层全屏背景：仅保留暖白色，确保底部上拉不露白
            AppTheme.background
                .ignoresSafeArea()

            NavigationStack(path: $path) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        yunvuHero
                        scrollBody
                    }
                }
                .scrollContentBackground(.hidden) // 隐藏系统默认白底，让自定义背景生效
                .ignoresSafeArea(edges: .top)
                .navigationDestination(for: GameKind.self) { kind in
                    gameContainer(for: kind)
                }
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

    // MARK: - 书院头 + 段位腰带

    private var yunvuHero: some View {
        VStack(spacing: 0) {
            // 顶部：学印 + 标题 + 等级章
            HStack(spacing: 12) {
                // 朱砂「学」印
                Text("学")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(Color(red: 246/255, green: 241/255, blue: 231/255))
                    .frame(width: 36, height: 36)
                    .background(Color(red: 176/255, green: 58/255, blue: 46/255), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .rotationEffect(.degrees(-5))
                    .shadow(color: Color(red: 120/255, green: 40/255, blue: 30/255).opacity(0.3), radius: 4, y: 3)

                Text("益智书院")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .tracking(3)
                    .foregroundStyle(Color(red: 59/255, green: 50/255, blue: 38/255))

                Spacer()

                // 等级章
                Text("童生 · 三年级")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color(red: 217/255, green: 164/255, blue: 91/255))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(Color(red: 217/255, green: 164/255, blue: 91/255), lineWidth: 1.5)
                    )
            }
            .padding(.top, 56) // 适配状态栏
            .padding(.bottom, 18)

            // 段位腰带
            shuyuanBelt
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.bottom, 25)
        .background {
            ZStack(alignment: .top) {
                Color(red: 246/255, green: 241/255, blue: 231/255)
                    .frame(height: 1000)
                    .offset(y: -1000)
                LinearGradient(
                    colors: [
                        Color(red: 246/255, green: 241/255, blue: 231/255),
                        Color(red: 243/255, green: 237/255, blue: 224/255),
                        AppTheme.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    // 段位腰带：金色段位徽章 + 课业进度 + 功成名就 stats
    private var shuyuanBelt: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // 金色段位徽章
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
                    Text("童")
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundStyle(Color(red: 59/255, green: 50/255, blue: 38/255))
                }
                .modifier(GoldPulse())

                // 课业进度
                VStack(alignment: .leading, spacing: 4) {
                    Text("童生 · 课业 \(Int(beltProgress * 100))%")
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .tracking(1)
                        .foregroundStyle(Color(red: 240/255, green: 228/255, blue: 200/255))
                    Text("再修 3 门课，可晋「秀才」")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 240/255, green: 228/255, blue: 200/255).opacity(0.55))
                    // 经验条（动画增长）
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(red: 240/255, green: 228/255, blue: 200/255).opacity(0.15))
                                .frame(height: 8)
                            Capsule()
                                .fill(
                                    LinearGradient(colors: [
                                        Color(red: 217/255, green: 164/255, blue: 91/255),
                                        Color(red: 240/255, green: 216/255, blue: 160/255)
                                    ], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: geo.size.width * beltProgress, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 三统计
                HStack(spacing: 12) {
                    beltStat(value: "\(progress.totalMatchstickSolves)", label: "功课")
                    beltStat(value: "\(beltMedalCount)", label: "勋章")
                    beltStat(value: "\(progress.streakDays)", label: "连续")
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        Color(red: 59/255, green: 50/255, blue: 38/255),
                        Color(red: 42/255, green: 36/255, blue: 28/255)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: Color(red: 40/255, green: 30/255, blue: 15/255).opacity(0.35), radius: 12, y: 6)
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

    private struct GoldPulse: ViewModifier {
        @State private var glowing = false
        func body(content: Content) -> some View {
            content
                .shadow(
                    color: Color(red: 245/255, green: 214/255, blue: 123/255).opacity(glowing ? 0.55 : 0.25),
                    radius: glowing ? 14 : 8
                )
                .scaleEffect(glowing ? 1.04 : 1)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: glowing)
                .onAppear { glowing = true }
        }
    }

    private func beltStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 240/255, green: 228/255, blue: 200/255))
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .tracking(1)
                .foregroundStyle(Color(red: 240/255, green: 228/255, blue: 200/255).opacity(0.5))
        }
    }

    // MARK: - 主体（宣纸底）

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
        .background {
            // 背景处理：解决上拉露白
            ZStack(alignment: .bottom) {
                AppTheme.background
                
                // 向下无限延伸的暖白块（确保上拉时颜色统一）
                AppTheme.background
                    .frame(height: 1000)
                    .offset(y: 1000)
            }
        }
    }

    // 段标题·带「名 · 副标题」
    private func sectionHeader(title: String, sub: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .serif))
                .tracking(0.8)
                .foregroundStyle(AppTheme.textPrimary)
            Text(sub)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
            Rectangle()
                .fill(AppTheme.separator)
                .frame(height: 0.5)
            Spacer(minLength: 0)
        }
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
            Text("📜")
                .font(.system(size: 30))

            VStack(alignment: .leading, spacing: 4) {
                Text("每日一题")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(Color(red: 59/255, green: 50/255, blue: 38/255))
                Text("移动一根火柴，让等式成立")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 122/255, blue: 96/255))
                HStack(spacing: 14) {
                    todayStat(value: "\(MatchstickProblemSet.count)", label: "题")
                    todayStat(value: "\(progress.totalMatchstickSolves)", label: "已破")
                    todayStat(value: "\(progress.streakDays)", label: "连胜")
                }
                .padding(.top, 6)
            }

            Spacer()

            Text("修习 →")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 176/255, green: 58/255, blue: 46/255))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        Color(red: 251/255, green: 246/255, blue: 234/255),
                        Color(red: 239/255, green: 228/255, blue: 204/255)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: Color(red: 60/255, green: 45/255, blue: 25/255).opacity(0.18), radius: 10, y: 5)
        )
        .overlay(alignment: .leading) {
            // 朱砂竖排线
            Rectangle()
                .fill(
                    LinearGradient(colors: [
                        Color(red: 176/255, green: 58/255, blue: 46/255).opacity(0.5),
                        Color(red: 176/255, green: 58/255, blue: 46/255).opacity(0.15)
                    ], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 2)
                .padding(.vertical, 4)
                .padding(.leading, 6)
        }
    }

    private func todayStat(value: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 176/255, green: 58/255, blue: 46/255))
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 154/255, green: 140/255, blue: 116/255))
        }
    }

    // 分组标题（朱砂小印 + 名称 + 渐变线）
    private func subjectHeader(seal: String, title: String) -> some View {
        HStack(spacing: 10) {
            Text(seal)
                .font(.system(size: 11, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 240/255, green: 228/255, blue: 200/255))
                .frame(width: 22, height: 22)
                .background(Color(red: 59/255, green: 50/255, blue: 38/255), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .rotationEffect(.degrees(-4))
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .serif))
                .tracking(3)
                .foregroundStyle(Color(red: 59/255, green: 50/255, blue: 38/255))
            Rectangle()
                .fill(
                    LinearGradient(colors: [Color(red: 120/255, green: 100/255, blue: 70/255).opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing)
                )
                .frame(height: 1)
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
            Subject(seal: "数", icon: "🧮", name: "数理课", lessons: [
                Lesson(kind: .matchstick,     name: "火柴推理", sub: "移一根火柴，让等式成立", icon: "🧡"),
                Lesson(kind: .sudoku,         name: "星云数独", sub: "4×4 · 6×6 · 9×9 宫格", icon: "🪐"),
                Lesson(kind: .maze,           name: "迷宫乐园", sub: "走出迷宫，找到草莓熊", icon: "🧩"),
            ]),
            Subject(seal: "文", icon: "🖌", name: "文学课", lessons: [
                Lesson(kind: .poetryComplete, name: "诗词补全", sub: "古诗少一句 · 四选一", icon: "🍊"),
                Lesson(kind: .idiomFillBlank, name: "成语填空", sub: "缺个字，你来填", icon: "📝"),
                Lesson(kind: .antonymMatch,   name: "反义对对碰", sub: "找相反的好朋友", icon: "⚖️"),
                Lesson(kind: .sanzijing,      name: "三字经", sub: "人之初，性本善", icon: "📖"),
                Lesson(kind: .idiomFillLevel, name: "成语填字", sub: "500 关 · 看提示选对字", icon: "🀄"),
            ]),
            Subject(seal: "智", icon: "🎲", name: "游戏课", lessons: [
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
                Text(subject.icon).font(.system(size: 18))
                Text(subject.name)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .tracking(2)
                    .foregroundStyle(Color(red: 59/255, green: 50/255, blue: 38/255))
                Spacer()
                Text("\(doneCount) / \(subject.lessons.count) 门")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 154/255, green: 140/255, blue: 116/255))
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
                        .fill(Color(red: 120/255, green: 100/255, blue: 70/255).opacity(0.12))
                        .frame(height: 1)
                        .padding(.horizontal, 14)
                }
            }
            .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(red: 255/255, green: 252/255, blue: 244/255).opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color(red: 120/255, green: 100/255, blue: 70/255).opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func lessonRow(_ lesson: Lesson, index: Int) -> some View {
        let state = lessonState(lesson.kind)
        return HStack(spacing: 12) {
            // 中文序号
            Text(chineseNum(index))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 122/255, blue: 96/255))
                .frame(width: 26, height: 26)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color(red: 120/255, green: 100/255, blue: 70/255).opacity(0.3), lineWidth: 1.5)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(lesson.icon).font(.system(size: 14))
                    Text(lesson.name)
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundStyle(Color(red: 59/255, green: 50/255, blue: 38/255))
                }
                Text(lesson.sub)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 154/255, green: 140/255, blue: 116/255))
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
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(state.done ? Color(red: 74/255, green: 124/255, blue: 89/255)
                    : state.now ? Color(red: 176/255, green: 58/255, blue: 46/255)
                    : Color(red: 192/255, green: 180/255, blue: 154/255))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
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
                    .foregroundStyle(Color(red: 138/255, green: 122/255, blue: 96/255))
                Text(name)
                    .font(.system(size: 12.5, weight: .bold, design: .serif))
                    .tracking(0.3)
                    .foregroundStyle(Color(red: 59/255, green: 50/255, blue: 38/255))
                    .lineLimit(1)
                Text(sub)
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 154/255, green: 140/255, blue: 116/255))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(red: 255/255, green: 252/255, blue: 244/255).opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color(red: 120/255, green: 100/255, blue: 70/255).opacity(0.2), lineWidth: 1)
                    )
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
                .foregroundStyle(Color(red: 74/255, green: 124/255, blue: 89/255))
            Text("修学者，所以明理、益智、进德。每破一题则就一题之道，每成一课则进一阶之修。日拱一卒，功不唐捐。")
                .font(.system(size: 12, weight: .regular, design: .serif))
                .foregroundStyle(Color(red: 110/255, green: 98/255, blue: 80/255))
                .lineSpacing(4)
            Text("益智书院 · 谨题")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 176/255, green: 58/255, blue: 46/255))
                .rotationEffect(.degrees(-2))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 74/255, green: 124/255, blue: 89/255).opacity(0.06))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color(red: 74/255, green: 124/255, blue: 89/255))
                        .frame(width: 2)
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
