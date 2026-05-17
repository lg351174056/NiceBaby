import Foundation

struct ClassicalPoemRaw: Codable {
    let title: String
    let author: String?
    let paragraphs: [String]
    let rhythmic: String?
    let notes: [String]?
    let dynasty: String?
}

class ClassicalPoetryStore {
    static let shared = ClassicalPoetryStore()
    
    var collections: [(category: String, poems: [Poem])] = []
    
    private init() {
        loadAll()
    }
    
    private func loadAll() {
        guard let resourceURL = Bundle.main.resourceURL else { return }
        
        var loadedCollections: [(category: String, poems: [Poem])] = []
        let fm = FileManager.default
        
        if let enumerator = fm.enumerator(at: resourceURL,
                                          includingPropertiesForKeys: [.isRegularFileKey],
                                          options: [.skipsHiddenFiles]) {
            for case let url as URL in enumerator where url.pathExtension.lowercased() == "json" {
                let filename = url.lastPathComponent
                if filename == "唐诗三百首(二).json" { continue }
                
                if let data = try? Data(contentsOf: url),
                   let rawPoems = try? JSONDecoder().decode([ClassicalPoemRaw].self, from: data) {
                    
                    let categoryName = filename.replacingOccurrences(of: ".json", with: "")
                                               .replacingOccurrences(of: "^\\d+\\.", with: "", options: .regularExpression)
                    
                    let poems = rawPoems.enumerated().map { (index, raw) -> Poem in
                        let type = raw.rhythmic ?? raw.dynasty ?? "古诗词"
                        let content = raw.paragraphs.joined(separator: "\n")
                        return Poem(id: url.hashValue ^ index,
                                    title: raw.title,
                                    author: raw.author ?? "佚名",
                                    type: type,
                                    contents: content)
                    }
                    loadedCollections.append((category: categoryName, poems: poems))
                }
            }
        }
        
        self.collections = loadedCollections.sorted { $0.category < $1.category }
    }
}
