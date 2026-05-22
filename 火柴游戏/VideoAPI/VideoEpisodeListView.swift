import SwiftUI

struct VideoEpisodeListView: View {
    let series: VideoSeries
    @State private var episodes: [VideoEpisode] = []
    @State private var isLoading = false
    @State private var playingItem: PlayingItem?
    
    var body: some View {
        if #available(iOS 16.0, *) {
            ZStack {
                // 1. 沉浸式全屏背景：使用系列封面做极度模糊，营造影视级氛围
                GeometryReader { geo in
                    if let coverURL = URL(string: series.coverUrl), !series.coverUrl.isEmpty {
                        AsyncImage(url: coverURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .blur(radius: 60, opaque: true)
                                .overlay(Color.black.opacity(0.5))
                        } placeholder: {
                            Color(red: 0.1, green: 0.1, blue: 0.15)
                        }
                    } else {
                        Color(red: 0.1, green: 0.1, blue: 0.15)
                    }
                }
                .ignoresSafeArea()

                // 2. 主体内容
                VStack(alignment: .leading, spacing: 0) {
                    // 顶部标题区 (左侧对齐，更具杂志感)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EPISODES")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.accentBlue)
                            .tracking(2)
                        
                        Text(series.name)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    .padding(.bottom, 30)

                    if isLoading {
                        Spacer()
                        ProgressView("加载中...")
                            .tint(.white)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                        Spacer()
                    } else if episodes.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.3))
                            Text("暂无集数")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        // 3. 横向画廊 (彻底告别列表)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 24) {
                                ForEach(episodes) { ep in
                                    episodeGalleryCard(ep)
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 20)
                        }
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar) 
            .toolbar(.hidden, for: .tabBar)
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

    // MARK: - 画廊卡片视图 (横向画廊模式)
    private func episodeGalleryCard(_ ep: VideoEpisode) -> some View {
        Button {
            guard ep.isPlayable else { return }
            Task { await playEpisode(ep) }
        } label: {
            VStack(spacing: 0) {
                // 上半部分：大画幅封面
                ZStack {
                    if let coverURL = URL(string: ep.coverUrl), !ep.coverUrl.isEmpty {
                        AsyncImage(url: coverURL) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Rectangle()
                                    .fill(Color.white.opacity(0.1))
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                    }
                    
                    // 状态遮罩
                    if !ep.isPlayable {
                        Color.black.opacity(0.6)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.7))
                    } else {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                                    .offset(x: 3)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    }
                    
                    // 右下角时长
                    if ep.duration > 0 {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text(formatDuration(ep.duration))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(12)
                    }
                }
                .frame(width: 280, height: 180)
                .clipped()
                
                // 下半部分：信息区
                VStack(alignment: .leading, spacing: 8) {
                    Text("Episode \(ep.episodeNo)")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(ep.isPlayable ? AppTheme.accentBlue : .gray)
                        .textCase(.uppercase)
                    
                    Text(cleanTitle(ep.name))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer(minLength: 0)
                }
                .padding(20)
                .frame(width: 280, height: 120, alignment: .topLeading)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(GalleryCardBounceStyle())
        .disabled(!ep.isPlayable)
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
