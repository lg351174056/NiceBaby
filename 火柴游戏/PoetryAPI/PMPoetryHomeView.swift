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
        .task {
            await loadInitialData()
        }
        .onChange(of: selectedGenre) { _, _ in
            Task { await resetAndLoad() }
        }
        .onChange(of: selectedDynasty) { _, _ in
            Task { await resetAndLoad() }
        }
    }

    // MARK: - Filter Bar（竹青 chips）

    private var filterBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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

                    Button {
                        showDynastyPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedDynasty.displayName)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(selectedDynasty == .all ? Color(red: 176/255, green: 130/255, blue: 50/255) : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            selectedDynasty == .all
                                ? AnyShapeStyle(Color.white.opacity(0.85))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [Color(red: 245/255, green: 200/255, blue: 107/255), Color(red: 232/255, green: 168/255, blue: 62/255)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder(
                                selectedDynasty == .all
                                    ? Color(red: 200/255, green: 160/255, blue: 80/255).opacity(0.45)
                                    : Color(red: 217/255, green: 164/255, blue: 91/255),
                                lineWidth: 2
                            )
                        )
                        .shadow(color: Color(red: 120/255, green: 90/255, blue: 30/255).opacity(0.1), radius: 4, y: 2)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
        }
        .sheet(isPresented: $showDynastyPicker) {
            DynastyPickerSheet(selected: $selectedDynasty)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Daily Section（每日推荐 · 琥珀金横卡）

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(AppTheme.fieldMint)
                    .frame(width: 6, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                Text("每日推荐")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Spacer()
                Text("每日更新")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(dailyRecommends.prefix(6).enumerated()), id: \.element.id) { index, item in
                        NavigationLink(destination: PMPoetryDetailView(poetryId: item.id, initialName: item.name)) {
                            DailyRecommendCard(item: item, index: index)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Poetry Section

    private var poetrySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !dailyRecommends.isEmpty && selectedGenre == .all && selectedDynasty == .all {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(AppTheme.fieldMint)
                        .frame(width: 6, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    Text("诗词文库")
                        .font(.system(size: 15, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                    Spacer()
                    Text("\(poetryList.count) 首")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                }
                .padding(.horizontal, 18)
            }

            ForEach(Array(poetryList.enumerated()), id: \.element.id) { index, poetry in
                NavigationLink(destination: PMPoetryDetailView(poetryId: poetry.id, initialName: poetry.name)) {
                    PoetryListCard(poetry: poetry, index: index)
                }
                .buttonStyle(.plain)
            }

            if hasMorePages {
                Color.clear
                    .frame(height: 1)
                    .id(currentPage)
                    .onAppear {
                        Task { await loadMorePoetry() }
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
                .tint(AppTheme.fieldMint)
            Text("加载中...")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.fieldMoss)
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
        guard !isLoading, hasMorePages else { return }
        isLoading = true
        let nextPage = currentPage + 1
        let genreValue = selectedGenre == .all ? "all" : selectedGenre.rawValue
        let dynastyValue = selectedDynasty == .all ? "all" : selectedDynasty.rawValue
        let results = (try? await service.fetchPoetryList(genre: genreValue, dynasty: dynastyValue, page: nextPage)) ?? []
        let existingIDs = Set(poetryList.map(\.id))
        poetryList.append(contentsOf: results.filter { !existingIDs.contains($0.id) })
        currentPage = nextPage
        hasMorePages = results.count >= 10
        isLoading = false
    }
}

// MARK: - Daily Recommend Card（书野竹青 · 墨韵色板）

private struct DailyRecommendCard: View {
    let item: PMDailyRecommend
    let index: Int

    private let cardColors: [(Color, Color)] = [
        (AppTheme.fieldMint, Color(red: 46/255, green: 125/255, blue: 91/255)),
        (Color(red: 217/255, green: 164/255, blue: 91/255), AppTheme.fieldGold),
        (Color(red: 74/255, green: 111/255, blue: 165/255), Color(red: 59/255, green: 142/255, blue: 165/255)),
        (Color(red: 92/255, green: 75/255, blue: 138/255), Color(red: 140/255, green: 115/255, blue: 195/255)),
        (Color(red: 201/255, green: 100/255, blue: 66/255), Color(red: 168/255, green: 72/255, blue: 50/255)),
        (Color(red: 232/255, green: 106/255, blue: 158/255), Color(red: 186/255, green: 80/255, blue: 100/255)),
    ]

    private var colors: (Color, Color) {
        cardColors[index % cardColors.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(item.genre)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
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
                .stroke(AppTheme.fieldInk.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Poetry List Card（白卡竹绿描边）

private struct PoetryListCard: View {
    let poetry: PMPoetry
    let index: Int

    private let accentColors: [Color] = [
        AppTheme.fieldMint,
        AppTheme.fieldGold,
        Color(red: 74/255, green: 111/255, blue: 165/255),
        Color(red: 201/255, green: 100/255, blue: 66/255),
        Color(red: 186/255, green: 80/255, blue: 100/255),
    ]

    private var accent: Color { accentColors[index % accentColors.count] }

    private var emoji: String {
        let emojis = ["🏮", "🌙", "🎋", "🌸", "🍃"]
        return emojis[index % emojis.count]
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.1))
                Text(emoji)
                    .font(.system(size: 16))
                    .modifier(Sway(delay: Double(index % 5) * 0.2))
            }
            .frame(width: 40, height: 40)
            .overlay(Circle().strokeBorder(accent.opacity(0.3), lineWidth: 1.5))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(poetry.name)
                        .font(.system(size: 15, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                        .lineLimit(1)

                    if !poetry.genre.isEmpty {
                        Text(poetry.genre)
                            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(accent.opacity(0.1), in: Capsule())
                    }
                }

                Text("[\(poetry.dynasty)] \(poetry.poetName)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)

                Text(poetry.excerpt)
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .foregroundStyle(Color(red: 85/255, green: 112/255, blue: 95/255))
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
                    .foregroundStyle(AppTheme.fieldMoss)
            }
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
        .padding(.horizontal, 18)
    }

    private struct Sway: ViewModifier {
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

// MARK: - Filter Chip（竹青选中）

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(isSelected ? .white : AppTheme.fieldOliveDeep)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected
                        ? AnyShapeStyle(AppTheme.fieldMint)
                        : AnyShapeStyle(Color.white.opacity(0.85))
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(
                        isSelected
                            ? AppTheme.fieldInk
                            : AppTheme.fieldOlive.opacity(0.35),
                        lineWidth: 2
                    )
                )
                .shadow(color: isSelected ? AppTheme.fieldMint.opacity(0.3) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dynasty Picker Sheet（竹青选中）

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
                                    ? AnyShapeStyle(AppTheme.fieldMint)
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
