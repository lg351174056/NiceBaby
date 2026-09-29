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

// MARK: - 田园风扩展（知识百科专属点缀）

extension KnowledgeWikiGroup {
    /// 分组 emoji 点缀
    var wikiEmoji: String {
        switch id {
        case "13": return "🌐"
        case "2": return "📜"
        case "3": return "🎈"
        case "16": return "🎋"
        case "18": return "🎓"
        default: return "🧠"
        }
    }

    /// 分组淡彩底 + 深色（蓝天草地田园系）
    var wikiTint: (Color, Color) {
        switch id {
        case "13":
            return (AppTheme.fieldMint, Color(red: 227/255, green: 242/255, blue: 234/255))          // 薄荷
        case "2":
            return (Color(red: 194/255, green: 162/255, blue: 72/255), Color(red: 255/255, green: 243/255, blue: 214/255))  // 米金
        case "3":
            return (Color(red: 186/255, green: 80/255, blue: 100/255), Color(red: 253/255, green: 233/255, blue: 238/255))  // 绯粉
        case "16":
            return (Color(red: 59/255, green: 142/255, blue: 165/255), Color(red: 232/255, green: 244/255, blue: 247/255))  // 湖蓝
        case "18":
            return (Color(red: 92/255, green: 156/255, blue: 102/255), Color(red: 234/255, green: 245/255, blue: 228/255))  // 竹绿
        default:
            return (Color(red: 92/255, green: 75/255, blue: 138/255), Color(red: 240/255, green: 234/255, blue: 248/255))  // 墨紫
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

    /// 答对数
    var correctAnswerCount: Int {
        answerSelections.reduce(0) { partial, entry in
            guard let q = questions.first(where: { $0.id == entry.key }) else { return partial }
            return partial + (entry.value == q.correctIndex ? 1 : 0)
        }
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

// MARK: - 知识百科 · 田园风通用组件

/// 顶部导航（田园风）
private struct WikiNavBar: View {
    let title: String
    var trailing: (() -> AnyView)? = nil

    var body: some View {
        ZStack {
            HStack {
                GracefulBackButton()
                Spacer()
            }
            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
                .lineLimit(1)
        }
        .overlay(alignment: .trailing) {
            if let trailing { trailing() }
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }
}

/// 分区标题（绿条 + 楷体）
private struct WikiSectionTitle: View {
    let title: String
    let sub: String
    var showMore = false

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(AppTheme.fieldMint)
                .frame(width: 6, height: 20)
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
                .tracking(1)
            Text(sub)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.fieldMossLight)
            Spacer()
            if showMore {
                Text("全部 ›")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMint)
            }
        }
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
        ZStack {
            FieldBackground()

            // 田园点缀：太阳 + 云朵
            FieldSun()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 20)
                .padding(.top, 30)
                .allowsHitTesting(false)
            FieldCloud(scale: 1.0, delay: 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, 8)
                .padding(.top, 52)
                .allowsHitTesting(false)
            FieldCloud(scale: 0.72, delay: 2.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 20)
                .padding(.top, 78)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                WikiNavBar(title: "知识百科")

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
        }
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
            VStack(alignment: .leading, spacing: 0) {
                heroCard
                statsRow
                searchBar

                if let errorMessage = store.errorMessage {
                    inlineError(message: errorMessage)
                }

                if !searchText.isEmpty {
                    searchSection
                        .padding(.top, 14)
                } else {
                    featuredSection
                        .padding(.top, 14)

                    WikiSectionTitle(title: "漫游分组", sub: "GROUPS", showMore: true)
                        .padding(.top, 16)
                        .padding(.bottom, 10)

                    ForEach(Array(store.groups.enumerated()), id: \.element.id) { index, group in
                        groupSection(group, index: index)
                    }

                    footerCard
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 10)
            .padding(.bottom, 40)
        }
    }

    // MARK: Hero 卡（田园白卡）

    private var heroCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 227/255, green: 242/255, blue: 234/255),
                            Color(red: 189/255, green: 232/255, blue: 211/255)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("📚")
                    .font(.system(size: 24))
                    .modifier(FieldBob(delay: 0))
            }
            .frame(width: 52, height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.fieldMint.opacity(0.4), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("知识百科")
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("把海量题库做成一座可以漫游的知识花园")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                HStack(spacing: 10) {
                    Text("📖 百科")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMint)
                    Text("🧠 智力")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMint)
                    Text("🎢 急转弯")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.fieldGold)
                }
                .padding(.top, 2)
            }
            Spacer()
            VStack(spacing: 6) {
                Text("🍃")
                    .font(.system(size: 15))
                    .modifier(FieldFlutter(delay: 0.5))
                Text("🦋")
                    .font(.system(size: 15))
                    .modifier(FieldFlutter(delay: 1.2, reverse: true))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppTheme.fieldMint.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 8, y: 4)
        )
    }

    // MARK: 三统计卡

    private var statsRow: some View {
        HStack(spacing: 10) {
            wikiStat(emoji: "🌐", value: "\(store.status.wiki)", label: "百科题")
            wikiStat(emoji: "🧠", value: "\(store.status.iq)", label: "智力题")
            wikiStat(emoji: "🎢", value: "\(store.status.brain)", label: "急转弯")
        }
        .padding(.top, 12)
    }

    private func wikiStat(emoji: String, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(emoji).font(.system(size: 15))
            Text(value)
                .font(.system(size: 17, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.fieldMoss)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.06), radius: 5, y: 3)
        )
    }

    // MARK: 搜索栏

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.fieldMoss)

            TextField("搜索分类，比如 国学 / 地理 / 经典题库", text: $searchText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.fieldInk)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.fieldMossLight)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 1.5)
                )
        )
        .padding(.top, 12)
    }

    // MARK: 热门先逛（1 大卡 + 2 小卡）

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            WikiSectionTitle(title: "热门先逛", sub: "CURATED")

            HStack(spacing: 10) {
                if let big = store.topSelections.first {
                    NavigationLink {
                        KnowledgeWikiQuizView(group: big.group, category: big.category)
                    } label: {
                        featuredBigCard(big)
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 10) {
                    ForEach(Array(store.topSelections.dropFirst().prefix(2))) { selection in
                        NavigationLink {
                            KnowledgeWikiQuizView(group: selection.group, category: selection.category)
                        } label: {
                            featuredSmallCard(selection)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 210)
        }
    }

    private func featuredBigCard(_ selection: KnowledgeWikiCategorySelection) -> some View {
        let tint = selection.group.wikiTint
        return ZStack(alignment: .bottomTrailing) {
            Text(selection.group.shortMark)
                .font(.system(size: 96, weight: .black, design: .serif))
                .foregroundStyle(tint.0.opacity(0.12))
                .offset(x: 14, y: 20)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.1)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Text(selection.group.wikiEmoji)
                            .font(.system(size: 17))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(tint.0.opacity(0.4), lineWidth: 1.5)
                    )

                Spacer(minLength: 12)

                Text(selection.category.name)
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .lineLimit(2)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(selection.category.questionCount)")
                        .font(.system(size: 17, weight: .black, design: .serif))
                        .foregroundStyle(tint.0)
                    Text("题 · \(selection.group.name)")
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                    Spacer(minLength: 0)
                    Circle()
                        .fill(tint.1)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(tint.0)
                        )
                }
                .padding(.top, 6)
            }
            .padding(15)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.94), tint.1.opacity(0.7)],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(tint.0.opacity(0.32), lineWidth: 1.5)
        )
        .shadow(color: AppTheme.fieldGrassShadow.opacity(0.06), radius: 5, y: 3)
    }

    private func featuredSmallCard(_ selection: KnowledgeWikiCategorySelection) -> some View {
        let tint = selection.group.wikiTint
        return ZStack(alignment: .bottomTrailing) {
            Text(selection.group.shortMark)
                .font(.system(size: 52, weight: .black, design: .serif))
                .foregroundStyle(tint.0.opacity(0.10))
                .offset(x: 8, y: 10)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.1)
                    .frame(width: 26, height: 26)
                    .overlay(
                        Text(selection.group.wikiEmoji)
                            .font(.system(size: 13))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(tint.0.opacity(0.4), lineWidth: 1.5)
                    )

                Spacer(minLength: 8)

                Text(selection.category.name)
                    .font(.system(size: 12.5, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(selection.category.questionCount)")
                        .font(.system(size: 14, weight: .black, design: .serif))
                        .foregroundStyle(tint.0)
                    Text("题")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                    Spacer(minLength: 0)
                    Circle()
                        .fill(tint.1)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(tint.0)
                        )
                }
                .padding(.top, 4)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(tint.0.opacity(0.22), lineWidth: 1.5)
        )
    }

    // MARK: 分组卡

    private func groupSection(_ group: KnowledgeWikiGroup, index: Int) -> some View {
        let tint = group.wikiTint
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.1)
                        .frame(width: 38, height: 38)
                    Text(group.wikiEmoji)
                        .font(.system(size: 18))
                        .modifier(FieldBob(delay: Double(index % 5) * 0.2))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(tint.0.opacity(0.35), lineWidth: 1.5)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.system(size: 14, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                    Text("\(group.categories.count) 个门类 · \(group.totalQuestions) 题")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                }
                Spacer()
                Text("›")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.fieldMossLight)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)], spacing: 9) {
                ForEach(group.categories) { category in
                    NavigationLink {
                        KnowledgeWikiQuizView(group: group, category: category)
                    } label: {
                        categoryTile(category, tint: tint)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 1.5)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.06), radius: 6, y: 3)
        )
        .padding(.bottom, 12)
    }

    private func categoryTile(_ category: KnowledgeWikiCategory, tint: (Color, Color)) -> some View {
        HStack(spacing: 8) {
            Text(category.name)
                .font(.system(size: 11.5, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldOliveDeep)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(category.questionCount)")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(tint.0)

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppTheme.fieldMossLight)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.1.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(tint.0.opacity(0.25), lineWidth: 1.5)
                )
        )
    }

    // MARK: 搜索结果

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            WikiSectionTitle(title: "搜索结果", sub: "SEARCH")

            if searchResults.isEmpty {
                Text("没有找到对应门类，换个关键词试试。")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 1.5)
                            )
                    )
            } else {
                VStack(spacing: 10) {
                    ForEach(searchResults) { selection in
                        NavigationLink {
                            KnowledgeWikiQuizView(group: selection.group, category: selection.category)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(selection.group.wikiTint.1)
                                        .frame(width: 40, height: 40)
                                    Text(selection.group.wikiEmoji)
                                        .font(.system(size: 17))
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(selection.group.wikiTint.0.opacity(0.35), lineWidth: 1.5)
                                )

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(selection.category.name)
                                        .font(.system(size: 14, weight: .bold, design: .serif))
                                        .foregroundStyle(AppTheme.fieldInk)
                                    Text("\(selection.group.name) · \(selection.category.questionCount) 题")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(AppTheme.fieldMoss)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppTheme.fieldMossLight)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.9))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 1.5)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: 底部卡

    private var footerCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 234/255, green: 245/255, blue: 228/255))
                    .frame(width: 40, height: 40)
                Text("🎉")
                    .font(.system(size: 18))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppTheme.fieldMint.opacity(0.35), lineWidth: 1.5)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("入口已全量接入")
                    .font(.system(size: 14, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("共 \(KnowledgeWikiService.snapshotCategoryCount) 个门类，约 \(KnowledgeWikiService.snapshotQuestionCount) 道题，支持继续扩展与分页续拉。")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(AppTheme.fieldMint.opacity(0.25), lineWidth: 1.5)
                )
        )
    }

    private func inlineError(message: String) -> some View {
        Text(message)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(red: 232/255, green: 106/255, blue: 82/255))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 232/255, green: 106/255, blue: 82/255).opacity(0.08))
            )
            .padding(.top, 12)
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            ProgressView("正在整理百科入口...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .tint(AppTheme.fieldMint)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            Text("🌱")
                .font(.system(size: 34))
            Text("知识百科加载失败")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.fieldMoss)
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

    private var tint: (Color, Color) { group.wikiTint }

    var body: some View {
        ZStack {
            FieldBackground()

            FieldSun()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 20)
                .padding(.top, 30)
                .allowsHitTesting(false)
            FieldCloud(scale: 0.72, delay: 2.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 20)
                .padding(.top, 76)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                WikiNavBar(title: category.name) {
                    AnyView(
                        Button {
                            Task { await store.reload() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.fieldMint)
                                .frame(width: 34, height: 34)
                                .background(Color.white.opacity(0.9), in: Circle())
                                .overlay(Circle().strokeBorder(AppTheme.fieldMint.opacity(0.35), lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    )
                }

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
        }
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
            VStack(alignment: .leading, spacing: 12) {
                // 题号行：胶囊 + 进度信息
                HStack(spacing: 10) {
                    Text("第 \(store.currentIndex + 1) 题")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.fieldMint, in: Capsule())
                        .overlay(Capsule().strokeBorder(AppTheme.fieldInk, lineWidth: 1.5))

                    Text("共 \(category.questionCount) 题 · 已答对 \(store.correctAnswerCount)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)

                    Spacer()

                    Text(group.wikiEmoji)
                        .font(.system(size: 16))
                        .modifier(FieldBob(delay: 0))
                }

                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 232/255, green: 106/255, blue: 82/255))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(red: 232/255, green: 106/255, blue: 82/255).opacity(0.08))
                        )
                }

                if let question = store.currentQuestion {
                    questionCard(question)
                        .id(question.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }

                if store.isLoadingMore {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(AppTheme.fieldMint)
                        Text("正在为你续拉更多题目...")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.fieldMoss)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 1.5)
                            )
                    )
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 10)
            .padding(.bottom, 20)
            .animation(.easeOut(duration: 0.3), value: store.currentIndex)
        }
    }

    // MARK: 题目卡

    private func questionCard(_ question: KnowledgeWikiQuestion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Text("\(group.wikiEmoji) \(category.name)")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(tint.0)
                Text("· \(group.name)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                Spacer()
                Text("#\(question.remoteID)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMossLight)
            }

            Text(question.content)
                .font(.system(size: 19, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
                .lineSpacing(6)

            VStack(spacing: 9) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    optionButton(
                        label: optionLabel(for: index),
                        text: option,
                        index: index,
                        question: question
                    )
                }
            }
            .padding(.top, 2)

            if let selection = store.currentSelection {
                answerResultView(question: question, selection: selection)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 8, y: 4)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: store.currentSelection)
    }

    private func optionButton(label: String, text: String, index: Int, question: KnowledgeWikiQuestion) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                store.selectOption(index)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(optionBadgeFill(index: index, question: question))
                        .frame(width: 30, height: 30)
                    Text(label)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(optionBadgeTextColor(index: index, question: question))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(optionBadgeBorder(index: index, question: question), lineWidth: 1.5)
                )

                Text(text)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.fieldInk)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let symbol = optionSymbol(index: index, question: question) {
                    Image(systemName: symbol)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(optionHighlightColor(index: index, question: question))
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(optionBackground(index: index, question: question))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .strokeBorder(optionBorder(index: index, question: question), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(store.currentSelection == index ? 0.985 : 1)
    }

    private func answerResultView(question: KnowledgeWikiQuestion, selection: Int) -> some View {
        let correct = selection == question.correctIndex
        return HStack(alignment: .top, spacing: 10) {
            Text(correct ? "🎉" : "💡")
                .font(.system(size: 20))
                .modifier(FieldBob(delay: 0))

            VStack(alignment: .leading, spacing: 5) {
                Text(correct ? "答对了，继续向前。" : "这题拐了个弯。")
                    .font(.system(size: 14, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("正确答案：\(question.correctLetter) · \(question.correctAnswerText)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill((correct ? AppTheme.fieldMint : AppTheme.fieldGold).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder((correct ? AppTheme.fieldMint : AppTheme.fieldGold).opacity(0.3), lineWidth: 1.5)
                )
        )
    }

    // MARK: 底部操作栏

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                store.goPrevious()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("上一题")
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(store.currentIndex == 0 ? AppTheme.fieldMossLight : AppTheme.fieldOliveDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(Color.white.opacity(0.94))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .strokeBorder(AppTheme.fieldInk, lineWidth: 2)
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
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(AppTheme.fieldMint)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .strokeBorder(AppTheme.fieldInk, lineWidth: 2)
                        )
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

    // MARK: 选项样式辅助

    private func optionLabel(for index: Int) -> String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        return letters[safe: index] ?? "?"
    }

    private func optionBackground(index: Int, question: KnowledgeWikiQuestion) -> Color {
        guard let selected = store.currentSelection else { return Color.white.opacity(0.5) }
        if question.correctIndex == index {
            return AppTheme.fieldMint.opacity(0.12)
        }
        if selected == index {
            return AppTheme.fieldMint.opacity(0.18)
        }
        return Color.white.opacity(0.5)
    }

    private func optionBorder(index: Int, question: KnowledgeWikiQuestion) -> Color {
        guard let selected = store.currentSelection else { return AppTheme.fieldOlive.opacity(0.3) }
        if question.correctIndex == index {
            return AppTheme.fieldMint.opacity(0.6)
        }
        if selected == index {
            return AppTheme.fieldMint
        }
        return AppTheme.fieldOlive.opacity(0.3)
    }

    private func optionBadgeFill(index: Int, question: KnowledgeWikiQuestion) -> Color {
        guard let selected = store.currentSelection else { return tint.1 }
        if question.correctIndex == index {
            return AppTheme.fieldMint
        }
        if selected == index {
            return AppTheme.fieldMint
        }
        return tint.1
    }

    private func optionBadgeBorder(index: Int, question: KnowledgeWikiQuestion) -> Color {
        guard let selected = store.currentSelection else { return tint.0.opacity(0.35) }
        if question.correctIndex == index || selected == index {
            return AppTheme.fieldMint
        }
        return tint.0.opacity(0.35)
    }

    private func optionBadgeTextColor(index: Int, question: KnowledgeWikiQuestion) -> Color {
        guard store.currentSelection != nil else { return tint.0 }
        if question.correctIndex == index {
            return .white
        }
        if store.currentSelection == index {
            return .white
        }
        return tint.0
    }

    private func optionHighlightColor(index: Int, question: KnowledgeWikiQuestion) -> Color {
        if question.correctIndex == index {
            return AppTheme.fieldMint
        }
        if store.currentSelection == index {
            return AppTheme.fieldMint
        }
        return AppTheme.fieldMossLight
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
                .tint(AppTheme.fieldMint)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            Text("📭")
                .font(.system(size: 34))
            Text("题库加载失败")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.fieldMoss)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppTheme.paddingScreen)
    }
}
