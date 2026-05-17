import SwiftUI

struct LocalBook: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
    let category: String
}

struct BookSelection: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
}

struct ExploreView: View {
    @State private var selectedBook: BookSelection? = nil
    @State private var books: [LocalBook] = []
    @State private var categories: [String] = ["全部"]
    @State private var selectedCategory = "全部"
    @State private var searchText = ""
    @State private var isBouncing = false
    @State private var poetryCollections: [(category: String, poems: [Poem])] = []
    @State private var selectedPoetryCollection: (category: String, poems: [Poem])? = nil

    private var filteredBooks: [LocalBook] {
        var result = books
        if selectedCategory != "全部" {
            result = result.filter { $0.category == selectedCategory }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    private var bannerBooks: [LocalBook] {
        Array(filteredBooks.prefix(3))
    }

    private var listBooks: [LocalBook] {
        Array(filteredBooks.dropFirst(3))
    }

    private var groupedListBooks: [(category: String, books: [LocalBook])] {
        let grouped = Dictionary(grouping: listBooks, by: \.category)
        return grouped.keys.sorted().map { key in
            (category: key, books: grouped[key] ?? [])
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 固定 header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        Text("探索")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentBlue.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.accentBlue)
                        }
                    }
                    searchBar
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(AppTheme.background)

                // 可滚动内容
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        categoryScrollView
                            .padding(.top, 8)
                            .padding(.bottom, 24)

                        if filteredBooks.isEmpty && poetryCollections.isEmpty {
                            emptyState
                        } else {
                            if !bannerBooks.isEmpty {
                                bannerScrollView
                                    .padding(.bottom, 32)
                            }
                            
                            poetrySection
                            
                            listSection
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(item: $selectedBook) { book in
                BookReaderView(bookTitle: book.title, bookURL: book.url)
            }
            .fullScreenCover(item: Binding(
                get: { selectedPoetryCollection.map { PoetryCollectionWrapper(category: $0.category, poems: $0.poems) } },
                set: { if $0 == nil { selectedPoetryCollection = nil } }
            )) { wrapper in
                PoetryListView(category: wrapper.category, poems: wrapper.poems)
            }
            .onAppear {
                if books.isEmpty {
                    loadLocalBooks()
                }
                if poetryCollections.isEmpty {
                    poetryCollections = ClassicalPoetryStore.shared.collections
                }
            }
        }
    }

    // Wrapper to make tuples Identifiable for fullScreenCover
    struct PoetryCollectionWrapper: Identifiable {
        let id = UUID()
        let category: String
        let poems: [Poem]
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.textSecondary)
            TextField("搜索书名或分类", text: $searchText)
                .font(.body)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cornerMedium))
    }

    // MARK: - Category Scroll

    private var categoryScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(selectedCategory == category ? .white : AppTheme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedCategory == category ? AppTheme.accentBlue : Color.gray.opacity(0.1),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
        }
    }

    // MARK: - Banner Scroll

    private var bannerScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(bannerBooks.enumerated()), id: \.element.id) { index, book in
                    bannerCard(book: book, colorIndex: index)
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
        }
    }

    private static let bannerGradients: [(Color, Color)] = [
        (Color(red: 79/255, green: 70/255, blue: 229/255), Color(red: 129/255, green: 140/255, blue: 248/255)),
        (Color(red: 16/255, green: 185/255, blue: 129/255), Color(red: 34/255, green: 197/255, blue: 94/255)),
        (Color(red: 245/255, green: 158/255, blue: 11/255), Color(red: 250/255, green: 204/255, blue: 21/255))
    ]

    private func bannerCard(book: LocalBook, colorIndex: Int) -> some View {
        let colors = Self.bannerGradients[colorIndex % Self.bannerGradients.count]
        return Button {
            openBook(book)
        } label: {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [colors.0, colors.1],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                GeometryReader { proxy in
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 140))
                        .foregroundStyle(.white.opacity(0.12))
                        .offset(x: proxy.size.width - 120, y: isBouncing ? -15 : 15)
                        .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: isBouncing)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(book.category)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))

                    Text(book.title)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }
            .frame(width: 300, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: colors.0.opacity(0.3), radius: 10, x: 0, y: 6)
            .onAppear { isBouncing = true }
        }
        .buttonStyle(.plain)
    }

    // MARK: - List Section

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            if groupedListBooks.isEmpty && !listBooks.isEmpty {
                ForEach(listBooks) { book in
                    listCell(book: book)
                }
            } else {
                ForEach(groupedListBooks, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(group.category)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Text("\(group.books.count) 本")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.horizontal, AppTheme.paddingScreen)

                        ForEach(group.books) { book in
                            listCell(book: book)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Poetry Section

    private var poetrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !poetryCollections.isEmpty {
                HStack {
                    Text("国学经典")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("\(poetryCollections.count) 部")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(poetryCollections, id: \.category) { collection in
                            Button {
                                selectedPoetryCollection = collection
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(AppTheme.accentBlue.opacity(0.1))
                                        
                                        Image(systemName: "scroll.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(AppTheme.accentBlue)
                                    }
                                    .frame(width: 100, height: 100)
                                    
                                    Text(collection.category)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .lineLimit(1)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Text("\(collection.poems.count) 首")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)
                }
                .padding(.bottom, 16)
            }
        }
    }

    private static let cellColors: [Color] = [
        AppTheme.accentYellow,
        AppTheme.accentMint,
        AppTheme.accentPurple,
        AppTheme.accentPink,
        AppTheme.accentBlue
    ]

    private func listCell(book: LocalBook) -> some View {
        let colorIndex = abs(book.title.hashValue) % Self.cellColors.count
        let tint = Self.cellColors[colorIndex]
        let hasProgress = AppProgressStore.shared.bookProgress(for: book.url.lastPathComponent) > 0

        return Button {
            openBook(book)
        } label: {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.8), tint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "book.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(book.category)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)

                        if hasProgress {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.accentBlue)
                        }
                    }
                }

                Spacer()

                Text(hasProgress ? "继续" : "阅读")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accentBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(AppTheme.accentBlue.opacity(0.1), in: Capsule())
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
            Text("没有找到相关绘本")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Actions

    private func openBook(_ book: LocalBook) {
        print("📖 openBook: \(book.title) -> \(book.url.path)")
        print("📖 file exists: \(FileManager.default.fileExists(atPath: book.url.path))")
        selectedBook = BookSelection(title: book.title, url: book.url)
    }

    private func loadLocalBooks() {
        guard let resourceURL = Bundle.main.resourceURL else { return }

        var loaded: [LocalBook] = []
        let fm = FileManager.default
        if let enumerator = fm.enumerator(at: resourceURL,
                                          includingPropertiesForKeys: [.isRegularFileKey],
                                          options: [.skipsHiddenFiles]) {
            for case let url as URL in enumerator where url.pathExtension.lowercased() == "pdf" {
                let category = url.deletingLastPathComponent().lastPathComponent
                let rawTitle = url.deletingPathExtension().lastPathComponent
                let title = Self.cleanTitle(rawTitle)
                loaded.append(LocalBook(title: title, url: url, category: category))
            }
        }

        books = loaded.sorted { $0.title < $1.title }

        let uniqueCategories = Set(loaded.map(\.category)).sorted()
        categories = ["全部"] + uniqueCategories
    }

    private static func cleanTitle(_ raw: String) -> String {
        // "[书名].(韩)作者-xxx" → 提取中括号内容
        if let open = raw.firstIndex(of: "["),
           let close = raw.firstIndex(of: "]"), close > open {
            let start = raw.index(after: open)
            return String(raw[start..<close])
        }
        var cleaned = raw
        // 去掉 "-绘本学院" / "_绘本学院" 后缀
        cleaned = cleaned.replacingOccurrences(of: "-绘本学院", with: "")
        cleaned = cleaned.replacingOccurrences(of: "_绘本学院", with: "")
        // "写给儿童的二十四节气故事_04 冬" → "二十四节气故事·冬"
        // 通用：去掉 "_01 春" 这类编号前缀，保留季节/章节名
        if let underscoreRange = cleaned.range(of: "_\\d+\\s*", options: .regularExpression) {
            let suffix = String(cleaned[underscoreRange.upperBound...])
            let prefix = String(cleaned[..<underscoreRange.lowerBound])
            cleaned = suffix.isEmpty ? prefix : "\(prefix)·\(suffix)"
        }
        return cleaned
    }
}

#Preview {
    ExploreView()
}
