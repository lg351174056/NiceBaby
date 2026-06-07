import Combine
import Foundation
import SwiftUI

// MARK: - Models

/// 分类
struct WhyCategory: Identifiable, Hashable {
    let id: Int
    let name: String
    let description: String
    let icon: String
    let iconUrl: String?
    let color: String        // #RRGGBB
    let sortOrder: Int
    let type: String
    let enabled: Bool
    let questionCount: Int

    /// 把 #RRGGBB 解析为 Color，失败回退到品牌色
    var swiftUIColor: Color {
        WhyAPIService.colorFromHex(color) ?? AppTheme.accentBlue
    }
}

/// 问题
struct WhyQuestion: Identifiable, Hashable {
    let id: Int
    let title: String
    let content: String?
    let answer: String?
    let coverImage: String?
    let category: WhyCategory?
    let difficultyLevel: String?
    let difficultyText: String?
    let ageRange: String?
    let tagList: [String]
    let viewCount: Int
    let recommended: Bool
    let enabled: Bool
    let sortOrder: Int
    let createdAt: String?
    let updatedAt: String?

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: WhyQuestion, rhs: WhyQuestion) -> Bool { lhs.id == rhs.id }
}

/// 问题分页响应
struct WhyQuestionPage: Hashable {
    let content: [WhyQuestion]
    let totalElements: Int
    let totalPages: Int
    let number: Int
    let size: Int
}

// MARK: - Service

@MainActor
final class WhyAPIService: ObservableObject {
    static let shared = WhyAPIService()

    /// 缓存分类（避免重复请求）
    @Published private(set) var categories: [WhyCategory] = []
    @Published private(set) var isCategoriesLoading = false

    private let baseURL = "https://whys.langchuanxinxi.cn/wechat/api"
    /// 与抓包请求头保持一致，便于服务端识别为微信小程序来源
    private let referer = "https://servicewechat.com/wxc863a42f8df45139/3/page-frame.html"
    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 MicroMessenger/8.0.70(0x1800463a) NetType/WIFI Language/zh_CN"

    private init() {}

    // MARK: - Public API

    /// 获取所有启用的分类（首页）
    func fetchCategories(force: Bool = false) async -> [WhyCategory] {
        if !force, !categories.isEmpty { return categories }
        isCategoriesLoading = true
        defer { isCategoriesLoading = false }
        let list: [WhyCategory] = await get("/categories/enabled", params: [:]) { data in
            guard let arr = data as? [[String: Any]] else { return nil }
            return arr.compactMap { Self.parseCategory($0) }
        } ?? []
        self.categories = list
        return list
    }

    /// 获取推荐问题
    func fetchRecommended() async -> [WhyQuestion] {
        await get("/questions/recommended", params: [:]) { data in
            guard let arr = data as? [[String: Any]] else { return nil }
            return arr.compactMap { Self.parseQuestion($0) }
        } ?? []
    }

    /// 获取分类下问题列表（分页）
    func fetchQuestionsByCategory(categoryId: Int, page: Int = 0, size: Int = 10) async -> WhyQuestionPage {
        let params: [String: String] = [
            "page": "\(page)",
            "size": "\(size)",
            "sortBy": "sortOrder",
            "sortDir": "asc"
        ]
        let result: WhyQuestionPage? = await get("/questions/category/\(categoryId)/page", params: params) { data in
            guard let dict = data as? [String: Any] else { return nil }
            let contentArr = dict["content"] as? [[String: Any]] ?? []
            let list = contentArr.compactMap { Self.parseQuestion($0) }
            return WhyQuestionPage(
                content: list,
                totalElements: dict["totalElements"] as? Int ?? list.count,
                totalPages: dict["totalPages"] as? Int ?? 1,
                number: dict["number"] as? Int ?? page,
                size: dict["size"] as? Int ?? size
            )
        }
        return result ?? WhyQuestionPage(content: [], totalElements: 0, totalPages: 0, number: page, size: size)
    }

    /// 获取问题详情
    func fetchQuestionDetail(id: Int) async -> WhyQuestion? {
        await get("/questions/\(id)", params: [:]) { data in
            guard let dict = data as? [String: Any] else { return nil }
            return Self.parseQuestion(dict)
        }
    }

    /// 获取相关问题
    func fetchRelatedQuestions(id: Int, limit: Int = 3) async -> [WhyQuestion] {
        await get("/questions/\(id)/related", params: ["limit": "\(limit)"]) { data in
            guard let arr = data as? [[String: Any]] else { return nil }
            return arr.compactMap { Self.parseQuestion($0) }
        } ?? []
    }

    // MARK: - Network

    private func get<T>(_ path: String, params: [String: String], transform: @escaping (Any) -> T?) async -> T? {
        var components = URLComponents(string: "\(baseURL)\(path)")
        if !params.isEmpty {
            components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(referer, forHTTPHeaderField: "Referer")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let code = json?["code"] as? Int, code == 200, let result = json?["data"] else {
                return nil
            }
            return transform(result)
        } catch {
            print("[WhyAPI] GET \(path) failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Parsers

    private static func parseCategory(_ dict: [String: Any]) -> WhyCategory? {
        guard let id = dict["id"] as? Int, let name = dict["name"] as? String else { return nil }
        return WhyCategory(
            id: id,
            name: name,
            description: dict["description"] as? String ?? "",
            icon: dict["icon"] as? String ?? "",
            iconUrl: dict["iconUrl"] as? String,
            color: dict["color"] as? String ?? "#409EFF",
            sortOrder: dict["sortOrder"] as? Int ?? 0,
            type: dict["type"] as? String ?? "QUESTION",
            enabled: dict["enabled"] as? Bool ?? true,
            questionCount: dict["questionCount"] as? Int ?? 0
        )
    }

    private static func parseQuestion(_ dict: [String: Any]) -> WhyQuestion? {
        guard let id = dict["id"] as? Int else { return nil }
        let category: WhyCategory? = {
            if let cat = dict["category"] as? [String: Any] {
                return parseCategory(cat)
            }
            return nil
        }()
        return WhyQuestion(
            id: id,
            title: dict["title"] as? String ?? "",
            content: dict["content"] as? String,
            answer: dict["answer"] as? String,
            coverImage: dict["coverImage"] as? String,
            category: category,
            difficultyLevel: dict["difficultyLevel"] as? String,
            difficultyText: dict["difficultyText"] as? String,
            ageRange: dict["ageRange"] as? String,
            tagList: dict["tagList"] as? [String] ?? [],
            viewCount: dict["viewCount"] as? Int ?? 0,
            recommended: dict["recommended"] as? Bool ?? false,
            enabled: dict["enabled"] as? Bool ?? true,
            sortOrder: dict["sortOrder"] as? Int ?? 0,
            createdAt: dict["createdAt"] as? String,
            updatedAt: dict["updatedAt"] as? String
        )
    }

    // MARK: - Helpers

    /// 把 #RRGGBB / RRGGBB 解析为 Color
    static func colorFromHex(_ hex: String) -> Color? {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let val = Int(s, radix: 16) else { return nil }
        let r = Double((val >> 16) & 0xFF) / 255.0
        let g = Double((val >> 8) & 0xFF) / 255.0
        let b = Double(val & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}
