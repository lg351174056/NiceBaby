import Foundation

struct BishenFeatureArticle: Identifiable, Hashable, Decodable {
    struct Route: Hashable, Decodable {
        struct Info: Hashable, Decodable {
            let targetId: String
            let url: String
            let oneCmt: Bool?

            enum CodingKeys: String, CodingKey {
                case targetId = "targetId"
                case url
                case oneCmt
            }
        }

        let path: String
        let info: Info
    }

    var id: String { uuid }
    let rawId: String
    let uuid: String
    let triggerQuery: String
    let queryBannerDesc: String
    let queryBannerImageURL: String
    let backgroundImageURL: String?
    let releaseDate: TimeInterval
    let route: Route

    enum CodingKeys: String, CodingKey {
        case rawId = "id"
        case uuid
        case triggerQuery
        case queryBannerDesc
        case queryBannerImageURL = "queryBannerImageUrl"
        case backgroundImageURL = "bgImageUrl"
        case releaseDate = "release_date"
        case route
    }
}

struct BishenFeatureComment: Identifiable, Hashable, Decodable {
    let id: String
    let content: String
    let createdAt: TimeInterval
    let likeCount: Int
    let userNick: String
    let userIcon: String?

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case createdAt = "created_at"
        case likeCount = "like_count"
        case userNick = "user_nick"
        case userIcon = "user_icon"
    }
}

struct BishenFeatureArticleDetail: Hashable {
    let html: String
    let comments: [BishenFeatureComment]
}

enum BishenFeatureArticleError: LocalizedError {
    case invalidURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "文章接口地址无效"
        case .invalidResponse:
            return "文章数据解析失败"
        }
    }
}

final class BishenFeatureArticleService {
    static let shared = BishenFeatureArticleService()

    private let listBaseURL = "http://zw3.api.bishen.ink"
    private let commentBaseURL = "https://v4.api.bishen.ink"
    private let session: URLSession
    private let decoder: JSONDecoder

    private init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetchAllArticles() async throws -> [BishenFeatureArticle] {
        var allArticles: [BishenFeatureArticle] = []
        var offset = 0

        while true {
            let response: LatestResponse = try await fetchJSON(
                baseURL: listBaseURL,
                path: "/api/zw/latest-xss",
                queryItems: [URLQueryItem(name: "offset", value: String(offset))]
            )

            guard !response.results.isEmpty else { break }

            allArticles += response.results
            offset += response.results.count

            if response.results.count < 10 { break }
        }

        var seen = Set<String>()
        return allArticles.filter { article in
            seen.insert(article.id).inserted
        }
    }

    func fetchCommentTotals(targetIDs: [String]) async throws -> [String: Int] {
        let uniqueIDs = Array(Set(targetIDs))
        guard !uniqueIDs.isEmpty else { return [:] }

        var totals: [String: Int] = [:]

        for chunk in uniqueIDs.chunked(into: 10) {
            let response: CommentTotalsResponse = try await postJSON(
                baseURL: commentBaseURL,
                path: "/api/zw/comments/totals",
                body: ["refids": chunk]
            )

            for count in response.counts {
                totals[count.k] = count.c
            }
        }

        return totals
    }

    func fetchDetail(for article: BishenFeatureArticle) async throws -> BishenFeatureArticleDetail {
        async let html = fetchHTML(urlString: article.route.info.url)
        async let comments = fetchTopComments(targetID: article.targetID, limit: 3)
        return try await BishenFeatureArticleDetail(html: html, comments: comments)
    }

    func fetchTopComments(targetID: String, limit: Int = 3) async throws -> [BishenFeatureComment] {
        let response: TopCommentsResponse = try await fetchJSON(
            baseURL: commentBaseURL,
            path: "/api/cmt/rating-comments-with-rank",
            queryItems: [
                URLQueryItem(name: "target_id", value: targetID),
                URLQueryItem(name: "offset", value: "0"),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
        return response.comments
    }

    private func fetchHTML(urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw BishenFeatureArticleError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode),
              let html = String(data: data, encoding: .utf8) else {
            throw BishenFeatureArticleError.invalidResponse
        }

        return html
    }

    private func fetchJSON<T: Decodable>(
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        guard var components = URLComponents(string: baseURL + path) else {
            throw BishenFeatureArticleError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw BishenFeatureArticleError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw BishenFeatureArticleError.invalidResponse
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw BishenFeatureArticleError.invalidResponse
        }
    }

    private func postJSON<T: Decodable>(
        baseURL: String,
        path: String,
        body: [String: [String]]
    ) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw BishenFeatureArticleError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw BishenFeatureArticleError.invalidResponse
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw BishenFeatureArticleError.invalidResponse
        }
    }
}

private struct LatestResponse: Decodable {
    let code: Int
    let results: [BishenFeatureArticle]
}

private struct CommentTotalsResponse: Decodable {
    struct Count: Decodable {
        let c: Int
        let k: String
    }

    let code: Int
    let counts: [Count]
}

private struct TopCommentsResponse: Decodable {
    let code: Int
    let comments: [BishenFeatureComment]
}

private extension BishenFeatureArticle {
    var targetID: String { route.info.targetId }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
