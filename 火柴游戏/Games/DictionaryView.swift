import Combine

import SwiftUI
import AVFoundation

// MARK: - 汉语词典数据模型

struct DictEntry: Decodable, Identifiable, Hashable {
    let word: String
    let oldword: String
    let strokes: String
    let pinyin: String
    let radicals: String
    let explanation: String
    let more: String
    let briefExplanation: String
    let searchPinyin: String
    let searchExplanation: String
    
    var id: String { word + pinyin }

    private enum CodingKeys: String, CodingKey {
        case word
        case oldword
        case strokes
        case pinyin
        case radicals
        case explanation
        case more
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        word = try container.decode(String.self, forKey: .word)
        oldword = try container.decode(String.self, forKey: .oldword)
        strokes = try container.decode(String.self, forKey: .strokes)
        pinyin = try container.decode(String.self, forKey: .pinyin)
        radicals = try container.decode(String.self, forKey: .radicals)
        explanation = try container.decode(String.self, forKey: .explanation)
        more = try container.decode(String.self, forKey: .more)

        let cleaned = explanation
            .replacingOccurrences(of: "\n", with: "；")
            .replacingOccurrences(of: "  ", with: "")
        if cleaned.count <= 60 {
            briefExplanation = cleaned
        } else {
            let end = cleaned.index(cleaned.startIndex, offsetBy: 60)
            briefExplanation = String(cleaned[..<end]) + "…"
        }

        searchPinyin = pinyin.lowercased()
        searchExplanation = explanation.lowercased()
    }
    
    /// 拼音首字母（用于索引）
    nonisolated var pinyinInitial: Character {
        guard let first = pinyin.first else { return "#" }
        // 带声调的 Unicode 字母 → ASCII（ā→a，ɡ→g 等），避免被误归入 #
        switch first {
        case "ā", "á", "ǎ", "à": return "a"
        case "ē", "é", "ě", "è": return "e"
        case "ī", "í", "ǐ", "ì": return "i"
        case "ō", "ó", "ǒ", "ò": return "o"
        case "ū", "ú", "ǔ", "ù": return "u"
        case "ǖ", "ǘ", "ǚ", "ǜ", "ü": return "u"
        case "ɡ": return "g"
        default:
            let lower = String(first).lowercased()
            if let scalar = lower.unicodeScalars.first,
               scalar.value >= 97, scalar.value <= 122 {
                return Character(lower)
            }
            return "#"
        }
    }
}

// MARK: - 词典数据仓库（懒加载 + 拼音索引）

@MainActor
final class DictionaryStore: ObservableObject {
    static let shared = DictionaryStore()
    
    @Published var entries: [DictEntry] = []
    @Published var isLoading = true
    
    /// 拼音首字母 → 条目列表
    private(set) var pinyinIndex: [Character: [DictEntry]] = [:]
    private(set) var indexLetters: [Character] = []
    
    private init() {
        Task { await load() }
    }
    
    func load() async {
        self.isLoading = true
        
        await Task.detached(priority: .userInitiated) {
            guard let url = Bundle.main.url(forResource: "word", withExtension: "json") else {
                print("[DictionaryStore] word.json not found in bundle")
                await MainActor.run { self.isLoading = false }
                return
            }
            
            guard let data = try? Data(contentsOf: url) else {
                print("[DictionaryStore] Failed to read word.json")
                await MainActor.run { self.isLoading = false }
                return
            }
            
            let decoder = JSONDecoder()
            guard let all = try? decoder.decode([DictEntry].self, from: data) else {
                print("[DictionaryStore] Failed to decode word.json")
                await MainActor.run { self.isLoading = false }
                return
            }
            
            // 构建拼音索引
            var indexBuilder: [Character: [DictEntry]] = [:]
            for entry in all {
                let key = entry.pinyinInitial
                indexBuilder[key, default: []].append(entry)
            }
            for key in indexBuilder.keys {
                indexBuilder[key]?.sort { $0.pinyin.localizedStandardCompare($1.pinyin) == .orderedAscending }
            }
            let index = indexBuilder
            
            let sortedLetters = index.keys.sorted { a, b in
                if a == "#" { return false }
                if b == "#" { return true }
                return a < b
            }
            
            await MainActor.run {
                self.entries = all
                self.pinyinIndex = index
                self.indexLetters = sortedLetters
                self.isLoading = false
            }
        }.value
    }
    
    /// 按搜索词过滤
    func search(_ query: String) -> [DictEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        
        return entries.filter { entry in
            entry.word.contains(query) ||
            entry.searchPinyin.contains(q) ||
            entry.searchExplanation.contains(q)
        }
    }
    
    /// 某个拼音首字母下的条目数
    func count(for letter: Character) -> Int {
        pinyinIndex[letter]?.count ?? 0
    }
}

// MARK: - 词典 TTS

private final class DictTTS: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    static let shared = DictTTS()
    private let synth = AVSpeechSynthesizer()
    
    override init() { super.init(); synth.delegate = self }
    
    func speak(_ text: String) {
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        u.rate = 0.35
        u.pitchMultiplier = 1.05
        synth.speak(u)
    }
}

// MARK: - 词典主视图

struct DictionaryGameView: View {
    let onExit: () -> Void
    @StateObject private var store = DictionaryStore.shared
    
    @State private var searchText = ""
    @State private var selectedLetter: Character? = nil
    @State private var selectedEntry: DictEntry? = nil
    @State private var visibleEntries: [DictEntry] = []
    
    private let kind: GameKind = .idiomDictionary

    var body: some View {
        ZStack {
                // 蓝天草地背景（书野营地竹青风）
                FieldBackground()

                dictSun
                dictCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
                dictCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

                VStack(spacing: 0) {
                    // 透明导航条
                    ZStack {
                        HStack {
                            GracefulBackButton(action: onExit)
                            Spacer()
                        }
                        VStack(spacing: 2) {
                            Text("汉语词典")
                                .font(.system(size: 16, weight: .heavy, design: .serif))
                                .foregroundStyle(AppTheme.fieldInk)
                            Text("\(store.entries.count) 个汉字")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.fieldMoss)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .padding(.bottom, 6)

                    // 搜索栏
                    searchBar
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                    
                    if store.isLoading {
                        Spacer()
                        ProgressView("正在加载词典数据...")
                            .controlSize(.large)
                        Spacer()
                    } else {
                        // 拼音索引条 + 内容
                        VStack(spacing: 0) {
                            pinyinIndexBar
                            
                            if !searchText.isEmpty && visibleEntries.isEmpty {
                                emptySearchResult
                            } else if selectedLetter == nil && searchText.isEmpty {
                                welcomeView
                            } else if visibleEntries.isEmpty {
                                emptyState
                            } else {
                                entryListView
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if store.entries.isEmpty { Task { await store.load() } }
                ensureDefaultLetter()
                refreshVisibleEntries()
            }
            .onChange(of: store.entries.count) { _, _ in
                ensureDefaultLetter()
                refreshVisibleEntries()
            }
    }

    // MARK: - 搜索栏
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(red: 180/255, green: 160/255, blue: 130/255))
            
            TextField("搜索汉字或拼音...", text: $searchText)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .onChange(of: searchText) { _, newValue in
                    if !newValue.isEmpty { selectedLetter = nil }
                    refreshVisibleEntries()
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    refreshVisibleEntries()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(red: 180/255, green: 160/255, blue: 130/255).opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppTheme.fieldMint.opacity(0.4), lineWidth: 2)
        )
        .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 4, y: 2)
    }
    
    // MARK: - 拼音索引条
    
    private var pinyinIndexBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(store.indexLetters, id: \.self) { letter in
                    Button {
                        searchText = ""
                        selectedLetter = (selectedLetter == letter) ? nil : letter
                        refreshVisibleEntries()
                    } label: {
                        VStack(spacing: 2) {
                            Text(String(letter).uppercased())
                                .font(.system(size: 14, weight: selectedLetter == letter ? .heavy : .bold, design: .rounded))
                                .foregroundStyle(selectedLetter == letter ? .white : kind.palette.0)
                            Text("\(store.count(for: letter))")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(selectedLetter == letter ? .white.opacity(0.7) : AppTheme.textSecondary.opacity(0.5))
                        }
                        .frame(width: 40, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedLetter == letter
                                      ? AnyShapeStyle(LinearGradient(colors: [Color(red: 126/255, green: 211/255, blue: 160/255), AppTheme.fieldMint], startPoint: .topLeading, endPoint: .bottomTrailing))
                                      : AnyShapeStyle(Color.white.opacity(0.85)))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(selectedLetter == letter
                                            ? AppTheme.fieldInk
                                            : AppTheme.fieldOlive.opacity(0.3),
                                            lineWidth: 2)
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 欢迎页
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)
            
            Image(systemName: "character.book.closed.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(kind.palette.0.opacity(0.3))
            
            Text("点击上方拼音索引\n或输入汉字搜索")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            
            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 空搜索结果
    
    private var emptySearchResult: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 60)
            Image(systemName: "questionmark.circle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
            Text("未找到「\(searchText)」")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 60)
            Image(systemName: "text.page.slash")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
            Text("该拼音下暂无数据")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer(minLength: 60)
        }
    }
    
    // MARK: - 词条列表
    
    private var entryListView: some View {
        List {
            ForEach(visibleEntries) { entry in
                DictEntryRow(entry: entry, accent: kind.palette.0)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEntry = entry
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(AppTheme.background)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
        .padding(.top, 4)
        .sheet(item: $selectedEntry) { entry in
            DictDetailView(entry: entry, palette: kind.palette)
        }
    }


    // MARK: - 背景装饰（太阳/云）

    private var dictSun: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breathe = 1 + 0.03 * sin(t * 1.2)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 214/255, blue: 110/255).opacity(0.4),
                            Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.14),
                            .clear
                        ], center: .center, startRadius: 10, endRadius: 50)
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(breathe)
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 246/255, blue: 205/255),
                            Color(red: 255/255, green: 214/255, blue: 100/255),
                            Color(red: 247/255, green: 188/255, blue: 55/255)
                        ], center: .init(x: 0.38, y: 0.3), startRadius: 2, endRadius: 18)
                    )
                    .frame(width: 32, height: 32)
                    .scaleEffect(breathe)
                    .shadow(color: Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.8), radius: 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.trailing, 20)
            .padding(.top, 30)
        }
        .allowsHitTesting(false)
    }

    private func dictCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate + delay
            let drift = 14 * sin(t * 0.42)
            let bob = 3 * sin(t * 0.85 + 1.2)
            ZStack {
                ZStack {
                    Capsule().fill(Color.white.opacity(0.95)).frame(width: 42, height: 15).offset(y: 4)
                    Circle().fill(Color.white.opacity(0.95)).frame(width: 25, height: 25).offset(x: -9, y: -6)
                    Circle().fill(Color.white.opacity(0.9)).frame(width: 21, height: 21).offset(x: 7, y: -4)
                    Circle().fill(Color.white.opacity(0.9)).frame(width: 15, height: 15).offset(x: 0, y: -10)
                }
                .frame(width: 52, height: 30)
                .scaleEffect(scale)
                .offset(x: drift, y: bob)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, 390 * x - 10)
            .padding(.top, 390 * y)
        }
        .allowsHitTesting(false)
    }

    /// 默认选中第一个索引字母（A），避免进入空页面
    private func ensureDefaultLetter() {
        guard selectedLetter == nil, searchText.isEmpty,
              let first = store.indexLetters.first else { return }
        selectedLetter = first
    }

    private func refreshVisibleEntries() {
        if !searchText.isEmpty {
            visibleEntries = store.search(searchText)
        } else if let letter = selectedLetter {
            visibleEntries = store.pinyinIndex[letter] ?? []
        } else {
            visibleEntries = []
        }
    }
}

private struct DictEntryRow: View, Equatable {
    let entry: DictEntry
    let accent: Color

    static func == (lhs: DictEntryRow, rhs: DictEntryRow) -> Bool {
        lhs.entry.id == rhs.entry.id
    }

    var body: some View {
        HStack(spacing: 14) {
            // 左：田字格字卡
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(accent.opacity(0.45), lineWidth: 2)
                    )
                    .overlay {
                        // 田字格十字虚线
                        Rectangle()
                            .strokeBorder(accent.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .padding(10)
                    }
                Text(entry.word)
                    .font(.system(size: 30, weight: .heavy, design: .serif))
                    .foregroundStyle(accent)
            }
            .frame(width: 52, height: 52)
            .shadow(color: accent.opacity(0.18), radius: 4, y: 2)

            // 中：拼音 + 简要释义
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(entry.pinyin)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.fieldInk)

                    if !entry.radicals.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "character.book.closed")
                                .font(.system(size: 8, weight: .bold))
                            Text("\(entry.radicals)")
                        }
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(accent.opacity(0.1), in: Capsule())
                        .overlay(Capsule().strokeBorder(accent.opacity(0.3), lineWidth: 1))
                    }

                    Text("\(entry.strokes)画")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 176/255, green: 130/255, blue: 50/255))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Color(red: 245/255, green: 214/255, blue: 123/255).opacity(0.15), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color(red: 217/255, green: 164/255, blue: 91/255).opacity(0.35), lineWidth: 1))
                }

                Text(entry.briefExplanation)
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 85/255, green: 112/255, blue: 95/255))
                    .lineLimit(2)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)

            // 右：发音按钮
            Button {
                DictTTS.shared.speak(entry.word)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(colors: [Color(red: 126/255, green: 211/255, blue: 160/255), AppTheme.fieldMint], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle()
                    )
                    .overlay(Circle().strokeBorder(AppTheme.fieldInk, lineWidth: 1.5))
                    .shadow(color: AppTheme.fieldMint.opacity(0.35), radius: 4, y: 2)
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.fieldMossLight)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.28), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 5, y: 3)
        )
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
    }
}

// MARK: - 词条详情页

struct DictDetailView: View {
    let entry: DictEntry
    let palette: (Color, Color)
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 蓝天草地背景（书野营地竹青风）
                FieldBackground()

                detailSun
                detailCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
                detailCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 大字展示区
                        VStack(spacing: 12) {
                            Text(entry.word)
                                .font(.system(size: 80, weight: .heavy, design: .serif))
                                .foregroundStyle(AppTheme.textPrimary)
                                .padding(.top, 10)
                            
                            // 发音按钮
                            Button {
                                DictTTS.shared.speak(entry.word)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    Text(entry.pinyin)
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule().fill(
                                        LinearGradient(colors: [palette.0, palette.1],
                                                       startPoint: .leading, endPoint: .trailing)
                                    )
                                )
                                .shadow(color: palette.0.opacity(0.4), radius: 8, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white.opacity(0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)
                                )
                                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.1), radius: 8, y: 4)
                        )
                        .padding(.horizontal, 18)
                        
                        // 信息徽章
                        HStack(spacing: 12) {
                            infoBadge(icon: "pencil.tip", label: "笔画", value: entry.strokes)
                            infoBadge(icon: "character", label: "部首", value: entry.radicals.isEmpty ? "无" : entry.radicals)
                            if !entry.oldword.isEmpty && entry.oldword != entry.word {
                                infoBadge(icon: "textformat.size.smaller", label: "繁体", value: entry.oldword)
                            }
                        }
                        .padding(.horizontal, AppTheme.paddingScreen)
                        
                        // 释义区
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 8) {
                                Rectangle()
                                    .fill(palette.0)
                                    .frame(width: 3, height: 18)
                                    .clipShape(Capsule())
                                Text("释义")
                                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                            
                            // 分段显示 explanation
                            let paragraphs = entry.explanation
                                .components(separatedBy: "\n")
                                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                            
                            ForEach(paragraphs, id: \.self) { para in
                                Text(para.trimmingCharacters(in: .whitespaces))
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary.opacity(0.85))
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .strokeBorder(AppTheme.fieldOlive.opacity(0.28), lineWidth: 2)
                                )
                                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 5, y: 3)
                        )
                        .padding(.horizontal, 18)
                        
                        // 更多信息（可折叠）
                        if !entry.more.isEmpty && !entry.more.contains("搜索与") {
                            moreInfoSection
                                .padding(.horizontal, AppTheme.paddingScreen)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle(entry.word)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.0)
                }
            }
        }
    }
    
    private func infoBadge(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(palette.0)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 1.5)
                )
        )
    }
    

    // MARK: - 背景装饰（太阳/云）

    private var detailSun: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breathe = 1 + 0.03 * sin(t * 1.2)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 214/255, blue: 110/255).opacity(0.4),
                            Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.14),
                            .clear
                        ], center: .center, startRadius: 10, endRadius: 50)
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(breathe)
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 246/255, blue: 205/255),
                            Color(red: 255/255, green: 214/255, blue: 100/255),
                            Color(red: 247/255, green: 188/255, blue: 55/255)
                        ], center: .init(x: 0.38, y: 0.3), startRadius: 2, endRadius: 18)
                    )
                    .frame(width: 32, height: 32)
                    .scaleEffect(breathe)
                    .shadow(color: Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.8), radius: 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.trailing, 20)
            .padding(.top, 30)
        }
        .allowsHitTesting(false)
    }

    private func detailCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate + delay
            let drift = 14 * sin(t * 0.42)
            let bob = 3 * sin(t * 0.85 + 1.2)
            ZStack {
                ZStack {
                    Capsule().fill(Color.white.opacity(0.95)).frame(width: 42, height: 15).offset(y: 4)
                    Circle().fill(Color.white.opacity(0.95)).frame(width: 25, height: 25).offset(x: -9, y: -6)
                    Circle().fill(Color.white.opacity(0.9)).frame(width: 21, height: 21).offset(x: 7, y: -4)
                    Circle().fill(Color.white.opacity(0.9)).frame(width: 15, height: 15).offset(x: 0, y: -10)
                }
                .frame(width: 52, height: 30)
                .scaleEffect(scale)
                .offset(x: drift, y: bob)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, 390 * x - 10)
            .padding(.top, 390 * y)
        }
        .allowsHitTesting(false)
    }

    @State private var showMore = false
    
    private var moreInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showMore.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(palette.0.opacity(0.6))
                        .frame(width: 3, height: 18)
                        .clipShape(Capsule())
                    Text("详细资料")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: showMore ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(palette.0)
                }
            }
            .buttonStyle(.plain)
            
            if showMore {
                let moreText = entry.more
                    .replacingOccurrences(of: "\n", with: "\n\n")
                Text(moreText)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
