import SwiftUI
import Foundation
import Combine

// MARK: - Model

struct DictionaryIdiom: Identifiable, Hashable {
    let derivation: String?
    let example: String?
    let explanation: String?
    let pinyin: String          // 带声调："ā bí dì yù"
    let word: String            // "阿鼻地狱"
    let abbreviation: String    // "abdy"

    // 检索字段（预计算，避免每次搜索都重做 fold）
    let searchPinyinFlat: String   // "abidiyu"（去空格、去声调、小写）
    let searchAbbr: String         // "abdy"

    var id: String { word + pinyin }   // 防止同字成语 collision

    var initial: String {
        guard let first = abbreviation.first, first.isASCII, first.isLetter else {
            return "#"
        }
        return String(first).uppercased()
    }
}

private struct RawDictionaryIdiom: Codable {
    let derivation: String?
    let example: String?
    let explanation: String?
    let pinyin: String
    let word: String
    let abbreviation: String
}

// MARK: - 搜索匹配规则

private enum IdiomSearchScope {
    case empty
    case asciiPrefix(String)        // 字母（abbr 或全拼前缀）
    case chineseSubstring(String)   // 含字搜索

    static func parse(_ q: String) -> IdiomSearchScope {
        let trimmed = q.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .empty }
        if trimmed.allSatisfy({ $0.isASCII && $0.isLetter }) {
            return .asciiPrefix(trimmed.lowercased())
        }
        return .chineseSubstring(trimmed)
    }
}

// MARK: - ViewModel

@MainActor
final class IdiomDictionaryViewModel: ObservableObject {
    @Published var allIdioms: [DictionaryIdiom] = []
    @Published var groupedIdioms: [(key: String, idioms: [DictionaryIdiom])] = []
    @Published var availableLetters: [String] = []
    @Published var selectedLetter: String = "A"
    @Published var isLoading = true
    @Published var searchQuery: String = ""

    private var cancellables: Set<AnyCancellable> = []

    init() {
        // 防抖：3 万条遍历不慢，但避免每个字符都触发
        $searchQuery
            .removeDuplicates()
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyFilter() }
            .store(in: &cancellables)
    }

    func loadData() {
        guard isLoading else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            guard let url = Bundle.main.url(forResource: "成语大全", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let raw = try? JSONDecoder().decode([RawDictionaryIdiom].self, from: data) else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            let processed: [DictionaryIdiom] = raw.map { r in
                let flat = r.pinyin
                    .folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US"))
                    .replacingOccurrences(of: " ", with: "")
                    .lowercased()
                return DictionaryIdiom(
                    derivation: r.derivation,
                    example: r.example,
                    explanation: r.explanation,
                    pinyin: r.pinyin,
                    word: r.word,
                    abbreviation: r.abbreviation,
                    searchPinyinFlat: flat,
                    searchAbbr: r.abbreviation.lowercased()
                )
            }

            DispatchQueue.main.async {
                self.allIdioms = processed
                self.applyFilter()
                self.isLoading = false
            }
        }
    }

    private func applyFilter() {
        let scope = IdiomSearchScope.parse(searchQuery)
        let filtered: [DictionaryIdiom]
        
        switch scope {
        case .empty:
            // 【改动点】如果搜索框为空，按选中的字母进行强制过滤，不加载全量数据
            filtered = allIdioms.filter { $0.initial == selectedLetter }
        case .asciiPrefix(let prefix):
            filtered = allIdioms.filter {
                $0.searchAbbr.hasPrefix(prefix) || $0.searchPinyinFlat.hasPrefix(prefix)
            }
        case .chineseSubstring(let s):
            filtered = allIdioms.filter { $0.word.contains(s) }
        }

        let grouped = Dictionary(grouping: filtered, by: { $0.initial })
        let sortedKeys = grouped.keys.sorted {
            if $0 == "#" { return false }
            if $1 == "#" { return true }
            return $0 < $1
        }

        self.groupedIdioms = sortedKeys.map { key in
            let sorted = grouped[key]!.sorted { $0.pinyin < $1.pinyin }
            return (key: key, idioms: sorted)
        }
        
        // availableLetters 需要基于所有数据计算，而不是过滤后的数据
        let allGrouped = Dictionary(grouping: allIdioms, by: { $0.initial })
        self.availableLetters = allGrouped.keys.sorted {
            if $0 == "#" { return false }
            if $1 == "#" { return true }
            return $0 < $1
        }
    }
    
    // 供 UI 调用的字母切换方法
    func selectLetter(_ letter: String) {
        guard selectedLetter != letter else { return }
        selectedLetter = letter
        searchQuery = "" // 切换字母时清空搜索
        applyFilter()
    }

    var totalCount: Int { allIdioms.count }
    var filteredCount: Int { groupedIdioms.reduce(0) { $0 + $1.idioms.count } }
}

// MARK: - 主视图

struct IdiomDictionaryView: View {
    let onExit: () -> Void
    @StateObject private var viewModel = IdiomDictionaryViewModel()
    @State private var detailIdiom: DictionaryIdiom?
    @State private var bubbleLetter: String? = nil
    @FocusState private var searchFocused: Bool

    private let kind: GameKind = .idiomDictionary

    var body: some View {
        VStack(spacing: 0) {
            GameTopBar(
                title: kind.title,
                progressText: progressText,
                palette: kind.palette,
                onExit: onExit
            )

            searchBar
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 10)
                .padding(.bottom, 4)

            content
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear { viewModel.loadData() }
        .sheet(item: $detailIdiom) { idiom in
            IdiomDetailSheet(idiom: idiom, palette: kind.palette)
        }
        .overlay {
            if let letter = bubbleLetter {
                LetterBubble(letter: letter, color: kind.palette.0)
                    .transition(.scale.combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
    }

    private var progressText: String {
        if viewModel.isLoading { return "加载中..." }
        if viewModel.searchQuery.isEmpty { return "共 \(viewModel.totalCount) 个成语" }
        return "找到 \(viewModel.filteredCount) / \(viewModel.totalCount) 个"
    }

    // MARK: 搜索框

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
            TextField("搜成语 / 拼音 / 字", text: $viewModel.searchQuery)
                .focused($searchFocused)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.55))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.card, in: Capsule())
        .overlay(
            Capsule().strokeBorder(searchFocused ? kind.palette.0 : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.15), value: viewModel.searchQuery.isEmpty)
        .animation(.easeInOut(duration: 0.15), value: searchFocused)
    }

    // MARK: 内容区

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            VStack(spacing: 14) {
                ProgressView().controlSize(.large)
                Text("正在加载辞海...")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.groupedIdioms.isEmpty {
            emptyState
        } else {
            listWithIndex
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
            Text("没找到相关成语")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text("试试其他拼音首字母或汉字")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: 列表 + 字母索引（用 List 复用 UITableView 的 cell reuse，避免 3 万条爆内存）

    private var listWithIndex: some View {
        ZStack(alignment: .trailing) {
            List {
                ForEach(viewModel.groupedIdioms, id: \.key) { group in
                    // Section header
                    sectionHeader(letter: group.key, count: group.idioms.count)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(AppTheme.background)

                    ForEach(group.idioms) { idiom in
                        Button {
                            detailIdiom = idiom
                        } label: {
                            IdiomDictionaryCell(idiom: idiom)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(AppTheme.background)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in AppTheme.paddingScreen }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .padding(.trailing, 36)   // 给字母索引条留位

            if viewModel.availableLetters.count > 1 {
                AlphaIndexBar(
                    letters: viewModel.availableLetters,
                    selectedLetter: viewModel.searchQuery.isEmpty ? viewModel.selectedLetter : nil,
                    color: kind.palette.0,
                    onSelect: { letter in
                        viewModel.selectLetter(letter)
                        
                        bubbleLetter = letter
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            if bubbleLetter == letter { bubbleLetter = nil }
                        }
                    }
                )
                .padding(.trailing, 4)
            }
        }
    }

    private func sectionHeader(letter: String, count: Int) -> some View {
        HStack(spacing: 10) {
            Text(letter)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(
                    LinearGradient(
                        colors: [kind.palette.0, kind.palette.1],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
            Rectangle()
                .fill(kind.palette.0.opacity(0.15))
                .frame(height: 1)
            Text("\(count) 条")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.vertical, 8)
        .background(AppTheme.background)
        .id(letter)
    }
}

// MARK: - Cell（精简单行：成语 + 拼音 + 一行释义）

struct IdiomDictionaryCell: View {
    let idiom: DictionaryIdiom

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(idiom.word)
                        .font(.system(size: 19, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(idiom.pinyin)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.85))
                        .lineLimit(1)
                }
                if let exp = idiom.explanation, !exp.isEmpty {
                    Text(exp)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.35))
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .background(AppTheme.background)
    }
}

// MARK: - 字母索引条（拖动跟随 + 当前字母气泡）

struct AlphaIndexBar: View {
    let letters: [String]
    let selectedLetter: String?
    let color: Color
    let onSelect: (String) -> Void

    @State private var activeIndex: Int? = nil
    private let itemHeight: CGFloat = 18
    private let itemSpacing: CGFloat = 2
    private let itemWidth: CGFloat = 22

    private var unitHeight: CGFloat { itemHeight + itemSpacing }

    var body: some View {
        VStack(spacing: itemSpacing) {
            ForEach(Array(letters.enumerated()), id: \.element) { (idx, letter) in
                let isSelected = activeIndex != nil ? activeIndex == idx : letter == selectedLetter
                Text(letter)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(width: itemWidth, height: itemHeight)
                    .background {
                        if isSelected {
                            Circle().fill(color).frame(width: 22, height: 22)
                        }
                    }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(AppTheme.card.opacity(0.9), in: Capsule())
        .overlay(
            Capsule().strokeBorder(color.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: AppTheme.textPrimary.opacity(0.06), radius: 4, x: -1, y: 0)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let topPadding: CGFloat = 6
                    let y = value.location.y - topPadding
                    let i = max(0, min(letters.count - 1, Int(y / unitHeight)))
                    if activeIndex != i {
                        activeIndex = i
                        let letter = letters[i]
                        onSelect(letter)
                    }
                }
                .onEnded { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        activeIndex = nil
                    }
                }
        )
    }
}

// MARK: - 字母大气泡（拖动时居中显示）

struct LetterBubble: View {
    let letter: String
    let color: Color

    var body: some View {
        Text(letter)
            .font(.system(size: 60, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 120, height: 120)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.78)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .shadow(color: color.opacity(0.35), radius: 16, y: 6)
    }
}

// MARK: - 详情卡片（点击 Cell 弹出）

struct IdiomDetailSheet: View {
    let idiom: DictionaryIdiom
    let palette: (Color, Color)
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                    }
                }

                VStack(spacing: 8) {
                    Text(idiom.word)
                        .font(.system(size: 40, weight: .heavy, design: .serif))
                        .foregroundStyle(palette.0)
                        .multilineTextAlignment(.center)
                    Text(idiom.pinyin)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)

                if let exp = idiom.explanation, !exp.isEmpty {
                    sectionCard(title: "释义", content: exp, icon: "book.closed.fill", primary: true)
                }
                if let dev = idiom.derivation, !dev.isEmpty, dev != "无" {
                    sectionCard(title: "出处", content: dev, icon: "scroll.fill", primary: false)
                }
                if let ex = idiom.example, !ex.isEmpty, ex != "无" {
                    sectionCard(title: "例句", content: ex, icon: "quote.opening", primary: false)
                }
                Spacer(minLength: 24)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func sectionCard(title: String, content: String, icon: String, primary: Bool) -> some View {
        let tint = primary ? palette.0 : palette.1
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Text(content)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(5)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }
}
