import SwiftUI
import AVKit
import UIKit
import Photos

// MARK: - 壁纸图库（书野营地竹青风）

struct WallpaperGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: WallpaperMedia?
    private let outerHorizontalPadding: CGFloat = 10
    private let itemSpacing: CGFloat = 8
    private let itemHeight: CGFloat = 220

    private let wallpapers = WallpaperData.items

    private var videoCount: Int {
        wallpapers.filter { $0.type == .video }.count
    }

    var body: some View {
        ZStack {
            // 蓝天草地背景（固定）
            FieldBackground()

            gallerySun
            galleryCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            galleryCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text("壁纸图库")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                // 主题头
                heroHeader

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
                                MediaCell(item: item) {
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        selectedItem = item
                                    }
                                }
                                .frame(width: itemWidth, height: itemHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        .padding(.horizontal, outerHorizontalPadding)
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            if let selectedItem {
                WallpaperPreviewOverlay(item: selectedItem) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        self.selectedItem = nil
                    }
                }
                .zIndex(10)
                .transition(.opacity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
    }

    // 主题头（🖼 竹青）
    private var heroHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 227/255, green: 242/255, blue: 234/255),
                            Color(red: 189/255, green: 232/255, blue: 211/255)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("🖼")
                    .font(.system(size: 24))
                    .modifier(FieldBob(delay: 0.3))
            }
            .frame(width: 52, height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.fieldMint.opacity(0.4), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("壁纸图库")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("山川风物 · 收藏入屏")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                HStack(spacing: 12) {
                    Text("🖼 \(wallpapers.count) 张")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMint)
                    Text("🎬 \(videoCount) 个视频")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.fieldGold)
                }
                .padding(.top, 1)
            }
            Spacer()
            HStack(spacing: 6) {
                Text("🍃").font(.system(size: 15)).modifier(FieldBob(delay: 0))
                Text("🦋").font(.system(size: 14)).modifier(FieldFlutter(delay: 0.9))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppTheme.fieldMint.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.12), radius: 8, y: 4)
        )
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    // MARK: - 背景装饰（太阳/云）

    private var gallerySun: some View {
        FieldSun()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.trailing, 20)
            .padding(.top, 30)
            .allowsHitTesting(false)
    }

    private func galleryCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
        FieldCloud(scale: scale, delay: delay)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, 390 * x - 10)
            .padding(.top, 390 * y)
            .allowsHitTesting(false)
    }}// 媒体单元格：区分图片和视频
struct MediaCell: View {
    let item: WallpaperMedia
    let onTap: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(placeholderColor)

            if item.type == .video {
                if let url = URL(string: item.url) {
                    RemoteVideoThumbnail(url: url)
                        .allowsHitTesting(false)
                } else {
                    fallbackView
                }
                // 动态壁纸徽章（竹青播放胶囊 · 呼吸动效）
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 8, weight: .heavy))
                            Text("动态")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(colors: [
                                Color(red: 126/255, green: 211/255, blue: 160/255),
                                AppTheme.fieldMint
                            ], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: Capsule()
                        )
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.5), lineWidth: 1))
                        .shadow(color: AppTheme.fieldMint.opacity(0.5), radius: 4, y: 1)
                        .modifier(BadgeBreathe())
                        .padding(7)
                    }
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
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: AppTheme.fieldGrassShadow.opacity(0.12), radius: 6, y: 3)
        .clipped()
        .contentShape(Rectangle())
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
                ProgressView()
                    .controlSize(.small)
                    .tint(Color.white.opacity(0.7))
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
                withAnimation(.easeOut(duration: 0.2)) {
                    self.image = image
                }
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
            withAnimation(.easeOut(duration: 0.2)) {
                image = thumbnail
            }
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

// MARK: - 预览弹层（全屏沉浸 + 保存到相册）

struct WallpaperPreviewOverlay: View {
    let item: WallpaperMedia
    let onClose: () -> Void

    @State private var saveState: SaveState = .idle

    enum SaveState {
        case idle
        case saving
        case saved
        case failed
    }

    var body: some View {
        ZStack {
            // 底层：占位色（瞬间可见，无黑屏）
            WallpaperPlaceholderPalette.color(for: item.url)
                .ignoresSafeArea()

            // 媒体内容
            Group {
                if item.type == .video, let url = URL(string: item.url) {
                    LoopingVideoPlayer(url: url)
                } else if let url = URL(string: item.fullURL) {
                    // 缩略图立即显示（缓存命中），全尺寸图异步加载后淡入
                    RemoteWallpaperImage(url: url, contentMode: .fit)
                } else {
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .ignoresSafeArea()
            .onTapGesture(perform: onClose)

            // 顶部：左关闭 + 右保存
            VStack {
                HStack {
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
                    Spacer()
                    Button(action: { Task { await saveToAlbum() } }) {
                        ZStack {
                            Circle()
                                .fill(saveButtonFill)
                                .background(.ultraThinMaterial, in: Circle())
                                .frame(width: 42, height: 42)
                            Image(systemName: saveIcon)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .disabled(saveState == .saving)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()
            }
        }
        .onChange(of: item) { _, _ in
            saveState = .idle
        }
    }

    private var saveButtonFill: Color {
        switch saveState {
        case .idle: return .white.opacity(0.16)
        case .saving: return .gray.opacity(0.4)
        case .saved: return AppTheme.fieldMint.opacity(0.8)
        case .failed: return Color(red: 232/255, green: 100/255, blue: 82/255).opacity(0.8)
        }
    }

    private var saveIcon: String {
        switch saveState {
        case .idle: return "arrow.down.to.line"
        case .saving: return "arrow.down.circle.dotted"
        case .saved: return "checkmark"
        case .failed: return "exclamationmark"
        }
    }

    // MARK: - 保存逻辑（async/await 统一）

    @MainActor
    private func saveToAlbum() async {
        guard saveState == .idle else { return }
        saveState = .saving

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            saveState = .failed
            resetAfterDelay()
            return
        }

        if item.type == .video {
            await saveVideo()
        } else {
            await saveImage()
        }
    }

    @MainActor
    private func saveImage() async {
        guard let url = URL(string: item.fullURL) else {
            saveState = .failed
            resetAfterDelay()
            return
        }

        let image: UIImage
        if let cached = WallpaperImageCache.shared.image(for: url) {
            image = cached
        } else {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 30
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      200..<300 ~= httpResponse.statusCode,
                      let downloaded = UIImage(data: data) else {
                    saveState = .failed
                    resetAfterDelay()
                    return
                }
                WallpaperImageCache.shared.insert(downloaded, for: url)
                image = downloaded
            } catch {
                saveState = .failed
                resetAfterDelay()
                return
            }
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            saveState = .saved
        } catch {
            saveState = .failed
        }
        resetAfterDelay()
    }

    @MainActor
    private func saveVideo() async {
        guard let url = URL(string: item.url) else {
            saveState = .failed
            resetAfterDelay()
            return
        }

        do {
            let (tempFileURL, response) = try await URLSession.shared.download(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                saveState = .failed
                resetAfterDelay()
                return
            }
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("wallpaper_\(UUID().uuidString).mov")
            try FileManager.default.moveItem(at: tempFileURL, to: dest)

            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: dest)
            }
            try? FileManager.default.removeItem(at: dest)
            saveState = .saved
        } catch {
            saveState = .failed
        }
        resetAfterDelay()
    }

    private func resetAfterDelay() {
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { saveState = .idle }
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

// MARK: - 动态徽章呼吸动效

struct BadgeBreathe: ViewModifier {
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(on ? 1.0 : 0.9)
            .opacity(on ? 1 : 0.75)
            .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: on)
            .onAppear { on = true }
    }
}
