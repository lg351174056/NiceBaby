import SwiftUI

// MARK: - 成语百科（列表 + 搜索 + 分类 + 详情/故事）

struct IdiomEncyclopediaView: View {
    let onExit: () -> Void

    @State private var idioms: [IdiomEntry] = []
    @State private var searchText = ""
    @State private var selectedInitial: String?
    @State private var selectedIdiom: IdiomEntry?

    var body: some View {
        ZStack {
            FieldBackground()

            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        GracefulBackButton(action: onExit)
                        Spacer()
                    }
                    Text("成语百科")
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                // 搜索栏
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.fieldMoss)
                    TextField("搜索成语…", text: $searchText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.fieldInk)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(red: 160/255, green: 154/255, blue: 136/255))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 1.5))
                .padding(.horizontal, 18)
                .padding(.bottom, 8)

                // 列表 + 右侧 A-Z 索引
                ZStack(alignment: .trailing) {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredIdioms.prefix(200), id: \.id) { idiom in
                                    Button {
                                        selectedIdiom = idiom
                                    } label: {
                                        idiomRow(idiom)
                                    }
                                    .buttonStyle(.plain)
                                    .id(idiom.id)
                                }
                                if filteredIdioms.count > 200 {
                                    Text("共 \(filteredIdioms.count) 条，输入关键字缩小范围")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppTheme.fieldMoss)
                                        .padding(.vertical, 12)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.trailing, 20)
                            .padding(.bottom, 40)
                        }
                        .onChange(of: selectedInitial) { _, newVal in
                            if let initial = newVal,
                               let firstId = IdiomEncyclopediaStore.shared.firstId(for: initial) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(firstId, anchor: .top)
                                }
                            }
                        }
                    }

                    // 右侧 A-Z 拼音索引条（支持滑动选择）
                    SideIndexBar(
                        letters: pinyinInitials,
                        selected: $selectedInitial
                    )
                    .padding(.trailing, 2)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedIdiom) { idiom in
            IdiomEncyclopediaDetailSheet(idiom: idiom)
                .presentationDetents([.large])
        }
        .onAppear { loadData() }
    }

    private let pinyinInitials = ["A","B","C","D","E","F","G","H","J","K","L","M","N","O","P","Q","R","S","T","W","X","Y","Z"]

    private var filteredIdioms: [IdiomEntry] {
        var result = idioms
        if let initial = selectedInitial {
            result = IdiomEncyclopediaStore.shared.idioms(forPinyinInitial: initial)
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.contains(searchText) || $0.meaning.contains(searchText) }
        }
        return result
    }

    private func idiomRow(_ idiom: IdiomEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(idiom.name)
                        .font(.system(size: 15, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                    if IdiomEncyclopediaStore.shared.hasStory(idiom.name) {
                        Text("故事")
                            .font(.system(size: 8, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(red: 232/255, green: 106/255, blue: 82/255), in: Capsule())
                    }
                }
                Text(idiom.meaning)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(red: 160/255, green: 160/255, blue: 152/255))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 1.5))
        )
    }

    private func loadData() {
        guard idioms.isEmpty else { return }
        idioms = IdiomEncyclopediaStore.shared.allIdioms
    }
}

// MARK: - 详情弹层

private struct IdiomEncyclopediaDetailSheet: View {
    let idiom: IdiomEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let rich = IdiomCatalog.richInfo(for: idiom.name)
        let story = IdiomEncyclopediaStore.shared.story(for: idiom.name)

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // 标题
                HStack {
                    Text(idiom.name)
                        .font(.system(size: 28, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                        .tracking(2)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.fieldMoss)
                            .frame(width: 30, height: 30)
                            .background(Color(red: 240/255, green: 238/255, blue: 232/255), in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                // 拼音
                if let pinyin = rich.pinyin, !pinyin.isEmpty {
                    Text(pinyin)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMint)
                }

                // 释义
                detailBlock("释义", rich.explanation ?? idiom.meaning)

                // 出处
                if let origin = rich.derivation, !origin.isEmpty {
                    detailBlock("出处", origin)
                }

                // 例句
                if let example = rich.example, !example.isEmpty {
                    detailBlock("例句", example)
                }

                // 故事
                if let story, !story.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "book.pages")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(red: 232/255, green: 106/255, blue: 82/255))
                            Text("成语故事")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color(red: 232/255, green: 106/255, blue: 82/255))
                        }
                        Text(story)
                            .font(.system(size: 13.5, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.fieldInk)
                            .lineSpacing(5)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(red: 253/255, green: 248/255, blue: 240/255))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(red: 232/255, green: 106/255, blue: 82/255).opacity(0.2), lineWidth: 1))
                    )
                }
            }
            .padding(22)
            .padding(.bottom, 30)
        }
        .background(Color(red: 247/255, green: 245/255, blue: 240/255).ignoresSafeArea())
    }

    private func detailBlock(_ title: String, _ content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.fieldMoss)
            Text(content)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.fieldInk)
                .lineSpacing(4)
        }
    }
}

// MARK: - 数据模型

struct IdiomEntry: Identifiable, Hashable {
    let id: Int
    let name: String
    let meaning: String
}


// MARK: - 数据加载

final class IdiomEncyclopediaStore {
    static let shared = IdiomEncyclopediaStore()

    let allIdioms: [IdiomEntry]
    private let byPinyinInitial: [String: [IdiomEntry]]
    private let storiesIndex: [String: String]

    private init() {
        let idioms = Self.loadIdioms()
        self.allIdioms = idioms
        self.byPinyinInitial = Self.buildPinyinIndex(idioms)
        self.storiesIndex = Self.loadStories()
    }

    private static func loadIdioms() -> [IdiomEntry] {
        if let url = Bundle.main.url(forResource: "idiom_list", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            struct RawEntry: Decodable { let id: Int; let name: String; let meaning: String }
            if let arr = try? JSONDecoder().decode([RawEntry].self, from: data) {
                return arr.map { IdiomEntry(id: $0.id, name: $0.name, meaning: $0.meaning) }
            }
        }
        if let url = Bundle.main.url(forResource: "成语大全", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            struct DaquanEntry: Decodable { let word: String?; let explanation: String? }
            if let arr = try? JSONDecoder().decode([DaquanEntry].self, from: data) {
                return arr.enumerated().compactMap { idx, e in
                    guard let w = e.word, w.count == 4 else { return nil }
                    return IdiomEntry(id: idx + 1, name: w, meaning: e.explanation ?? "")
                }
            }
        }
        return []
    }

    private static func buildPinyinIndex(_ idioms: [IdiomEntry]) -> [String: [IdiomEntry]] {
        var result: [String: [IdiomEntry]] = [:]
        for idiom in idioms {
            let initial = pinyinInitial(of: idiom.name)
            result[initial, default: []].append(idiom)
        }
        return result
    }

    private static func loadStories() -> [String: String] {
        guard let url = Bundle.main.url(forResource: "成语故事", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        struct RawStory: Decodable { let name: String; let story: String }
        guard let arr = try? JSONDecoder().decode([RawStory].self, from: data) else { return [:] }
        var dict: [String: String] = [:]
        for s in arr { dict[s.name] = s.story }
        return dict
    }

    func hasStory(_ name: String) -> Bool { storiesIndex[name] != nil }
    func story(for name: String) -> String? { storiesIndex[name] }

    func idioms(forPinyinInitial letter: String) -> [IdiomEntry] {
        byPinyinInitial[letter] ?? []
    }

    func firstId(for letter: String) -> Int? {
        byPinyinInitial[letter]?.first?.id
    }

    private static func pinyinInitial(of text: String) -> String {
        guard let first = text.first else { return "#" }
        guard let scalar = first.unicodeScalars.first, (0x4E00...0x9FFF).contains(scalar.value) else {
            let c = String(first).uppercased()
            return c.first?.isLetter == true ? c : "#"
        }
        // 快速查表：汉字 Unicode → 拼音首字母（基于 GB2312 排序规律）
        let code = scalar.value
        let table: [(UInt32, String)] = [
            (0x5765, "A"), (0x58F0, "B"), (0x5BFF, "C"), (0x5D4B, "D"),
            (0x5F20, "E"), (0x6208, "F"), (0x6536, "G"), (0x6B50, "H"),
            (0x6D9E, "J"), (0x7075, "K"), (0x7545, "L"), (0x7B60, "M"),
            (0x7D59, "N"), (0x7F9E, "O"), (0x8109, "P"), (0x82CC, "Q"),
            (0x853C, "R"), (0x8BC2, "S"), (0x9009, "T"), (0x9274, "W"),
            (0x9B54, "X"), (0x9E4B, "Y"), (0x9F43, "Z")
        ]
        for i in stride(from: table.count - 1, through: 0, by: -1) {
            if code >= table[i].0 { return table[i].1 }
        }
        return "A"
    }
}

// MARK: - 右侧索引条（点击 + 滑动）

private struct SideIndexBar: View {
    let letters: [String]
    @Binding var selected: String?
    @State private var isDragging = false
    @GestureState private var dragLocation: CGPoint = .zero

    var body: some View {
        VStack(spacing: 0) {
            ForEach(letters, id: \.self) { letter in
                Text(letter)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(selected == letter ? Color.white : AppTheme.fieldMint)
                    .frame(width: 18, height: 18)
                    .background(selected == letter ? AppTheme.fieldMint : Color.clear, in: Circle())
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isDragging ? Color.white.opacity(0.95) : Color.white.opacity(0.7))
                .shadow(color: Color.black.opacity(isDragging ? 0.12 : 0.05), radius: 4, y: 2)
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($dragLocation) { value, state, _ in
                    state = value.location
                }
                .onChanged { value in
                    isDragging = true
                    updateSelection(at: value.location)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded { }
        )
    }

    private func updateSelection(at point: CGPoint) {
        let totalHeight = CGFloat(letters.count) * 18 + 8
        let y = max(0, min(point.y - 4, totalHeight - 8))
        let index = Int(y / 18)
        let clamped = max(0, min(index, letters.count - 1))
        let letter = letters[clamped]
        if selected != letter {
            selected = letter
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

