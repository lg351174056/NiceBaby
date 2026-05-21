import SwiftUI

struct VideoSeriesListView: View {
    let category: VideoCategory
    @State private var seriesList: [VideoSeries] = []
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("正在加载...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if seriesList.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                    Text("暂无系列")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                seriesContent
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .background(AppTheme.background)
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
            VStack(alignment: .leading, spacing: 24) {
                if seriesList.count > 3 {
                    featuredSection
                }

                allSeriesSection
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - 精选推荐横向滚动

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("精选推荐")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, AppTheme.paddingScreen)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(seriesList.prefix(6)) { series in
                        NavigationLink(destination: VideoEpisodeListView(series: series)) {
                            FeaturedSeriesCard(series: series)
                        }
                        .buttonStyle(CardBounceStyle())
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
            }
        }
    }

    // MARK: - 全部系列

    private var allSeriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("全部系列")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(seriesList.count) 部")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, AppTheme.paddingScreen)

            LazyVStack(spacing: 12) {
                ForEach(seriesList) { series in
                    NavigationLink(destination: VideoEpisodeListView(series: series)) {
                        SeriesRowCard(series: series)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
        }
    }
}

// MARK: - 精选大卡片

private struct FeaturedSeriesCard: View {
    let series: VideoSeries

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                if let url = URL(string: series.coverUrl), !series.coverUrl.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.accentBlue.opacity(0.15), AppTheme.accentPurple.opacity(0.1)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: "film")
                                    .font(.system(size: 24))
                                    .foregroundStyle(AppTheme.accentBlue.opacity(0.4))
                            )
                    }
                    .frame(width: 160, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accentMint.opacity(0.2), AppTheme.accentBlue.opacity(0.15)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 100)
                        .overlay(
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(AppTheme.accentBlue.opacity(0.5))
                        )
                }

                if series.isVip {
                    Text("VIP")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.accentTerracotta)
                        .clipShape(Capsule())
                        .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(series.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text("\(series.episodeCount) 集")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(width: 160)
    }
}

// MARK: - 全部系列行卡片

private struct SeriesRowCard: View {
    let series: VideoSeries

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                if let url = URL(string: series.coverUrl), !series.coverUrl.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.accentBlue.opacity(0.08))
                            .overlay(
                                Image(systemName: "film")
                                    .foregroundStyle(AppTheme.accentBlue.opacity(0.3))
                            )
                    }
                    .frame(width: 72, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.accentBlue.opacity(0.08))
                        .frame(width: 72, height: 48)
                        .overlay(
                            Image(systemName: "play.rectangle.fill")
                                .foregroundStyle(AppTheme.accentBlue.opacity(0.4))
                        )
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(series.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Label("\(series.episodeCount) 集", systemImage: "film.stack")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    if series.isVip {
                        Text("VIP")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(AppTheme.accentTerracotta)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

private struct CardBounceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
