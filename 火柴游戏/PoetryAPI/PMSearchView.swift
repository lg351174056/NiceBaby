import SwiftUI

struct PMSearchView: View {
    @State private var keyword = ""
    @State private var hotKeywords: [PMHotKeyword] = []
    @State private var poetryResults: [PMPoetry] = []
    @State private var poetResults: [PMSearchPoet] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var selectedTab: SearchTab = .poetry
    @FocusState private var isFocused: Bool

    enum SearchTab: String, CaseIterable {
        case poetry = "诗词"
        case poet = "作者"
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            if hasSearched {
                searchResults
            } else {
                hotKeywordsView
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            hotKeywords = (try? await PoetryAPIService.shared.fetchHotKeywords()) ?? []
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.6))

                TextField("搜索诗词、诗人...", text: $keyword)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .focused($isFocused)
                    .onSubmit { performSearch() }

                if !keyword.isEmpty {
                    Button {
                        keyword = ""
                        hasSearched = false
                        poetryResults = []
                        poetResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

            if isFocused || !keyword.isEmpty {
                Button("搜索") { performSearch() }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accentBlue)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.vertical, 10)
        .animation(.spring(response: 0.3), value: isFocused)
    }

    // MARK: - Hot Keywords

    private var hotKeywordsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.orange)
                    Text("热门搜索")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(.top, 12)

                FlowLayoutPM(spacing: 8) {
                    ForEach(hotKeywords) { item in
                        Button {
                            keyword = item.keyword
                            performSearch()
                        } label: {
                            Text(item.keyword)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .shadow(color: .black.opacity(0.03), radius: 3, y: 1)
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Search Results

    private var searchResults: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(SearchTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedTab = tab }
                    } label: {
                        VStack(spacing: 6) {
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: selectedTab == tab ? .heavy : .bold, design: .rounded))
                                .foregroundStyle(selectedTab == tab ? AppTheme.accentBlue : AppTheme.textSecondary)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(selectedTab == tab ? AppTheme.accentBlue : .clear)
                                .frame(height: 3).frame(width: 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)

            Divider().foregroundStyle(AppTheme.separator)

            if isSearching {
                VStack {
                    Spacer(minLength: 60)
                    ProgressView().controlSize(.large)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    switch selectedTab {
                    case .poetry:
                        poetryResultsList
                    case .poet:
                        poetResultsList
                    }
                }
            }
        }
    }

    private var poetryResultsList: some View {
        LazyVStack(spacing: 0) {
            if poetryResults.isEmpty {
                emptyState
            } else {
                ForEach(poetryResults) { poetry in
                    NavigationLink(destination: PMPoetryDetailView(poetryId: poetry.id, initialName: poetry.name)) {
                        SearchPoetryRow(poetry: poetry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 40)
    }

    private var poetResultsList: some View {
        LazyVStack(spacing: 10) {
            if poetResults.isEmpty {
                emptyState
            } else {
                ForEach(poetResults) { poet in
                    PoetRow(poet: poet)
                }
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 12)
        .padding(.bottom, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 40)
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
            Text("暂无结果")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Actions

    private func performSearch() {
        guard !keyword.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isFocused = false
        isSearching = true
        hasSearched = true
        Task {
            async let p1 = try? PoetryAPIService.shared.searchPoetry(keyword: keyword)
            async let p2 = try? PoetryAPIService.shared.searchPoet(keyword: keyword)
            poetryResults = await p1 ?? []
            poetResults = await p2 ?? []
            isSearching = false
        }
    }
}

// MARK: - Search Poetry Row

private struct SearchPoetryRow: View {
    let poetry: PMPoetry

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(poetry.name)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("[\(poetry.dynasty)] \(poetry.poetName)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text(poetry.excerpt)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                .lineLimit(2)
                .lineSpacing(3)
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.vertical, 12)
        .background(AppTheme.card)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.separator).frame(height: 0.5)
                .padding(.leading, AppTheme.paddingScreen)
        }
    }
}

// MARK: - Poet Row

private struct PoetRow: View {
    let poet: PMSearchPoet

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.accentTerracotta, AppTheme.accentYellow],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 42, height: 42)
                .overlay(
                    Text(String(poet.name.prefix(1)))
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(poet.name)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(poet.dynasty)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accentBlue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.accentBlue.opacity(0.1), in: Capsule())
                }
                if poet.poetryCount > 0 {
                    Text("收录 \(poet.poetryCount) 首")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }
}

// MARK: - Flow Layout

struct FlowLayoutPM: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(x: bounds.minX + result.positions[index].x,
                                y: bounds.minY + result.positions[index].y)
            subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            lineHeight = max(lineHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + lineHeight), positions)
    }
}
