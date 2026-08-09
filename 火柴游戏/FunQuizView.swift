import SwiftUI

// MARK: - 趣味答题 · 分类定义

struct FunQuizCategory: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
    let gradient: [Color]
    let totalQuestionCount: Int

    var prompt: String {
        switch id {
        case "40": return "新百科 · 地理"
        case "41": return "新百科 · 文化"
        case "42": return "新百科 · 科学"
        case "43": return "新百科 · 历史"
        case "44": return "新百科 · 社交"
        case "60": return "新百科 · 电影电视"
        case "63": return "新百科 · 体育"
        case "72": return "新百科 · 自然"
        default: return title
        }
    }

    static let totalQuestionCount = all.reduce(0) { $0 + $1.totalQuestionCount }

    static let all: [FunQuizCategory] = [
        FunQuizCategory(
            id: "40",
            title: "地理",
            subtitle: "国家、城市、地标与世界知识",
            symbolName: "globe.europe.africa.fill",
            gradient: [AppTheme.accentIndigo, AppTheme.accentJade],
            totalQuestionCount: 832
        ),
        FunQuizCategory(
            id: "41",
            title: "文化",
            subtitle: "神话、文学、艺术、语言与风俗",
            symbolName: "theatermasks.fill",
            gradient: [AppTheme.accentPink, AppTheme.accentInkPurple],
            totalQuestionCount: 1860
        ),
        FunQuizCategory(
            id: "42",
            title: "科学",
            subtitle: "人体、现象、医学、工具与常识",
            symbolName: "cross.case.fill",
            gradient: [AppTheme.accentJade, AppTheme.accentBamboo],
            totalQuestionCount: 1163
        ),
        FunQuizCategory(
            id: "43",
            title: "历史",
            subtitle: "人物、古城、典故与文明坐标",
            symbolName: "building.columns.fill",
            gradient: [AppTheme.accentYellow, AppTheme.accentCinnabar],
            totalQuestionCount: 840
        ),
        FunQuizCategory(
            id: "44",
            title: "社交",
            subtitle: "性格、心理、关系与社会认知",
            symbolName: "person.2.fill",
            gradient: [AppTheme.accentInkPurple, AppTheme.accentPink],
            totalQuestionCount: 676
        ),
        FunQuizCategory(
            id: "60",
            title: "电影电视",
            subtitle: "电影、动画、电视剧与银幕彩蛋",
            symbolName: "popcorn.fill",
            gradient: [AppTheme.accentCinnabar, AppTheme.accentPink],
            totalQuestionCount: 412
        ),
        FunQuizCategory(
            id: "63",
            title: "体育",
            subtitle: "球场、拳台、规则与冠军故事",
            symbolName: "sportscourt.fill",
            gradient: [AppTheme.accentBamboo, AppTheme.accentIndigo],
            totalQuestionCount: 246
        ),
        FunQuizCategory(
            id: "72",
            title: "自然",
            subtitle: "动物、植物、宝石与自然万象",
            symbolName: "leaf.fill",
            gradient: [AppTheme.accentJade, AppTheme.accentYellow],
            totalQuestionCount: 1025
        )
    ]
}

// MARK: - 趣味答题 · 数据模型

struct FunQuizQuestion: Identifiable, Hashable {
    let remoteID: Int
    let categoryID: String
    let content: String
    let options: [String]
    let correctLetter: String
    let analysis: String
    let thumbnailURL: URL?
    let imageURL: URL?

    var id: String { "\(categoryID)-\(remoteID)" }

    var correctIndex: Int? {
        guard let scalar = correctLetter.uppercased().unicodeScalars.first else { return nil }
        let value = Int(scalar.value) - 65
        guard value >= 0, value < options.count else { return nil }
        return value
    }

    var correctAnswerText: String {
        guard let correctIndex, options.indices.contains(correctIndex) else { return "暂无" }
        return options[correctIndex]
    }
}

private struct FunQuizQuestionPayload: Decodable {
    let content: String
    let optionsPayload: String
    let id: String
    let correct: String
    let categoryID: String
    let thumbnailPath: String?
    let imagePath: String?
    let analysis: String

    enum CodingKeys: String, CodingKey {
        case content
        case optionsPayload = "options"
        case id
        case correct
        case categoryID = "quiz_category"
        case thumbnailPath = "thumbnail_img_url"
        case imagePath = "img_url"
        case analysis
    }

    var question: FunQuizQuestion {
        let decodedOptions = (try? JSONDecoder().decode([String].self, from: Data(optionsPayload.utf8))) ?? []
        return FunQuizQuestion(
            remoteID: Int(id) ?? 0,
            categoryID: categoryID,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            options: decodedOptions.map {
                $0.replacingOccurrences(of: #"^[A-Z][\.\、]\s*"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            },
            correctLetter: correct,
            analysis: analysis.trimmingCharacters(in: .whitespacesAndNewlines),
            thumbnailURL: Self.makeURL(path: thumbnailPath),
            imageURL: Self.makeURL(path: imagePath)
        )
    }

    private static func makeURL(path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "http://m.beauty-story.cn/\(path)")
    }
}

private struct FunQuizResponse: Decodable {
    let data: [FunQuizQuestionPayload]
}

enum FunQuizError: LocalizedError {
    case invalidURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "趣味答题接口地址无效"
        case .invalidResponse:
            return "趣味答题返回内容解析失败"
        }
    }
}

// MARK: - 趣味答题 · 服务

final class FunQuizService {
    static let shared = FunQuizService()

    private let baseURL = "http://m.beauty-story.cn"
    private let session: URLSession
    private let decoder = JSONDecoder()

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchQuestions(categoryID: String, after questionID: Int = 0) async throws -> [FunQuizQuestion] {
        let response: FunQuizResponse = try await fetch(
            path: "/api/baikequiz/qlist",
            queryItems: [
                URLQueryItem(name: "quizCategory", value: categoryID),
                URLQueryItem(name: "paperType", value: "3"),
                URLQueryItem(name: "id", value: String(questionID)),
                URLQueryItem(name: "isNotPass", value: "true")
            ]
        )
        return response.data.map(\.question)
    }

    private func fetch<T: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> T {
        guard var components = URLComponents(string: baseURL + path) else {
            throw FunQuizError.invalidURL
        }
        components.queryItems = queryItems
        guard let url = components.url else {
            throw FunQuizError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("*/*", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw FunQuizError.invalidResponse
        }

        guard let decodedData = decodeServerPayload(data) else {
            throw FunQuizError.invalidResponse
        }

        do {
            return try decoder.decode(T.self, from: decodedData)
        } catch {
            throw FunQuizError.invalidResponse
        }
    }

    // 服务端通常直接返回 base64 文本，URLSession 会自动处理压缩层。
    private func decodeServerPayload(_ data: Data) -> Data? {
        if data.first == UInt8(ascii: "{") || data.first == UInt8(ascii: "[") {
            return data
        }

        guard let text = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return nil }

        if text.first == "{" || text.first == "[" {
            return Data(text.utf8)
        }

        if let base64Data = Data(base64Encoded: text) {
            if base64Data.first == UInt8(ascii: "{") || base64Data.first == UInt8(ascii: "[") {
                return base64Data
            }
            if let base64Text = String(data: base64Data, encoding: .utf8),
               base64Text.first == "{" || base64Text.first == "[" {
                return Data(base64Text.utf8)
            }
        }

        return nil
    }
}

// MARK: - 趣味答题 · 首页 Store

@Observable
final class FunQuizHomeStore {
    private let service: FunQuizService

    private(set) var previews: [String: FunQuizQuestion] = [:]
    private(set) var loadedCounts: [String: Int] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    let categories = FunQuizCategory.all

    init(service: FunQuizService = .shared) {
        self.service = service
    }

    func loadIfNeeded() async {
        guard previews.isEmpty else { return }
        await load()
    }

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await withThrowingTaskGroup(of: (String, FunQuizQuestion?, Int).self) { group in
                for category in categories {
                    group.addTask {
                        let questions = try await self.service.fetchQuestions(categoryID: category.id)
                        return (category.id, questions.first, questions.count)
                    }
                }

                for try await (categoryID, preview, count) in group {
                    if let preview {
                        previews[categoryID] = preview
                    }
                    loadedCounts[categoryID] = count
                }
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var totalLoadedCount: Int {
        loadedCounts.values.reduce(0, +)
    }
}

// MARK: - 趣味答题 · 题库 Store

@Observable
final class FunQuizPlayStore {
    private let service: FunQuizService
    let category: FunQuizCategory

    private(set) var questions: [FunQuizQuestion] = []
    private(set) var currentIndex = 0
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var errorMessage: String?
    private(set) var selectedAnswers: [String: Int] = [:]
    private var reachedEnd = false

    init(category: FunQuizCategory, service: FunQuizService = .shared) {
        self.category = category
        self.service = service
    }

    var currentQuestion: FunQuizQuestion? {
        questions[safe: currentIndex]
    }

    var answeredCount: Int {
        selectedAnswers.count
    }

    var currentSelection: Int? {
        guard let currentQuestion else { return nil }
        return selectedAnswers[currentQuestion.id]
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
        selectedAnswers = [:]
        reachedEnd = false

        do {
            let batch = try await service.fetchQuestions(categoryID: category.id)
            questions = batch
            reachedEnd = batch.isEmpty
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func selectOption(_ index: Int) {
        guard let currentQuestion else { return }
        selectedAnswers[currentQuestion.id] = index
    }

    @MainActor
    func previous() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    @MainActor
    func next() async {
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
            let known = Set(questions.map(\.id))
            let fresh = batch.filter { !known.contains($0.id) }
            if fresh.isEmpty {
                reachedEnd = true
            } else {
                questions += fresh
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

// MARK: - 趣味答题 · 首页

struct FunQuizHomeView: View {
    @State private var store = FunQuizHomeStore()

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

            homeSun
            homeCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            homeCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text("趣味答题")
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                Group {
                    if store.isLoading && store.previews.isEmpty {
                        loadingView
                    } else {
                        contentView
                    }
                }
            }
        }
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
            VStack(alignment: .leading, spacing: 16) {
                heroCard

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

                sectionTitle("八个栏目", sub: "NEW WIKI")

                ForEach(store.categories) { category in
                    NavigationLink {
                        FunQuizPlayView(category: category)
                    } label: {
                        categoryCard(category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 14)
            .padding(.bottom, 30)
        }
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [Color(red: 143/255, green: 227/255, blue: 192/255), Color(red: 76/255, green: 175/255, blue: 125/255), Color(red: 46/255, green: 125/255, blue: 91/255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.1))
                .frame(width: 180, height: 180)
                .offset(x: 72, y: 84)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("FUN QUIZ")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2.1)
                        .foregroundStyle(.white.opacity(0.86))
                    Spacer()
                    Text("轻松开答")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.14), in: Capsule())
                }

                Text("趣味答题")
                    .font(.system(size: 30, weight: .heavy, design: .serif))
                    .foregroundStyle(.white)

                Text("八个栏目，装下一整片有趣的知识世界。想逛地理、文化、科学，还是电影电视，点进去就能接着玩。")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineSpacing(4)

                HStack(spacing: 10) {
                    heroMetric(value: "\(store.categories.count)", label: "栏目")
                    heroMetric(value: "\(FunQuizCategory.totalQuestionCount)", label: "总题量")
                    heroMetric(value: "\(store.totalLoadedCount)", label: "已载入")
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

    private func heroMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func categoryCard(_ category: FunQuizCategory) -> some View {
        let preview = store.previews[category.id]
        let loadedCount = store.loadedCounts[category.id] ?? 0

        return HStack(spacing: 14) {
            ZStack {
                LinearGradient(
                    colors: category.gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 72, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                Image(systemName: category.symbolName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(category.title)
                    .font(.system(size: 20, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(category.subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)

                if let preview, !preview.content.isEmpty {
                    Text("例如：\(preview.content)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.82))
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    metricPill(title: "总计 \(category.totalQuestionCount) 题", color: category.gradient.first ?? AppTheme.accentIndigo)
                    metricPill(title: "已装载 \(loadedCount) 题", color: category.gradient.last ?? AppTheme.accentJade)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.25), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 6, y: 3)
        )
    }

    private func metricPill(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.1), in: Capsule())
    }

    private func sectionTitle(_ title: String, sub: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
            Text(sub)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.7)
                .foregroundStyle(AppTheme.textSecondary.opacity(0.75))
            Rectangle()
                .fill(AppTheme.separator)
                .frame(height: 0.5)
            Spacer()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 80)
            ProgressView("正在整理趣味题库...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .tint(AppTheme.accentBamboo)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 背景装饰（太阳/云）

    private var homeSun: some View {
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

    private func homeCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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


// MARK: - 趣味答题 · 答题页

struct FunQuizPlayView: View {
    let category: FunQuizCategory
    @State private var store: FunQuizPlayStore
    @State private var showAnalysis = true

    init(category: FunQuizCategory) {
        self.category = category
        _store = State(initialValue: FunQuizPlayStore(category: category))
    }

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

            playSun
            playCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            playCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                        Button {
                            Task { await store.reload() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.9), in: Circle())
                                .overlay(Circle().strokeBorder(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.35), lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    }
                    Text(category.title)
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

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
                topCard

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
                            .tint(category.gradient.first ?? AppTheme.accentPink)
                        Text("正在续拉这一馆的更多题目...")
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

    private var topCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(category.prompt)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.8)
                        .foregroundStyle(category.gradient.first ?? AppTheme.accentPink)
                    Text(category.title)
                        .font(.system(size: 28, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill((category.gradient.first ?? AppTheme.accentPink).opacity(0.12))
                        .frame(width: 58, height: 58)
                    Image(systemName: category.symbolName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(category.gradient.first ?? AppTheme.accentPink)
                }
            }

            Text(category.subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(3)

            HStack(spacing: 10) {
                topMetric(value: "\(category.totalQuestionCount)", title: "总题量")
                topMetric(value: "\(store.questions.count)", title: "已装载")
                topMetric(value: "\(store.answeredCount)", title: "已作答")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.1), radius: 8, y: 4)
        )
    }

    private func topMetric(value: String, title: String) -> some View {
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
                .fill((category.gradient.first ?? AppTheme.accentPink).opacity(0.06))
        )
    }

    private func questionCard(_ question: FunQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("第 \(store.currentIndex + 1) 题")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(category.gradient.first ?? AppTheme.accentPink, in: Capsule())
                Spacer()
                Text("#\(question.remoteID)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if let imageURL = question.imageURL ?? question.thumbnailURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(AppTheme.separator.opacity(0.3))
                            .frame(height: 190)
                            .overlay(ProgressView().tint(category.gradient.first ?? AppTheme.accentPink))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 190)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    case .failure:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            Text(question.content)
                .font(.system(size: 24, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(6)

            VStack(spacing: 10) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    optionButton(question: question, index: index, option: option)
                }
            }

            if let selection = store.currentSelection {
                resultView(question: question, selection: selection)

                if showAnalysis, !question.analysis.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("解析")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(category.gradient.first ?? AppTheme.accentPink)
                        Text(question.analysis)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill((category.gradient.first ?? AppTheme.accentPink).opacity(0.06))
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.28), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.1), radius: 8, y: 4)
        )
    }

    private func optionButton(question: FunQuizQuestion, index: Int, option: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                store.selectOption(index)
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(optionBadgeFill(question: question, index: index))
                        .frame(width: 34, height: 34)
                    Text(optionLabel(index))
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(optionBadgeText(question: question, index: index))
                }

                Text(option)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let symbol = optionSymbol(question: question, index: index) {
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(optionAccent(question: question, index: index))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(optionBackground(question: question, index: index))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(optionBorder(question: question, index: index), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func resultView(question: FunQuizQuestion, selection: Int) -> some View {
        let correct = selection == question.correctIndex
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: correct ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(correct ? AppTheme.accentBamboo : AppTheme.accentCinnabar)

            VStack(alignment: .leading, spacing: 6) {
                Text(correct ? "这题拿下了。" : "这题有点会拐弯。")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("正确答案：\(question.correctLetter.uppercased()) · \(question.correctAnswerText)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showAnalysis.toggle()
                }
            } label: {
                Text(showAnalysis ? "收起解析" : "展开解析")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(category.gradient.first ?? AppTheme.accentPink)
            }
            .buttonStyle(.plain)
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
                store.previous()
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
                Task { await store.next() }
            } label: {
                HStack(spacing: 6) {
                    Text("下一题")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(red: 126/255, green: 211/255, blue: 160/255), Color(red: 76/255, green: 175/255, blue: 125/255)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color(red: 61/255, green: 74/255, blue: 54/255), lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }

    private func optionLabel(_ index: Int) -> String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        return letters[safe: index] ?? "?"
    }

    private func optionBackground(question: FunQuizQuestion, index: Int) -> Color {
        guard let selected = store.currentSelection else { return AppTheme.card }
        if question.correctIndex == index {
            return AppTheme.accentBamboo.opacity(0.1)
        }
        if selected == index {
            return AppTheme.accentCinnabar.opacity(0.08)
        }
        return AppTheme.card
    }

    private func optionBorder(question: FunQuizQuestion, index: Int) -> Color {
        guard let selected = store.currentSelection else { return AppTheme.separator }
        if question.correctIndex == index {
            return AppTheme.accentBamboo.opacity(0.32)
        }
        if selected == index {
            return AppTheme.accentCinnabar.opacity(0.28)
        }
        return AppTheme.separator
    }

    private func optionBadgeFill(question: FunQuizQuestion, index: Int) -> Color {
        guard store.currentSelection != nil else { return (category.gradient.first ?? AppTheme.accentPink).opacity(0.12) }
        if question.correctIndex == index {
            return AppTheme.accentBamboo
        }
        if store.currentSelection == index {
            return AppTheme.accentCinnabar
        }
        return (category.gradient.first ?? AppTheme.accentPink).opacity(0.12)
    }

    private func optionBadgeText(question: FunQuizQuestion, index: Int) -> Color {
        guard store.currentSelection != nil else { return category.gradient.first ?? AppTheme.accentPink }
        if question.correctIndex == index || store.currentSelection == index {
            return .white
        }
        return category.gradient.first ?? AppTheme.accentPink
    }

    private func optionAccent(question: FunQuizQuestion, index: Int) -> Color {
        if question.correctIndex == index {
            return AppTheme.accentBamboo
        }
        if store.currentSelection == index {
            return AppTheme.accentCinnabar
        }
        return AppTheme.textSecondary
    }

    private func optionSymbol(question: FunQuizQuestion, index: Int) -> String? {
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
            ProgressView("正在装载趣味题目...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .tint(AppTheme.accentBamboo)
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

    // MARK: - 背景装饰（太阳/云）

    private var playSun: some View {
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

    private func playCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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
