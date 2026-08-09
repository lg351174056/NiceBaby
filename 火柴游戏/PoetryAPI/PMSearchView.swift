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
        .task {
            hotKeywords = (try? await PoetryAPIService.shared.fetchHotKeywords()) ?? []
        }
    }

    // MARK: - Search Bar（竹青描边）

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))

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
                            .foregroundStyle(Color(red: 160/255, green: 176/255, blue: 152/255))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.4), lineWidth: 2)
            )
            .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 4, y: 2)

            if isFocused || !keyword.isEmpty {
                Button("搜索") { performSearch() }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .animation(.spring(response: 0.3), value: isFocused)
    }

    // MARK: - Hot Keywords（琥珀金）

    private var hotKeywordsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color(red: 76/255, green: 175/255, blue: 125/255))
                        .frame(width: 6, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    Text("热门搜索")
                        .font(.system(size: 15, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    Spacer()
                    Text("实时更新")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                }
                .padding(.top, 12)

                FlowLayoutPM(spacing: 8) {
                    ForEach(Array(hotKeywords.enumerated()), id: \.element.id) { index, item in
                        Button {
                            keyword = item.keyword
                            performSearch()
                        } label: {
                            Text(item.keyword)
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(index < 3
                                    ? Color(red: 176/255, green: 130/255, blue: 50/255)
                                    : Color(red: 74/255, green: 92/255, blue: 66/255))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Color.white.opacity(0.9),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(index < 3
                                            ? Color(red: 200/255, green: 160/255, blue: 80/255).opacity(0.5)
                                            : Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3),
                                            lineWidth: 1.5)
                                )
                                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.06), radius: 3, y: 1)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
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
                                .foregroundStyle(selectedTab == tab
                                    ? Color(red: 76/255, green: 175/255, blue: 125/255)
                                    : Color(red: 138/255, green: 154/255, blue: 122/255))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(selectedTab == tab
                                    ? Color(red: 76/255, green: 175/255, blue: 125/255)
                                    : .clear)
                                .frame(height: 3).frame(width: 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal, 18)

            Divider().foregroundStyle(Color(red: 30/255, green: 28/255, blue: 24/255).opacity(0.08))

            if isSearching {
                VStack {
                    Spacer(minLength: 60)
                    ProgressView()
                        .controlSize(.large)
                        .tint(Color(red: 76/255, green: 175/255, blue: 125/255))
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
        LazyVStack(spacing: 10) {
            if poetryResults.isEmpty {
                emptyState
            } else {
                ForEach(poetryResults) { poetry in
                    NavigationLink(destination: PMPoetryDetailView(poetryId: poetry.id, initialName: poetry.name)) {
                        SearchPoetryRow(poetry: poetry)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 18)
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
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 40)
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
            Text("暂无结果")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
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

// MARK: - Search Poetry Row（白卡竹绿描边）

private struct SearchPoetryRow: View {
    let poetry: PMPoetry

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.1))
                Text("📜")
                    .font(.system(size: 15))
            }
            .frame(width: 36, height: 36)
            .overlay(Circle().strokeBorder(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.3), lineWidth: 1.5))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(poetry.name)
                        .font(.system(size: 15, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    Spacer()
                    Text("[\(poetry.dynasty)] \(poetry.poetName)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                }
                Text(poetry.excerpt)
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .foregroundStyle(Color(red: 85/255, green: 112/255, blue: 95/255))
                    .lineLimit(2)
                    .lineSpacing(3)
            }
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

// MARK: - Poet Row（竹青头像渐变）

private struct PoetRow: View {
    let poet: PMSearchPoet

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 126/255, green: 211/255, blue: 160/255), Color(red: 76/255, green: 175/255, blue: 125/255)],
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
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    Text(poet.dynasty)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.1), in: Capsule())
                }
                if poet.poetryCount > 0 {
                    Text("收录 \(poet.poetryCount) 首")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.25), lineWidth: 2)
                )
        )
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
