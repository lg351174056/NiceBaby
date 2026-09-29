import SwiftUI

// MARK: - 专题列表（图一样式：封面卡片网格 + 观看按钮）

struct BilibiliTopicListView: View {
    let category: BilibiliCategory

    @State private var infos: [String: BilibiliVideoInfo] = [:]
    @State private var loaded = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ZStack {
            FieldBackground()
            topicSun
            topicCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            topicCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条（返回 + 分类名，中间「专题列表」）
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text("专题列表")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                if category.topics.isEmpty {
                    emptyState
                } else {
                    topicGrid
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .task {
            await loadInfos()
        }
    }

    // MARK: - 数据加载

    private func loadInfos() async {
        guard !loaded else { return }
        loaded = true
        let topics = category.topics
        await withTaskGroup(of: (String, BilibiliVideoInfo?).self) { group in
            for topic in topics {
                group.addTask {
                    let info = await BilibiliAPIService.shared.fetchVideoInfo(bvid: topic.bvid)
                    return (topic.bvid, info)
                }
            }
            for await (bvid, info) in group {
                if let info { infos[bvid] = info }
            }
        }
    }

    // MARK: - 专题网格

    private var topicGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // 分类头
                HStack(spacing: 8) {
                    Text(category.icon)
                        .font(.system(size: 18))
                    Text(category.name)
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                    Rectangle()
                        .fill(
                            LinearGradient(colors: [
                                Color(red: 251/255, green: 114/255, blue: 153/255).opacity(0.35),
                                .clear
                            ], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(height: 2)
                    Text("\(category.topics.count) 个专题")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 12)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(category.topics) { topic in
                        NavigationLink(destination: BilibiliSeriesDetailView(category: category, topic: topic)) {
                            topicCard(topic)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 30)
            }
        }
    }

    private func topicCard(_ topic: BilibiliTopic) -> some View {
        let info = infos[topic.bvid]
        let title = topic.customTitle ?? BilibiliAPIService.cleanSeriesTitle(info?.title ?? "")
        let subtitle = topic.customSubtitle ?? "\(info?.partCount ?? 0) 集精选动画"
        let cover = info?.coverUrl ?? ""

        return VStack(alignment: .leading, spacing: 8) {
            // 封面（固定高度，加载过程不改变尺寸）
            ZStack {
                BilibiliRemoteCover(urlString: cover, iconSize: 30)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 128)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            // 标题 + 副标题
            Text(title)
                .font(.system(size: 14, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                Text(subtitle)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text("观看")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(red: 245/255, green: 166/255, blue: 60/255))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.22), lineWidth: 1.5)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.1), radius: 6, y: 3)
        )
    }

    // MARK: - 空态

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text(category.icon)
                .font(.system(size: 44))
            Text("专题整理中 · 敬请期待")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.fieldMoss)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 背景装饰（太阳/云）

    private var topicSun: some View {
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

    private func topicCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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
}
