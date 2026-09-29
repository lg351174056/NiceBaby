import Combine
import Foundation

// MARK: - Models

struct PMPoetry: Identifiable, Hashable {
    let id: String
    let name: String
    let excerpt: String
    let dynasty: String
    let poetId: String
    let poetName: String
    let genre: String
    let upCount: Int
    let downCount: Int
    let viewCount: Int
}

struct PMPoetryDetail: Identifiable, Hashable {
    let id: String
    let name: String
    let content: String
    let excerpt: String
    let style: String
    let dynasty: String
    let poetId: String
    let poetName: String
    let genre: String
    let upCount: Int
    let downCount: Int
    let viewCount: Int
    let tags: [PMTag]
    let abouts: PMAbouts
    let poet: PMPoetInfo?

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PMPoetryDetail, rhs: PMPoetryDetail) -> Bool { lhs.id == rhs.id }
}

struct PMTag: Identifiable, Hashable {
    let id: String
    let name: String
}

struct PMAbouts: Hashable {
    let yizhu: PMAboutItem?
    let shangxi: PMAboutItem?
    let fanyi: PMAboutItem?
}

struct PMAboutItem: Hashable {
    let id: String
    let title: String
    let content: String
    let author: String
}

struct PMPoetInfo: Hashable {
    let name: String
    let content: String
    let dynasty: String
}

struct PMHotRecommend: Identifiable, Hashable {
    let id: String
    let name: String
    let genre: String
}

struct PMDailyRecommend: Identifiable, Hashable {
    let id: String
    let name: String
    let excerpt: String
    let dynasty: String
    let poetId: String
    let poetName: String
    let genre: String
}

struct PMGuji: Identifiable, Hashable {
    let id: String
    let poetId: String
    let poetName: String
    let name: String
    let excerpt: String
    let upCount: Int
    let downCount: Int
    let viewCount: Int
}

struct PMGujiBook: Hashable {
    let id: String
    let poetId: String
    let poetName: String
    let name: String
    let content: String
    let upCount: Int
    let viewCount: Int
}

struct PMGujiChapter: Identifiable, Hashable {
    let id: String
    let poetId: String
    let poetName: String
    let name: String
    let type: String
    let genre: String
    let chapter: String
}

struct PMGujiDetail: Identifiable, Hashable {
    let id: String
    let poetId: String
    let poetName: String
    let name: String
    let style: String
    let type: String
    let genre: String
    let chapter: String
    let parentName: String
    let parentId: String
    let content: String
    let upCount: Int
    let viewCount: Int
    let abouts: PMAbouts

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PMGujiDetail, rhs: PMGujiDetail) -> Bool { lhs.id == rhs.id }
}

struct PMSearchPoet: Identifiable, Hashable {
    let id: String
    let name: String
    let content: String
    let dynasty: String
    let poetryCount: Int
}

struct PMHotKeyword: Identifiable, Hashable {
    let id = UUID()
    let keyword: String
}

// MARK: - Filter Options

enum PMGenreFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case shi = "诗"
    case ci = "词"
    case wenyanwen = "文言文"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .shi: return "诗"
        case .ci: return "词"
        case .wenyanwen: return "文言文"
        }
    }
}

enum PMDynastyFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case xianqin = "先秦"
    case lianghan = "两汉"
    case weijin = "魏晋"
    case nanbeichao = "南北朝"
    case sui = "隋代"
    case tang = "唐代"
    case wudai = "五代"
    case song = "宋代"
    case jin = "金朝"
    case yuan = "元代"
    case ming = "明代"
    case qing = "清代"
    case jindai = "近代"
    case dangdai = "当代"
    case other = "其他"

    var id: String { rawValue }
    var displayName: String {
        self == .all ? "全部" : rawValue
    }
}

// MARK: - API Service

@MainActor
final class PoetryAPIService: ObservableObject {
    static let shared = PoetryAPIService()

    private let baseURL = "https://programmanual.cn/api"
    private let referer = "https://servicewechat.com/wx65ebc075064b25ac/45/page-frame.html"

    @Published var token: String {
        didSet { UserDefaults.standard.set(token, forKey: "pm_poetry_token") }
    }
    @Published var uid: String {
        didSet { UserDefaults.standard.set(uid, forKey: "pm_poetry_uid") }
    }

    private init() {
        self.token = UserDefaults.standard.string(forKey: "pm_poetry_token")
            ?? "d887fe56b5f3350fdd5c08c32738cb754b064cf9"
        self.uid = UserDefaults.standard.string(forKey: "pm_poetry_uid")
            ?? "o3ULE5BrLaV8xjPQrZQIqoSFJcBo"
    }

    private func buildRequest(path: String, queryItems: [URLQueryItem] = []) -> URLRequest? {
        var components = URLComponents(string: baseURL + path)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(token, forHTTPHeaderField: "token")
        request.setValue(uid, forHTTPHeaderField: "uid")
        request.setValue(referer, forHTTPHeaderField: "Referer")
        return request
    }

    // MARK: - Poetry List

    func fetchPoetryList(genre: String = "all", dynasty: String = "all", tag: String = "all", poetId: String = "all", page: Int = 1) async throws -> [PMPoetry] {
        guard let request = buildRequest(path: "/poetry/list", queryItems: [
            URLQueryItem(name: "genre", value: genre),
            URLQueryItem(name: "dynasty", value: dynasty),
            URLQueryItem(name: "tag", value: tag),
            URLQueryItem(name: "poet_id", value: poetId),
            URLQueryItem(name: "page", value: "\(page)")
        ]) else { return [] }

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let list = json?["data"] as? [[String: Any]] else { return [] }

        return list.compactMap { item in
            guard let id = item["id"] as? String,
                  let name = item["name"] as? String else { return nil }
            return PMPoetry(
                id: id,
                name: name,
                excerpt: item["excerpt"] as? String ?? "",
                dynasty: item["dynasty"] as? String ?? "",
                poetId: item["poet_id"] as? String ?? "",
                poetName: item["poet_name"] as? String ?? "",
                genre: item["genre"] as? String ?? "",
                upCount: item["up_count"] as? Int ?? 0,
                downCount: item["down_count"] as? Int ?? 0,
                viewCount: item["view_count"] as? Int ?? 0
            )
        }
    }

    // MARK: - Poetry Detail

    func fetchPoetryDetail(id: String) async throws -> PMPoetryDetail? {
        guard let request = buildRequest(path: "/poetry/\(id)") else { return nil }
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let item = json?["data"] as? [String: Any],
              let poetryId = item["id"] as? String else { return nil }

        let tags = (item["tags"] as? [[String: Any]] ?? []).compactMap { t -> PMTag? in
            guard let tid = t["tag_id"] as? String, let name = t["name"] as? String else { return nil }
            return PMTag(id: tid, name: name)
        }

        let aboutsDict = item["abouts"] as? [String: Any] ?? [:]
        let abouts = parseAbouts(aboutsDict)

        var poetInfo: PMPoetInfo?
        if let poetDict = item["poet"] as? [String: Any] {
            poetInfo = PMPoetInfo(
                name: poetDict["name"] as? String ?? "",
                content: poetDict["content"] as? String ?? "",
                dynasty: poetDict["dynasty"] as? String ?? ""
            )
        }

        return PMPoetryDetail(
            id: poetryId,
            name: item["name"] as? String ?? "",
            content: item["content"] as? String ?? "",
            excerpt: item["excerpt"] as? String ?? "",
            style: item["style"] as? String ?? "",
            dynasty: item["dynasty"] as? String ?? "",
            poetId: item["poet_id"] as? String ?? "",
            poetName: item["poet_name"] as? String ?? "",
            genre: item["genre"] as? String ?? "",
            upCount: item["up_count"] as? Int ?? 0,
            downCount: item["down_count"] as? Int ?? 0,
            viewCount: item["view_count"] as? Int ?? 0,
            tags: tags,
            abouts: abouts,
            poet: poetInfo
        )
    }

    // MARK: - Hot Recommend

    func fetchHotRecommend() async throws -> [PMHotRecommend] {
        guard let request = buildRequest(path: "/poetry/hot-recommend") else { return [] }
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let list = json?["data"] as? [[String: Any]] else { return [] }

        return list.compactMap { item in
            guard let id = item["id"] as? String,
                  let name = item["name"] as? String else { return nil }
            return PMHotRecommend(id: id, name: name, genre: item["genre"] as? String ?? "")
        }
    }

    // MARK: - Daily Recommend

    func fetchDailyRecommend() async throws -> [PMDailyRecommend] {
        guard let request = buildRequest(path: "/poetry/daily-recommend") else { return [] }
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let list = json?["data"] as? [[String: Any]] else { return [] }

        return list.compactMap { item in
            guard let id = item["id"] as? String,
                  let name = item["name"] as? String else { return nil }
            return PMDailyRecommend(
                id: id, name: name,
                excerpt: item["excerpt"] as? String ?? "",
                dynasty: item["dynasty"] as? String ?? "",
                poetId: item["poet_id"] as? String ?? "",
                poetName: item["poet_name"] as? String ?? "",
                genre: item["genre"] as? String ?? ""
            )
        }
    }

    // MARK: - Guji List

    func fetchGujiList(page: Int = 1, genre: String = "", type: String = "") async throws -> [PMGuji] {
        guard let request = buildRequest(path: "/guji/list", queryItems: [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "genre", value: genre),
            URLQueryItem(name: "type", value: type)
        ]) else { return [] }

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let list = json?["data"] as? [[String: Any]] else { return [] }

        return list.compactMap { item in
            guard let id = item["id"] as? String,
                  let name = item["name"] as? String else { return nil }
            return PMGuji(
                id: id,
                poetId: item["poet_id"] as? String ?? "",
                poetName: item["poet_name"] as? String ?? "",
                name: name,
                excerpt: item["excerpt"] as? String ?? "",
                upCount: item["up_count"] as? Int ?? 0,
                downCount: item["down_count"] as? Int ?? 0,
                viewCount: item["view_count"] as? Int ?? 0
            )
        }
    }

    // MARK: - Guji Chapters

    func fetchGujiChapters(id: String) async throws -> (book: PMGujiBook?, chapters: [PMGujiChapter]) {
        guard let request = buildRequest(path: "/guji/\(id)/chapters") else { return (nil, []) }
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let dataDict = json?["data"] as? [String: Any] else { return (nil, []) }

        var book: PMGujiBook?
        if let b = dataDict["book"] as? [String: Any] {
            book = PMGujiBook(
                id: b["id"] as? String ?? "",
                poetId: b["poet_id"] as? String ?? "",
                poetName: b["poet_name"] as? String ?? "",
                name: b["name"] as? String ?? "",
                content: b["content"] as? String ?? "",
                upCount: b["up_count"] as? Int ?? 0,
                viewCount: b["view_count"] as? Int ?? 0
            )
        }

        var chapters: [PMGujiChapter] = []
        if let chaptersDict = dataDict["chapters"] as? [String: Any] {
            for (_, value) in chaptersDict {
                if let arr = value as? [[String: Any]] {
                    for c in arr {
                        guard let cid = c["id"] as? String, let name = c["name"] as? String else { continue }
                        chapters.append(PMGujiChapter(
                            id: cid,
                            poetId: c["poet_id"] as? String ?? "",
                            poetName: c["poet_name"] as? String ?? "",
                            name: name,
                            type: c["type"] as? String ?? "",
                            genre: c["genre"] as? String ?? "",
                            chapter: c["chapter"] as? String ?? ""
                        ))
                    }
                }
            }
        }

        return (book, chapters)
    }

    // MARK: - Guji Detail

    func fetchGujiDetail(id: String) async throws -> PMGujiDetail? {
        guard let request = buildRequest(path: "/guji/\(id)") else { return nil }
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let item = json?["data"] as? [String: Any],
              let gujiId = item["id"] as? String else { return nil }

        let aboutsDict = item["abouts"] as? [String: Any] ?? [:]
        let abouts = parseAbouts(aboutsDict)

        return PMGujiDetail(
            id: gujiId,
            poetId: item["poet_id"] as? String ?? "",
            poetName: item["poet_name"] as? String ?? "",
            name: item["name"] as? String ?? "",
            style: item["style"] as? String ?? "",
            type: item["type"] as? String ?? "",
            genre: item["genre"] as? String ?? "",
            chapter: item["chapter"] as? String ?? "",
            parentName: item["parent_name"] as? String ?? "",
            parentId: item["parent_id"] as? String ?? "",
            content: item["content"] as? String ?? "",
            upCount: item["up_count"] as? Int ?? 0,
            viewCount: item["view_count"] as? Int ?? 0,
            abouts: abouts
        )
    }

    // MARK: - Search

    func searchPoetry(keyword: String, page: Int = 1) async throws -> [PMPoetry] {
        guard let request = buildRequest(path: "/poetry/search/poetry", queryItems: [
            URLQueryItem(name: "keyword", value: keyword),
            URLQueryItem(name: "page", value: "\(page)")
        ]) else { return [] }

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let list = json?["data"] as? [[String: Any]] else { return [] }

        return list.compactMap { item in
            guard let id = item["id"] as? String,
                  let name = item["name"] as? String else { return nil }
            return PMPoetry(
                id: id,
                name: name,
                excerpt: item["excerpt"] as? String ?? item["content"] as? String ?? "",
                dynasty: item["dynasty"] as? String ?? "",
                poetId: item["poet_id"] as? String ?? "",
                poetName: item["poet_name"] as? String ?? "",
                genre: item["genre"] as? String ?? "",
                upCount: item["up_count"] as? Int ?? 0,
                downCount: item["down_count"] as? Int ?? 0,
                viewCount: item["view_count"] as? Int ?? 0
            )
        }
    }

    func searchPoet(keyword: String, page: Int = 1) async throws -> [PMSearchPoet] {
        guard let request = buildRequest(path: "/poetry/search/poet", queryItems: [
            URLQueryItem(name: "keyword", value: keyword),
            URLQueryItem(name: "page", value: "\(page)")
        ]) else { return [] }

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let list = json?["data"] as? [[String: Any]] else { return [] }

        return list.compactMap { item in
            guard let id = item["id"] as? String,
                  let name = item["name"] as? String else { return nil }
            return PMSearchPoet(
                id: id,
                name: name,
                content: item["content"] as? String ?? "",
                dynasty: item["dynasty"] as? String ?? "",
                poetryCount: item["poetry_count"] as? Int ?? 0
            )
        }
    }

    func fetchHotKeywords() async throws -> [PMHotKeyword] {
        guard let request = buildRequest(path: "/poetry/search/hot-keywords") else { return [] }
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let list = json?["data"] as? [[String: Any]] else { return [] }

        return list.compactMap { item in
            guard let keyword = item["keyword"] as? String else { return nil }
            return PMHotKeyword(keyword: keyword)
        }
    }

    // MARK: - Helpers

    private func parseAbouts(_ dict: [String: Any]) -> PMAbouts {
        func parseItem(_ key: String) -> PMAboutItem? {
            guard let d = dict[key] as? [String: Any],
                  let id = d["id"] as? String else { return nil }
            return PMAboutItem(
                id: id,
                title: d["title"] as? String ?? "",
                content: d["content"] as? String ?? "",
                author: d["author"] as? String ?? ""
            )
        }
        return PMAbouts(
            yizhu: parseItem("yizhu"),
            shangxi: parseItem("shangxi"),
            fanyi: parseItem("fanyi")
        )
    }
}
