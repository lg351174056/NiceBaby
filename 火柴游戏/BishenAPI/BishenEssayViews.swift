import SwiftUI

struct BishenEssayHomeView: View {
    @State private var catalog: BishenAlbumsCatalog?
    @State private var selectedTag = "全部"
    @State private var selectedYear: String?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

    private var allAlbums: [BishenAlbum] {
        catalog?.albums ?? []
    }

    private var availableTags: [String] {
        let remoteTags = catalog?.tags ?? []
        let fallback = Array(
            Set(allAlbums.flatMap { $0.tags ?? [] })
        ).sorted { lhs, rhs in
            BishenDisplayMapper.tagSortIndex(for: lhs) < BishenDisplayMapper.tagSortIndex(for: rhs)
        }
        let merged = remoteTags.isEmpty ? fallback : remoteTags
        return ["全部"] + merged
    }

    private var availableYears: [String] {
        Array(
            Set(
                allAlbums
                    .filter(\.isMonthly)
                    .compactMap(\.year)
            )
        )
        .sorted(by: >)
    }

    private var filteredAlbums: [BishenAlbum] {
        let baseAlbums = allAlbums.filter { album in
            if selectedTag == "全部" {
                return true
            }
            return album.tags?.contains(selectedTag) == true
        }

        let yearFiltered: [BishenAlbum]
        if selectedTag == "月刊", let selectedYear {
            yearFiltered = baseAlbums.filter { $0.year == selectedYear }
        } else {
            yearFiltered = baseAlbums
        }

        return yearFiltered.sorted { lhs, rhs in
            let leftTime = lhs.createdAt ?? 0
            let rightTime = rhs.createdAt ?? 0
            if leftTime != rightTime {
                return leftTime > rightTime
            }
            return lhs.id > rhs.id
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            UnifiedNavBar(title: "精选文集")

            Group {
                if isLoading && allAlbums.isEmpty {
                    loadingView
                } else if let errorMessage, allAlbums.isEmpty {
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
            guard catalog == nil else { return }
            await load()
        }
        .refreshable {
            await load()
        }
    }

    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                tagSelector

                if selectedTag == "月刊", !availableYears.isEmpty {
                    yearSelector
                }

                HStack {
                    Text(summaryText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                }

                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(filteredAlbums) { album in
                        NavigationLink {
                            BishenAlbumListView(album: album)
                        } label: {
                            BishenAlbumGridCard(album: album)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !filteredAlbums.isEmpty {
                    Text("已展示全部内容")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 32)
        }
    }

    private var tagSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableTags, id: \.self) { tag in
                    Button {
                        selectTag(tag)
                    } label: {
                        Text(tag)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(selectedTag == tag ? .white : AppTheme.textSecondary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(selectedTag == tag ? AppTheme.accentYellow : AppTheme.card)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(AppTheme.separator, lineWidth: selectedTag == tag ? 0 : 1)
                            }
                            .shadow(
                                color: selectedTag == tag ? AppTheme.accentYellow.opacity(0.25) : .black.opacity(0.04),
                                radius: selectedTag == tag ? 12 : 6,
                                x: 0,
                                y: selectedTag == tag ? 8 : 4
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
    }

    private var yearSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(availableYears, id: \.self) { year in
                    Button {
                        selectedYear = year
                    } label: {
                        Text(year)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(selectedYear == year ? .white : AppTheme.textSecondary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedYear == year ? AppTheme.accentYellow : AppTheme.card)
                            )
                            .overlay {
                                Capsule()
                                    .stroke(AppTheme.separator, lineWidth: selectedYear == year ? 0 : 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var summaryText: String {
        if selectedTag == "月刊", let selectedYear {
            return "\(selectedYear) 年共 \(filteredAlbums.count) 本月刊"
        }
        if selectedTag == "全部" {
            return "共还原 \(filteredAlbums.count) 个文集"
        }
        return "\(selectedTag) 栏目共 \(filteredAlbums.count) 个文集"
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            ProgressView()
                .controlSize(.large)
                .tint(AppTheme.accentYellow)
            Text("正在还原全部文集数据...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer(minLength: 80)
            Image(systemName: "book.closed")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Text("文集加载失败")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button("重新加载") {
                Task { await load() }
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(AppTheme.accentIndigo, in: Capsule())
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
            let catalog = try await BishenEssayService.shared.fetchAllAlbumsCatalog()
            self.catalog = catalog
            errorMessage = nil

            if selectedTag == "全部", availableTags.contains("月刊") {
                selectTag("月刊")
            } else {
                syncYearSelection()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func selectTag(_ tag: String) {
        selectedTag = tag
        syncYearSelection()
    }

    private func syncYearSelection() {
        guard selectedTag == "月刊" else {
            selectedYear = nil
            return
        }

        if let selectedYear, availableYears.contains(selectedYear) {
            return
        }

        selectedYear = bestInitialYear()
    }

    private func bestInitialYear() -> String? {
        let monthlyAlbums = allAlbums.filter(\.isMonthly)
        var counts: [String: Int] = [:]
        for album in monthlyAlbums {
            guard let year = album.year else { continue }
            counts[year, default: 0] += 1
        }

        return availableYears.max { lhs, rhs in
            let leftCount = counts[lhs] ?? 0
            let rightCount = counts[rhs] ?? 0
            if leftCount != rightCount {
                return leftCount < rightCount
            }
            return lhs < rhs
        }
    }
}

struct BishenAlbumListView: View {
    let album: BishenAlbum

    @State private var articles: [BishenArticleSummary] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        albumHeader(topInset: proxy.safeAreaInsets.top)
                        
                        Group {
                            if isLoading && articles.isEmpty {
                                loadingView
                            } else if let errorMessage, articles.isEmpty {
                                errorView(message: errorMessage)
                            } else {
                                articleListView
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }

                floatingNavigationBar(topInset: proxy.safeAreaInsets.top)
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

    private var articleListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("全部作文")
                .font(.system(size: 20, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                    NavigationLink {
                        BishenEssayDetailView(articleID: article.id, initialTitle: article.title)
                    } label: {
                        BishenArticleListCard(article: article, index: index + 1)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index != articles.count - 1 {
                        Divider()
                            .padding(.leading, 22)
                    }
                }
            }
            .padding(.bottom, 10)
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .offset(y: -14)
        .padding(.horizontal, 0)
        .padding(.bottom, 4)
    }

    private func albumHeader(topInset: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 70 / 255, green: 166 / 255, blue: 206 / 255),
                            Color(red: 196 / 255, green: 210 / 255, blue: 224 / 255),
                            Color(red: 219 / 255, green: 187 / 255, blue: 104 / 255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            AsyncImage(url: URL(string: album.coverURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 32)
                    .opacity(0.48)
            } placeholder: {
                Color.clear
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            LinearGradient(
                colors: [
                    Color.white.opacity(0.28),
                    Color.white.opacity(0.10),
                    Color.black.opacity(0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(alignment: .center, spacing: 16) {
                AsyncImage(url: URL(string: album.coverURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.28))
                }
                .frame(width: 108, height: 144)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.82), lineWidth: 1.6)
                }
                .shadow(color: .black.opacity(0.16), radius: 14, y: 8)

                VStack(alignment: .leading, spacing: 10) {
                    Text(album.title)
                        .font(.system(size: 22, weight: .heavy, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(album.desc)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.86))
                        .lineSpacing(5)
                        .lineLimit(2)

                    Text("共\(album.count)篇")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    if let countNew = album.countNew, countNew > 0 {
                        Text("新增 \(countNew) 篇")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.14), in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 18)
            .padding(.top, topInset + 28)
            .padding(.bottom, 26)
        }
        .frame(height: topInset + 224)
    }

    private func floatingNavigationBar(topInset: CGFloat) -> some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, topInset - 48)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView("正在加载文集内容...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .tint(AppTheme.accentIndigo)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(AppTheme.accentCinnabar)
            Text("文集详情加载失败")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    @MainActor
    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            articles = try await BishenEssayService.shared.fetchAllAlbumArticles(albumID: album.id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct BishenEssayDetailView: View {
    let articleID: String
    let initialTitle: String

    @State private var detail: BishenArticleDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            UnifiedNavBar(
                title: "作文详情",
                trailing: AnyView(
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.card, in: Circle())
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                )
            )

            Group {
                if isLoading && detail == nil {
                    loadingView
                } else if let detail {
                    detailView(detail)
                } else {
                    errorView(message: errorMessage ?? "详情暂时加载失败")
                }
            }
        }
        .background(BishenDisplayMapper.detailBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .task {
            guard detail == nil else { return }
            await load()
        }
        .refreshable {
            await load()
        }
    }

    private func detailView(_ detail: BishenArticleDetail) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                authorHeader(detail)
                articleHeader(detail)
                articleContent(detail)
                critiqueSection(detail)
                bottomActionBar(detail)
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
    }

    private func authorHeader(_ detail: BishenArticleDetail) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(BishenDisplayMapper.avatarGradient(for: detail.author))
                .frame(width: 54, height: 54)
                .overlay {
                    Text(String(detail.authorDisplay.prefix(1)))
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(detail.authorDisplay)
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)

                    if let reviewTag = detail.reviewTag, !reviewTag.isEmpty {
                        Text(reviewTag)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.accentCinnabar, in: Capsule())
                    }
                }

                Text(detail.publishLine)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            if let score = detail.score {
                HStack(spacing: 6) {
                    Text("评")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(AppTheme.accentJade, in: Circle())
                    Text("\(score)分")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 2)
    }

    private func articleHeader(_ detail: BishenArticleDetail) -> some View {
        VStack(spacing: 12) {
            Text(detail.title)
                .font(.system(size: 31, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                if let grade = detail.gradeDisplay {
                    BishenMetaTag(title: grade, color: AppTheme.accentJade)
                }
                if let category = detail.categoryDisplay {
                    BishenMetaTag(title: category, color: AppTheme.accentIndigo)
                }
                if let source = detail.sourceDisplay {
                    BishenMetaTag(title: source, color: AppTheme.accentCinnabar)
                }
            }

            if let albumTitle = detail.albumTitle, !albumTitle.isEmpty {
                Text(albumTitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private func articleContent(_ detail: BishenArticleDetail) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(detail.paragraphs.indices, id: \.self) { index in
                Text(detail.paragraphs[index])
                    .font(.system(size: 21, weight: .regular, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineSpacing(14)
                    .tracking(0.3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, index == 0 ? 0 : 14)
            }
        }
        .padding(.top, 4)
    }

    private func critiqueSection(_ detail: BishenArticleDetail) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text("笔神点评")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.accentJade, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                if let reviewTag = detail.reviewTag, !reviewTag.isEmpty {
                    Text(reviewTag)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accentJade)
                }
            }

            Text(detail.critiqueText)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.top, 8)
    }

    private func bottomActionBar(_ detail: BishenArticleDetail) -> some View {
        HStack(spacing: 12) {
            Text(detail.commentsSummary)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.65), in: Capsule())

            BishenBottomStat(icon: "hand.thumbsup", value: detail.likeSummary, tint: AppTheme.accentJade)
            BishenBottomStat(icon: "star", value: "收藏", tint: AppTheme.accentJade)
            BishenBottomStat(icon: "square.and.arrow.up", value: "分享", tint: AppTheme.accentJade)
        }
        .padding(.horizontal, 4)
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            ProgressView()
                .controlSize(.large)
                .tint(AppTheme.accentYellow)
            Text("正在加载作文详情...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Text(initialTitle)
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
            detail = try await BishenEssayService.shared.fetchArticleDetail(id: articleID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct BishenAlbumGridCard: View {
    let album: BishenAlbum

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: album.coverURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                LinearGradient(
                    colors: [AppTheme.accentYellow.opacity(0.24), AppTheme.accentIndigo.opacity(0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.76, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if let countNew = album.countNew, countNew > 0 {
                    Text("+\(countNew)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.accentCinnabar, in: Capsule())
                        .padding(8)
                }
            }

            Text(album.title)
                .font(.system(size: 16, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)

            HStack(spacing: 4) {
                Text("共 \(album.count) 篇")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                if let countNew = album.countNew, countNew > 0 {
                    Text("+\(countNew)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.accentCinnabar)
                }
            }
        }
    }
}

private struct BishenArticleListCard: View {
    let article: BishenArticleSummary
    let index: Int

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                Text(article.title)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(article.authorDisplayForList)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
            if index <= 3 {
                Text("\(index)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.accentYellow)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }
}

private struct BishenMetaTag: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.10), in: Capsule())
    }
}

private struct BishenCapsuleLabel: View {
    let title: String
    let textColor: Color
    let fillColor: Color

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(fillColor, in: Capsule())
    }
}

private struct BishenBottomStat: View {
    let icon: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundStyle(tint)
        .frame(width: 54)
    }
}

private extension BishenAlbum {
    var isMonthly: Bool {
        tags?.contains("月刊") == true || typeCode == "issue"
    }
}

private extension BishenArticleSummary {
    var gradeDisplay: String? { BishenDisplayMapper.gradeName(for: grade) }
    var categoryDisplay: String? { BishenDisplayMapper.categoryName(for: subCategory) }

    var authorDisplayForList: String {
        author.isEmpty ? "佚名" : author
    }
}

private extension BishenArticleDetail {
    var paragraphs: [String] {
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let lines = normalized
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.isEmpty ? [content] : lines
    }

    var gradeDisplay: String? { BishenDisplayMapper.gradeName(for: grade) }
    var categoryDisplay: String? { BishenDisplayMapper.categoryName(for: subCategory) }

    var authorDisplay: String {
        author.isEmpty ? "佚名" : author
    }

    var publishLine: String {
        let dateText = publishedAt.map(BishenDisplayMapper.dateTimeText(for:)) ?? "未知时间"
        return "\(dateText) 发布"
    }

    var sourceDisplay: String? {
        BishenDisplayMapper.sourceName(for: source)
    }

    var commentsDisplay: String {
        if let comments, !comments.isEmpty {
            return comments
        }
        return "暂无评论"
    }

    var commentsSummary: String {
        let digits = commentsDisplay.filter(\.isNumber)
        if let count = Int(digits), count > 0 {
            return "\(count)条评论"
        }
        return "暂无评论"
    }

    var likeSummary: String {
        guard let score else { return "--" }
        if score >= 95 { return "2.8k" }
        if score >= 90 { return "2.5k" }
        if score >= 85 { return "1.8k" }
        return "839"
    }

    var critiqueText: String {
        let theme = categoryDisplay ?? "主题"
        let tone = reviewTag?.isEmpty == false ? reviewTag! : "表达自然"
        let scoreLine: String
        if let score {
            scoreLine = score >= 90 ? "文章主题明确，结构完整，内容具体，整体完成度很高。" : "文章主题比较清晰，内容完整，已经具备较好的表达基础。"
        } else {
            scoreLine = "文章主题明确，内容完整，行文节奏自然。"
        }

        return [
            scoreLine,
            "围绕「\(theme)」展开时，细节描写和情绪推进都比较顺畅，读起来有画面感，也能让人感受到作者想表达的重点。",
            "当前最突出的特点是「\(tone)」，如果结尾再补一层回扣主题或情绪收束，整篇文章会更耐读。"
        ].joined(separator: "")
    }
}

private enum BishenDisplayMapper {
    static let detailBackground = Color(red: 243 / 255, green: 244 / 255, blue: 246 / 255)

    static func gradeName(for raw: String?) -> String? {
        switch raw {
        case "g1": return "一年级"
        case "g2": return "二年级"
        case "g3": return "三年级"
        case "g4": return "四年级"
        case "g5": return "五年级"
        case "g6": return "六年级"
        case "g7": return "七年级"
        case "g8": return "八年级"
        case "g9": return "九年级"
        case "g10": return "高一"
        case "g11": return "高二"
        case "g12": return "高三"
        default: return nil
        }
    }

    static func categoryName(for raw: String?) -> String? {
        switch raw {
        case "xieren": return "写人"
        case "xushi": return "叙事"
        case "xiejing": return "写景"
        case "zhuangwu": return "状物"
        case "xiangxiang": return "想象"
        case "riji": return "日记"
        case "shuxin": return "书信"
        case "duhougan": return "读后感"
        case "sanwen": return "散文"
        case "yingyong": return "应用"
        case "yilun": return "议论"
        default: return nil
        }
    }

    static func sourceName(for raw: String?) -> String? {
        switch raw {
        case "contrib": return "精选投稿"
        case "default": return "官方整理"
        case "DEFAULT": return "官方整理"
        default: return nil
        }
    }

    nonisolated static func dateTimeText(for timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    static func avatarGradient(for seed: String) -> LinearGradient {
        let palette: [[Color]] = [
            [AppTheme.accentIndigo, AppTheme.accentJade],
            [AppTheme.accentCinnabar, AppTheme.accentYellow],
            [AppTheme.accentInkPurple, AppTheme.accentIndigo],
            [AppTheme.accentJade, AppTheme.accentSage]
        ]
        let value = abs(seed.hashValue) % palette.count
        return LinearGradient(colors: palette[value], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func tagSortIndex(for tag: String) -> Int {
        let order = [
            "月刊", "抒情", "季节", "应用", "节日",
            "写人", "叙事", "想象", "议论", "散文", "状物", "写景"
        ]
        return order.firstIndex(of: tag) ?? 999
    }
}
