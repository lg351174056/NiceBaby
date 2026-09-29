import SwiftUI
import WebKit

// MARK: - 笔神精选 · L1 精选主页（书野文苑）

struct BishenFeatureArticleHomeView: View {
    @State private var articles: [BishenFeatureArticle] = []
    @State private var commentTotals: [String: Int] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // 蓝天草地背景（固定）
            FieldBackground()

            gardenSun
            gardenCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            gardenCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                transparentNavBar

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
        }
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

    private var transparentNavBar: some View {
        ZStack {
            HStack {
                GracefulBackButton()
                Spacer()
            }
            Text("笔神精选")
                .font(.system(size: 18, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }

    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                heroHeader

                if let featured = articles.first {
                    featuredCard(featured)
                        .padding(.top, 12)
                }

                sectionTitle(
                    title: "文章列表",
                    countText: "\(articles.count) 篇 · 每日上新"
                )

                LazyVStack(spacing: 10) {
                    ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                        NavigationLink {
                            BishenFeatureArticleDetailView(
                                article: article,
                                initialCommentCount: commentTotals[article.route.info.targetId] ?? 0,
                                archiveArticles: articles,
                                archiveCommentTotals: commentTotals
                            )
                        } label: {
                            BishenFeatureArticleListCard(
                                article: article,
                                index: index,
                                commentCount: commentTotals[article.route.info.targetId] ?? 0
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 8)

                if !articles.isEmpty {
                    Text("已展示全部内容 ✓")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                        .padding(.bottom, 14)
                }
            }
            .padding(.bottom, 20)
        }
    }

    // 主题头（书野文苑）
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
                Text("🖋")
                    .font(.system(size: 24))
                    .modifier(FieldBob(delay: 0.3))
            }
            .frame(width: 52, height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.fieldMint.opacity(0.4), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("笔神精选")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("每天一篇好文章 · 妙笔生花")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                HStack(spacing: 12) {
                    Text("📰 \(articles.count) 篇文章")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMint)
                    Text("🔥 今日更新")
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
        .padding(.top, 10)
    }

    // 今日置顶大图卡（渐变装饰封面：太阳 + 线条 + 遮罩）
    private func featuredCard(_ article: BishenFeatureArticle) -> some View {
        NavigationLink {
            BishenFeatureArticleDetailView(
                article: article,
                initialCommentCount: commentTotals[article.route.info.targetId] ?? 0,
                archiveArticles: articles,
                archiveCommentTotals: commentTotals
            )
        } label: {
            ZStack(alignment: .bottomLeading) {
                // 绿色渐变封面（设计稿风格）
                LinearGradient(
                    colors: [
                        Color(red: 156/255, green: 207/255, blue: 180/255),
                        AppTheme.fieldMint,
                        Color(red: 46/255, green: 125/255, blue: 91/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 168)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                // 右上太阳（呼吸）
                Text("☀️")
                    .font(.system(size: 22))
                    .modifier(SunBreathe())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(14)

                // 白色装饰线条
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.white.opacity(0.28))
                        .frame(height: 5)
                        .padding(.horizontal, 14)
                    Capsule()
                        .fill(Color.white.opacity(0.22))
                        .frame(height: 5)
                        .padding(.horizontal, 14)
                        .frame(width: 150, alignment: .leading)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 44)

                // 底部遮罩
                LinearGradient(
                    colors: [.clear, Color(red: 20/255, green: 45/255, blue: 30/255).opacity(0.62)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text("🏷 \(article.triggerQuery)")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.18), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 1))

                    Text(article.queryBannerDesc)
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(.white)
                        .lineSpacing(4)
                        .lineLimit(2)

                    Text("\(article.monthDayText) 今日精选 · 💬 \(article.commentSummary(count: commentTotals[article.route.info.targetId] ?? 0))")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(14)
            }
            .padding(.horizontal, 18)
        }
        .buttonStyle(.plain)
    }

    private struct SunBreathe: ViewModifier {
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                content
                    .scaleEffect(1 + 0.04 * sin(t * 1.2))
            }
        }
    }

    private func sectionTitle(title: String, countText: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(AppTheme.fieldMint)
                .frame(width: 6, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
            Spacer()
            Text(countText)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.fieldMoss)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    // MARK: - 背景装饰（太阳/云）

    private var gardenSun: some View {
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

    private func gardenCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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

    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 80)
            ProgressView("正在翻开书页...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .tint(AppTheme.fieldMint)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            Image(systemName: "doc.text.image")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(AppTheme.fieldGold)
            Text("文章列表加载失败")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.fieldMoss)
                .multilineTextAlignment(.center)
            Button("重新翻书") {
                Task { await load() }
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(AppTheme.fieldMint, in: Capsule())
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

// MARK: - L2 文章详情（书野文苑）

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
        ZStack {
            // 蓝天草地背景（固定）
            FieldBackground()

            detailSun
            detailCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            detailCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                transparentNavBar

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
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .task {
            guard detail == nil else { return }
            await load()
        }
    }

    private var transparentNavBar: some View {
        ZStack {
            HStack {
                GracefulBackButton()
                Spacer()
                if !archiveArticles.isEmpty {
                    NavigationLink {
                        BishenFeatureArticleArchiveView(
                            articles: archiveArticles,
                            commentTotals: archiveCommentTotals
                        )
                    } label: {
                        Text("往期")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.fieldMint)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.9), in: Capsule())
                            .overlay(Capsule().strokeBorder(AppTheme.fieldMint.opacity(0.35), lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("文章详情")
                .font(.system(size: 18, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }

    private func contentView(_ detail: BishenFeatureArticleDetail) -> some View {
        GeometryReader { proxy in
            let contentWidth = proxy.size.width
            let sectionWidth = max(0, contentWidth - AppTheme.paddingScreen * 2)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    articleHeadCard

                    BishenFeatureHTMLView(html: detail.html, height: $contentHeight)
                        .frame(width: contentWidth, height: max(contentHeight, 320))

                    if !detail.comments.isEmpty {
                        commentsSection(detail.comments, sectionWidth: sectionWidth)
                    }

                    if !relatedArticles.isEmpty {
                        relatedSection(sectionWidth: sectionWidth)
                    }
                }
                .frame(width: contentWidth, alignment: .leading)
                .padding(.bottom, 32)
            }
        }
    }

    // 文章头卡
    private var articleHeadCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("🏷 \(article.triggerQuery)")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 46/255, green: 125/255, blue: 91/255))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(AppTheme.fieldMint.opacity(0.12), in: Capsule())
                    .overlay(Capsule().strokeBorder(AppTheme.fieldMint.opacity(0.4), lineWidth: 1.5))
            }

            Text(article.queryBannerDesc)
                .font(.system(size: 26, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
                .lineSpacing(6)

            HStack(spacing: 12) {
                Text("💬 \(max(initialCommentCount, detail?.comments.count ?? 0)) 条评论")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMint)
                Text("🕘 \(article.releaseDateText) 发布")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.12), radius: 8, y: 4)
        )
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 10)
    }

    private func commentsSection(_ comments: [BishenFeatureComment], sectionWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title: "精选评论", countText: "\(max(initialCommentCount, comments.count)) 条")

            VStack(spacing: 10) {
                ForEach(comments) { comment in
                    BishenFeatureCommentCard(comment: comment)
                }
            }
        }
        .frame(width: sectionWidth)
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    private func relatedSection(sectionWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(AppTheme.fieldMint)
                    .frame(width: 6, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                Text("更多文章")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Spacer()
                NavigationLink {
                    BishenFeatureArticleArchiveView(
                        articles: archiveArticles,
                        commentTotals: archiveCommentTotals
                    )
                } label: {
                    Text("查看全部")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMint)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 10) {
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
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: sectionWidth)
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    private func sectionTitle(title: String, countText: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(AppTheme.fieldMint)
                .frame(width: 6, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
            Spacer()
            Text(countText)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.fieldMoss)
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
                .tint(AppTheme.fieldMint)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            Image(systemName: "doc.richtext")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(AppTheme.fieldGold)
            Text(article.queryBannerDesc)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.fieldMoss)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    // MARK: - 背景装饰（太阳/云）

    private var detailSun: some View {
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

    private func detailCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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

// MARK: - L3 往期归档（书野文苑）

struct BishenFeatureArticleArchiveView: View {
    let articles: [BishenFeatureArticle]
    let commentTotals: [String: Int]

    var body: some View {
        ZStack {
            // 蓝天草地背景（固定）
            FieldBackground()

            archiveSun
            archiveCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            archiveCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text("更多文章")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // 日期徽章（第一组用最新日期）
                        if let first = articles.first {
                            dateBadge(first)
                        }

                        LazyVStack(spacing: 10) {
                            ForEach(articles) { article in
                                VStack(alignment: .leading, spacing: 0) {
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
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 8)

                        Text("已展示全部内容 ✓")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
    }

    // 日期徽章（按月份分组）
    private func dateBadge(_ article: BishenFeatureArticle) -> some View {
        HStack(spacing: 6) {
            Text(article.monthDayText)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
            Text("· \(article.weekdayText)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 184/255, green: 200/255, blue: 170/255))
        }
        .foregroundStyle(Color(red: 240/255, green: 232/255, blue: 214/255))
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.fieldInk)
        )
        .padding(.leading, 22)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: - 背景装饰（太阳/云）

    private var archiveSun: some View {
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

    private func archiveCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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
}

// MARK: - 卡片组件（书野文苑）

// L1 文章列表卡（横排图卡）
private struct BishenFeatureArticleListCard: View {
    let article: BishenFeatureArticle
    let index: Int
    let commentCount: Int

    private var tintColors: [Color] {
        let palette: [[Color]] = [
            [Color(red: 253/255, green: 232/255, blue: 200/255), Color(red: 245/255, green: 166/255, blue: 35/255)],
            [Color(red: 228/255, green: 232/255, blue: 248/255), Color(red: 122/255, green: 143/255, blue: 216/255)],
            [Color(red: 248/255, green: 227/255, blue: 238/255), Color(red: 232/255, green: 106/255, blue: 158/255)],
            [Color(red: 214/255, green: 232/255, blue: 245/255), Color(red: 91/255, green: 168/255, blue: 217/255)]
        ]
        return palette[index % palette.count]
    }

    private var placeholderEmoji: String {
        let emojis = ["🌻", "🌊", "🌸", "🚀", "🍃", "🌙", "🎨", "📮"]
        return emojis[index % emojis.count]
    }

    var body: some View {
        HStack(spacing: 12) {
            // 渐变缩略图 + emoji 装饰（设计稿风格）
            ZStack {
                LinearGradient(colors: tintColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Text(placeholderEmoji)
                    .font(.system(size: 26))
                    .modifier(ThumbSway(delay: Double(index % 5) * 0.2))
            }
            .frame(width: 96, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(article.queryBannerDesc)
                    .font(.system(size: 13.5, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text("🏷 \(article.triggerQuery)")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMint)
                    Text(article.monthDayText)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                    Text("💬 \(article.commentCountText(count: commentCount))")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                }
            }
            Spacer(minLength: 0)
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
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 5, y: 3)
        )
    }
}

// 渐变缩略图 emoji 摆动（L1/L2/L3 共用）
private struct ThumbSway: ViewModifier {
    let delay: Double
    func body(content: Content) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate + delay
            content
                .rotationEffect(.degrees(sin(t * 2.6) * 4), anchor: .bottom)
        }
    }
}

// L2 精选评论卡
private struct BishenFeatureCommentCard: View {
    let comment: BishenFeatureComment

    private var avatarGradient: [Color] {
        let palette: [[Color]] = [
            [Color(red: 126/255, green: 211/255, blue: 160/255), AppTheme.fieldMint],
            [Color(red: 248/255, green: 167/255, blue: 196/255), Color(red: 232/255, green: 106/255, blue: 158/255)],
            [Color(red: 156/255, green: 196/255, blue: 240/255), Color(red: 91/255, green: 168/255, blue: 217/255)],
            [Color(red: 245/255, green: 200/255, blue: 107/255), Color(red: 245/255, green: 166/255, blue: 35/255)]
        ]
        let value = abs(comment.userName.hashValue) % palette.count
        return palette[value]
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: avatarGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(String(comment.userName.prefix(1)))
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 34, height: 34)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(comment.userName)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.fieldInk)
                    Spacer()
                    Text(comment.createdAtText)
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMossLight)
                }

                Text(comment.content)
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 85/255, green: 112/255, blue: 95/255))
                    .lineSpacing(5)

                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup")
                        .font(.system(size: 11, weight: .medium))
                    Text("\(comment.likeCount)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(AppTheme.fieldMint)
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 2)
                )
        )
    }
}

// L3 往期归档卡（大图卡）
private struct BishenFeatureArticleArchiveCard: View {
    let article: BishenFeatureArticle
    let commentCount: Int

    private var tintColors: [Color] {
        let palette: [[Color]] = [
            [Color(red: 253/255, green: 232/255, blue: 200/255), Color(red: 245/255, green: 166/255, blue: 35/255)],
            [Color(red: 228/255, green: 232/255, blue: 248/255), Color(red: 122/255, green: 143/255, blue: 216/255)],
            [Color(red: 214/255, green: 232/255, blue: 245/255), Color(red: 91/255, green: 168/255, blue: 217/255)],
            [Color(red: 248/255, green: 227/255, blue: 238/255), Color(red: 232/255, green: 106/255, blue: 158/255)]
        ]
        let value = abs(article.id.hashValue) % palette.count
        return palette[value]
    }

    private var placeholderEmoji: String {
        let emojis = ["🌻", "🌊", "🚀", "🌸", "🍃", "🌙"]
        let value = abs(article.id.hashValue) % emojis.count
        return emojis[value]
    }

    var body: some View {
        HStack(spacing: 12) {
            // 渐变缩略图 + emoji 装饰（设计稿风格）
            ZStack {
                LinearGradient(colors: tintColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Text(placeholderEmoji)
                    .font(.system(size: 28))
                    .modifier(ThumbSway(delay: Double(abs(article.id.hashValue) % 5) * 0.2))
            }
            .frame(width: 110, height: 74)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(article.queryBannerDesc)
                    .font(.system(size: 13, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text("🏷 \(article.triggerQuery)")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMint)
                    Text(article.releaseDateText)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                    Text("💬 \(article.commentCountText(count: commentCount))")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                }
            }
            Spacer(minLength: 0)
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
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 5, y: 3)
        )
    }
}

// L2 更多文章紧凑卡
private struct BishenFeatureArticleCompactCard: View {
    let article: BishenFeatureArticle
    let commentCount: Int

    private var tintColors: [Color] {
        let palette: [[Color]] = [
            [Color(red: 253/255, green: 232/255, blue: 200/255), Color(red: 245/255, green: 166/255, blue: 35/255)],
            [Color(red: 228/255, green: 232/255, blue: 248/255), Color(red: 122/255, green: 143/255, blue: 216/255)],
            [Color(red: 248/255, green: 227/255, blue: 238/255), Color(red: 232/255, green: 106/255, blue: 158/255)]
        ]
        let value = abs(article.id.hashValue) % palette.count
        return palette[value]
    }

    private var placeholderEmoji: String {
        let emojis = ["🌻", "🌊", "🌸", "🚀"]
        let value = abs(article.id.hashValue) % emojis.count
        return emojis[value]
    }

    var body: some View {
        HStack(spacing: 12) {
            // 渐变缩略图 + emoji 装饰（设计稿风格）
            ZStack {
                LinearGradient(colors: tintColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Text(placeholderEmoji)
                    .font(.system(size: 18))
                    .modifier(ThumbSway(delay: Double(abs(article.id.hashValue) % 4) * 0.2))
            }
            .frame(width: 52, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(article.queryBannerDesc)
                    .font(.system(size: 12.5, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text(article.monthDayText)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                    Text("💬 \(article.commentCountText(count: commentCount))")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                }
            }
            Spacer(minLength: 0)
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
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 2)
                )
        )
    }
}

// MARK: - 正文 HTML 渲染（WebView，保留原实现）

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

// MARK: - 数据格式化

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
