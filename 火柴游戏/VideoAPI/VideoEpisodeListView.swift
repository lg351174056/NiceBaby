import SwiftUI

struct VideoEpisodeListView: View {
    let series: VideoSeries
    @State private var episodes: [VideoEpisode] = []
    @State private var isLoading = false
    @State private var playingItem: PlayingItem?

    var body: some View {
        if #available(iOS 16.0, *) {
            Group {
                if isLoading {
                    ProgressView("正在加载集数...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if episodes.isEmpty {
                    Text("暂无集数")
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(episodes) { ep in
                                episodeRow(ep)
                            }
                        }
                        .padding(.horizontal, AppTheme.paddingScreen)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle(series.name)
            .navigationBarTitleDisplayMode(.inline)
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
            // Fallback on earlier versions
        }
    }

    private func episodeRow(_ ep: VideoEpisode) -> some View {
        Button {
            guard ep.isPlayable else { return }
            Task { await playEpisode(ep) }
        } label: {
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    if let coverURL = URL(string: ep.coverUrl), !ep.coverUrl.isEmpty {
                        AsyncImage(url: coverURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(AppTheme.accentBlue.opacity(0.08))
                        }
                        .frame(width: 80, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppTheme.accentBlue.opacity(0.08))
                            .frame(width: 80, height: 52)
                            .overlay(
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundStyle(AppTheme.accentBlue.opacity(0.4))
                            )
                    }
                    if ep.duration > 0 {
                        Text(formatDuration(ep.duration))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.black.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(4)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("第\(ep.episodeNo)集")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.accentBlue)
                    Text(ep.name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(ep.isPlayable ? AppTheme.textPrimary : AppTheme.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                if ep.isPlayable {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.accentBlue)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.gray.opacity(0.5))
                }
            }
            .padding(12)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerSmall, style: .continuous))
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!ep.isPlayable)
    }

    private func playEpisode(_ ep: VideoEpisode) async {
        guard let info = await VideoAPIService.shared.getPlayUrl(episodeId: ep.id, infoId: series.id) else {
            print("[VideoPlayer] 获取播放地址失败: episodeId=\(ep.id), infoId=\(series.id)")
            return
        }
        print("[VideoPlayer] playUrl: \(info.playUrl)")
        guard let url = URL(string: info.playUrl) else {
            print("[VideoPlayer] URL 解析失败: \(info.playUrl)")
            return
        }
        playingItem = PlayingItem(url: url, name: ep.name, coverUrl: ep.coverUrl)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct PlayingItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let coverUrl: String
}
