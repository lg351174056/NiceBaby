import SwiftUI

struct BishenEssayHomeView: View {
    @Environment(\.dismiss) private var dismiss
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
                        // 写作花园主题头
                        gardenHeader

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
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.9), in: Circle())
                        .overlay(
                            Circle().strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35), lineWidth: 2)
                        )
                        .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.12), radius: 4, y: 2)
                }
                Spacer()
            }
            Text("精选文集")
                .font(.system(size: 16, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }

    // MARK: - 写作花园主题头（紧凑二级页头部）

    private var gardenHeader: some View {
        HStack(spacing: 12) {
            // 向日葵（摇摆）
            Text("🌻")
                .font(.system(size: 34))
                .modifier(GardenSway(delay: 0))

            VStack(alignment: .leading, spacing: 3) {
                Text("写作花园")
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Text("每篇好作文，都是开在纸上的花")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }
            Spacer()
            // 蝴蝶蜜蜂扑翅
            HStack(spacing: 6) {
                Text("🦋").font(.system(size: 15)).modifier(GardenFlutter(delay: 0, reverse: false))
                Text("🐝").font(.system(size: 15)).modifier(GardenFlutter(delay: 1.0, reverse: true))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.12), radius: 8, y: 4)
        )
        .padding(.horizontal, 18)
        .padding(.top, 10)
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

    private struct GardenSway: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .rotationEffect(.degrees(sin(t * 2.4) * 5), anchor: .bottom)
            }
        }
    }

    private struct GardenFlutter: ViewModifier {
        let delay: Double
        let reverse: Bool
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(x: CGFloat(sin(t * 1.8) * 3), y: CGFloat(sin(t * 2.4) * 4))
                    .rotationEffect(.degrees((reverse ? -1 : 1) * sin(t * 3) * 6))
            }
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            tagSelector

            if selectedTag == "月刊", !availableYears.isEmpty {
                yearSelector
            }

            // 分区标题
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color(red: 76/255, green: 175/255, blue: 125/255))
                    .frame(width: 6, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                Text(selectedTag == "月刊" ? "花园月刊" : "花园花圃")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Spacer()
                Text(summaryText)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 10)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(filteredAlbums) { album in
                    NavigationLink {
                        BishenAlbumListView(album: album)
                    } label: {
                        BishenAlbumGridCard(album: album)
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
                                        lineWidth: selectedTag == tag ? 2 : 2
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
        VStack(spacing: 12) {
            ProgressView("正在浇灌花园...")
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
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.9), in: Circle())
                                .overlay(Circle().strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35), lineWidth: 2))
                                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.12), radius: 4, y: 2)
                        }
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
                        gardenSign

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
            Text("🦋").font(.system(size: 16)).modifier(GardenFlutter(delay: 0, reverse: false))
            Text("🐝").font(.system(size: 15)).modifier(GardenFlutter(delay: 1.2, reverse: true))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.trailing, 24)
        .padding(.top, 140)
        .allowsHitTesting(false)
    }

    private struct GardenFlutter: ViewModifier {
        let delay: Double
        let reverse: Bool
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(x: CGFloat(sin(t * 1.8) * 3), y: CGFloat(sin(t * 2.4) * 4))
                    .rotationEffect(.degrees((reverse ? -1 : 1) * sin(t * 3) * 6))
            }
        }
    }

    private struct GardenBloom: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .rotationEffect(.degrees(sin(t * 2.6) * 5), anchor: .bottom)
            }
        }
    }

    // 花园立牌头（花朵圆牌 + 标题 + meta）
    private var gardenSign: some View {
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
                    .modifier(GardenBloom(delay: 0))
            }
            .frame(width: 60, height: 60)
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
            ProgressView("正在浇灌花园...")
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
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.9), in: Circle())
                                .overlay(Circle().strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35), lineWidth: 2))
                                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.12), radius: 4, y: 2)
                        }
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
            Text("🦋").font(.system(size: 16)).modifier(DetailFlutter(delay: 0, reverse: false))
            Text("🐝").font(.system(size: 15)).modifier(DetailFlutter(delay: 1.2, reverse: true))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.trailing, 24)
        .padding(.top, 140)
        .allowsHitTesting(false)
    }

    private struct DetailFlutter: ViewModifier {
        let delay: Double
        let reverse: Bool
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(x: CGFloat(sin(t * 1.8) * 3), y: CGFloat(sin(t * 2.4) * 4))
                    .rotationEffect(.degrees((reverse ? -1 : 1) * sin(t * 3) * 6))
            }
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

    private var flowerEmoji: String {
        let flowers = ["🌷", "🌼", "🌹", "🌺", "🌸", "🌻"]
        let seed = abs(album.id.hashValue)
        return flowers[seed % flowers.count]
    }

    private var tint: Color {
        let colors: [Color] = [
            Color(red: 234/255, green: 246/255, blue: 228/255),
            Color(red: 248/255, green: 232/255, blue: 240/255),
            Color(red: 232/255, green: 240/255, blue: 248/255),
            Color(red: 248/255, green: 240/255, blue: 224/255),
        ]
        return colors[abs(album.id.hashValue) % colors.count]
    }

    var body: some View {
        VStack(spacing: 5) {
            // 花朵图标（摇摆）
            Text(flowerEmoji)
                .font(.system(size: 26))
                .modifier(FlowerSway(delay: Double(abs(album.id.hashValue) % 5) * 0.2))

            Text(album.title)
                .font(.system(size: 12, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(spacing: 4) {
                Text("共 \(album.count) 篇")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                if let countNew = album.countNew, countNew > 0 {
                    Text("+\(countNew)")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 176/255, green: 138/255, blue: 62/255))
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.1), radius: 6, y: 3)
        )
    }

    private struct FlowerSway: ViewModifier {
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
                    .font(.system(size: 14, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .lineLimit(2)
                Text(article.authorDisplayForList)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
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
