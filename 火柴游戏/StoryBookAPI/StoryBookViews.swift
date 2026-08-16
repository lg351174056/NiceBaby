import SwiftUI
import AVKit
import WebKit

// MARK: - Navigation Target

enum StoryNavTarget: Hashable {
    case home
}

// MARK: - 分类 emoji & 配色

private let storyClassEmoji: [String: String] = [
    "睡前故事":"🌙","幼儿故事":"🐣","寓言故事":"🦊","成语故事":"📜","益智故事":"🧩",
    "格林童话":"🏰","安徒生童话":"🧜","伊索寓言":"🦁","一千零一夜":"🕌","绕口令大全":"🌀",
    "中国童话故事":"🐉","木偶奇遇记":"🤥","中国上下五千年":"🏺","世界上下五千年":"🌍",
    "民间故事":"🏮","科学故事":"🔬","谜语故事":"❓","惊险故事":"🎢","王尔德童话":"🌹",
    "帝王故事":"👑","动物故事":"🐰","公主故事":"👸","0-5岁宝宝爱听的故事":"🍼",
    "儿童绘本故事":"🖍️","幼儿益智启蒙故事":"🧠","国学经典故事":"📚","古代寓言故事":"🦉",
    "中外名人故事":"🌟","中华五千年":"🏺","世界五千年":"🌍","笑话故事":"😂","小喇叭广播剧":"📻",
    "中国神话故事":"🐲","希腊神话故事":"⚡","孙越叔叔说故事":"👨","小老鼠漂流记":"🐭",
    "少儿版红楼梦经典故事":"🏯","儿童广播剧封神演义":"🔱","阿凡提笑话大全":"😄",
    "拉封丹寓言":"📖","机智与幽默的故事":"😆","《史记》人物故事":"📖","东周列国春秋篇故事":"⚔️",
    "东周列国战国篇故事":"🗡️","民间故事济公传":"🪷","小淘气尼古拉的故事":"🧒",
]

private let storyPalette: [(Color, Color)] = [
    (Color(red: 76/255, green: 175/255, blue: 125/255), Color(red: 190/255, green: 232/255, blue: 211/255)),
    (Color(red: 194/255, green: 162/255, blue: 72/255), Color(red: 255/255, green: 236/255, blue: 190/255)),
    (Color(red: 59/255, green: 142/255, blue: 165/255), Color(red: 200/255, green: 228/255, blue: 240/255)),
    (Color(red: 232/255, green: 106/255, blue: 82/255), Color(red: 255/255, green: 224/255, blue: 214/255)),
    (Color(red: 92/255, green: 75/255, blue: 138/255), Color(red: 224/255, green: 214/255, blue: 240/255)),
    (Color(red: 186/255, green: 80/255, blue: 100/255), Color(red: 250/255, green: 220/255, blue: 228/255)),
]

private func storyEmoji(_ name: String?) -> String { storyClassEmoji[name ?? ""] ?? "📚" }

private func storyTint(_ index: Int) -> (Color, Color) { storyPalette[index % storyPalette.count] }

// MARK: - 分类首页

struct StoryBookHomeView: View {
    @State private var mode: StoryBookMode = .read
    @State private var classes: [StoryClassItem] = []
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var pushTarget: StoryClassItem?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            FieldBackground()

            VStack(spacing: 0) {
                navBar(title: "儿童故事集")

                heroCard

                modeSwitch

                if isLoading {
                    Spacer()
                    ProgressView("故事分类赶来中…")
                        .controlSize(.large)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                    Spacer()
                } else if loadFailed {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("😵")
                            .font(.system(size: 40))
                        Text("分类加载失败，检查下网络吧")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.fieldMoss)
                        Button("再试一次") {
                            load()
                        }
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(AppTheme.fieldMint, in: Capsule())
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(classes.enumerated()), id: \.element.id) { index, item in
                                classCard(item, index: index)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $pushTarget) { item in
            StoryBookListView(mode: mode, classItem: item)
        }
        .onAppear { load() }
    }

    private func load() {
        isLoading = true
        loadFailed = false
        Task {
            do {
                classes = try await StoryBookAPI.fetchClasses(mode: mode)
                isLoading = false
            } catch {
                isLoading = false
                loadFailed = true
            }
        }
    }

    private var heroCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 227/255, green: 242/255, blue: 234/255),
                            Color(red: 189/255, green: 232/255, blue: 211/255)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("📚")
                    .font(.system(size: 24))
                    .modifier(FieldBob(delay: 0))
            }
            .frame(width: 52, height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.fieldMint.opacity(0.4), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("儿童故事集")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("睡前故事 · 童话 · 寓言 · 绘本音频")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                Text("小朋友，来听一个故事吧")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundStyle(Color(red: 63/255, green: 143/255, blue: 104/255))
                    .lineLimit(1)
            }
            Spacer()
            Text("🦋")
                .font(.system(size: 18))
                .modifier(FieldFlutter(delay: 1))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppTheme.fieldMint.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 8, y: 4)
        )
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 10)
    }

    private var modeSwitch: some View {
        HStack(spacing: 10) {
            modeButton(.read)
            modeButton(.listen)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private func modeButton(_ m: StoryBookMode) -> some View {
        let isOn = mode == m
        return Button {
            guard !isOn else { return }
            mode = m
            load()
        } label: {
            Text("\(m.emoji) \(m.title)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(isOn ? .white : AppTheme.fieldOliveDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isOn ? AppTheme.fieldMint : Color.white.opacity(0.88))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(isOn ? AppTheme.fieldMint : AppTheme.fieldOlive.opacity(0.35), lineWidth: 2)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func classCard(_ item: StoryClassItem, index: Int) -> some View {
        let tint = storyTint(index)
        return Button {
            pushTarget = item
        } label: {
            VStack(spacing: 8) {
                Text(storyEmoji(item.classname))
                    .font(.system(size: 30))
                    .modifier(FieldBob(delay: Double(index % 5) * 0.2))

                Text(item.classname)
                    .font(.system(size: 12, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .lineLimit(1)

                Capsule()
                    .fill(tint.0.opacity(0.45))
                    .frame(width: 24, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint.1.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(tint.0.opacity(0.35), lineWidth: 1.5)
                    )
                    .shadow(color: AppTheme.fieldGrassShadow.opacity(0.06), radius: 5, y: 3)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 故事列表

struct StoryBookListView: View {
    let mode: StoryBookMode
    let classItem: StoryClassItem

    @State private var stories: [StoryItem] = []
    @State private var pageIndex = 1
    @State private var total = 0
    @State private var isLoading = false
    @State private var isFinished = false
    @State private var pushTarget: StoryItem?

    var body: some View {
        ZStack {
            FieldBackground()

            VStack(spacing: 0) {
                navBar(title: "\(storyEmoji(classItem.classname)) \(classItem.classname)", trailing: "\(total) 篇")

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
                            Button {
                                pushTarget = story
                            } label: {
                                storyRow(story, index: index)
                            }
                            .buttonStyle(.plain)
                        }

                        if !isFinished {
                            Button {
                                loadMore()
                            } label: {
                                HStack(spacing: 6) {
                                    if isLoading {
                                        ProgressView().tint(AppTheme.fieldMint)
                                    }
                                    Text(isLoading ? "寻找故事中…" : "再找一些故事 ⬇")
                                }
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.fieldMint)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.9))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 1.5)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        } else {
                            Text("故事都看完啦 🌙")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.fieldMoss)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $pushTarget) { story in
            StoryBookDetailView(mode: mode, classItem: classItem, story: story)
        }
        .onAppear {
            if stories.isEmpty { loadMore() }
        }
    }

    private func loadMore() {
        guard !isLoading, !isFinished else { return }
        isLoading = true
        Task {
            do {
                let result = try await StoryBookAPI.fetchStories(mode: mode, classid: classItem.classid, page: pageIndex)
                total = result.total
                if result.items.isEmpty {
                    isFinished = true
                } else {
                    stories.append(contentsOf: result.items)
                    pageIndex += 1
                    if stories.count >= result.total { isFinished = true }
                }
            } catch {
                isFinished = true
            }
            isLoading = false
        }
    }

    private func storyRow(_ story: StoryItem, index: Int) -> some View {
        let tint = storyTint(index)
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.1)
                if let cover = story.coverURL, let url = URL(string: cover) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Text(storyEmoji(story.classname ?? classItem.classname))
                                .font(.system(size: 20))
                        }
                    }
                } else {
                    Text(storyEmoji(story.classname ?? classItem.classname))
                        .font(.system(size: 20))
                        .modifier(FieldBob(delay: Double(index % 6) * 0.3))
                }
            }
            .frame(width: 46, height: 46)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(tint.0.opacity(0.35), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(.system(size: 14, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(story.newstime ?? "")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                    if mode == .listen, !(story.mp3link ?? "").isEmpty {
                        Label("音频", systemImage: "speaker.wave.2.fill")
                            .font(.system(size: 8, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.fieldMint)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.fieldMossLight)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 1.5)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 5, y: 3)
        )
    }
}

// MARK: - 故事详情

struct StoryBookDetailView: View {
    let mode: StoryBookMode
    let classItem: StoryClassItem
    let story: StoryItem

    @State private var detailHTML = ""
    @State private var mp3URL: String?
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var contentHeight: CGFloat = 200

    @State private var isPlayingAudio = false
    @State private var audioPlayer: AVPlayer?
    @State private var audioProgress: Double = 0
    @State private var audioDuration: Double = 0

    var body: some View {
        ZStack {
            FieldBackground()

            VStack(spacing: 0) {
                navBar(title: "\(mode.emoji) \(classItem.classname)")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // 封面
                        if let cover = story.coverURL, let url = URL(string: cover) {
                            AsyncImage(url: url) { phase in
                                if case .success(let image) = phase {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                } else if case .failure = phase {
                                    Color.white.opacity(0.6)
                                        .frame(height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                } else {
                                    ProgressView()
                                        .frame(height: 120)
                                }
                            }
                        }

                        // 听故事播放器
                        if mode == .listen, let mp3 = mp3URL, !mp3.isEmpty {
                            playerCard(url: mp3)
                        }

                        // 正文
                        VStack(alignment: .leading, spacing: 8) {
                            Text(story.title)
                                .font(.system(size: 22, weight: .heavy, design: .serif))
                                .foregroundStyle(AppTheme.fieldInk)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("\(story.newstime ?? "") · \(classItem.classname)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.fieldMoss)

                            Divider()
                                .overlay(AppTheme.fieldOlive.opacity(0.3))

                            if isLoading {
                                HStack(spacing: 8) {
                                    ProgressView().tint(AppTheme.fieldMint)
                                    Text("故事打开中…")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.fieldMoss)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            } else if loadFailed {
                                VStack(spacing: 10) {
                                    Text("😵 故事打开失败")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.fieldMoss)
                                    Button("再试一次") { loadDetail() }
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(AppTheme.fieldMint, in: Capsule())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            } else {
                                StoryHTMLView(html: detailHTML, height: $contentHeight)
                                    .frame(height: contentHeight)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.94))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 1.5)
                                )
                                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 8, y: 4)
                        )
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { loadDetail() }
        .onDisappear { audioPlayer?.pause() }
    }

    private func loadDetail() {
        isLoading = true
        loadFailed = false
        Task {
            do {
                let content = try await StoryBookAPI.fetchDetail(mode: mode, id: story.id, classid: story.classid)
                detailHTML = (content["newstext"] as? String) ?? (content["smalltext"] as? String) ?? ""
                if detailHTML.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    detailHTML = "<p style=\"color:#8A9A7A\">这篇故事只有音频哦，点上面的播放按钮听吧 🎧</p>"
                }
                if mp3URL == nil {
                    mp3URL = (content["mp3link"] as? String) ?? story.mp3link
                }
                isLoading = false
            } catch {
                isLoading = false
                loadFailed = true
            }
        }
    }

    private func playerCard(url: String) -> some View {
        VStack(spacing: 10) {
            Text(storyEmoji(classItem.classname))
                .font(.system(size: 38))
                .modifier(FieldBob(delay: 0))
            Text(story.title)
                .font(.system(size: 15, weight: .heavy, design: .serif))
                .foregroundStyle(.white)
                .lineLimit(1)

            Button {
                togglePlay(url: url)
            } label: {
                Image(systemName: isPlayingAudio ? "pause.fill" : "play.fill")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .frame(width: 60, height: 60)
                    .background(Color(red: 255/255, green: 201/255, blue: 61/255), in: Circle())
                    .overlay(Circle().strokeBorder(Color(red: 61/255, green: 74/255, blue: 54/255), lineWidth: 2))
            }
            .buttonStyle(.plain)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.45)).frame(height: 9)
                    Capsule()
                        .fill(Color(red: 255/255, green: 201/255, blue: 61/255))
                        .frame(width: geo.size.width * audioProgress, height: 9)
                }
            }
            .frame(height: 9)
            .overlay(Capsule().strokeBorder(Color(red: 61/255, green: 74/255, blue: 54/255), lineWidth: 1.5))

            HStack {
                Text(fmtTime(audioProgress * audioDuration))
                Spacer()
                Text(fmtTime(audioDuration))
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.95))
        }
        .padding(18)
        .background(
            LinearGradient(colors: [
                Color(red: 189/255, green: 232/255, blue: 211/255),
                AppTheme.fieldMint
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color(red: 61/255, green: 74/255, blue: 54/255), lineWidth: 2)
            )
            .shadow(color: AppTheme.fieldGrassShadow.opacity(0.2), radius: 8, y: 4)
        )
    }

    private func togglePlay(url: String) {
        if isPlayingAudio {
            audioPlayer?.pause()
            isPlayingAudio = false
            return
        }
        guard let u = URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url) else { return }
        if audioPlayer == nil {
            let player = AVPlayer(url: u)
            audioPlayer = player
            player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
                let d = player.currentItem?.duration.seconds ?? 0
                audioDuration = d.isFinite ? d : 0
                audioProgress = d > 0 ? min(time.seconds / d, 1) : 0
            }
        } else if audioPlayer?.currentItem == nil {
            audioPlayer = AVPlayer(url: u)
        }
        audioPlayer?.seek(to: .zero)
        audioPlayer?.play()
        isPlayingAudio = true
    }

    private func fmtTime(_ sec: Double) -> String {
        guard sec.isFinite, sec > 0 else { return "0:00" }
        let s = Int(sec)
        return "\(s / 60):\(String(format: "%02d", s % 60))"
    }
}

// MARK: - 正文 HTML 渲染（WKWebView）

private struct StoryHTMLView: UIViewRepresentable {
    let html: String
    @Binding var height: CGFloat

    private static let handlerName = "storyContentSize"

    func makeCoordinator() -> Coordinator { Coordinator(height: $height) }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: Self.handlerName)
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.loadHTMLString(Self.buildHTML(from: html), baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(Self.buildHTML(from: html), baseURL: nil)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: handlerName)
        webView.navigationDelegate = nil
    }

    private static func buildHTML(from raw: String) -> String {
        let body = raw.replacingOccurrences(of: "<img ", with: "<img style=\"max-width:100%;border-radius:12px;\" ")
        return """
        <html><head><meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { margin:0; padding:0; font-family:-apple-system,"PingFang SC",sans-serif;
                 font-size:17px; line-height:1.95; color:#3D4A36; font-weight:600;
                 -webkit-user-select:none; }
          p { margin:0 0 1em; }
          img { max-width:100%; border-radius:12px; }
        </style></head>
        <body>\(body)</body></html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let height: Binding<CGFloat>
        init(height: Binding<CGFloat>) { self.height = height }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { result, _ in
                if let h = result as? CGFloat {
                    DispatchQueue.main.async { self.height.wrappedValue = max(h, 60) }
                }
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {}
    }
}

// MARK: - 通用顶部导航

private func navBar(title: String, trailing: String = "") -> some View {
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
    .overlay(alignment: .trailing) {
        if !trailing.isEmpty {
            Text(trailing)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.fieldMint)
        }
    }
    .padding(.horizontal, 18)
    .padding(.top, 6)
    .padding(.bottom, 6)
}
