import Combine
import Foundation

struct VideoCategory: Identifiable, Hashable {
    let id: Int
    let name: String
    let seriesCount: Int
}

struct VideoSeries: Identifiable, Hashable {
    let id: Int
    let name: String
    let episodeCount: Int
    let coverUrl: String
    let isVip: Bool
}

struct VideoEpisode: Identifiable, Hashable {
    let id: Int
    let name: String
    let episodeNo: Int
    let isPlayable: Bool
    let duration: Int
    let coverUrl: String
}

struct VideoPlayInfo {
    let playUrl: String
    let name: String
    let expireAt: String
}

@MainActor
final class VideoAPIService: ObservableObject {
    static let shared = VideoAPIService()

    @Published var token: String {
        didSet { UserDefaults.standard.set(token, forKey: "video_api_token") }
    }

    private let baseURL = "https://api.lw1111.cn"

    private static let defaultToken = "eyJpc3N1ZWRBdCI6MTc3OTM0MTEzNTI5OCwic2NvcGUiOiJtaW5pYXBwIiwidXNlcklkIjoidV8xMDk2NCIsIm9wZW5pZCI6Im9IUTVyN2Z4TGR2emFhbjRURUYwejZyNmRUUHciLCJkZXZpY2VJZCI6ImRldmljZV9tcGYxcml3M19wM3ZmZTE0YiJ9.4MyjzP3cEIsyNuDjnlJ_dSstDcWFqjPNaq5WAtvTXEw"

    private init() {
        let saved = UserDefaults.standard.string(forKey: "video_api_token") ?? ""
        self.token = saved.isEmpty ? Self.defaultToken : saved
    }

    private func post<T>(_ path: String, body: [String: Any], transform: @escaping (Any) -> T?) async -> T? {
        guard !token.isEmpty else { return nil }
        guard let url = URL(string: "\(baseURL)\(path)") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("https://servicewechat.com/wxcbf549e856866db7/23/page-frame.html", forHTTPHeaderField: "Referer")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let code = json["code"] as? Int, code == 0,
                  let resultData = json["data"] else { return nil }
            return transform(resultData)
        } catch {
            return nil
        }
    }

    func fetchCategories() async -> [VideoCategory] {
        await post("/app-api/video/sort/page", body: ["pageNo": 1, "pageSize": 1000]) { data in
            guard let dict = data as? [String: Any],
                  let list = dict["list"] as? [[String: Any]] else { return nil }
            return list.compactMap { item in
                guard let id = item["id"] as? Int,
                      let name = item["name"] as? String else { return nil }
                return VideoCategory(id: id, name: name, seriesCount: item["num"] as? Int ?? 0)
            }
        } ?? []
    }

    func fetchSeries(sortId: Int) async -> [VideoSeries] {
        await post("/app-api/video/info/page", body: ["sortId": sortId, "pageNo": 1, "pageSize": 1000]) { data in
            guard let dict = data as? [String: Any],
                  let list = dict["list"] as? [[String: Any]] else { return nil }
            return list.compactMap { item in
                guard let id = item["id"] as? Int,
                      let name = item["name"] as? String else { return nil }
                return VideoSeries(
                    id: id,
                    name: name,
                    episodeCount: item["episodeCount"] as? Int ?? 0,
                    coverUrl: item["coverUrl"] as? String ?? "",
                    isVip: item["vip"] as? Bool ?? false
                )
            }
        } ?? []
    }

    func fetchEpisodes(infoId: Int) async -> [VideoEpisode] {
        await post("/app-api/video/info/diversity/page", body: ["infoId": infoId, "pageNo": 1, "pageSize": 1000]) { data in
            guard let dict = data as? [String: Any],
                  let list = dict["list"] as? [[String: Any]] else { return nil }
            return list.compactMap { item in
                guard let id = item["id"] as? Int,
                      let name = item["name"] as? String else { return nil }
                return VideoEpisode(
                    id: id,
                    name: name,
                    episodeNo: item["episodeNo"] as? Int ?? 0,
                    isPlayable: item["isPlayable"] as? Bool ?? false,
                    duration: item["duration"] as? Int ?? 0,
                    coverUrl: item["coverUrl"] as? String ?? ""
                )
            }
        } ?? []
    }

    func getPlayUrl(episodeId: Int, infoId: Int) async -> VideoPlayInfo? {
        await post("/playback/check", body: ["id": String(episodeId), "infoId": String(infoId)]) { data in
            guard let dict = data as? [String: Any],
                  let playUrl = dict["playUrl"] as? String ?? dict["authorizedVideoUrl"] as? String,
                  !playUrl.isEmpty else { return nil }
            let name = (dict["payload"] as? [String: Any])?["name"] as? String ?? ""
            let expireAt = dict["expireAt"] as? String ?? ""
            return VideoPlayInfo(playUrl: playUrl, name: name, expireAt: expireAt)
        }
    }
}
