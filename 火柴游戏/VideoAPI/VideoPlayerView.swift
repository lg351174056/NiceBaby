import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: URL
    let title: String
    let coverUrl: String
    let onDismiss: () -> Void

    @State private var player: AVPlayer?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }

            HStack {
                Button {
                    player?.pause()
                    onDismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(.top, 54)
            .padding(.horizontal, 16)
        }
        .statusBarHidden()
        .onAppear {
            let headers: [String: String] = [
                "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15",
                "Referer": "https://servicewechat.com/wxcbf549e856866db7/23/page-frame.html"
            ]
            let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
            let item = AVPlayerItem(asset: asset)
            let avPlayer = AVPlayer(playerItem: item)
            self.player = avPlayer
            avPlayer.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}
