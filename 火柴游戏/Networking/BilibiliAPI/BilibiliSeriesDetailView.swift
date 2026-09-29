import SwiftUI

// MARK: - 专题详情（图二样式：大封面 + 选集列表）

struct BilibiliSeriesDetailView: View {
    let category: BilibiliCategory
    let topic: BilibiliTopic

    @State private var info: BilibiliVideoInfo?
    @State private var isLoading = false
    @State private var loaded = false

    private var title: String {
        topic.customTitle ?? BilibiliAPIService.cleanSeriesTitle(info?.title ?? "")
    }

    private var subtitle: String {
        topic.customSubtitle ?? "\(info?.partCount ?? 0) 集精选动画"
    }

    var body: some View {
        ZStack {
            FieldBackground()
            detailSun
            detailCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            detailCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text(title)
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                        .lineLimit(1)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                if let info {
                    content(info)
                } else if isLoading {
                    Spacer()
                    ProgressView("正在加载选集...")
                        .tint(Color(red: 251/255, green: 114/255, blue: 153/255))
                        .foregroundStyle(AppTheme.fieldMoss)
                    Spacer()
                } else {
                    VStack(spacing: 14) {
                        Text(topic.bvid)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.fieldMoss)
                        Text("加载失败，请检查网络")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundStyle(AppTheme.fieldMoss)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .task {
            await loadInfo()
        }
    }

    // MARK: - 数据加载

    private func loadInfo() async {
        guard !loaded else { return }
        loaded = true
        isLoading = true
        info = await BilibiliAPIService.shared.fetchVideoInfo(bvid: topic.bvid)
        isLoading = false
    }

    // MARK: - 主体内容

    private func content(_ info: BilibiliVideoInfo) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // 大封面 + 播放按钮
                ZStack {
                    BilibiliRemoteCover(urlString: info.coverUrl, iconSize: 34)

                    // 中央播放按钮
                    Button {
                        playFirstPart(info)
                    } label: {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                            .frame(width: 62, height: 62)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                                    .offset(x: 2)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                    }
                    .buttonStyle(GalleryCardBounceStyle())
                }
                .frame(maxWidth: .infinity)
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.18), radius: 10, y: 5)
                .padding(.horizontal, 18)
                .padding(.top, 8)

                // 标题区
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)

                // 选集标题
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color(red: 251/255, green: 114/255, blue: 153/255))
                        .frame(width: 6, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    Text("选集")
                        .font(.system(size: 15, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                    Spacer()
                    Text("\(info.parts.count) 集")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 8)

                // 选集列表
                LazyVStack(spacing: 8) {
                    ForEach(info.parts) { part in
                        episodeRow(part)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
        }
    }

    private func episodeRow(_ part: BilibiliPart) -> some View {
        Button {
            playPart(part)
        } label: {
            HStack(spacing: 12) {
                // 集数徽章
                Text(String(format: "%02d", part.page))
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color(red: 74/255, green: 92/255, blue: 66/255))
                    .frame(width: 38, height: 30)
                    .background(Color(red: 240/255, green: 240/255, blue: 240/255), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(part.title)
                    .font(.system(size: 13, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .lineLimit(1)

                Spacer()

                Text(BilibiliAPIService.formatDuration(part.duration))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.fieldMoss)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.fieldMossLight)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppTheme.fieldOlive.opacity(0.22), lineWidth: 1.5)
                    )
                    .shadow(color: AppTheme.fieldGrassShadow.opacity(0.07), radius: 4, y: 2)
            )
        }
        .buttonStyle(GalleryCardBounceStyle())
    }

    private func playFirstPart(_ info: BilibiliVideoInfo) {
        guard let first = info.parts.first else { return }
        playPart(first)
    }

    private func playPart(_ part: BilibiliPart) {
        BilibiliPlayerWindow.shared.present(
            title: "\(title) · 第 \(part.page) 集",
            urlString: topic.episodeLink(page: part.page),
            fallbackURLString: "\(topic.link)?p=\(part.page)",
            onDismiss: {}
        )
    }

    // MARK: - 背景装饰（太阳/云）

    private var detailSun: some View {
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

    private func detailCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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
