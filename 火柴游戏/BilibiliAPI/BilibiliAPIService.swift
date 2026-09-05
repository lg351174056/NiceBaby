import Foundation

// MARK: - B站专题 · 数据模型

struct BilibiliCategory: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let icon: String
    let tag: String
    let topics: [BilibiliTopic]

    static let all: [BilibiliCategory] = [
        BilibiliCategory(
            id: "math",
            name: "数学思维",
            subtitle: "趣味数学启蒙 · 数感与逻辑",
            icon: "🧮",
            tag: "数感 · 逻辑",
            topics: []
            // TODO: 在这里追加专题，例如 BilibiliTopic(link: "https://www.bilibili.com/video/BVxxxx", customTitle: "数学小天才")
        ),
        BilibiliCategory(
            id: "encyclopedia",
            name: "趣味百科",
            subtitle: "十万个为什么 · 万物有答案",
            icon: "🦖",
            tag: "百科 · 科普",
            topics: []
            // TODO: 在这里追加专题
        ),
        BilibiliCategory(
            id: "chinese",
            name: "国学语文",
            subtitle: "少儿史记 · 诗词与传统文化",
            icon: "📜",
            tag: "史记 · 国学",
            topics: [
                BilibiliTopic(
                    link: "https://www.bilibili.com/video/BV1YS42197bP/?spm_id_from=333.337.search-card.all.click&vd_source=5b83a293ee6e0cda699882e819dc26b6",
                    customTitle: "少儿史记",
                    customSubtitle: "20 集精选动画"
                ),
                // TODO: 例如 成语故事 86 集精选动画
            ]
        ),
        BilibiliCategory(
            id: "science",
            name: "科学探秘",
            subtitle: "身边的科学 · 动手做实验",
            icon: "🔬",
            tag: "科学 · 实验",
            topics: []
            // TODO: 在这里追加专题
        ),
        BilibiliCategory(
            id: "history",
            name: "历史故事",
            subtitle: "上下五千年 · 有趣的中国史",
            icon: "🏯",
            tag: "历史 · 故事",
            topics: []
            // TODO: 在这里追加专题
        ),
    ]
}

struct BilibiliTopic: Identifiable {
    let id: String
    let bvid: String
    var customTitle: String? = nil
    var customSubtitle: String? = nil

    init(link: String, customTitle: String? = nil, customSubtitle: String? = nil) {
        self.bvid = BilibiliAPIService.bvid(from: link)
        self.customTitle = customTitle
        self.customSubtitle = customSubtitle
        self.id = bvid
    }

    var link: String { "https://www.bilibili.com/video/\(bvid)" }

    /// 嵌入式播放器链接（无详情页/无跳转引导，打开即播放）
    func episodeLink(page: Int) -> String {
        "https://player.bilibili.com/player.html?bvid=\(bvid)&page=\(page)&high_quality=1&danmaku=0&autoplay=1"
    }
}

// MARK: - B站接口信息

struct BilibiliVideoInfo {
    let bvid: String
    let title: String
    let coverUrl: String
    let partCount: Int
    let parts: [BilibiliPart]
}

struct BilibiliPart: Identifiable {
    let id: String
    let page: Int
    let title: String
    let duration: Int
}

// MARK: - B站公共接口

final class BilibiliAPIService {
    static let shared = BilibiliAPIService()

    private let viewAPI = "https://api.bilibili.com/x/web-interface/view"
    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

    func fetchVideoInfo(bvid: String) async -> BilibiliVideoInfo? {
        guard let url = URL(string: "\(viewAPI)?bvid=\(bvid)") else { return nil }
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  (json["code"] as? Int) == 0,
                  let info = json["data"] as? [String: Any] else { return nil }

            let title = info["title"] as? String ?? ""
            let pic = (info["pic"] as? String ?? "")
                .replacingOccurrences(of: "http://", with: "https://")
            let pages = (info["pages"] as? [[String: Any]] ?? []).compactMap { p -> BilibiliPart? in
                guard let page = p["page"] as? Int else { return nil }
                let rawPart = p["part"] as? String ?? "第 \(page) 集"
                return BilibiliPart(
                    id: "\(bvid)-\(page)",
                    page: page,
                    title: Self.cleanPartTitle(rawPart),
                    duration: p["duration"] as? Int ?? 0
                )
            }
            return BilibiliVideoInfo(
                bvid: bvid,
                title: title,
                coverUrl: pic,
                partCount: pages.count,
                parts: pages
            )
        } catch {
            return nil
        }
    }

    /// 从任意 B 站链接中提取 BV / av 号
    static func bvid(from link: String) -> String {
        if let range = link.range(of: "BV[0-9A-Za-z]+", options: .regularExpression) {
            return String(link[range])
        }
        if let range = link.range(of: "av[0-9]+", options: .regularExpression) {
            return String(link[range])
        }
        return link
    }

    /// 去掉分 P 标题开头的序号，如 "01 炎黄战蚩尤" → "炎黄战蚩尤"
    static func cleanPartTitle(_ part: String) -> String {
        part.replacingOccurrences(of: "^\\s*\\d+\\s*", with: "", options: .regularExpression)
    }

    /// 从完整标题提取短标题：《少儿史记科普动画》，爆笑历史故事... → 少儿史记科普动画
    static func cleanSeriesTitle(_ raw: String) -> String {
        var t = raw.replacingOccurrences(of: "【[^】]*】", with: "", options: .regularExpression)
        if let range = t.range(of: "《[^》]*》", options: .regularExpression) {
            return String(t[range]).dropFirst().dropLast().description
        }
        for sep in ["，", "。", ","] {
            if let idx = t.firstIndex(of: Character(sep)) {
                t = String(t[..<idx])
                break
            }
        }
        return t.trimmingCharacters(in: .whitespaces)
    }

    static func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
