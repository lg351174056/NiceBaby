import Foundation

struct BishenAlbumsCatalog: Hashable {
    let albums: [BishenAlbum]
    let tags: [String]
}

struct BishenAlbum: Identifiable, Hashable, Decodable {
    let id: String
    let title: String
    let desc: String
    let coverURL: String
    let count: Int
    let countNew: Int?
    let updateDate: String
    let year: String?
    let tags: [String]?
    let createdAt: TimeInterval?
    let typeCode: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case desc
        case coverURL = "coverUrl"
        case count
        case countNew
        case updateDate
        case year
        case tags
        case createdAt
        case typeCode = "type"
    }
}

struct BishenArticleSummary: Identifiable, Hashable, Decodable {
    let id: String
    let title: String
    let author: String
    let preview: String?
    let grade: String?
    let gradeMode: String?
    let subCategory: String?
    let words: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case preview
        case grade
        case gradeMode = "grade_m"
        case subCategory = "sub_cate"
        case words
    }
}

struct BishenArticleDetail: Identifiable, Hashable, Decodable {
    let id: String
    let title: String
    let author: String
    let content: String
    let grade: String?
    let gradeMode: String?
    let subCategory: String?
    let albumTitle: String?
    let source: String?
    let score: Int?
    let reviewTag: String?
    let publishedAt: TimeInterval?
    let userID: String?
    let comments: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case content
        case grade
        case gradeMode = "grade_m"
        case subCategory = "sub_cate"
        case albumTitle = "album_title"
        case source = "src"
        case score
        case reviewTag = "review_tag"
        case publishedAt = "pub_at"
        case userID = "user_id"
        case comments
    }
}

enum BishenEssayError: LocalizedError {
    case invalidURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "接口地址无效"
        case .invalidResponse:
            return "返回内容无法解析"
        }
    }
}

final class BishenEssayService {
    static let shared = BishenEssayService()

    private let baseURL = "http://zw3.api.bishen.ink"
    private let session: URLSession
    private let decoder: JSONDecoder

    private init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetchAllAlbumsCatalog() async throws -> BishenAlbumsCatalog {
        var allAlbums: [BishenAlbum] = []
        var offset = 0
        var knownTags: [String] = []

        while true {
            let response: AlbumsResponse = try await fetch(
                path: "/api/v2/zw/albums",
                queryItems: [
                    URLQueryItem(name: "year", value: ""),
                    URLQueryItem(name: "offset", value: String(offset)),
                    URLQueryItem(name: "limit", value: "10")
                ]
            )

            if knownTags.isEmpty {
                knownTags = response.tags
            }

            guard !response.albums.isEmpty else { break }

            allAlbums += response.albums
            offset += response.albums.count
        }

        var seen = Set<String>()
        let deduplicated = allAlbums.filter { album in
            seen.insert(album.id).inserted
        }

        return BishenAlbumsCatalog(albums: deduplicated, tags: knownTags)
    }

    func fetchDailyRecommendations(dayKey: String? = nil) async throws -> [BishenArticleSummary] {
        let response: DailyResponse = try await fetch(
            path: "/api/zw/rec-daily",
            queryItems: [URLQueryItem(name: "daykey", value: dayKey ?? Self.currentDayKey())]
        )
        return response.articles
    }

    func fetchAlbumArticles(albumID: String, offset: Int = 0) async throws -> [BishenArticleSummary] {
        let response: AlbumArticlesResponse = try await fetch(
            path: "/api/zw/albums/\(albumID)",
            queryItems: [URLQueryItem(name: "offset", value: String(offset))]
        )
        return response.articles
    }

    func fetchAllAlbumArticles(albumID: String) async throws -> [BishenArticleSummary] {
        var allArticles: [BishenArticleSummary] = []
        var offset = 0
        var totalCount = Int.max

        while allArticles.count < totalCount {
            let response: AlbumArticlesResponse = try await fetch(
                path: "/api/zw/albums/\(albumID)",
                queryItems: [URLQueryItem(name: "offset", value: String(offset))]
            )
            let batch = response.articles
            guard !batch.isEmpty else { break }

            allArticles += batch
            offset += batch.count
            totalCount = response.meta?.count ?? allArticles.count
        }

        return allArticles
    }

    func fetchArticleDetail(id: String) async throws -> BishenArticleDetail {
        let response: DetailResponse = try await fetch(path: "/api/m/zw/zws/\(id)")
        return response.article
    }

    private func fetch<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        guard var components = URLComponents(string: baseURL + path) else {
            throw BishenEssayError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw BishenEssayError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw BishenEssayError.invalidResponse
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw BishenEssayError.invalidResponse
        }
    }

    nonisolated static func currentDayKey(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 8)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private struct AlbumsResponse: Decodable {
    let albums: [BishenAlbum]
    let tags: [String]
}

private struct DailyResponse: Decodable {
    let articles: [BishenArticleSummary]
}

private struct AlbumArticlesResponse: Decodable {
    let articles: [BishenArticleSummary]
    let meta: BishenAlbum?
}

private struct DetailResponse: Decodable {
    let article: BishenArticleDetail
}
