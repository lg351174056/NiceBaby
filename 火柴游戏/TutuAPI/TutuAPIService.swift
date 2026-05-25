import Combine
import Foundation

// MARK: - Models

struct TutuTag: Identifiable, Hashable {
    let id: Int
    let name: String
    let stage: Int
    let abbr: String
    let sort: Int
}

struct TutuCategory: Identifiable, Hashable {
    let id: Int
    let name: String
    let icon: String
}

struct TutuSubCategory: Identifiable, Hashable {
    let id: Int
    let name: String
    let image: String
    let repositoriesId: Int?
}

struct TutuResource: Identifiable, Hashable {
    let id: Int
    let title: String
    let image: String
    let actualSales: Int
    let fileType: Int
    let previewSupported: Int
}

struct TutuResourceDetail: Identifiable, Hashable {
    let id: Int
    let title: String
    let image: String
    let categoryName: String
    let scale: Int
    let documents: [TutuDocument]
    let collectedOrNot: Bool
}

struct TutuDocument: Identifiable, Hashable {
    let id = UUID()
    let fileName: String
    let previewDocuments: String
    let imageWidth: Double
    let imageHeight: Double
}

struct TutuDownloadPermission {
    let isVIP: Bool
    let quantityLimitCondition: Bool
    let nonmemberQuantityLimitCondition: Bool
}

// MARK: - Service

@MainActor
final class TutuAPIService: ObservableObject {
    static let shared = TutuAPIService()

    @Published var token: String {
        didSet { UserDefaults.standard.set(token, forKey: "tutu_api_token") }
    }

    @Published var selectedTagId: Int {
        didSet { UserDefaults.standard.set(selectedTagId, forKey: "tutu_selected_tag_id") }
    }

    private let baseURL = "https://www.tutuzlk.com/api/applet-tutu"
    private let cdnBase = "https://cdn.tutuzlk.com"

    private static let defaultToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJBUFAiLCJpc3MiOiJTZXJ2aWNlIiwiZXhwIjoxODExMjA4MDczLCJ1c2VyIjoie1wiaWRcIjoyNTAxMDksXCJuYW1lXCI6XCJvUlRsbzE1WjNLeXAzXzM0bU9fNkVjWE0xckZBXCJ9IiwiaWF0IjoxNzc5NjcyMDczfQ.ow2cqnTWO3eEGkFOwfATmrYm8lDsA1UPQ2QvSyDJjd8"

    private init() {
        let saved = UserDefaults.standard.string(forKey: "tutu_api_token") ?? ""
        self.token = saved.isEmpty ? Self.defaultToken : saved
        self.selectedTagId = UserDefaults.standard.integer(forKey: "tutu_selected_tag_id")
        if self.selectedTagId == 0 {
            self.selectedTagId = 31
        }
    }

    func fullImageURL(_ path: String) -> String {
        if path.hasPrefix("http") { return path }
        return "\(cdnBase)\(path)"
    }

    // MARK: - Network

    private func get<T>(_ path: String, params: [String: String] = [:], transform: @escaping (Any) -> T?) async -> T? {
        guard !token.isEmpty else { return nil }

        var components = URLComponents(string: "\(baseURL)\(path)")
        if !params.isEmpty {
            components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("wx1fc992757279ade9", forHTTPHeaderField: "X-App-Id")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("https://servicewechat.com/wx1fc992757279ade9/7/page-frame.html", forHTTPHeaderField: "Referer")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let code = json["code"] as? Int, code == 1,
                  let resultData = json["data"] else { return nil }
            return transform(resultData)
        } catch {
            return nil
        }
    }

    // MARK: - API Methods

    func fetchTags() async -> [TutuTag] {
        await get("/repositories/tag/list") { data in
            guard let list = data as? [[String: Any]] else { return nil }
            return list.compactMap { item in
                guard let id = item["id"] as? Int,
                      let name = item["name"] as? String else { return nil }
                return TutuTag(
                    id: id,
                    name: name,
                    stage: item["stage"] as? Int ?? 1,
                    abbr: item["abbr"] as? String ?? "",
                    sort: item["sort"] as? Int ?? 0
                )
            }
        } ?? []
    }

    func fetchCategories(tagId: Int) async -> [TutuCategory] {
        await get("/repositories/category/list", params: ["repositoriesTagId": String(tagId)]) { data in
            guard let list = data as? [[String: Any]] else { return nil }
            return list.compactMap { item in
                guard let id = item["id"] as? Int,
                      let name = item["name"] as? String else { return nil }
                return TutuCategory(
                    id: id,
                    name: name,
                    icon: item["icon"] as? String ?? ""
                )
            }
        } ?? []
    }

    func fetchSubCategories(parentId: Int, tagId: Int, page: Int = 1) async -> [TutuSubCategory] {
        await get("/repositories/category/lowermost/list", params: [
            "parentId": String(parentId),
            "repositoriesTagId": String(tagId),
            "pageIndex": String(page),
            "pageSize": "50"
        ]) { data in
            guard let dict = data as? [String: Any],
                  let records = dict["records"] as? [[String: Any]] else { return nil }
            return records.compactMap { item in
                guard let id = item["id"] as? Int,
                      let name = item["name"] as? String else { return nil }
                return TutuSubCategory(
                    id: id,
                    name: name,
                    image: item["image"] as? String ?? "",
                    repositoriesId: item["repositoriesId"] as? Int
                )
            }
        } ?? []
    }

    func fetchResources(categoryId: Int, tagId: Int, page: Int = 1) async -> [TutuResource] {
        await get("/repositories/list", params: [
            "categoryId": String(categoryId),
            "repositoriesTagId": String(tagId),
            "pageIndex": String(page),
            "pageSize": "20"
        ]) { data in
            guard let dict = data as? [String: Any],
                  let records = dict["records"] as? [[String: Any]] else { return nil }
            return records.compactMap { item in
                guard let id = item["id"] as? Int,
                      let title = item["title"] as? String else { return nil }
                return TutuResource(
                    id: id,
                    title: title,
                    image: item["image"] as? String ?? "",
                    actualSales: item["actualSales"] as? Int ?? 0,
                    fileType: item["fileType"] as? Int ?? 0,
                    previewSupported: item["previewSupported"] as? Int ?? 0
                )
            }
        } ?? []
    }

    func fetchResourceDetail(id: Int) async -> TutuResourceDetail? {
        await get("/repositories/details/\(id)") { data in
            guard let dict = data as? [String: Any],
                  let id = dict["id"] as? Int,
                  let title = dict["title"] as? String else { return nil }
            let docs = (dict["documents"] as? [[String: Any]])?.map { doc in
                TutuDocument(
                    fileName: doc["fileName"] as? String ?? "",
                    previewDocuments: doc["previewDocuments"] as? String ?? "",
                    imageWidth: Double(doc["imageWidth"] as? String ?? "0") ?? 0,
                    imageHeight: Double(doc["imageHigh"] as? String ?? "0") ?? 0
                )
            } ?? []
            return TutuResourceDetail(
                id: id,
                title: title,
                image: dict["image"] as? String ?? "",
                categoryName: dict["categoryName"] as? String ?? "",
                scale: dict["scale"] as? Int ?? 0,
                documents: docs,
                collectedOrNot: dict["collectedOrNot"] as? Bool ?? false
            )
        }
    }

    func verifyDownload(resourceId: Int) async -> TutuDownloadPermission? {
        await get("/wx/user/download/verify", params: ["repositoriesId": String(resourceId)]) { data in
            guard let dict = data as? [String: Any] else { return nil }
            return TutuDownloadPermission(
                isVIP: dict["isVIP"] as? Bool ?? false,
                quantityLimitCondition: dict["quantityLimitCondition"] as? Bool ?? false,
                nonmemberQuantityLimitCondition: dict["nonmemberQuantityLimitCondition"] as? Bool ?? false
            )
        }
    }
}
