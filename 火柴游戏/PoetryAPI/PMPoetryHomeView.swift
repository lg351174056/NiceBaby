import SwiftUI

struct PMPoetryHomeView: View {
    @StateObject private var service = PoetryAPIService.shared
    @State private var poetryList: [PMPoetry] = []
    @State private var dailyRecommends: [PMDailyRecommend] = []
    @State private var currentPage = 1
    @State private var isLoading = false
    @State private var hasMorePages = true

    @State private var selectedGenre: PMGenreFilter = .all
    @State private var selectedDynasty: PMDynastyFilter = .all
    @State private var showDynastyPicker = false
    @State private var appearAnimation = false

    var body: some View {
        VStack(spacing: 0) {
            filterBar

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    if !dailyRecommends.isEmpty && selectedGenre == .all && selectedDynasty == .all {
                        dailySection
                    }

                    poetrySection

                    if isLoading {
                        loadingIndicator
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            await loadInitialData()
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
        .onChange(of: selectedGenre) { _, _ in
            Task { await resetAndLoad() }
        }
        .onChange(of: selectedDynasty) { _, _ in
            Task { await resetAndLoad() }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PMGenreFilter.allCases) { genre in
                        FilterChip(
                            title: genre.displayName,
                            isSelected: selectedGenre == genre
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedGenre = genre
                            }
                        }
                    }

                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal, 4)

                    Button {
                        showDynastyPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedDynasty.displayName)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(selectedDynasty == .all ? AppTheme.textSecondary : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedDynasty == .all
                                ? AnyShapeStyle(AppTheme.card.opacity(0.8))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.55, blue: 0.1), Color(red: 0.98, green: 0.7, blue: 0.2)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                        )
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.06), radius: 3, y: 2)
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.vertical, 10)
            }

            Divider()
                .foregroundStyle(AppTheme.separator)
        }
        .background(AppTheme.background.opacity(0.95))
        .sheet(isPresented: $showDynastyPicker) {
            DynastyPickerSheet(selected: $selectedDynasty)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Daily Section

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.accentTerracotta)
                Text("每日推荐")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(dailyRecommends.prefix(6).enumerated()), id: \.element.id) { index, item in
                        NavigationLink(destination: PMPoetryDetailView(poetryId: item.id, initialName: item.name)) {
                            DailyRecommendCard(item: item, index: index)
                                .opacity(appearAnimation ? 1 : 0)
                                .animation(
                                    .easeOut(duration: 0.4).delay(Double(index) * 0.06),
                                    value: appearAnimation
                                )
                        }
                        .buttonStyle(CardBounceStyle())
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Poetry Section

    private var poetrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !dailyRecommends.isEmpty && selectedGenre == .all && selectedDynasty == .all {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(AppTheme.accentBlue)
                        .frame(width: 4, height: 18)
                    Text("诗词文库")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("\(poetryList.count) 首")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, AppTheme.paddingScreen)
            }

            ForEach(Array(poetryList.enumerated()), id: \.element.id) { index, poetry in
                NavigationLink(destination: PMPoetryDetailView(poetryId: poetry.id, initialName: poetry.name)) {
                    PoetryListCard(poetry: poetry, index: index)
                        .opacity(appearAnimation ? 1 : 0)
                        .animation(
                            .easeOut(duration: 0.3).delay(Double(min(index, 8)) * 0.04),
                            value: appearAnimation
                        )
                }
                .buttonStyle(.plain)
                .onAppear {
                    if index == poetryList.count - 3, hasMorePages, !isLoading {
                        Task { await loadMorePoetry() }
                    }
                }
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Loading

    private var loadingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("加载中...")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Data

    private func loadInitialData() async {
        isLoading = true
        async let dailyTask = try? service.fetchDailyRecommend()
        async let poetryTask = try? service.fetchPoetryList(page: 1)

        dailyRecommends = await dailyTask ?? []
        poetryList = await poetryTask ?? []
        isLoading = false
    }

    private func resetAndLoad() async {
        currentPage = 1
        hasMorePages = true
        poetryList = []
        isLoading = true
        let genreValue = selectedGenre == .all ? "all" : selectedGenre.rawValue
        let dynastyValue = selectedDynasty == .all ? "all" : selectedDynasty.rawValue
        let results = (try? await service.fetchPoetryList(genre: genreValue, dynasty: dynastyValue, page: 1)) ?? []
        poetryList = results
        hasMorePages = results.count >= 10
        isLoading = false
    }

    private func loadMorePoetry() async {
        guard !isLoading else { return }
        isLoading = true
        currentPage += 1
        let genreValue = selectedGenre == .all ? "all" : selectedGenre.rawValue
        let dynastyValue = selectedDynasty == .all ? "all" : selectedDynasty.rawValue
        let results = (try? await service.fetchPoetryList(genre: genreValue, dynasty: dynastyValue, page: currentPage)) ?? []
        poetryList.append(contentsOf: results)
        hasMorePages = results.count >= 10
        isLoading = false
    }
}

// MARK: - Daily Recommend Card

private struct DailyRecommendCard: View {
    let item: PMDailyRecommend
    let index: Int

    private let cardColors: [(Color, Color)] = [
        (Color(red: 0.95, green: 0.35, blue: 0.25), Color(red: 0.98, green: 0.55, blue: 0.35)),
        (Color(red: 0.3, green: 0.2, blue: 0.7), Color(red: 0.55, green: 0.4, blue: 0.9)),
        (Color(red: 0.1, green: 0.6, blue: 0.5), Color(red: 0.2, green: 0.8, blue: 0.6)),
        (Color(red: 0.85, green: 0.5, blue: 0.1), Color(red: 0.95, green: 0.7, blue: 0.2)),
        (Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.4, green: 0.6, blue: 0.95)),
        (Color(red: 0.7, green: 0.2, blue: 0.5), Color(red: 0.9, green: 0.4, blue: 0.6)),
    ]

    private var colors: (Color, Color) {
        cardColors[index % cardColors.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(item.genre)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.2), in: Capsule())
                Spacer()
            }

            Text(item.name)
                .font(.system(size: 17, weight: .heavy, design: .serif))
                .foregroundStyle(.white)
                .lineLimit(2)

            Spacer(minLength: 4)

            Text("[\(item.dynasty)] \(item.poetName)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))

            Text(item.excerpt)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(2)
                .lineSpacing(2)
        }
        .padding(14)
        .frame(width: 160, height: 170, alignment: .topLeading)
        .background(
            LinearGradient(colors: [colors.0, colors.1], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: colors.0.opacity(0.3), radius: 8, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Poetry List Card

private struct PoetryListCard: View {
    let poetry: PMPoetry
    let index: Int

    private let accentColors: [Color] = [
        AppTheme.accentBlue,
        AppTheme.accentPurple,
        AppTheme.accentMint,
        AppTheme.accentTerracotta,
        AppTheme.accentPink,
    ]

    private var accent: Color { accentColors[index % accentColors.count] }

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(accent.gradient)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(poetry.name)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    if !poetry.genre.isEmpty {
                        Text(poetry.genre)
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(accent.opacity(0.1), in: Capsule())
                    }
                }

                Text("[\(poetry.dynasty)] \(poetry.poetName)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                Text(poetry.excerpt)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                    .lineLimit(2)
                    .lineSpacing(2)
            }

            Spacer()

            VStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(accent.opacity(0.5))
                Text("\(poetry.upCount)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.vertical, 12)
        .background(AppTheme.card)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.separator)
                .frame(height: 0.5)
                .padding(.leading, AppTheme.paddingScreen + 18)
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        : AnyShapeStyle(AppTheme.card.opacity(0.8))
                )
                .clipShape(Capsule())
                .shadow(color: isSelected ? AppTheme.accentBlue.opacity(0.3) : .clear, radius: 4, y: 2)
        }
    }
}

// MARK: - Dynasty Picker Sheet

private struct DynastyPickerSheet: View {
    @Binding var selected: PMDynastyFilter
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 70), spacing: 10)]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("选择朝代")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(PMDynastyFilter.allCases) { dynasty in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selected = dynasty
                        }
                        dismiss()
                    } label: {
                        Text(dynasty.displayName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(selected == dynasty ? .white : AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selected == dynasty
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [Color(red: 0.95, green: 0.55, blue: 0.1), Color(red: 0.98, green: 0.7, blue: 0.2)],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    : AnyShapeStyle(AppTheme.background)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(selected == dynasty ? Color.clear : AppTheme.separator, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

// MARK: - Bounce Style

private struct CardBounceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
