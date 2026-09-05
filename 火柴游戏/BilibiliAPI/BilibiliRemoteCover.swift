import SwiftUI
import UIKit

// MARK: - B站封面加载（固定尺寸，无 AsyncImage 阶段宽度跳动）

struct BilibiliRemoteCover: View {
    let urlString: String
    var iconSize: CGFloat = 26

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 255/255, green: 228/255, blue: 238/255),
                    Color(red: 251/255, green: 180/255, blue: 205/255)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: iconSize))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .clipped()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: urlString) {
            guard image == nil, !urlString.isEmpty, let url = URL(string: urlString) else { return }
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let loaded = UIImage(data: data) {
                image = loaded
            }
        }
    }
}