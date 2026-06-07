import SwiftUI
import AVKit
import UIKit

struct WallpaperGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: WallpaperMedia?
    @Namespace private var previewNamespace
    private let outerHorizontalPadding: CGFloat = 10
    private let itemSpacing: CGFloat = 6
    private let itemHeight: CGFloat = 300
    
    private let wallpapers = WallpaperData.items
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.8))
                                .frame(width: 36, height: 36)
                                .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("壁纸图库")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Circle()
                        .fill(.clear)
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(AppTheme.background)
                
                GeometryReader { proxy in
                    let itemWidth = floor((proxy.size.width - (outerHorizontalPadding * 2) - (itemSpacing * 2)) / 3)
                    let columns = [
                        GridItem(.fixed(itemWidth), spacing: itemSpacing),
                        GridItem(.fixed(itemWidth), spacing: itemSpacing),
                        GridItem(.fixed(itemWidth), spacing: itemSpacing)
                    ]
                    
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: itemSpacing) {
                            ForEach(wallpapers) { item in
                                MediaCell(
                                    item: item,
                                    namespace: previewNamespace,
                                    isPreviewing: selectedItem?.id == item.id
                                ) {
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                                        selectedItem = item
                                    }
                                }
                                .frame(width: itemWidth, height: itemHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                        .padding(.horizontal, outerHorizontalPadding)
                        .padding(.top, itemSpacing)
                        .padding(.bottom, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            if let selectedItem {
                WallpaperPreviewOverlay(
                    item: selectedItem,
                    namespace: previewNamespace
                ) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.9)) {
                        self.selectedItem = nil
                    }
                }
                .zIndex(10)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}

// 媒体单元格：区分图片和视频
struct MediaCell: View {
    let item: WallpaperMedia
    let namespace: Namespace.ID
    let isPreviewing: Bool
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(placeholderColor)
            
            if item.type == .video {
                if let url = URL(string: item.url) {
                    RemoteVideoThumbnail(url: url)
                        .allowsHitTesting(false)
                } else {
                    fallbackView
                }
            } else {
                if let url = URL(string: item.url) {
                    RemoteWallpaperImage(url: url, contentMode: .fill)
                        .allowsHitTesting(false)
                } else {
                    fallbackView
                }
            }
        }
        .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
        .clipped()
        .contentShape(Rectangle())
        .matchedGeometryEffect(id: item.id, in: namespace, isSource: !isPreviewing)
        .onTapGesture(perform: onTap)
    }
    
    private var fallbackView: some View {
        Rectangle()
            .fill(.clear)
    }
    
    private var placeholderColor: Color {
        WallpaperPlaceholderPalette.color(for: item.url)
    }
}

struct RemoteWallpaperImage: View {
    let url: URL
    let contentMode: ContentMode
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(url: URL, contentMode: ContentMode) {
        self.url = url
        self.contentMode = contentMode
        _image = State(initialValue: WallpaperImageCache.shared.image(for: url))
    }
    
    var body: some View {
        ZStack {
            WallpaperPlaceholderPalette.color(for: url.absoluteString)
            
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .transition(.opacity.animation(.easeOut(duration: 0.2)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .overlay {
            if isLoading && image == nil {
                Rectangle()
                    .fill(.white.opacity(0.04))
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    @MainActor
    private func loadImage() async {
        guard image == nil, !isLoading else { return }
        if let cached = WallpaperImageCache.shared.image(for: url) {
            image = cached
            return
        }
        isLoading = true
        defer { isLoading = false }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.cachePolicy = .returnCacheDataElseLoad
        request.setValue("image/webp,image/*;q=0.8,*/*;q=0.5", forHTTPHeaderField: "Accept")
        request.setValue("zh-CN,zh-Hans;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                return
            }
            if let image = UIImage(data: data) {
                WallpaperImageCache.shared.insert(image, for: url)
                self.image = image
            }
        } catch {
        }
    }
}

struct RemoteVideoThumbnail: View {
    let url: URL
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(url: URL) {
        self.url = url
        _image = State(initialValue: WallpaperImageCache.shared.image(for: url))
    }
    
    var body: some View {
        ZStack {
            WallpaperPlaceholderPalette.color(for: url.absoluteString)
            
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .transition(.opacity.animation(.easeOut(duration: 0.2)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: url) {
            await loadThumbnail()
        }
    }
    
    @MainActor
    private func loadThumbnail() async {
        guard image == nil, !isLoading else { return }
        if let cached = WallpaperImageCache.shared.image(for: url) {
            image = cached
            return
        }
        isLoading = true
        defer { isLoading = false }
        
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 500, height: 1000)
        
        do {
            let cgImage = try await generator.image(at: CMTime(seconds: 0.1, preferredTimescale: 600)).image
            let thumbnail = UIImage(cgImage: cgImage)
            WallpaperImageCache.shared.insert(thumbnail, for: url)
            image = thumbnail
        } catch {
        }
    }
}

// 简易的静音循环播放器，用于代替动图展示
struct LoopingVideoPlayer: View {
    let url: URL
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
            if let player {
                LoopingPlayerView(player: player)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .onAppear {
            setupPlayer()
            player?.play()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func setupPlayer() {
        guard player == nil else { return }
        let item = AVPlayerItem(url: url)
        let newPlayer = AVQueuePlayer()
        newPlayer.isMuted = true
        newPlayer.actionAtItemEnd = .none
        let newLooper = AVPlayerLooper(player: newPlayer, templateItem: item)
        self.looper = newLooper
        self.player = newPlayer
    }
}

struct LoopingPlayerView: UIViewRepresentable {
    let player: AVQueuePlayer
    
    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

struct WallpaperPreviewOverlay: View {
    let item: WallpaperMedia
    let namespace: Namespace.ID
    let onClose: () -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.96)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
            
            Group {
                if item.type == .video, let url = URL(string: item.url) {
                    LoopingVideoPlayer(url: url)
                } else if let url = URL(string: item.url) {
                    RemoteWallpaperImage(url: url, contentMode: .fit)
                } else {
                    Color.black
                }
            }
            .matchedGeometryEffect(id: item.id, in: namespace)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            
            Button(action: onClose) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.16))
                        .background(.ultraThinMaterial, in: Circle())
                        .frame(width: 42, height: 42)
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.leading, 20)
            .padding(.top, 20)
        }
    }
}

enum WallpaperPlaceholderPalette {
    private static let colors: [Color] = [
        Color(red: 0.95, green: 0.79, blue: 0.67),
        Color(red: 0.73, green: 0.83, blue: 0.98),
        Color(red: 0.72, green: 0.9, blue: 0.82),
        Color(red: 0.89, green: 0.78, blue: 0.95),
        Color(red: 0.98, green: 0.89, blue: 0.67),
        Color(red: 0.82, green: 0.8, blue: 0.96),
        Color(red: 0.74, green: 0.86, blue: 0.93)
    ]
    
    static func color(for key: String) -> Color {
        let index = abs(key.hashValue) % colors.count
        return colors[index]
    }
}

final class WallpaperImageCache {
    static let shared = WallpaperImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {
        cache.countLimit = 600
    }
    
    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    
    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
