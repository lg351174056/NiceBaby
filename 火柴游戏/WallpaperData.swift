import Foundation

enum MediaType: String, Codable {
    case image
    case video
}

struct WallpaperMedia: Identifiable, Hashable, Codable {
    var id = UUID()
    let url: String
    let type: MediaType
    
    enum CodingKeys: String, CodingKey {
        case url
        case type
    }
}

class WallpaperData {
    static let items: [WallpaperMedia] = {
        guard let url = Bundle.main.url(forResource: "wallpapers", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        do {
            let items = try JSONDecoder().decode([WallpaperMedia].self, from: data)
            let validItems = items.filter { URL(string: $0.url) != nil }
            return validItems
        } catch {
            return []
        }
    }()
}
