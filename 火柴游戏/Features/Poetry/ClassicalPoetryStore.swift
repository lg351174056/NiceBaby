import Foundation
import Combine
import SwiftUI

struct ClassicalPoemRaw: Codable {
    let title: String
    let author: String?
    let paragraphs: [String]
    let rhythmic: String?
    let notes: [String]?
    let dynasty: String?
}

/// 国学经典库单本书籍的数据结构
struct PoetryCollection: Codable, Identifiable, Hashable {
    let title: String          // 书名/分类名，例如 "花间集卷第一"
    let description: String?   // 简介
    let poems: [Poem]          // 该集合下的所有诗词
    
    var id: String { title }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
    
    static func == (lhs: PoetryCollection, rhs: PoetryCollection) -> Bool {
        lhs.title == rhs.title
    }
}

@MainActor
final class ClassicalPoetryStore: ObservableObject {
    static let shared = ClassicalPoetryStore()
    
    @Published var allCollections: [PoetryCollection] = []
    @Published var isReady = false
    
    private init() {
        Task {
            await loadAllClassicalPoetry()
        }
    }
    
    private func loadAllClassicalPoetry() async {
        guard let resourceURL = Bundle.main.resourceURL else {
            print("找不到 resourceURL 目录")
            self.isReady = true
            return
        }
        
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: resourceURL,
                                             includingPropertiesForKeys: [.isRegularFileKey],
                                             options: [.skipsHiddenFiles]) else {
            self.isReady = true
            return
        }
        
        var jsonURLs: [URL] = []
        if let allObjects = enumerator.allObjects as? [URL] {
            jsonURLs = allObjects.filter { $0.pathExtension.lowercased() == "json" }
        }
        
        var loadedCollections: [PoetryCollection] = []
        
        // 并发加载所有 JSON 文件
        await withTaskGroup(of: PoetryCollection?.self) { group in
            for url in jsonURLs {
                group.addTask {
                    let filename = url.lastPathComponent
                    
                    // 过滤掉已经在 PoemCatalog 中加载的 300 首，以及非古诗类的游戏数据
                    let excludeFiles = [
                        "唐诗三百首(二).json",
                        "成语大全.json",
                        "歇后语.json",
                        "三字经 - 新版.json",
                        "三字经 - 传统.json",
                        "authors.json"
                    ]
                    
                    if excludeFiles.contains(filename) { return nil }
                    
                    guard let data = try? Data(contentsOf: url) else { return nil }
                    
                    do {
                        let rawPoems = try JSONDecoder().decode([ClassicalPoemRaw].self, from: data)
                        let rawName = filename.replacingOccurrences(of: ".json", with: "")
                                              .replacingOccurrences(of: "^\\d+\\.", with: "", options: .regularExpression)
                        let categoryName = Self.mapToChineseName(rawName: rawName)
                        
                        let poems = rawPoems.enumerated().map { (index, raw) -> Poem in
                            let type = raw.rhythmic ?? raw.dynasty ?? "古诗词"
                            let content = raw.paragraphs.joined(separator: "\n")
                            return Poem(id: url.hashValue ^ index,
                                        title: raw.title,
                                        author: raw.author ?? "佚名",
                                        type: type,
                                        contents: content)
                        }
                        return PoetryCollection(title: categoryName, description: nil, poems: poems)
                    } catch {
                        // 格式不匹配则忽略
                        return nil
                    }
                }
            }
            
            for await collection in group {
                if let collection = collection {
                    loadedCollections.append(collection)
                }
            }
        }
        
        // 按名称简单排序
        loadedCollections.sort { $0.title < $1.title }
        
        self.allCollections = loadedCollections
        self.isReady = true
    }
    
    /// 建立教材英文文件名到中文的映射表
    nonisolated private static func mapToChineseName(rawName: String) -> String {
        let mapping: [String: String] = [
            // 小学
            "poetry_primary_g1_t1": "一年级上册",
            "poetry_primary_g1_t2": "一年级下册",
            "poetry_primary_g2_t1": "二年级上册",
            "poetry_primary_g2_t2": "二年级下册",
            "poetry_primary_g3_t1": "三年级上册",
            "poetry_primary_g3_t2": "三年级下册",
            "poetry_primary_g4_t1": "四年级上册",
            "poetry_primary_g4_t2": "四年级下册",
            "poetry_primary_g5_t1": "五年级上册",
            "poetry_primary_g5_t2": "五年级下册",
            "poetry_primary_g6_t1": "六年级上册",
            "poetry_primary_g6_t2": "六年级下册",
            // 初中
            "poetry_junior_g7_t1_in": "七年级上册(课内)",
            "poetry_junior_g7_t1_out": "七年级上册(课外)",
            "poetry_junior_g7_t2_in": "七年级下册(课内)",
            "poetry_junior_g7_t2_out": "七年级下册(课外)",
            "poetry_junior_g8_t1_in": "八年级上册(课内)",
            "poetry_junior_g8_t1_out": "八年级上册(课外)",
            "poetry_junior_g8_t2_in": "八年级下册(课内)",
            "poetry_junior_g8_t2_out": "八年级下册(课外)",
            "poetry_junior_g9_t1_in": "九年级上册(课内)",
            "poetry_junior_g9_t1_out": "九年级上册(课外)",
            "poetry_junior_g9_t2_in": "九年级下册(课内)",
            "poetry_junior_g9_t2_out": "九年级下册(课外)",
            // 高中
            "poetry_senior_g10_t1": "高一上册",
            "poetry_senior_g10_t2": "高一下册",
            "poetry_senior_g11_t1": "高二上册",
            "poetry_senior_g11_t2": "高二下册"
        ]
        
        if let chineseName = mapping[rawName] {
            return chineseName
        }
        return rawName
    }
    
    // MARK: - 大卡片分类引擎
    
    /// 教材同步学段定义
    enum TextbookStage: String, CaseIterable, Identifiable, Hashable {
        case primary = "小学"
        case junior = "初中"
        case senior = "高中"
        var id: String { rawValue }
        
        var prefix: String {
            switch self {
            case .primary: return "poetry_primary"
            case .junior: return "poetry_junior"
            case .senior: return "poetry_senior"
            }
        }
        
        var emoji: String {
            switch self {
            case .primary: return "🎒"
            case .junior: return "📖"
            case .senior: return "🎓"
            }
        }
        
        var gradientColors: (Color, Color) {
            switch self {
            case .primary: return (Color(red: 16/255, green: 185/255, blue: 129/255), Color(red: 52/255, green: 211/255, blue: 153/255))
            case .junior: return (Color(red: 79/255, green: 70/255, blue: 229/255), Color(red: 129/255, green: 140/255, blue: 248/255))
            case .senior: return (Color(red: 245/255, green: 158/255, blue: 11/255), Color(red: 251/255, green: 191/255, blue: 36/255))
            }
        }
    }
    
    /// 获取特定学段的所有教材册子
    func textbookCollections(for stage: TextbookStage) -> [PoetryCollection] {
        allCollections.filter { collection in
            // 通过 title 对应映射表查找
            let stagePrefix: [String]
            switch stage {
            case .primary:
                stagePrefix = ["一年级", "二年级", "三年级", "四年级", "五年级", "六年级"]
            case .junior:
                stagePrefix = ["七年级", "八年级", "九年级"]
            case .senior:
                stagePrefix = ["高一", "高二"]
            }
            return stagePrefix.contains(where: { collection.title.hasPrefix($0) })
        }.sorted { $0.title < $1.title }
    }
    
    enum PoetryCategory {
        case textbook    // 教材同步
        case classic     // 千古绝唱 (300首等)
        case shijing     // 诗经
        case huajian     // 花间集与二主词
        case form        // 体裁分类 (绝句/律诗等)
        case other       // 其他
    }
    
    /// 获取特定大类下的所有书籍/合集
    func collections(for category: PoetryCategory) -> [PoetryCollection] {
        switch category {
        case .textbook:
            return allCollections.filter { $0.title.contains("年级") || $0.title.contains("高中") || $0.title.contains("文言文") }
                .sorted { $0.title < $1.title }
            
        case .classic:
            // 注意：唐诗三百首(二)在 PoemCatalog 里，这里加载的是本地其它的如宋词三百首、千家诗等
            return allCollections.filter { $0.title.contains("三百首") || $0.title.contains("千家诗") || $0.title.contains("古诗十九首") }
            
        case .shijing:
            return allCollections.filter { $0.title.contains("国风") || $0.title.contains("小雅") || $0.title.contains("大雅") || $0.title.contains("颂") }
            
        case .huajian:
            return allCollections.filter { $0.title.contains("花间集") || $0.title.contains("南唐二主词") }
                .sorted { $0.title < $1.title }
            
        case .form:
            return allCollections.filter {
                $0.title.contains("绝句") || $0.title.contains("律诗") || $0.title.contains("古诗") || $0.title.contains("乐府")
            }.filter { !$0.title.contains("十九首") } // 排除古诗十九首，它在经典里
            
        case .other:
            // 不属于以上的其他文件
            return allCollections.filter { collection in
                let categories: [PoetryCategory] = [.textbook, .classic, .shijing, .huajian, .form]
                for cat in categories {
                    if self.collections(for: cat).contains(where: { $0.id == collection.id }) {
                        return false
                    }
                }
                return true
            }
        }
    }
}
