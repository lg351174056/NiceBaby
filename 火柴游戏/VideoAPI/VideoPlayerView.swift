import AVKit
import SwiftUI

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

            Button {
                player?.pause()
                onDismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4)
                .padding(16)
            }
        }
        .onAppear {
            let normalizedUrl = normalizeVideoUrl(url)
            let avPlayer = AVPlayer(url: normalizedUrl)
            self.player = avPlayer
            avPlayer.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func normalizeVideoUrl(_ original: URL) -> URL {
        guard let decoded = original.absoluteString.removingPercentEncoding else { return original }
        guard let reEncoded = decoded.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return original }
        return URL(string: reEncoded) ?? original
    }
}
