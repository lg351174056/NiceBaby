import SwiftUI

// MARK: - 小学作文精选 · L1 精选文集主页（书野学堂）

struct BishenEssayHomeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var catalog: BishenAlbumsCatalog?
    @State private var dailyArticle: BishenArticleSummary?
    @State private var selectedTag = "全部"
    @State private var selectedYear: String?
    @State private var isLoading = true
    @State private var errorMessage: String?

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

    // 本月精选已移除：与全部文集是包含关系，会导致分类重复出现
    // 统一只展示全部文集，用封面大卡让页面更饱满

    var body: some View {
        ZStack {
            // 蓝天草地背景（固定）
            LinearGradient(
                colors: [
                    Color(red: 190/255, green: 227/255, blue: 245/255),
                    Color(red: 220/255, green: 242/255, blue: 220/255),
                    Color(red: 207/255, green: 235/255, blue: 196/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            gardenSun
            gardenCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            gardenCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条：返回 + 居中标题，蓝天通屏
                transparentNavBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroHeader

                        if let dailyArticle {
                            dailyCard(dailyArticle)
                                .padding(.top, 12)
                        }

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
                    .padding(.bottom, 20)
                }
            }
        }
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

    // 透明导航条（返回 + 居中标题）
    private var transparentNavBar: some View {
        ZStack {
            HStack {
                GracefulBackButton()
                Spacer()
            }
            Text("小学作文精选")
                .font(.system(size: 16, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }

    // MARK: - 主题头（书野学堂）

    private var heroHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 255/255, green: 235/255, blue: 210/255),
                            Color(red: 245/255, green: 200/255, blue: 150/255)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("✍️")
                    .font(.system(size: 24))
                    .modifier(FieldBob(delay: 0.3))
            }
            .frame(width: 52, height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(red: 200/255, green: 160/255, blue: 80/255).opacity(0.4), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("小学作文精选")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Text("1~6 年级 · 好词好句，学会写作的第一步")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                HStack(spacing: 12) {
                    Text("📚 \(allAlbums.count) 册文集")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                    Text("✨ 每日更新")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 176/255, green: 138/255, blue: 62/255))
                }
                .padding(.top, 1)
            }
            Spacer()
            // 叶片 + 蝴蝶动效
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
                        .strokeBorder(Color(red: 200/255, green: 160/255, blue: 80/255).opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color(red: 120/255, green: 90/255, blue: 30/255).opacity(0.1), radius: 8, y: 4)
        )
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }

    // MARK: - 每日一文横卡

    private func dailyCard(_ article: BishenArticleSummary) -> some View {
        NavigationLink {
            BishenEssayDetailView(articleID: article.id, initialTitle: article.title)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(colors: [
                                Color(red: 255/255, green: 217/255, blue: 122/255),
                                Color(red: 245/255, green: 166/255, blue: 35/255)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Text("🌞")
                        .font(.system(size: 21))
                        .modifier(FieldBob(delay: 0.2))
                }
                .frame(width: 44, height: 44)
                .shadow(color: Color(red: 245/255, green: 166/255, blue: 35/255).opacity(0.4), radius: 6, y: 3)

                VStack(alignment: .leading, spacing: 3) {
                    Text("每日一文 · \(BishenDisplayMapper.currentDayText())")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 176/255, green: 130/255, blue: 50/255))
                    Text("《\(article.title)》")
                        .font(.system(size: 14, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 92/255, green: 74/255, blue: 38/255))
                        .lineLimit(1)
                    Text(article.preview ?? article.authorDisplayForList)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 154/255, green: 134/255, blue: 85/255))
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 201/255, green: 162/255, blue: 75/255))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 255/255, green: 246/255, blue: 227/255),
                            Color(red: 255/255, green: 233/255, blue: 196/255)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color(red: 200/255, green: 160/255, blue: 80/255).opacity(0.35), lineWidth: 2)
                    )
                    .shadow(color: Color(red: 120/255, green: 90/255, blue: 30/255).opacity(0.1), radius: 8, y: 4)
            )
            .padding(.horizontal, 18)
        }
        .buttonStyle(.plain)
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

    private struct FieldBob: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(y: CGFloat(sin(t * 2.2) * 4.0))
            }
        }
    }

    private struct FieldFlutter: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(x: CGFloat(sin(t * 1.8) * 3), y: CGFloat(sin(t * 2.4) * 4))
                    .rotationEffect(.degrees(sin(t * 3) * 6))
            }
        }
    }

    // MARK: - 内容区

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            tagSelector

            if selectedTag == "月刊", !availableYears.isEmpty {
                yearSelector
            }

            // 全部文集（单列表：两列封面大卡，避免分类重复出现）
            sectionTitle(
                title: "全部文集",
                countText: "共 \(filteredAlbums.count) 册"
            )

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(filteredAlbums) { album in
                    NavigationLink {
                        BishenAlbumListView(album: album)
                    } label: {
                        BookCoverCard(album: album)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)

            if !filteredAlbums.isEmpty {
                Text("已展示全部内容 ✓")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
            }
        }
    }

    private func sectionTitle(title: String, countText: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color(red: 76/255, green: 175/255, blue: 125/255))
                .frame(width: 6, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            Spacer()
            Text(countText)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    private var tagSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableTags, id: \.self) { tag in
                    Button {
                        selectTag(tag)
                    } label: {
                        Text(tag)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(selectedTag == tag ? .white : Color(red: 74/255, green: 92/255, blue: 66/255))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(selectedTag == tag
                                        ? Color(red: 76/255, green: 175/255, blue: 125/255)
                                        : Color.white.opacity(0.85))
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(
                                        selectedTag == tag ? Color(red: 61/255, green: 74/255, blue: 54/255)
                                            : Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35),
                                        lineWidth: 2
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
    }

    private var yearSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableYears, id: \.self) { year in
                    Button {
                        selectedYear = year
                    } label: {
                        Text(year)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(selectedYear == year ? Color(red: 240/255, green: 232/255, blue: 214/255)
                                : Color(red: 138/255, green: 154/255, blue: 122/255))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedYear == year
                                        ? Color(red: 61/255, green: 74/255, blue: 54/255)
                                        : Color.white.opacity(0.7))
                            )
                            .overlay {
                                Capsule()
                                    .strokeBorder(
                                        Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.4),
                                        style: StrokeStyle(lineWidth: 1.5, dash: selectedYear == year ? [] : [4, 3])
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView("正在翻开书页...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .tint(Color(red: 76/255, green: 175/255, blue: 125/255))
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color(red: 176/255, green: 138/255, blue: 62/255))
            Text("书摊暂时打不开")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                .multilineTextAlignment(.center)
            Button("重新翻书") {
                Task { await load() }
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(red: 76/255, green: 175/255, blue: 125/255), in: Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    @MainActor
    private func load() async {
        isLoading = true
        defer { isLoading = false }

        async let catalogTask: BishenAlbumsCatalog = BishenEssayService.shared.fetchAllAlbumsCatalog()
        async let dailyTask: [BishenArticleSummary] = BishenEssayService.shared.fetchDailyRecommendations()

        do {
            let (catalog, daily) = try await (catalogTask, dailyTask)
            self.catalog = catalog
            dailyArticle = daily.first
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

// MARK: - 文集封面大卡（L1 两列网格）

private struct BookCoverCard: View {
    let album: BishenAlbum

    private var coverGradient: [Color] {
        let palette: [[Color]] = [
            [Color(red: 255/255, green: 238/255, blue: 216/255), Color(red: 248/255, green: 204/255, blue: 152/255)],
            [Color(red: 227/255, green: 242/255, blue: 234/255), Color(red: 189/255, green: 232/255, blue: 211/255)],
            [Color(red: 232/255, green: 240/255, blue: 248/255), Color(red: 168/255, green: 200/255, blue: 232/255)],
            [Color(red: 245/255, green: 232/255, blue: 245/255), Color(red: 222/255, green: 190/255, blue: 226/255)]
        ]
        let seed = abs(album.id.hashValue)
        return palette[seed % palette.count]
    }

    private var bookEmoji: String {
        let books = ["📕", "📗", "📘", "📙", "📓", "📔"]
        let seed = abs(album.id.hashValue)
        return books[seed % books.count]
    }

    private var coverTag: String {
        if album.isMonthly {
            return "月刊"
        }
        return album.tags?.first(where: { $0 != "月刊" }) ?? "作文选集"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 封面区（渐变 + 书本 + 标签 + NEW）
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: coverGradient, startPoint: .topLeading, endPoint: .bottomTrailing)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(bookEmoji)
                            .font(.system(size: 24))
                            .modifier(BookBob(delay: Double(abs(album.id.hashValue) % 5) * 0.2))
                        Spacer()
                        if let countNew = album.countNew, countNew > 0 {
                            Text("NEW")
                                .font(.system(size: 8, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color(red: 232/255, green: 106/255, blue: 158/255), in: Capsule())
                        }
                    }
                    Text(coverTag)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255).opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.55), in: Capsule())
                }
                .padding(10)
            }
            .frame(height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 1.5)
            )

            // 信息区
            VStack(alignment: .leading, spacing: 3) {
                Text(album.title)
                    .font(.system(size: 13, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .lineLimit(1)

                if !album.desc.isEmpty {
                    Text(album.desc)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Text("\(album.count) 篇")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                    if let year = album.year, album.isMonthly {
                        Text(year)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 176/255, green: 138/255, blue: 62/255))
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.25), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.1), radius: 6, y: 3)
        )
    }

    private struct BookBob: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(y: CGFloat(sin(t * 2.2) * 3.5))
            }
        }
    }
}

// MARK: - L2 文集作文列表

struct BishenAlbumListView: View {
    let album: BishenAlbum

    @State private var articles: [BishenArticleSummary] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // 蓝天草地背景（固定）
            LinearGradient(
                colors: [
                    Color(red: 190/255, green: 227/255, blue: 245/255),
                    Color(red: 220/255, green: 242/255, blue: 220/255),
                    Color(red: 207/255, green: 235/255, blue: 196/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            listSun
            listCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            listCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)
            listFlutter

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text(album.title)
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                        .lineLimit(1)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        albumHeadCard

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

    // MARK: - 背景装饰（太阳/云/蝴蝶蜜蜂）

    private var listSun: some View {
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

    private func listCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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

    // 蝴蝶蜜蜂（右上）
    private var listFlutter: some View {
        ZStack {
            Text("🦋").font(.system(size: 16)).modifier(Flutter(delay: 0))
            Text("🐝").font(.system(size: 15)).modifier(Flutter(delay: 1.2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.trailing, 24)
        .padding(.top, 140)
        .allowsHitTesting(false)
    }

    private struct Flutter: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(x: CGFloat(sin(t * 1.8) * 3), y: CGFloat(sin(t * 2.4) * 4))
                    .rotationEffect(.degrees(sin(t * 3) * 6))
            }
        }
    }

    private struct Bloom: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .rotationEffect(.degrees(sin(t * 2.6) * 5), anchor: .bottom)
            }
        }
    }

    // 文集头卡（花朵圆牌 + 标题 + meta）
    private var albumHeadCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 248/255, green: 232/255, blue: 216/255),
                            Color(red: 240/255, green: 200/255, blue: 168/255)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("🌷")
                    .font(.system(size: 28))
                    .modifier(Bloom(delay: 0))
            }
            .frame(width: 58, height: 58)
            .overlay(
                Circle().strokeBorder(Color(red: 176/255, green: 138/255, blue: 94/255).opacity(0.35), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.system(size: 17, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .lineLimit(2)
                Text(album.desc.isEmpty ? "精选优秀小学生作文" : album.desc)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                    .lineLimit(2)
                HStack(spacing: 12) {
                    Text("🌼 \(album.count) 朵")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                    if let countNew = album.countNew, countNew > 0 {
                        Text("✨ 新开 \(countNew)")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 176/255, green: 138/255, blue: 62/255))
                    }
                }
                .padding(.top, 2)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.12), radius: 8, y: 4)
        )
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }

    private var articleListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 分区标题
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color(red: 76/255, green: 175/255, blue: 125/255))
                    .frame(width: 6, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                Text("花园里的作文")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Spacer()
                Text("\(articles.count) 朵")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            LazyVStack(spacing: 10) {
                ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                    NavigationLink {
                        BishenEssayDetailView(articleID: article.id, initialTitle: article.title)
                    } label: {
                        BishenArticleListCard(article: article, index: index + 1)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 6)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView("正在翻开花园...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .tint(Color(red: 76/255, green: 175/255, blue: 125/255))
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color(red: 176/255, green: 138/255, blue: 62/255))
            Text("花园暂时打不开")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                .multilineTextAlignment(.center)
            Button("重新浇灌") {
                Task { await load() }
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(red: 76/255, green: 175/255, blue: 125/255), in: Capsule())
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

// MARK: - L3 作文详情（书野学堂）

struct BishenEssayDetailView: View {
    let articleID: String
    let initialTitle: String

    @State private var detail: BishenArticleDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // 蓝天草地背景（固定）
            LinearGradient(
                colors: [
                    Color(red: 190/255, green: 227/255, blue: 245/255),
                    Color(red: 220/255, green: 242/255, blue: 220/255),
                    Color(red: 207/255, green: 235/255, blue: 196/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            detailSun
            detailCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            detailCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)
            detailFlutter

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.9), in: Circle())
                            .overlay(Circle().strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35), lineWidth: 2))
                    }
                    Text("作文详情")
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

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
        }
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

    // MARK: - 背景装饰（太阳/云/蝴蝶）

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

    // 蝴蝶蜜蜂（右上）
    private var detailFlutter: some View {
        ZStack {
            Text("🦋").font(.system(size: 16)).modifier(DetailFlutter(delay: 0))
            Text("🐝").font(.system(size: 15)).modifier(DetailFlutter(delay: 1.2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.trailing, 24)
        .padding(.top, 140)
        .allowsHitTesting(false)
    }

    private struct DetailFlutter: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(x: CGFloat(sin(t * 1.8) * 3), y: CGFloat(sin(t * 2.4) * 4))
                    .rotationEffect(.degrees(sin(t * 3) * 6))
            }
        }
    }

    private func detailView(_ detail: BishenArticleDetail) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                paperCard(detail)
                bottomActionBar(detail)
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
    }

    // 纸张容器
    private func paperCard(_ detail: BishenArticleDetail) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            authorHeader(detail)
            articleHeader(detail)
            articleContent(detail)
            critiqueSection(detail)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.12), radius: 8, y: 4)
        )
    }

    private func authorHeader(_ detail: BishenArticleDetail) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(BishenDisplayMapper.avatarGradient(for: detail.author))
                .frame(width: 46, height: 46)
                .overlay {
                    Text(String(detail.authorDisplay.prefix(1)))
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(detail.authorDisplay)
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Text(detail.publishLine)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }

            Spacer()

            if let score = detail.score {
                HStack(spacing: 6) {
                    Text("评")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(AppTheme.accentJade, in: Circle())
                    Text("\(score) 分")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(red: 238/255, green: 247/255, blue: 238/255), in: Capsule())
                .overlay(
                    Capsule().strokeBorder(AppTheme.accentJade.opacity(0.4), lineWidth: 1.5)
                )
            }
        }
    }

    private func articleHeader(_ detail: BishenArticleDetail) -> some View {
        VStack(spacing: 12) {
            Text(detail.title)
                .font(.system(size: 27, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
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
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 14)
    }

    private func articleContent(_ detail: BishenArticleDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(detail.paragraphs.indices, id: \.self) { index in
                Text(detail.paragraphs[index])
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .lineSpacing(16)
                    .tracking(0.3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, 16)
    }

    private func critiqueSection(_ detail: BishenArticleDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("笔神点评")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.accentJade, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                if let reviewTag = detail.reviewTag, !reviewTag.isEmpty {
                    Text("· \(reviewTag)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 46/255, green: 125/255, blue: 91/255))
                }
            }

            Text(detail.critiqueText)
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 85/255, green: 112/255, blue: 95/255))
                .lineSpacing(7)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(red: 238/255, green: 247/255, blue: 238/255).opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.35), lineWidth: 2)
        )
        .padding(.top, 16)
    }

    private func bottomActionBar(_ detail: BishenArticleDetail) -> some View {
        HStack(spacing: 12) {
            Text("💬 \(detail.commentsSummary)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.7), in: Capsule())
                .overlay(
                    Capsule().strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.25), lineWidth: 1.5)
                )

            actionStat(icon: "hand.thumbsup", label: "点赞")
            actionStat(icon: "star", label: "收藏")
            actionStat(icon: "square.and.arrow.up", label: "分享")
        }
    }

    private func actionStat(icon: String, label: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
            Text(label)
                .font(.system(size: 8.5, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(AppTheme.accentJade)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
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

// MARK: - 文章列表卡（L2）

private struct BishenArticleListCard: View {
    let article: BishenArticleSummary
    let index: Int

    // 花朵图标轮换（不重复），序号对应
    private var bloomEmoji: String {
        let blooms = ["🌱", "🌸", "🌼", "🌷", "🌹", "🌺", "🌻", "🍀", "🦋", "🌿", "🌻", "🌷"]
        return blooms[(index - 1) % blooms.count]
    }

    private var tint: Color {
        let colors: [Color] = [
            Color(red: 234/255, green: 246/255, blue: 228/255),
            Color(red: 248/255, green: 232/255, blue: 240/255),
            Color(red: 232/255, green: 240/255, blue: 248/255),
            Color(red: 248/255, green: 240/255, blue: 224/255),
        ]
        return colors[(index - 1) % colors.count]
    }

    var body: some View {
        HStack(spacing: 12) {
            // 花朵圆标（摇摆，相位错开）
            ZStack {
                Circle()
                    .fill(tint)
                Text(bloomEmoji)
                    .font(.system(size: 17))
                    .modifier(BloomSway(delay: Double(index % 6) * 0.3))
            }
            .frame(width: 42, height: 42)
            .overlay(
                Circle().strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(article.title)
                    .font(.system(size: 13.5, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .lineLimit(2)
                HStack(spacing: 8) {
                    if let grade = article.gradeDisplay {
                        Text(grade)
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                    }
                    if let category = article.categoryDisplay {
                        Text(category)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                    }
                    if article.gradeDisplay == nil, article.categoryDisplay == nil {
                        Text(article.authorDisplayForList)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(red: 160/255, green: 176/255, blue: 152/255))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.25), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 5, y: 3)
        )
    }

    private struct BloomSway: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .rotationEffect(.degrees(sin(t * 2.6) * 4), anchor: .bottom)
            }
        }
    }
}

// MARK: - 通用小组件

private struct BishenMetaTag: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(color.opacity(0.10), in: Capsule())
            .overlay(
                Capsule().strokeBorder(color.opacity(0.35), lineWidth: 1.5)
            )
    }
}

// MARK: - 数据映射

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
        case "default", "DEFAULT": return "官方整理"
        default: return nil
        }
    }

    nonisolated static func dateTimeText(for timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    nonisolated static func currentDayText(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
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
