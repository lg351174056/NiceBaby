import SwiftUI

struct VideoSeriesListView: View {
    let category: VideoCategory
    @State private var seriesList: [VideoSeries] = []
    @State private var isLoading = false

    var body: some View {
        ZStack {
            // 蓝天草地背景（书野营地竹青风）
            LinearGradient(
                colors: [
                    Color(red: 190/255, green: 227/255, blue: 245/255),
                    Color(red: 220/255, green: 242/255, blue: 220/255),
                    Color(red: 207/255, green: 235/255, blue: 196/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            seriesSun
            seriesCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            seriesCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text(category.name)
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                        .lineLimit(1)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                Group {
                    if isLoading {
                        ProgressView("正在加载...")
                            .tint(Color(red: 76/255, green: 175/255, blue: 125/255))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if seriesList.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 40))
                                .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
                            Text("暂无系列")
                                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        seriesContent
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .task {
            if seriesList.isEmpty {
                isLoading = true
                seriesList = await VideoAPIService.shared.fetchSeries(sortId: category.id)
                isLoading = false
            }
        }
    }

    private var seriesContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if seriesList.count > 3 {
                    featuredSection
                }

                allSeriesSection
            }
            .padding(.bottom, 30)
        }
    }

    // MARK: - 精选推荐横向滚动

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("精选推荐", countText: nil)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(seriesList.prefix(6)) { series in
                        NavigationLink(destination: VideoEpisodeListView(series: series)) {
                            FeaturedSeriesCard(series: series)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    // MARK: - 全部系列

    private var allSeriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("全部系列", countText: "\(seriesList.count) 部")

            LazyVStack(spacing: 10) {
                ForEach(seriesList) { series in
                    NavigationLink(destination: VideoEpisodeListView(series: series)) {
                        SeriesRowCard(series: series)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
        }
    }

    private func sectionTitle(_ title: String, countText: String?) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color(red: 76/255, green: 175/255, blue: 125/255))
                .frame(width: 6, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            Spacer()
            if let countText {
                Text(countText)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    // MARK: - 背景装饰（太阳/云）

    private var seriesSun: some View {
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

    private func seriesCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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

// MARK: - 精选大卡片

private struct FeaturedSeriesCard: View, Equatable {
    let series: VideoSeries

    static func == (lhs: FeaturedSeriesCard, rhs: FeaturedSeriesCard) -> Bool {
        lhs.series.id == rhs.series.id
    }

    private var placeholderGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 189/255, green: 232/255, blue: 211/255), Color(red: 76/255, green: 175/255, blue: 125/255)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                if let url = URL(string: series.coverUrl), !series.coverUrl.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(placeholderGradient)
                            .overlay(
                                Image(systemName: "film")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white.opacity(0.8))
                            )
                    }
                    .frame(width: 160, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(placeholderGradient)
                        .frame(width: 160, height: 100)
                        .overlay(
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.85))
                        )
                }

                if series.isVip {
                    Text("VIP")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 232/255, green: 100/255, blue: 82/255))
                        .clipShape(Capsule())
                        .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(series.name)
                    .font(.system(size: 13, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .lineLimit(1)
                Text("\(series.episodeCount) 集")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }
        }
        .frame(width: 160)
    }
}

// MARK: - 全部系列行卡片

private struct SeriesRowCard: View, Equatable {
    let series: VideoSeries

    static func == (lhs: SeriesRowCard, rhs: SeriesRowCard) -> Bool {
        lhs.series.id == rhs.series.id
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                if let url = URL(string: series.coverUrl), !series.coverUrl.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(red: 189/255, green: 232/255, blue: 211/255))
                            .overlay(
                                Image(systemName: "film")
                                    .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.6))
                            )
                    }
                    .frame(width: 72, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 189/255, green: 232/255, blue: 211/255))
                        .frame(width: 72, height: 48)
                        .overlay(
                            Image(systemName: "play.rectangle.fill")
                                .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.6))
                        )
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(series.name)
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Label("\(series.episodeCount) 集", systemImage: "film.stack")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                    if series.isVip {
                        Text("VIP")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color(red: 232/255, green: 100/255, blue: 82/255))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
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
}
