import SwiftUI

struct VideoEpisodeListView: View {
    let series: VideoSeries
    @State private var episodes: [VideoEpisode] = []
    @State private var isLoading = false
    @State private var playingItem: PlayingItem?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if #available(iOS 16.0, *) {
            ZStack {
                // 蓝天草地背景（书野营地竹青风）
                LinearGradient(
                    colors: [
                        Color(red: 190/255, green: 227/255, blue: 245/255),
                        Color(red: 220/255, green: 242/255, blue: 220/255),
                        Color(red: 207/255, green: 235/255, blue: 196/255)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                listSun
                listCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
                listCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

                // 主体内容
                VStack(alignment: .leading, spacing: 0) {
                    // 透明导航条
                    ZStack {
                        HStack {
                            GracefulBackButton()
                            Spacer()
                        }
                        Text("剧集列表")
                            .font(.system(size: 16, weight: .heavy, design: .serif))
                            .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .padding(.bottom, 6)

                    // 系列头卡
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(colors: [
                                        Color(red: 227/255, green: 242/255, blue: 234/255),
                                        Color(red: 189/255, green: 232/255, blue: 211/255)
                                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                            Text("🎬")
                                .font(.system(size: 24))
                                .modifier(Bob(delay: 0.3))
                        }
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.4), lineWidth: 2)
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(series.name)
                                .font(.system(size: 15, weight: .heavy, design: .serif))
                                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                                .lineLimit(2)
                            Text("\(episodes.count) 集 · 每日更新")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.3), lineWidth: 2)
                            )
                            .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.12), radius: 8, y: 4)
                    )
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                    if isLoading {
                        Spacer()
                        ProgressView("加载中...")
                            .tint(Color(red: 76/255, green: 175/255, blue: 125/255))
                            .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                            .frame(maxWidth: .infinity)
                        Spacer()
                    } else if episodes.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
                            Text("暂无集数")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        // 剧集列表（书野竹青风图卡）
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 10) {
                                ForEach(Array(episodes.enumerated()), id: \.element.id) { index, ep in
                                    episodeCard(ep, index: index)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 12)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden()
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .enableSwipeBack()
            .fullScreenCover(item: $playingItem) { item in
                VideoPlayerView(url: item.url, title: item.name, coverUrl: item.coverUrl) {
                    playingItem = nil
                }
            }
            .task {
                if episodes.isEmpty {
                    isLoading = true
                    episodes = await VideoAPIService.shared.fetchEpisodes(infoId: series.id)
                    isLoading = false
                }
            }
        } else {
            // Fallback
        }
    }

    // MARK: - 背景装饰（太阳/云）

    private var listSun: some View {
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

    private func listCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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

    private struct Bob: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(y: CGFloat(sin(t * 2.2) * 4.0))
            }
        }
    }

    // MARK: - 剧集图卡（书野竹青风）

    private func episodeCard(_ ep: VideoEpisode, index: Int) -> some View {
        Button {
            guard ep.isPlayable else { return }
            Task { await playEpisode(ep) }
        } label: {
            HStack(spacing: 12) {
                // 封面缩略图
                ZStack {
                    if let coverURL = URL(string: ep.coverUrl), !ep.coverUrl.isEmpty {
                        AsyncImage(url: coverURL) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                placeholderThumb(index: index)
                            }
                        }
                    } else {
                        placeholderThumb(index: index)
                    }

                    // 播放/锁定状态
                    if !ep.isPlayable {
                        Color.black.opacity(0.55)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.8))
                    } else {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white)
                                    .offset(x: 2)
                            )
                    }

                    // 时长
                    if ep.duration > 0 {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text(formatDuration(ep.duration))
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color(red: 30/255, green: 50/255, blue: 38/255).opacity(0.75))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(7)
                    }
                }
                .frame(width: 110, height: 74)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // 信息区
                VStack(alignment: .leading, spacing: 5) {
                    Text("第 \(ep.episodeNo) 集")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(ep.isPlayable ? Color(red: 76/255, green: 175/255, blue: 125/255) : Color(red: 168/255, green: 184/255, blue: 154/255))
                    Text(cleanTitle(ep.name))
                        .font(.system(size: 13.5, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 160/255, green: 176/255, blue: 152/255))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.25), lineWidth: 2)
                    )
                    .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 5, y: 3)
            )
        }
        .buttonStyle(GalleryCardBounceStyle())
        .disabled(!ep.isPlayable)
    }

    private func placeholderThumb(index: Int) -> some View {
        let palette: [[Color]] = [
            [Color(red: 189/255, green: 232/255, blue: 211/255), Color(red: 76/255, green: 175/255, blue: 125/255)],
            [Color(red: 245/255, green: 217/255, blue: 168/255), Color(red: 217/255, green: 169/255, blue: 94/255)],
            [Color(red: 203/255, green: 226/255, blue: 240/255), Color(red: 91/255, green: 168/255, blue: 217/255)]
        ]
        return Rectangle()
            .fill(LinearGradient(colors: palette[index % palette.count], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private func playEpisode(_ ep: VideoEpisode) async {
        guard let info = await VideoAPIService.shared.getPlayUrl(episodeId: ep.id, infoId: series.id) else { return }
        guard let url = URL(string: info.playUrl) else { return }
        playingItem = PlayingItem(url: url, name: ep.name, coverUrl: ep.coverUrl)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
    private func cleanTitle(_ rawName: String) -> String {
        let parts = rawName.components(separatedBy: "-")
        if parts.count > 1 {
            let cleaned = parts[1...].joined(separator: "-").trimmingCharacters(in: .whitespaces)
            return cleaned.isEmpty ? rawName : cleaned
        }
        return rawName
    }
}

struct GalleryCardBounceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PlayingItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let coverUrl: String
}
