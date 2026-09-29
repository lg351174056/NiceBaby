import Foundation

// MARK: - 儿童故事集 · 数据模型

enum StoryBookMode {
    case read     // 读故事
    case listen   // 听故事

    var apiPrefix: String { self == .read ? "readStory" : "listenStory" }
    var title: String { self == .read ? "读故事" : "听故事" }
    var emoji: String { self == .read ? "📖" : "🎧" }
}

struct StoryClassItem: Decodable, Identifiable, Hashable {
    let classid: String
    let classname: String
    let intro: String?
    let classimg: String?
    var id: String { classid }
}

struct StoryItem: Decodable, Identifiable, Hashable {
    let id: String
    let classid: String
    let classname: String?
    let title: String
    let newstime: String?
    let titlepic: String?
    let thumbnail: String?
    let smalltext: String?
    let mp3link: String?
    var coverURL: String? { titlepic ?? thumbnail }
}

// MARK: - 儿童故事集 · 网络服务

enum StoryBookAPI {
    private static let base = "https://www.bmf365.com/e/appapi/"

    /// 统一解码：响应可能是 ①BOM+JSON ②"77u/"前缀+base64 ③纯base64
    private static func decodeJSON(_ data: Data) throws -> [String: Any] {
        var processed = data
        if processed.count >= 3, processed.prefix(3) == Data([0xEF, 0xBB, 0xBF]) {
            processed = processed.dropFirst(3)
        }
        if let obj = try? JSONSerialization.jsonObject(with: processed),
           let dict = obj as? [String: Any] {
            return dict
        }
        guard let text = String(data: processed, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw URLError(.cannotDecodeContentData)
        }
        var b64 = text
        if b64.hasPrefix("77u/") { b64 = String(b64.dropFirst(4)) }
        if let d = Data(base64Encoded: b64, options: .ignoreUnknownCharacters),
           let obj = try? JSONSerialization.jsonObject(with: d),
           let dict = obj as? [String: Any] {
            return dict
        }
        throw URLError(.cannotDecodeContentData)
    }

    private static func post(_ query: String, body: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: base + query) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try decodeJSON(data)
    }

    static func fetchClasses(mode: StoryBookMode) async throws -> [StoryClassItem] {
        let json = try await post("?api=\(mode.apiPrefix)/class", body: [:])
        guard let arr = json["data"] as? [[String: Any]] else { return [] }
        let items = try JSONSerialization.data(withJSONObject: arr)
        return try JSONDecoder().decode([StoryClassItem].self, from: items)
    }

    static func fetchStories(mode: StoryBookMode, classid: String, page: Int) async throws -> (items: [StoryItem], total: Int) {
        let json = try await post(
            "?api=\(mode.apiPrefix)/list&classid=\(classid)&pageIndex=\(page)",
            body: ["classid": classid, "pageIndex": page]
        )
        let total = (json["total"] as? NSNumber)?.intValue ?? (json["total"] as? String).flatMap(Int.init) ?? 0
        guard let arr = json["data"] as? [[String: Any]] else { return ([], total) }
        let items = try JSONSerialization.data(withJSONObject: arr)
        let decoded = try JSONDecoder().decode([StoryItem].self, from: items)
        return (decoded, total)
    }

    /// 返回详情正文 HTML（newstext）、封面、标题等
    static func fetchDetail(mode: StoryBookMode, id: String, classid: String) async throws -> [String: Any] {
        let json = try await post(
            "?api=\(mode.apiPrefix)/detail&id=\(id)&classid=\(classid)",
            body: ["appid": "wx1fee37411b05bc13", "timestamp": Int(Date().timeIntervalSince1970)]
        )
        let content = (json["data"] as? [String: Any])?["content"] as? [String: Any] ?? [:]
        return content
    }
}
