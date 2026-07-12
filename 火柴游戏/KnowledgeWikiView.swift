import SwiftUI
import Foundation

// MARK: - 知识百科 · 数据模型

struct KnowledgeWikiStatus: Hashable, Decodable {
    let wiki: Int
    let iq: Int
    let brain: Int
}

struct KnowledgeWikiGroup: Identifiable, Hashable, Decodable {
    let id: String
    let name: String
    let intro: String
    let categories: [KnowledgeWikiCategory]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case intro = "jieshao"
        case categories = "sontypes"
    }

    var totalQuestions: Int {
        categories.reduce(0) { $0 + $1.questionCount }
    }

    var palette: (Color, Color) {
        switch id {
        case "13":
            return (AppTheme.accentJade, AppTheme.accentIndigo)
        case "2":
            return (AppTheme.accentYellow, AppTheme.accentCinnabar)
        case "3":
            return (AppTheme.accentPink, AppTheme.accentJade)
        case "16":
            return (AppTheme.accentBamboo, AppTheme.accentIndigo)
        case "18":
            return (AppTheme.accentYellow, AppTheme.accentBamboo)
        default:
            return (AppTheme.accentInkPurple, AppTheme.accentIndigo)
        }
    }

    var symbolName: String {
        switch id {
        case "13": return "sparkles"
        case "2": return "medal.star.fill"
        case "3": return "paperplane.fill"
        case "16": return "scroll.fill"
        case "18": return "graduationcap.fill"
        default: return "brain.head.profile"
        }
    }

    var shortMark: String {
        switch id {
        case "13": return "综"
        case "2": return "典"
        case "3": return "趣"
        case "16": return "雅"
        case "18": return "学"
        default: return "霸"
        }
    }
}

struct KnowledgeWikiCategory: Identifiable, Hashable, Decodable {
    let id: String
    let name: String
    let questionCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case questionCount = "r_count"
    }
}

struct KnowledgeWikiQuestion: Identifiable, Hashable {
    let remoteID: Int
    let categoryID: String
    let content: String
    let options: [String]
    let correctOption: String

    var id: String { "\(categoryID)-\(remoteID)" }

    var correctIndex: Int? {
        guard let scalar = correctOption.uppercased().unicodeScalars.first else { return nil }
        let value = Int(scalar.value) - 65
        guard value >= 0, value < options.count else { return nil }
        return value
    }

    var correctLetter: String {
        correctOption.uppercased()
    }

    var correctAnswerText: String {
        guard let correctIndex, options.indices.contains(correctIndex) else { return "暂无" }
        return options[correctIndex]
    }
}

struct KnowledgeWikiCategorySelection: Identifiable, Hashable {
    let group: KnowledgeWikiGroup
    let category: KnowledgeWikiCategory

    var id: String { "\(group.id)-\(category.id)" }
}

// MARK: - 知识百科 · 服务

enum KnowledgeWikiError: LocalizedError {
    case invalidURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "知识百科接口地址无效"
        case .invalidResponse:
            return "知识百科返回内容无法解析"
        }
    }
}

final class KnowledgeWikiService {
    static let shared = KnowledgeWikiService()

    static let snapshotStatus = KnowledgeWikiStatus(wiki: 1392, iq: 676, brain: 448)
    static let snapshotCategoryCount = 86
    static let snapshotQuestionCount = 29_166

    private let baseURL = "http://m.beauty-story.cn"
    private let session: URLSession
    private let decoder = JSONDecoder()

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCatalog() async throws -> [KnowledgeWikiGroup] {
        let response: KnowledgeWikiCatalogResponse = try await fetch(path: "/api/newpaper/navlist")
        return response.data
    }

    func fetchStatus() async throws -> KnowledgeWikiStatus {
        let response: KnowledgeWikiStatusResponse = try await fetch(path: "/api/paper/get_Paper_status")
        return response.data
    }

    func fetchQuestions(categoryID: String, after questionID: Int = 0) async throws -> [KnowledgeWikiQuestion] {
        let response: KnowledgeWikiQuestionResponse = try await fetch(
            path: "/api/newpaper/get",
            queryItems: [
                URLQueryItem(name: "id", value: String(questionID)),
                URLQueryItem(name: "paperType", value: "10"),
                URLQueryItem(name: "k_category_id", value: categoryID),
                URLQueryItem(name: "paper_type", value: "10")
            ]
        )
        return response.data.map(\.question)
    }

    private func fetch<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        guard var components = URLComponents(string: baseURL + path) else {
            throw KnowledgeWikiError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw KnowledgeWikiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw KnowledgeWikiError.invalidResponse
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw KnowledgeWikiError.invalidResponse
        }
    }
}

private struct KnowledgeWikiCatalogResponse: Decodable {
    let data: [KnowledgeWikiGroup]
}

private struct KnowledgeWikiStatusResponse: Decodable {
    let data: KnowledgeWikiStatus
}

private struct KnowledgeWikiQuestionResponse: Decodable {
    let data: [KnowledgeWikiQuestionPayload]
}

private struct KnowledgeWikiQuestionPayload: Decodable {
    let id: String
    let categoryID: String
    let content: String
    let optionsPayload: String
    let correctOption: String

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case optionsPayload = "options"
        case correctOption = "correct_option"
        case categoryID = "k_category_id"
    }

    var question: KnowledgeWikiQuestion {
        let data = Data(optionsPayload.utf8)
        let decodedOptions = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        let cleanedOptions = decodedOptions.map { option in
            let stripped = option.replacingOccurrences(
                of: #"^[A-Z][\.\、]\s*"#,
                with: "",
                options: .regularExpression
            )
            return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return KnowledgeWikiQuestion(
            remoteID: Int(id) ?? 0,
            categoryID: categoryID,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            options: cleanedOptions,
            correctOption: correctOption
        )
    }
}

// MARK: - 知识百科 · 首页 Store

@Observable
final class KnowledgeWikiHomeStore {
    private let service: KnowledgeWikiService

    private(set) var groups: [KnowledgeWikiGroup] = []
    private(set) var status: KnowledgeWikiStatus = KnowledgeWikiService.snapshotStatus
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(service: KnowledgeWikiService = .shared) {
        self.service = service
    }

    var allSelections: [KnowledgeWikiCategorySelection] {
        groups.flatMap { group in
            group.categories.map { KnowledgeWikiCategorySelection(group: group, category: $0) }
        }
    }

    var topSelections: [KnowledgeWikiCategorySelection] {
        allSelections
            .sorted { lhs, rhs in
                if lhs.category.questionCount != rhs.category.questionCount {
                    return lhs.category.questionCount > rhs.category.questionCount
                }
                return lhs.category.id < rhs.category.id
            }
            .prefix(3)
            .map { $0 }
    }

    func loadIfNeeded() async {
        guard groups.isEmpty else { return }
        await load()
    }

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let catalog = service.fetchCatalog()
            async let status = service.fetchStatus()
            self.groups = try await catalog
            self.status = try await status
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - 知识百科 · 题库 Store

@Observable
final class KnowledgeWikiQuizStore {
    private let service: KnowledgeWikiService
    let group: KnowledgeWikiGroup
    let category: KnowledgeWikiCategory

    private(set) var questions: [KnowledgeWikiQuestion] = []
    private(set) var currentIndex = 0
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var errorMessage: String?
    private(set) var answerSelections: [String: Int] = [:]
    private var reachedEnd = false

    init(
        group: KnowledgeWikiGroup,
        category: KnowledgeWikiCategory,
        service: KnowledgeWikiService = .shared
    ) {
        self.group = group
        self.category = category
        self.service = service
    }

    var currentQuestion: KnowledgeWikiQuestion? {
        questions[safe: currentIndex]
    }

    var answeredCount: Int {
        answerSelections.count
    }

    var currentSelection: Int? {
        guard let currentQuestion else { return nil }
        return answerSelections[currentQuestion.id]
    }

    var progress: Double {
        guard category.questionCount > 0 else { return 0 }
        return Double(min(currentIndex + 1, category.questionCount)) / Double(category.questionCount)
    }

    func loadIfNeeded() async {
        guard questions.isEmpty else { return }
        await reload()
    }

    @MainActor
    func reload() async {
        isLoading = true
        defer { isLoading = false }

        currentIndex = 0
        questions = []
        answerSelections = [:]
        reachedEnd = false

        do {
            let batch = try await service.fetchQuestions(categoryID: category.id)
            questions = batch
            reachedEnd = batch.isEmpty || batch.count >= category.questionCount
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func selectOption(_ index: Int) {
        guard let currentQuestion else { return }
        answerSelections[currentQuestion.id] = index
    }

    @MainActor
    func goPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    @MainActor
    func goNext() async {
        guard !questions.isEmpty else { return }

        if currentIndex < questions.count - 1 {
            currentIndex += 1
            await prefetchIfNeeded()
            return
        }

        guard !reachedEnd else { return }

        await loadMore()
        if currentIndex < questions.count - 1 {
            currentIndex += 1
        }
    }

    @MainActor
    private func prefetchIfNeeded() async {
        guard currentIndex >= questions.count - 4, !reachedEnd else { return }
        await loadMore()
    }

    @MainActor
    private func loadMore() async {
        guard !isLoadingMore, !reachedEnd else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let lastID = questions.last?.remoteID ?? 0
            let batch = try await service.fetchQuestions(categoryID: category.id, after: lastID)

            if batch.isEmpty {
                reachedEnd = true
            } else {
                let known = Set(questions.map(\.id))
                let newItems = batch.filter { !known.contains($0.id) }
                questions += newItems
                reachedEnd = questions.count >= category.questionCount || newItems.isEmpty
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 知识百科 · 首页

struct KnowledgeWikiHomeView: View {
    @State private var store = KnowledgeWikiHomeStore()
    @State private var searchText = ""

    private var searchResults: [KnowledgeWikiCategorySelection] {
        guard !searchText.isEmpty else { return [] }
        return store.allSelections.filter {
            $0.category.name.localizedCaseInsensitiveContains(searchText) ||
            $0.group.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            UnifiedNavBar(title: "知识百科")

            Group {
                if store.isLoading && store.groups.isEmpty {
                    loadingView
                } else if let errorMessage = store.errorMessage, store.groups.isEmpty {
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
            await store.loadIfNeeded()
        }
        .refreshable {
            await store.load()
        }
    }

    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                searchBar

                if let errorMessage = store.errorMessage {
                    inlineError(message: errorMessage)
                }

                if !searchText.isEmpty {
                    searchSection
                } else {
                    featuredSection

                    ForEach(store.groups) { group in
                        groupSection(group)
                    }

                    footerCard
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 14)
            .padding(.bottom, 32)
        }
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [AppTheme.accentInkPurple, AppTheme.accentIndigo, AppTheme.accentJade],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 200, height: 200)
                .offset(x: 80, y: 90)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Label("KNOWLEDGE ATLAS", systemImage: "sparkles")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.8)
                        .foregroundStyle(.white.opacity(0.88))

                    Spacer()

                    Text("86 个入口")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.16), in: Capsule())
                }

                Text("知识百科")
                    .font(.system(size: 30, weight: .heavy, design: .serif))
                    .foregroundStyle(.white)

                Text("把海量题库做成一座可以漫游的知识花园，随手点开一个门类，就能直接开答。")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineSpacing(4)

                HStack(spacing: 10) {
                    heroStat(title: "百科", value: store.status.wiki)
                    heroStat(title: "智力", value: store.status.iq)
                    heroStat(title: "急转弯", value: store.status.brain)
                }
            }
            .padding(22)
        }
        .frame(minHeight: 220)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private func heroStat(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)

            TextField("搜索分类，比如 国学 / 地理 / 经典题库", text: $searchText)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.72))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(AppTheme.separator, lineWidth: 1)
                )
        )
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("热门先逛", sub: "CURATED")

            HStack(spacing: 12) {
                ForEach(store.topSelections) { selection in
                    NavigationLink {
                        KnowledgeWikiQuizView(group: selection.group, category: selection.category)
                    } label: {
                        featuredCategoryCard(selection)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func featuredCategoryCard(_ selection: KnowledgeWikiCategorySelection) -> some View {
        let palette = selection.group.palette
        return VStack(alignment: .leading, spacing: 8) {
            Image(systemName: selection.group.symbolName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(palette.0)

            Text(selection.category.name)
                .font(.system(size: 15, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)

            Text("\(selection.category.questionCount) 题")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(palette.0.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private func groupSection(_ group: KnowledgeWikiGroup) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(group.palette.0.opacity(0.14))
                        .frame(width: 42, height: 42)
                    Image(systemName: group.symbolName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(group.palette.0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 20, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(group.intro)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineSpacing(3)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                summaryPill("\(group.categories.count) 个门类", color: group.palette.0)
                summaryPill("\(group.totalQuestions) 题", color: group.palette.1)
            }

            let columns = [GridItem(.adaptive(minimum: 112), spacing: 10)]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(group.categories) { category in
                    NavigationLink {
                        KnowledgeWikiQuizView(group: group, category: category)
                    } label: {
                        categoryTile(category, palette: group.palette)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(AppTheme.separator, lineWidth: 1)
                )
        )
        .overlay(alignment: .topTrailing) {
            Text(group.shortMark)
                .font(.system(size: 58, weight: .black, design: .serif))
                .foregroundStyle(group.palette.0.opacity(0.08))
                .padding(.top, 12)
                .padding(.trailing, 18)
        }
    }

    private func summaryPill(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.1), in: Capsule())
    }

    private func categoryTile(_ category: KnowledgeWikiCategory, palette: (Color, Color)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.name)
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Text("\(category.questionCount)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(palette.0)
                Text("题")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(palette.1.opacity(0.86))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(palette.0.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("搜索结果", sub: "SEARCH")

            if searchResults.isEmpty {
                Text("没有找到对应门类，换个关键词试试。")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppTheme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(AppTheme.separator, lineWidth: 1)
                            )
                    )
            } else {
                VStack(spacing: 10) {
                    ForEach(searchResults) { selection in
                        NavigationLink {
                            KnowledgeWikiQuizView(group: selection.group, category: selection.category)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(selection.group.palette.0.opacity(0.12))
                                        .frame(width: 42, height: 42)
                                    Image(systemName: selection.group.symbolName)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(selection.group.palette.0)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selection.category.name)
                                        .font(.system(size: 16, weight: .bold, design: .serif))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("\(selection.group.name) · \(selection.category.questionCount) 题")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(AppTheme.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .strokeBorder(AppTheme.separator, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var footerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.accentBamboo)

            VStack(alignment: .leading, spacing: 4) {
                Text("入口已全量接入")
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("共 \(KnowledgeWikiService.snapshotCategoryCount) 个门类，约 \(KnowledgeWikiService.snapshotQuestionCount) 道题，支持继续扩展与分页续拉。")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(3)
            }

            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.accentBamboo.opacity(0.08))
        )
    }

    private func sectionTitle(_ title: String, sub: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
            Text(sub)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(AppTheme.textSecondary.opacity(0.75))
            Rectangle()
                .fill(AppTheme.separator)
                .frame(height: 0.5)
            Spacer(minLength: 0)
        }
    }

    private func inlineError(message: String) -> some View {
        Text(message)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.accentCinnabar)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.accentCinnabar.opacity(0.08))
            )
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            ProgressView("正在整理百科入口...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .tint(AppTheme.accentInkPurple)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Text("知识百科加载失败")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppTheme.paddingScreen)
    }
}

// MARK: - 知识百科 · 答题页

struct KnowledgeWikiQuizView: View {
    let group: KnowledgeWikiGroup
    let category: KnowledgeWikiCategory
    @State private var store: KnowledgeWikiQuizStore

    init(group: KnowledgeWikiGroup, category: KnowledgeWikiCategory) {
        self.group = group
        self.category = category
        _store = State(initialValue: KnowledgeWikiQuizStore(group: group, category: category))
    }

    var body: some View {
        VStack(spacing: 0) {
            UnifiedNavBar(
                title: category.name,
                trailing: AnyView(
                    Button {
                        Task { await store.reload() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.card, in: Circle())
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                )
            )

            Group {
                if store.isLoading && store.questions.isEmpty {
                    loadingView
                } else if let errorMessage = store.errorMessage, store.questions.isEmpty {
                    errorView(message: errorMessage)
                } else {
                    contentView
                }
            }
        }
        .background(
            LinearGradient(
                colors: [group.palette.0.opacity(0.1), AppTheme.background, AppTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .task {
            await store.loadIfNeeded()
        }
        .refreshable {
            await store.reload()
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
    }

    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                quizHero

                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.accentCinnabar)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.accentCinnabar.opacity(0.08))
                        )
                }

                if let question = store.currentQuestion {
                    questionCard(question)
                }

                if store.isLoadingMore {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(group.palette.0)
                        Text("正在为你续拉更多题目...")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(AppTheme.separator, lineWidth: 1)
                            )
                    )
                }

                Spacer(minLength: 36)
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
    }

    private var quizHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.name)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(group.palette.0)
                    Text(category.name)
                        .font(.system(size: 26, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(group.palette.0.opacity(0.14))
                        .frame(width: 56, height: 56)
                    Image(systemName: group.symbolName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(group.palette.0)
                }
            }

            Text("当前已载入 \(store.questions.count) / \(category.questionCount) 题，支持边答边续拉，不用等整库全量下载。")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(3)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("答题进度")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text("\(min(store.currentIndex + 1, category.questionCount)) / \(category.questionCount)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(group.palette.0)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(group.palette.0.opacity(0.12))
                            .frame(height: 8)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [group.palette.0, group.palette.1],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: proxy.size.width * store.progress, height: 8)
                    }
                }
                .frame(height: 8)
            }

            HStack(spacing: 10) {
                quizMetric(title: "已作答", value: "\(store.answeredCount)")
                quizMetric(title: "题量", value: "\(category.questionCount)")
                quizMetric(title: "门类", value: "\(group.categories.count)")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(group.palette.0.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private func quizMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(group.palette.0.opacity(0.06))
        )
    }

    private func questionCard(_ question: KnowledgeWikiQuestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("第 \(store.currentIndex + 1) 题")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(group.palette.0, in: Capsule())

                Spacer()

                Text("#\(question.remoteID)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Text(question.content)
                .font(.system(size: 24, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(6)

            VStack(spacing: 10) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    optionButton(
                        label: optionLabel(for: index),
                        text: option,
                        index: index,
                        question: question
                    )
                }
            }

            if let selection = store.currentSelection {
                answerResultView(question: question, selection: selection)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(AppTheme.separator, lineWidth: 1)
                )
        )
    }

    private func optionButton(label: String, text: String, index: Int, question: KnowledgeWikiQuestion) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                store.selectOption(index)
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(optionBadgeFill(index: index, question: question))
                        .frame(width: 34, height: 34)
                    Text(label)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(optionBadgeTextColor(index: index, question: question))
                }

                Text(text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let symbol = optionSymbol(index: index, question: question) {
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(optionHighlightColor(index: index, question: question))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(optionBackground(index: index, question: question))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(optionBorder(index: index, question: question), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func answerResultView(question: KnowledgeWikiQuestion, selection: Int) -> some View {
        let correct = selection == question.correctIndex
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: correct ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(correct ? AppTheme.accentBamboo : AppTheme.accentCinnabar)

            VStack(alignment: .leading, spacing: 6) {
                Text(correct ? "答对了，继续向前。" : "这题拐了个弯。")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("正确答案：\(question.correctLetter) · \(question.correctAnswerText)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(3)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill((correct ? AppTheme.accentBamboo : AppTheme.accentCinnabar).opacity(0.08))
        )
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                store.goPrevious()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("上一题")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(store.currentIndex == 0 ? AppTheme.textSecondary : AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(AppTheme.separator, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(store.currentIndex == 0)

            Button {
                Task { await store.goNext() }
            } label: {
                HStack(spacing: 6) {
                    Text(store.currentIndex + 1 >= category.questionCount ? "已到末题" : "下一题")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [group.palette.0, group.palette.1],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .disabled(store.currentIndex + 1 >= category.questionCount)
            .opacity(store.currentIndex + 1 >= category.questionCount ? 0.45 : 1)
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }

    private func optionLabel(for index: Int) -> String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        return letters[safe: index] ?? "?"
    }

    private func optionBackground(index: Int, question: KnowledgeWikiQuestion) -> Color {
        guard let selected = store.currentSelection else { return AppTheme.card }
        if question.correctIndex == index {
            return AppTheme.accentBamboo.opacity(0.1)
        }
        if selected == index {
            return AppTheme.accentCinnabar.opacity(0.08)
        }
        return AppTheme.card
    }

    private func optionBorder(index: Int, question: KnowledgeWikiQuestion) -> Color {
        guard let selected = store.currentSelection else { return AppTheme.separator }
        if question.correctIndex == index {
            return AppTheme.accentBamboo.opacity(0.35)
        }
        if selected == index {
            return AppTheme.accentCinnabar.opacity(0.28)
        }
        return AppTheme.separator
    }

    private func optionBadgeFill(index: Int, question: KnowledgeWikiQuestion) -> Color {
        guard let selected = store.currentSelection else { return group.palette.0.opacity(0.12) }
        if question.correctIndex == index {
            return AppTheme.accentBamboo
        }
        if selected == index {
            return AppTheme.accentCinnabar
        }
        return group.palette.0.opacity(0.12)
    }

    private func optionBadgeTextColor(index: Int, question: KnowledgeWikiQuestion) -> Color {
        guard store.currentSelection != nil else { return group.palette.0 }
        if question.correctIndex == index {
            return .white
        }
        if store.currentSelection == index {
            return .white
        }
        return group.palette.0
    }

    private func optionHighlightColor(index: Int, question: KnowledgeWikiQuestion) -> Color {
        if question.correctIndex == index {
            return AppTheme.accentBamboo
        }
        if store.currentSelection == index {
            return AppTheme.accentCinnabar
        }
        return AppTheme.textSecondary
    }

    private func optionSymbol(index: Int, question: KnowledgeWikiQuestion) -> String? {
        guard let selected = store.currentSelection else { return nil }
        if question.correctIndex == index {
            return "checkmark.circle.fill"
        }
        if selected == index {
            return "xmark.circle.fill"
        }
        return nil
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            ProgressView("正在装载题库...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .tint(group.palette.0)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            Image(systemName: "questionmark.folder")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Text("题库加载失败")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppTheme.paddingScreen)
    }
}
