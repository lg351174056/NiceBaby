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

    private var yunvuHero: some View {
        VStack(spacing: 0) {
            // 顶部标题行：kicker + 标题 + 武印
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YǍN · WǓ · 演武修真")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(3.4)
                        .foregroundStyle(Color(red: 243/255, green: 232/255, blue: 210/255).opacity(0.6))
                    Text("演武场")
                        .font(.system(size: 28, weight: .heavy, design: .serif))
                        .tracking(1)
                        .foregroundStyle(Color(red: 243/255, green: 232/255, blue: 210/255))
                }
                Spacer()
                wuSeal
            }
            .padding(.top, 56) // 适配状态栏
            .padding(.bottom, 20) // 缩短与腰带的间距

            // 段位腰带
            danBelt
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.bottom, 25)
        .background {
            // 背景处理：解决下拉露白 + 保持渐变颜色准确
            ZStack(alignment: .top) {
                // 1. 向上无限延伸的深色块（解决下拉露深紫色）
                Color(red: 31/255, green: 26/255, blue: 40/255)
                    .frame(height: 1000)
                    .offset(y: -1000)

                // 2. 标准渐变底（高度与内容一致，颜色从当前顶端开始）
                LinearGradient(
                    colors: [
                        Color(red: 31/255, green: 26/255, blue: 40/255),
                        Color(red: 45/255, green: 36/255, blue: 65/255),
                        AppTheme.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    // 武印：朱砂圆印 + 毛笔字「武」(倾斜 -4°)
    private var wuSeal: some View {
        ZStack {
            Circle()
                .fill(AppTheme.accentCinnabar)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 2)
                )
                .shadow(color: AppTheme.accentCinnabar.opacity(0.5), radius: 5, x: 0, y: 4)
            Text("武")
                .font(.system(size: 17, weight: .black, design: .serif))
                .foregroundStyle(Color(red: 255/255, green: 248/255, blue: 238/255))
        }
        .rotationEffect(.degrees(-4))
    }

    // 段位腰带：6 段位记号 + 段位文案 + 功成名就 stats
    private var danBelt: some View {
        VStack(spacing: 14) {
            // 记号 + 段位 + 距下一阶
            HStack(spacing: 8) {
                // 4 on / 6 总计
                HStack(spacing: 4) {
                    ForEach(0..<6, id: \.self) { i in
                        Capsule()
                            .fill(i < 4 ? AppTheme.accentCinnabar : Color(red: 243/255, green: 232/255, blue: 210/255).opacity(0.16))
                            .frame(width: 14, height: 6)
                            .shadow(color: i < 4 ? AppTheme.accentCinnabar.opacity(0.6) : .clear, radius: 3)
                    }
                }
                Text("勤学 · 三品")
                    .font(.system(size: 14, weight: .heavy, design: .serif))
                    .tracking(1)
                    .foregroundStyle(Color(red: 243/255, green: 232/255, blue: 210/255))
                Spacer()
                Text("距 精通 · 一阶")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(Color(red: 243/255, green: 232/255, blue: 210/255).opacity(0.5))
            }

            // 顶部细光带
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [.clear, AppTheme.accentCinnabar, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
                .offset(y: -16)
            }

            // 功成名就三格
            HStack(spacing: 8) {
                beltStat(value: "\(progress.totalMatchstickSolves)", label: "火柴通破")
                beltStat(value: "\(progress.streakDays)", label: "连胜日")
                beltStat(value: "\(progress.totalMatchstickSolves + progress.openedPoemIds.count)", label: "今练")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 10/255, green: 8/255, blue: 16/255).opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(red: 243/255, green: 232/255, blue: 210/255).opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func beltStat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 243/255, green: 232/255, blue: 210/255))
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .tracking(1)
                .foregroundStyle(Color(red: 243/255, green: 232/255, blue: 210/255).opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(red: 243/255, green: 232/255, blue: 210/255).opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color(red: 243/255, green: 232/255, blue: 210/255).opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - 主体（宣纸底）

    private var scrollBody: some View {
        VStack(spacing: 22) {
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

    // MARK: - 擂台主推（朱砂渐变 + 巨字「擂」水印）

    private var arenaSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "擂台 · 主推", sub: "FEATURED")
            Button { pushGame(.matchstick) } label: {
                arenaCard
            }
            .buttonStyle(.bouncy)

            // 迷宫乐园 · 儿童走迷宫（火柴推理下方）
            Button { pushGame(.maze) } label: {
                mazeCard
            }
            .buttonStyle(.bouncy)

            // 星云数独 · 4/6/9（迷宫下方）
            Button { pushGame(.sudoku) } label: {
                sudokuCard
            }
            .buttonStyle(.bouncy)
        }
    }

    private var sudokuCard: some View {
        ZStack(alignment: .topTrailing) {
            // 深蓝紫星云底
            LinearGradient(
                colors: [
                    Color(red: 20/255, green: 18/255, blue: 48/255),
                    Color(red: 36/255, green: 31/255, blue: 78/255),
                    Color(red: 48/255, green: 40/255, blue: 96/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
            )
            .shadow(color: Color(red: 110/255, green: 95/255, blue: 168/255).opacity(0.4), radius: 10, x: 0, y: 6)

            // 星点
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 2, height: 2)
                    .offset(
                        x: CGFloat([-40, 30, 70, -55, 10, 55][i]),
                        y: CGFloat([-30, 10, -42, 25, 42, 5][i])
                    )
            }

            // 金色行星水印
            Circle()
                .fill(RadialGradient(colors: [
                    Color(red: 255/255, green: 233/255, blue: 168/255),
                    Color(red: 245/255, green: 214/255, blue: 123/255).opacity(0.5),
                    Color.clear
                ], center: .init(x: 0.35, y: 0.3), startRadius: 4, endRadius: 60))
                .frame(width: 110, height: 110)
                .offset(x: 40, y: -28)

            // 文案
            VStack(alignment: .leading, spacing: 0) {
                Text("星云数独")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color(red: 237/255, green: 232/255, blue: 255/255))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.16))
                    )

                Text("在星海深处\n破解数字的奥秘")
                    .font(.system(size: 21, weight: .heavy, design: .serif))
                    .tracking(0.8)
                    .foregroundStyle(Color(red: 237/255, green: 232/255, blue: 255/255))
                    .padding(.top, 8)
                    .lineSpacing(2)

                Text("4×4 · 6×6 · 9×9 · 每局随机生成")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 125/255, green: 249/255, blue: 255/255).opacity(0.85))
                    .padding(.top, 4)

                HStack(spacing: 14) {
                    sudokuStat(value: "3", label: "难度")
                    sudokuStat(value: "\(sudokuTotalCleared)", label: "已解")
                    sudokuStat(value: sudokuBest, label: "最快")
                }
                .padding(.top, 12)

                HStack(spacing: 6) {
                    Text("入 局")
                        .font(.system(size: 13, weight: .heavy, design: .serif))
                        .tracking(1)
                        .foregroundStyle(Color(red: 20/255, green: 18/255, blue: 48/255))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Color(red: 20/255, green: 18/255, blue: 48/255))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [
                            Color(red: 245/255, green: 214/255, blue: 123/255),
                            Color(red: 212/255, green: 168/255, blue: 75/255)
                        ], startPoint: .leading, endPoint: .trailing))
                )
                .padding(.top, 16)
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minHeight: 230)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var sudokuTotalCleared: Int {
        (4...9).filter { $0 == 4 || $0 == 6 || $0 == 9 }
            .map { SudokuProgressStore.clearCount(size: $0) }
            .reduce(0, +)
    }

    private var sudokuBest: String {
        let best = [4, 6, 9]
            .map { SudokuProgressStore.bestTime(size: $0) }
            .filter { $0 > 0 }
            .min() ?? 0
        guard best > 0 else { return "--" }
        return "\(best / 60):\(String(format: "%02d", best % 60))"
    }

    private func sudokuStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 237/255, green: 232/255, blue: 255/255))
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 237/255, green: 232/255, blue: 255/255).opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    private var mazeCard: some View {
        ZStack(alignment: .topTrailing) {
            // 粉彩游乐场底
            LinearGradient(
                colors: [
                    Color(red: 255/255, green: 186/255, blue: 208/255),
                    Color(red: 245/255, green: 140/255, blue: 178/255),
                    Color(red: 232/255, green: 106/255, blue: 158/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
            )
            .shadow(color: Color(red: 232/255, green: 106/255, blue: 158/255).opacity(0.35), radius: 10, x: 0, y: 6)

            // 大圆点水印
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 150, height: 150)
                .offset(x: 42, y: -30)

            // 文案
            VStack(alignment: .leading, spacing: 0) {
                Text("迷宫乐园")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color(red: 255/255, green: 248/255, blue: 238/255))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )

                Text("走出迷宫\n找到草莓熊")
                    .font(.system(size: 21, weight: .heavy, design: .serif))
                    .tracking(0.8)
                    .foregroundStyle(Color(red: 255/255, green: 248/255, blue: 238/255))
                    .padding(.top, 8)
                    .lineSpacing(2)

                Text("20 关 · 每关迷宫随机生成，越走越难")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 255/255, green: 248/255, blue: 238/255).opacity(0.85))
                    .padding(.top, 4)

                HStack(spacing: 14) {
                    mazeStat(value: "20", label: "关卡")
                    mazeStat(value: "\(mazeClearedCount)", label: "已通关")
                    mazeStat(value: "\(mazeBestStar)", label: "最高星")
                }
                .padding(.top, 12)

                HStack(spacing: 6) {
                    Text("入 迷")
                        .font(.system(size: 13, weight: .heavy, design: .serif))
                        .tracking(1)
                        .foregroundStyle(Color(red: 232/255, green: 106/255, blue: 158/255))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Color(red: 232/255, green: 106/255, blue: 158/255))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(red: 255/255, green: 248/255, blue: 238/255).opacity(0.95))
                )
                .padding(.top, 14)
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minHeight: 230)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var mazeClearedCount: Int {
        (0..<20).filter { MazeProgressStore.stars(level: $0) > 0 }.count
    }

    private var mazeBestStar: Int {
        (0..<20).map { MazeProgressStore.stars(level: $0) }.max() ?? 0
    }

    private func mazeStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 255/255, green: 248/255, blue: 238/255))
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 255/255, green: 248/255, blue: 238/255).opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    private var arenaCard: some View {
        ZStack(alignment: .topTrailing) {
            // 渐变朱砂底
            LinearGradient(
                colors: [
                    Color(red: 107/255, green: 42/255, blue: 34/255),
                    Color(red: 168/255, green: 54/255, blue: 47/255),
                    AppTheme.accentCinnabar
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: AppTheme.accentCinnabar.opacity(0.3), radius: 10, x: 0, y: 6)

            // 巨字「擂」水印：右上角溢出被剪 - 关键还原点
            Text("擂")
                .font(.system(size: 140, weight: .black, design: .serif))
                .foregroundStyle(Color(red: 255/255, green: 248/255, blue: 238/255).opacity(0.08))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: -8, y: -22)
                .allowsHitTesting(false)

            // 文案
            VStack(alignment: .leading, spacing: 0) {
                Text("擂")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color(red: 255/255, green: 248/255, blue: 238/255))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                    )

                Text("火柴推理")
                    .font(.system(size: 22, weight: .heavy, design: .serif))
                    .tracking(0.8)
                    .foregroundStyle(Color(red: 255/255, green: 248/255, blue: 238/255))
                    .padding(.top, 10)

                Text("移一根火柴，让等式成立")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 243/255, green: 232/255, blue: 210/255).opacity(0.75))
                    .padding(.top, 4)

                HStack(spacing: 14) {
                    arenaStat(value: "\(MatchstickProblemSet.count)", label: "题")
                    arenaStat(value: "\(progress.totalMatchstickSolves)", label: "已破")
                    arenaStat(value: "\(progress.streakDays)", label: "连胜")
                }
                .padding(.top, 14)

                HStack(spacing: 6) {
                    Text("入 擂")
                        .font(.system(size: 13, weight: .heavy, design: .serif))
                        .tracking(1)
                        .foregroundStyle(AppTheme.accentCinnabar)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(AppTheme.accentCinnabar)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(red: 255/255, green: 248/255, blue: 238/255).opacity(0.95))
                )
                .padding(.top, 16)
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minHeight: 230)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - 万象 · 知识百科（入口卡片）

    private var encyclopediaSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "万象 · 知识百科", sub: "ATLAS")
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

    private func arenaStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 255/255, green: 248/255, blue: 238/255))
            Text(label)
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color(red: 243/255, green: 232/255, blue: 210/255).opacity(0.55))
        }
    }

    // MARK: - 招式 · 列阵（6 招式卡 2 列网格）

    private struct Move {
        let kind: GameKind?
        let badge: String   // 能 / 习 / 习 / 未
        let badgeColor: Color
        let no: String      // 壹式 / 贰式 ...
        let name: String
        let sub: String
        let pct: Double
        let progress: Double
        let statusHint: String
    }

    private var moves: [Move] {
        let ink = AppTheme.accentInkPurple
        let bamboo = AppTheme.accentBamboo
        let cinnabar = AppTheme.accentCinnabar
        return [
            Move(kind: .poetryComplete, badge: "能", badgeColor: ink,     no: "壹式", name: "诗词补全",   sub: "古诗少一句 · 四选一",       pct: 43, progress: 0.42, statusHint: "有所习"),
            Move(kind: .surnameMatch,   badge: "习", badgeColor: bamboo,   no: "贰式", name: "百家姓闯关", sub: "看 / 听 / 选 三招式",       pct: 38, progress: 0.38, statusHint: "勤习"),
            Move(kind: .antonymMatch,   badge: "能", badgeColor: cinnabar,  no: "叁式", name: "反义对对碰", sub: "翻乐 · 跷板 · 闯图",        pct: 56, progress: 0.56, statusHint: "精进"),
            Move(kind: .idiomFillBlank, badge: "能", badgeColor: cinnabar,  no: "肆式", name: "成语填空",   sub: "缺一选一 · 集经史",         pct: 31, progress: 0.31, statusHint: "初习"),
            Move(kind: .sanzijing,      badge: "能", badgeColor: bamboo,   no: "伍式", name: "三字经",     sub: "人之初 · 性本善",          pct: 88, progress: 0.88, statusHint: "近通"),
            Move(kind: .idiomFillLevel, badge: "新", badgeColor: cinnabar,  no: "陆式", name: "成语填空(贰)", sub: "500关 · 看提示选对字",      pct: 0,  progress: 0,    statusHint: "新开"),
            Move(kind: .brainTeaser,    badge: "新", badgeColor: ink,       no: "柒式", name: "脑筋急转弯", sub: "150题 · 绕弯急转有惊喜",       pct: 0,  progress: 0,    statusHint: "新开"),
            Move(kind: .funQuiz,        badge: "新", badgeColor: bamboo,    no: "捌式", name: "趣味答题",   sub: "多主题 · 图片题与冷知识漫游", pct: 0,  progress: 0,    statusHint: "新开")
        ]
    }

    private var movesSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "招式 · 列阵", sub: "FIVE MOVES")
            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(moves.enumerated()), id: \.offset) { _, move in
                    moveCard(move)
                }
            }
        }
    }

    private func moveCard(_ move: Move) -> some View {
        let locked = move.kind == nil
        return Button {
            if let kind = move.kind { pushGame(kind) }
        } label: {
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(move.no)
                        .font(.system(size: 11, weight: .medium, design: .serif))
                        .tracking(0.6)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(move.name)
                        .font(.system(size: 15, weight: .heavy, design: .serif))
                        .tracking(0.4)
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.top, 4)
                        .lineLimit(1)
                    Text(move.sub)
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.top, 2)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, minHeight: 32, alignment: .topLeading)

                    GeometryReader { _ in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppTheme.separator)
                                .frame(height: 3)
                            Capsule()
                                .fill(move.badgeColor)
                                .frame(width: max(0, CGFloat(move.progress)) * 80, height: 3)
                        }
                    }
                    .frame(height: 3)
                    .padding(.top, 8)

                    HStack {
                        Text("\(move.pct) %")
                            .font(.system(size: 10, weight: .medium, design: .serif))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text(move.statusHint)
                            .font(.system(size: 9.5, weight: .medium, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 右上角印章徽记
                Text(move.badge)
                    .font(.system(size: 10, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 255/255, green: 248/255, blue: 238/255))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(move.badgeColor)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppTheme.separator, lineWidth: 1)
                    )
            )
            .opacity(locked ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(locked)
    }

    // MARK: - 器械 · 文房三器

    private var toolsSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "器械 · 文房三器", sub: "TOOLS")
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
                    .foregroundStyle(AppTheme.textSecondary)
                Text(name)
                    .font(.system(size: 12.5, weight: .heavy, design: .serif))
                    .tracking(0.3)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(sub)
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(AppTheme.separator, lineWidth: 1)
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
                .foregroundStyle(AppTheme.accentInkPurple)
            Text("演武者，所以明理、益智、修心。每破一题则就一题之道，每通一式则进一阶之修。即所见，亦所学也。")
                .font(.system(size: 12, weight: .regular, design: .serif))
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(4)
            Text("演武修真 · 益智谨题")
                .font(.system(size: 13, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.accentCinnabar)
                .rotationEffect(.degrees(-2))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.accentInkPurple.opacity(0.06))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(AppTheme.accentInkPurple)
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
