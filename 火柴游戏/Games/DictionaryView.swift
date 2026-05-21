import Combine

import SwiftUI
import AVFoundation

// MARK: - 汉语词典数据模型

struct DictEntry: Codable, Identifiable {
    let word: String
    let oldword: String
    let strokes: String
    let pinyin: String
    let radicals: String
    let explanation: String
    let more: String
    
    var id: String { word + pinyin }
    
    /// 简化释义（去掉换行和过多细节，适合卡片预览）
    var briefExplanation: String {
        let cleaned = explanation
            .replacingOccurrences(of: "\n", with: "；")
            .replacingOccurrences(of: "  ", with: "")
        // 截取前 60 字
        if cleaned.count <= 60 { return cleaned }
        let end = cleaned.index(cleaned.startIndex, offsetBy: 60)
        return String(cleaned[..<end]) + "…"
    }
    
    /// 拼音首字母（用于索引）
    var pinyinInitial: Character {
        guard let first = pinyin.first else { return "#" }
        let lower = String(first).lowercased()
        if lower >= "a" && lower <= "z" { return Character(lower) }
        return "#"
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
            var index: [Character: [DictEntry]] = [:]
            for entry in all {
                let key = entry.pinyinInitial
                index[key, default: []].append(entry)
            }
            
            // 排序每组内条目
            for key in index.keys {
                index[key]?.sort { $0.pinyin.localizedStandardCompare($1.pinyin) == .orderedAscending }
            }
            
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
            entry.pinyin.lowercased().contains(q) ||
            entry.explanation.lowercased().contains(q)
        }
    }
    
    /// 某个拼音首字母下的条目数
    func count(for letter: Character) -> Int {
        pinyinIndex[letter]?.count ?? 0
    }
}

// MARK: - 词典 TTS

private final class DictTTS: NSObject, AVSpeechSynthesizerDelegate {
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
    
    private let kind: GameKind = .idiomDictionary
    
    /// 当前展示的条目列表
    private var displayEntries: [DictEntry] {
        if !searchText.isEmpty {
            return store.search(searchText)
        }
        if let letter = selectedLetter {
            return store.pinyinIndex[letter] ?? []
        }
        return []
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 252/255, green: 250/255, blue: 245/255).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部栏
                    GameTopBar(
                        title: "汉语词典",
                        progressText: "\(store.entries.count) 个汉字",
                        palette: kind.palette,
                        onExit: onExit
                    )
                    
                    // 搜索栏
                    searchBar
                        .padding(.horizontal, AppTheme.paddingScreen)
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
                            
                            if !searchText.isEmpty && displayEntries.isEmpty {
                                emptySearchResult
                            } else if selectedLetter == nil && searchText.isEmpty {
                                welcomeView
                            } else if displayEntries.isEmpty {
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
            }
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
                .onChange(of: searchText) { _, _ in
                    if !searchText.isEmpty { selectedLetter = nil }
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(red: 180/255, green: 160/255, blue: 130/255).opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
    
    // MARK: - 拼音索引条
    
    private var pinyinIndexBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(store.indexLetters, id: \.self) { letter in
                    Button {
                        searchText = ""
                        withAnimation(.easeInOut(duration: 0.1)) {
                            selectedLetter = (selectedLetter == letter) ? nil : letter
                        }
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
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedLetter == letter
                                      ? AnyShapeStyle(LinearGradient(colors: [kind.palette.0, kind.palette.1], startPoint: .topLeading, endPoint: .bottomTrailing))
                                      : AnyShapeStyle(Color.white.opacity(0.6))
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
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(displayEntries) { entry in
                    Button {
                        selectedEntry = entry
                    } label: {
                        entryRow(entry)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .sheet(item: $selectedEntry) { entry in
            DictDetailView(entry: entry, palette: kind.palette)
        }
    }
    
    @ViewBuilder
    private func entryRow(_ entry: DictEntry) -> some View {
        HStack(spacing: 14) {
            // 左：大字
            Text(entry.word)
                .font(.system(size: 32, weight: .heavy, design: .serif))
                .foregroundStyle(kind.palette.0)
                .frame(width: 48, height: 48)
                .background(kind.palette.0.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            
            // 中：拼音 + 简要释义
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(entry.pinyin)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    if !entry.radicals.isEmpty {
                        Text("部首: \(entry.radicals)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.textSecondary.opacity(0.06), in: Capsule())
                    }
                    
                    Text("\(entry.strokes)画")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.textSecondary.opacity(0.06), in: Capsule())
                }
                
                Text(entry.briefExplanation)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 右：发音按钮
            Button {
                DictTTS.shared.speak(entry.word)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(kind.palette.0)
                    .frame(width: 36, height: 36)
                    .background(kind.palette.0.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.3))
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 3, y: 1)
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
                Color(red: 252/255, green: 250/255, blue: 245/255).ignoresSafeArea()
                
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
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
                        .padding(.horizontal, AppTheme.paddingScreen)
                        
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
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                        .padding(.horizontal, AppTheme.paddingScreen)
                        
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
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 3, y: 1)
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