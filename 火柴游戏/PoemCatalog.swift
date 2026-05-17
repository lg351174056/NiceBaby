import Foundation

struct Poem: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let author: String
    let type: String
    let contents: String
}

/// 从 Bundle 懒加载《唐诗三百首》JSON，供首页与发现页共用。
enum PoemCatalog {
    private static var cached: [Poem]?
    private static let lock = NSLock()

    static func poems() -> [Poem] {
        lock.lock()
        defer { lock.unlock() }
        if let cached { return cached }
        guard let url = Bundle.main.url(forResource: "唐诗三百首(二)", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Poem].self, from: data) else {
            return []
        }
        cached = decoded
        return decoded
    }

    static func dailyPoemIndex(total: Int) -> Int {
        guard total > 0 else { return 0 }
        let day = Calendar.current.startOfDay(for: Date())
        let n = Int(day.timeIntervalSince1970 / 86400)
        return n % total
    }
}
