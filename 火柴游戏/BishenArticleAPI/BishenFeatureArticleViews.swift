import SwiftUI
import WebKit

struct BishenFeatureArticleHomeView: View {
    @State private var articles: [BishenFeatureArticle] = []
    @State private var commentTotals: [String: Int] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            UnifiedNavBar(title: "文章精选")

            Group {
                if isLoading && articles.isEmpty {
                    loadingView
                } else if let errorMessage, articles.isEmpty {
                    errorView(message: errorMessage)
                } else {
                    contentView
                }
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .task {
            guard articles.isEmpty else { return }
            await load()
        }
        .refreshable {
            await load()
        }
    }

    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("已还原 \(articles.count) 篇文章")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.top, 8)

                LazyVStack(spacing: 14) {
                    ForEach(articles) { article in
                        NavigationLink {
                            BishenFeatureArticleDetailView(
                                article: article,
                                initialCommentCount: commentTotals[article.route.info.targetId] ?? 0,
                                archiveArticles: articles,
                                archiveCommentTotals: commentTotals
                            )
                        } label: {
                            BishenFeatureArticleCard(
                                article: article,
                                commentCount: commentTotals[article.route.info.targetId] ?? 0
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.bottom, 28)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 80)
            ProgressView("正在加载文章内容...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .tint(AppTheme.accentIndigo)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            Image(systemName: "doc.text.image")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Text("文章列表加载失败")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    @MainActor
    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let articles = try await BishenFeatureArticleService.shared.fetchAllArticles()
            let totals = try await BishenFeatureArticleService.shared.fetchCommentTotals(
                targetIDs: articles.map { $0.route.info.targetId }
            )
            self.articles = articles
            self.commentTotals = totals
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct BishenFeatureArticleDetailView: View {
    let article: BishenFeatureArticle
    let initialCommentCount: Int
    let archiveArticles: [BishenFeatureArticle]
    let archiveCommentTotals: [String: Int]

    @State private var detail: BishenFeatureArticleDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var contentHeight: CGFloat = 320

    init(
        article: BishenFeatureArticle,
        initialCommentCount: Int,
        archiveArticles: [BishenFeatureArticle] = [],
        archiveCommentTotals: [String: Int] = [:]
    ) {
        self.article = article
        self.initialCommentCount = initialCommentCount
        self.archiveArticles = archiveArticles
        self.archiveCommentTotals = archiveCommentTotals
    }

    var body: some View {
        VStack(spacing: 0) {
            UnifiedNavBar(
                title: "文章详情",
                trailing: archiveArticles.isEmpty ? nil : AnyView(
                    NavigationLink {
                        BishenFeatureArticleArchiveView(
                            articles: archiveArticles,
                            commentTotals: archiveCommentTotals
                        )
                    } label: {
                        Text("往期")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.card, in: Capsule())
                    }
                    .buttonStyle(.plain)
                )
            )

            Group {
                if isLoading && detail == nil {
                    loadingView
                } else if let detail {
                    contentView(detail)
                } else {
                    errorView(message: errorMessage ?? "文章详情加载失败")
                }
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .task {
            guard detail == nil else { return }
            await load()
        }
    }

    private func contentView(_ detail: BishenFeatureArticleDetail) -> some View {
        GeometryReader { proxy in
            let contentWidth = proxy.size.width
            let sectionWidth = max(0, contentWidth - AppTheme.paddingScreen * 2)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    BishenFeatureHTMLView(html: detail.html, height: $contentHeight)
                        .frame(width: contentWidth, height: max(contentHeight, 320))

                    if !detail.comments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("精选评论")
                                    .font(.system(size: 19, weight: .heavy, design: .serif))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                Text("\(max(initialCommentCount, detail.comments.count)) 条")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            VStack(spacing: 12) {
                                ForEach(detail.comments) { comment in
                                    BishenFeatureCommentCard(comment: comment)
                                }
                            }
                        }
                        .frame(width: sectionWidth)
                        .padding(.horizontal, AppTheme.paddingScreen)
                    }

                    if !relatedArticles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("更多文章")
                                    .font(.system(size: 19, weight: .heavy, design: .serif))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                NavigationLink {
                                    BishenFeatureArticleArchiveView(
                                        articles: archiveArticles,
                                        commentTotals: archiveCommentTotals
                                    )
                                } label: {
                                    Text("查看全部")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.accentJade)
                                }
                                .buttonStyle(.plain)
                            }

                            VStack(spacing: 12) {
                                ForEach(relatedArticles) { relatedArticle in
                                    NavigationLink {
                                        BishenFeatureArticleDetailView(
                                            article: relatedArticle,
                                            initialCommentCount: archiveCommentTotals[relatedArticle.route.info.targetId] ?? 0,
                                            archiveArticles: archiveArticles,
                                            archiveCommentTotals: archiveCommentTotals
                                        )
                                    } label: {
                                        BishenFeatureArticleCompactCard(
                                            article: relatedArticle,
                                            commentCount: archiveCommentTotals[relatedArticle.route.info.targetId] ?? 0
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(width: sectionWidth)
                        .padding(.horizontal, AppTheme.paddingScreen)
                    }
                }
                .frame(width: contentWidth, alignment: .leading)
                .padding(.bottom, 32)
            }
        }
    }

    private var relatedArticles: [BishenFeatureArticle] {
        archiveArticles
            .filter { $0.id != article.id }
            .prefix(6)
            .map { $0 }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 80)
            ProgressView("正在加载文章详情...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .tint(AppTheme.accentJade)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            Image(systemName: "doc.richtext")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Text(article.queryBannerDesc)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    @MainActor
    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            detail = try await BishenFeatureArticleService.shared.fetchDetail(for: article)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct BishenFeatureArticleArchiveView: View {
    let articles: [BishenFeatureArticle]
    let commentTotals: [String: Int]

    var body: some View {
        VStack(spacing: 0) {
            UnifiedNavBar(title: "更多文章")

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(articles) { article in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .lastTextBaseline, spacing: 8) {
                                Text(article.monthDayText)
                                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text(article.weekdayText)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            NavigationLink {
                                BishenFeatureArticleDetailView(
                                    article: article,
                                    initialCommentCount: commentTotals[article.route.info.targetId] ?? 0,
                                    archiveArticles: articles,
                                    archiveCommentTotals: commentTotals
                                )
                            } label: {
                                BishenFeatureArticleArchiveCard(
                                    article: article,
                                    commentCount: commentTotals[article.route.info.targetId] ?? 0
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
    }
}

private struct BishenFeatureArticleCard: View {
    let article: BishenFeatureArticle
    let commentCount: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: article.queryBannerImageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                LinearGradient(
                    colors: [AppTheme.accentIndigo.opacity(0.20), AppTheme.accentJade.opacity(0.16)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .frame(height: 184)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.52)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(article.triggerQuery)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.16), in: Capsule())

                Text(article.queryBannerDesc)
                    .font(.system(size: 20, weight: .heavy, design: .serif))
                    .foregroundStyle(.white)
                    .lineSpacing(4)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(article.releaseDateText)
                    Text("·")
                    Text(article.commentSummary(count: commentCount))
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.84))
            }
            .padding(16)
        }
    }
}

private struct BishenFeatureCommentCard: View {
    let comment: BishenFeatureComment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: comment.userIcon ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(AppTheme.accentIndigo.opacity(0.16))
                    .overlay {
                        Text(String(comment.userName.prefix(1)))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.accentIndigo)
                    }
            }
            .frame(width: 38, height: 38)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(comment.userName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text(comment.createdAtText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Text(comment.content)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(5)

                HStack(spacing: 6) {
                    Image(systemName: "hand.thumbsup")
                        .font(.system(size: 12, weight: .medium))
                    Text("\(comment.likeCount)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundStyle(AppTheme.accentJade)
            }
        }
        .padding(14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct BishenFeatureArticleArchiveCard: View {
    let article: BishenFeatureArticle
    let commentCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: article.queryBannerImageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                LinearGradient(
                    colors: [AppTheme.accentIndigo.opacity(0.16), AppTheme.accentJade.opacity(0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .frame(height: 196)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(alignment: .leading, spacing: 14) {
                Text(article.queryBannerDesc)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineSpacing(4)

                HStack {
                    Spacer()
                    HStack(spacing: 5) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 13, weight: .medium))
                        Text(article.commentCountText(count: commentCount))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(16)
        }
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 5)
    }
}

private struct BishenFeatureArticleCompactCard: View {
    let article: BishenFeatureArticle
    let commentCount: Int

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: article.queryBannerImageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.accentIndigo.opacity(0.14))
            }
            .frame(width: 110, height: 78)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(article.queryBannerDesc)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(article.releaseDateText)
                    Text(article.commentCountText(count: commentCount))
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct BishenFeatureHTMLView: UIViewRepresentable {
    let html: String
    @Binding var height: CGFloat

    private static let messageHandlerName = "bishenContentSize"

    func makeCoordinator() -> Coordinator {
        Coordinator(height: $height)
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: Self.messageHandlerName)

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
        webView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        webView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let safeHTML = Self.buildSafeHTML(from: html)
        context.coordinator.loadedID = html.hashValue
        webView.loadHTMLString(safeHTML, baseURL: URL(string: "https://image.bishen.ink"))

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedID != html.hashValue else { return }
        let safeHTML = Self.buildSafeHTML(from: html)
        context.coordinator.loadedID = html.hashValue
        webView.loadHTMLString(safeHTML, baseURL: URL(string: "https://image.bishen.ink"))
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: messageHandlerName)
        webView.navigationDelegate = nil
    }

    private static func buildSafeHTML(from rawHTML: String) -> String {
        let bodyContent = BishenArticleHTMLSanitizer.sanitizeBodyContent(from: rawHTML)

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src * data:; style-src 'unsafe-inline'; script-src 'unsafe-inline'; connect-src 'none'; frame-src 'none'; object-src 'none'; base-uri 'none';">
        <style>
        html, body {
            margin: 0; padding: 0;
            width: 100%; max-width: 100%;
            overflow-x: hidden;
            position: relative;
            background: #fff;
            -webkit-text-size-adjust: 100%;
        }
        body {
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', sans-serif;
            color: #3E3E3E;
            word-break: break-word;
            overflow-wrap: break-word;
            box-sizing: border-box;
        }
        * {
            box-sizing: border-box !important;
            max-width: 100% !important;
            min-width: 0 !important;
        }
        img {
            max-width: 100% !important;
            height: auto !important;
            display: block;
        }
        section, div, article, header, footer, main, figure {
            max-width: 100% !important;
            overflow-x: hidden !important;
        }
        p, span, strong, em, a {
            max-width: 100% !important;
            overflow-wrap: break-word;
            word-break: break-word;
        }
        p {
            line-height: 1.9;
            font-size: 17px;
            color: #3E3E3E;
        }
        table { width: 100%; max-width: 100%; overflow-x: auto; display: block; }
        video, iframe, canvas, svg { max-width: 100%; height: auto; display: block; }
        </style>
        </head>
        <body>
        \(bodyContent)
        <script>
        (function(){
            var h = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.bishenContentSize;
            if(!h) return;
            function r(){
                h.postMessage({height: Math.max(document.body.scrollHeight, document.body.offsetHeight)});
            }
            window.onload = r;
            setTimeout(r, 300);
            setTimeout(r, 1500);
            setTimeout(r, 4000);
            var imgs = document.images;
            for(var i=0;i<imgs.length;i++){if(!imgs[i].complete) imgs[i].onload=r;}
            if(window.ResizeObserver) new ResizeObserver(r).observe(document.body);
            window.__bishenReportSize = r;
        })();
        </script>
        </body>
        </html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        @Binding var height: CGFloat
        var loadedID: Int?

        init(height: Binding<CGFloat>) {
            self._height = height
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("window.__bishenReportSize && window.__bishenReportSize();", completionHandler: nil)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            let url = navigationAction.request.url
            if url?.scheme == "about" || url?.absoluteString == "about:blank" {
                decisionHandler(.allow)
                return
            }
            if navigationAction.targetFrame?.isMainFrame == true,
               navigationAction.navigationType == .other {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "bishenContentSize",
                  let body = message.body as? [String: Any],
                  let rawHeight = body["height"] as? Double else {
                return
            }
            let resolved = max(CGFloat(rawHeight), 320)
            if abs(resolved - height) > 2 {
                DispatchQueue.main.async { self.height = resolved }
            }
        }
    }
}

private extension BishenFeatureArticle {
    var releaseDateText: String {
        BishenFeatureFormatter.dateText(for: releaseDate)
    }

    func commentSummary(count: Int) -> String {
        count > 0 ? "\(count) 评论" : "暂无评论"
    }

    var monthDayText: String {
        BishenFeatureFormatter.monthDayText(for: releaseDate)
    }

    var weekdayText: String {
        BishenFeatureFormatter.weekdayText(for: releaseDate)
    }

    func commentCountText(count: Int) -> String {
        if count >= 1000 {
            let value = Double(count) / 1000.0
            return String(format: "%.1fk", value)
        }
        return "\(count)"
    }
}

private extension BishenFeatureComment {
    var userName: String {
        userNick.isEmpty ? "匿名用户" : userNick
    }

    var createdAtText: String {
        BishenFeatureFormatter.dateText(for: createdAt)
    }
}

private enum BishenFeatureFormatter {
    nonisolated static func dateText(for timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    nonisolated static func monthDayText(for timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    nonisolated static func weekdayText(for timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }
}
