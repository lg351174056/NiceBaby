import SwiftUI

// MARK: - 书野竹青配色（AI 作文）

fileprivate enum ZuowenStyle {
    static let bambooGreen = Color(red: 76/255, green: 175/255, blue: 125/255)
    static let bambooGreenLight = Color(red: 126/255, green: 211/255, blue: 160/255)
    static let inkGreen = Color(red: 61/255, green: 74/255, blue: 54/255)
    static let deepGreen = Color(red: 46/255, green: 125/255, blue: 91/255)
    static let sage = Color(red: 138/255, green: 154/255, blue: 122/255)
    static let strokeGreen = Color(red: 110/255, green: 140/255, blue: 90/255)
    static let chipText = Color(red: 74/255, green: 92/255, blue: 66/255)
    static let gold = Color(red: 176/255, green: 130/255, blue: 50/255)
    static let goldSoft = Color(red: 245/255, green: 200/255, blue: 107/255)
    static let iceBlue = Color(red: 190/255, green: 227/255, blue: 245/255)
    static let mint = Color(red: 220/255, green: 242/255, blue: 220/255)
    static let grass = Color(red: 207/255, green: 235/255, blue: 196/255)

    static let skyGradient = LinearGradient(
        colors: [iceBlue, mint, grass],
        startPoint: .top, endPoint: .bottom
    )
    static let greenGradient = LinearGradient(
        colors: [bambooGreenLight, bambooGreen],
        startPoint: .leading, endPoint: .trailing
    )
}

// MARK: - AI作文大全

enum AIZuowenNavTarget: Hashable { case home }

struct AIZuowenView: View {
    @State private var essays: [ZuowenEssay] = []
    @State private var isLoading = false
    @State private var page = 1
    @State private var hasMore = true
    @State private var showFilter = false
    @State private var selectedEssay: ZuowenEssay?

    // 筛选状态
    @State private var section: ZuowenSection = .xiaoxue
    @State private var gradeOrCategory = "一年级"
    @State private var selectedType = ""
    @State private var selectedCount = ""

    private let essayEmojis = ["🌻", "🎠", "🥟", "🐘", "🖌", "🚀", "🎣", "⛺️", "🦋", "🌱", "📚", "🍂"]

    var body: some View {
        ZStack {
            ZuowenStyle.skyGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text("AI作文大全")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(ZuowenStyle.inkGreen)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                // 整页滚动
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroCard
                        sectionCards
                        gradeChips
                        filterSummaryRow
                        sectionHeader
                        if essays.isEmpty && !isLoading {
                            emptyState
                        } else {
                            essayList
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: ZuowenEssay.self) { essay in
            ZuowenDetailView(essay: essay)
        }
        .sheet(isPresented: $showFilter) {
            ZuowenFilterSheet(
                section: section,
                gradeOrCategory: $gradeOrCategory,
                selectedType: $selectedType,
                selectedCount: $selectedCount,
                onApply: { refresh() }
            )
            .presentationDetents([.medium])
        }
        .onAppear { if essays.isEmpty { loadMore() } }
    }

    // MARK: - 头部

    private var heroCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(red: 227/255, green: 242/255, blue: 234/255), Color(red: 189/255, green: 232/255, blue: 211/255)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(ZuowenStyle.bambooGreen.opacity(0.4), lineWidth: 2)
                    )
                Text("✍️")
                    .font(.system(size: 24))
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text("AI作文大全")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(ZuowenStyle.inkGreen)
                Text("海量范文 · 名师精选 · 一键朗读")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ZuowenStyle.sage)
                    .padding(.top, 2)
                HStack(spacing: 10) {
                    Text("📚 5000+ 篇")
                        .font(.system(size: 9.5, weight: .heavy))
                        .foregroundStyle(ZuowenStyle.bambooGreen)
                    Text("🤖 AI 精选")
                        .font(.system(size: 9.5, weight: .heavy))
                        .foregroundStyle(ZuowenStyle.gold)
                }
                .padding(.top, 3)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(ZuowenStyle.bambooGreen.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.12), radius: 14, y: 5)
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }

    // MARK: - 三段切换卡

    private var sectionCards: some View {
        HStack(spacing: 10) {
            ForEach(ZuowenSection.allCases, id: \.self) { s in
                sectionCard(s)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private func sectionCard(_ s: ZuowenSection) -> some View {
        let meta = sectionMeta(s)
        let isOn = section == s
        return Button {
            section = s
            gradeOrCategory = s.defaultGrade
            selectedType = ""
            selectedCount = ""
            refresh()
        } label: {
            VStack(spacing: 4) {
                Text(meta.icon)
                    .font(.system(size: 22))
                Text(s.label)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(isOn ? ZuowenStyle.deepGreen : ZuowenStyle.inkGreen)
                Text(meta.sub)
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundStyle(ZuowenStyle.sage)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isOn
                          ? LinearGradient(colors: [Color(red: 238/255, green: 247/255, blue: 238/255), Color(red: 223/255, green: 242/255, blue: 228/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [Color.white.opacity(0.88)], startPoint: .top, endPoint: .bottom))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(isOn ? ZuowenStyle.bambooGreen : ZuowenStyle.strokeGreen.opacity(0.25), lineWidth: 2)
                    )
            )
            .shadow(color: isOn ? ZuowenStyle.bambooGreen.opacity(0.15) : .clear, radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func sectionMeta(_ s: ZuowenSection) -> (icon: String, sub: String) {
        switch s {
        case .xiaoxue: return ("🎒", "1 ~ 6 年级")
        case .chuzhong: return ("📕", "7 ~ 9 年级")
        case .gaozhong: return ("📗", "高一 ~ 高三")
        }
    }

    // MARK: - 年级 chips + 筛选按钮

    private var gradeChips: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(section.grades, id: \.self) { g in
                        chip(g, isOn: gradeOrCategory == g) {
                            gradeOrCategory = g
                            refresh()
                        }
                    }
                }
                .padding(.horizontal, 18)
            }

            Button { showFilter = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 11, weight: .heavy))
                    Text("筛选")
                        .font(.system(size: 11.5, weight: .heavy))
                }
                .foregroundStyle(ZuowenStyle.gold)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.85), in: Capsule())
                .overlay(Capsule().strokeBorder(ZuowenStyle.gold.opacity(0.45), lineWidth: 2))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 18)
        }
        .padding(.top, 12)
    }

    private func chip(_ text: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 11.5, weight: .heavy))
                .foregroundStyle(isOn ? .white : ZuowenStyle.chipText)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isOn ? ZuowenStyle.bambooGreen : Color.white.opacity(0.85), in: Capsule())
                .overlay(Capsule().strokeBorder(isOn ? ZuowenStyle.inkGreen.opacity(0.6) : ZuowenStyle.strokeGreen.opacity(0.35), lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 已选条件

    private var filterSummaryRow: some View {
        HStack(spacing: 8) {
            Text("已选：\(filterSummary)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(ZuowenStyle.sage)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.7), in: Capsule())
                .overlay(Capsule().strokeBorder(ZuowenStyle.strokeGreen.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
            Spacer()
            Button {
                gradeOrCategory = ""
                selectedType = ""
                selectedCount = ""
                refresh()
            } label: {
                Text("✕ 清空")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(ZuowenStyle.bambooGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.85), in: Capsule())
                    .overlay(Capsule().strokeBorder(ZuowenStyle.bambooGreen.opacity(0.35), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }

    private var filterSummary: String {
        var parts = [gradeOrCategory.isEmpty ? "全部" : gradeOrCategory]
        if !selectedType.isEmpty { parts.append(selectedType) }
        if !selectedCount.isEmpty { parts.append(selectedCount) }
        return parts.joined(separator: " · ")
    }

    // MARK: - 分区标题

    private var sectionHeader: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(ZuowenStyle.bambooGreen)
                .frame(width: 6, height: 20)
            Text("精选范文")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(ZuowenStyle.inkGreen)
            Spacer()
            Text("按热度排序 · \(essays.count) 篇")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(ZuowenStyle.sage)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    // MARK: - 列表

    private var essayList: some View {
        LazyVStack(spacing: 10) {
            ForEach(essays) { essay in
                NavigationLink(value: essay) {
                    essayRow(essay, emoji: essayEmojis[stableIndex(essay) % essayEmojis.count])
                }
                .buttonStyle(.plain)
                .onAppear {
                    if essay.id == essays.last?.id { loadMore() }
                }
            }
            if isLoading {
                ProgressView()
                    .tint(ZuowenStyle.bambooGreen)
                    .padding(.vertical, 16)
            } else if !hasMore {
                Text("— 已加载全部 · 共计 5000+ 篇 —")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
                    .padding(.vertical, 12)
            } else {
                Button { loadMore() } label: {
                    Text("加载更多")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(ZuowenStyle.greenGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(ZuowenStyle.inkGreen, lineWidth: 2)
                        )
                        .shadow(color: ZuowenStyle.bambooGreen.opacity(0.35), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)
                .padding(.top, 6)
            }
        }
        .padding(.horizontal, 18)
    }

    private func essayRow(_ essay: ZuowenEssay, emoji: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 234/255, green: 246/255, blue: 228/255))
                    .overlay(Circle().strokeBorder(ZuowenStyle.strokeGreen.opacity(0.3), lineWidth: 2))
                Text(emoji)
                    .font(.system(size: 17))
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text(essay.title)
                        .font(.system(size: 14, weight: .heavy, design: .serif))
                        .foregroundStyle(ZuowenStyle.inkGreen)
                        .lineLimit(1)
                    Spacer()
                    if !essay.count.isEmpty {
                        Text(essay.count)
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(ZuowenStyle.gold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(ZuowenStyle.goldSoft.opacity(0.25), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(ZuowenStyle.gold.opacity(0.35), lineWidth: 1))
                    }
                }
                Text(essay.cttip)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ZuowenStyle.sage)
                    .lineLimit(2)
                    .lineSpacing(2)
                    .padding(.top, 3)
                HStack(spacing: 6) {
                    if !essay.grade.isEmpty { miniTag(essay.grade) }
                    if !essay.type.isEmpty { miniTag(essay.type) }
                }
                .padding(.top, 5)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(red: 160/255, green: 176/255, blue: 152/255))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(ZuowenStyle.strokeGreen.opacity(0.25), lineWidth: 2))
        )
    }

    private func stableIndex(_ essay: ZuowenEssay) -> Int {
        abs(essay.id.hashValue)
    }

    private func miniTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .heavy))
            .foregroundStyle(ZuowenStyle.bambooGreen)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(ZuowenStyle.bambooGreen.opacity(0.1), in: Capsule())
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("📝")
                .font(.system(size: 40))
            Text("暂无结果，换个条件试试")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(ZuowenStyle.sage)
        }
        .padding(.top, 80)
    }

    // MARK: - Network

    private func refresh() {
        essays = []
        page = 1
        hasMore = true
        loadMore()
    }

    private func loadMore() {
        guard !isLoading, hasMore else { return }
        isLoading = true
        Task {
            let result = await ZuowenAPI.fetchList(
                section: section,
                gradeOrCategory: gradeOrCategory,
                type: selectedType,
                count: selectedCount,
                page: page
            )
            await MainActor.run {
                isLoading = false
                if result.isEmpty {
                    hasMore = false
                } else {
                    essays.append(contentsOf: result)
                    page += 1
                }
            }
        }
    }
}

// MARK: - 详情页（作文本方格纸）

struct ZuowenDetailView: View {
    let essay: ZuowenEssay

    private let paperLine = Color(red: 201/255, green: 100/255, blue: 66/255).opacity(0.35)
    private let paperInk = Color(red: 61/255, green: 58/255, blue: 48/255)
    private let paperBg = Color(red: 251/255, green: 248/255, blue: 238/255)

    private let cols = 13
    private var cellSize: CGFloat { (UIScreen.main.bounds.width - 36 - 24) / CGFloat(cols) }

    var body: some View {
        ZStack {
            ZuowenStyle.skyGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    // 方格纸
                    let rows = buildRows(cols: cols)
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                            HStack(spacing: 0) {
                                ForEach(0..<cols, id: \.self) { col in
                                    let ch: Character? = col < row.count ? row[col] : nil
                                    ZStack {
                                        Rectangle()
                                            .stroke(paperLine, lineWidth: 0.6)
                                        if let ch, ch != "　" {
                                            Text(String(ch))
                                                .font(.system(size: cellSize * 0.6, weight: .medium, design: .serif))
                                                .foregroundStyle(paperInk)
                                        }
                                    }
                                    .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(paperBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(ZuowenStyle.strokeGreen.opacity(0.4), lineWidth: 1.5)
                            )
                    )
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            HStack {
                GracefulBackButton()
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
        }
    }


    /// 构建格子行：标题居中一行 + 正文按段换行、段首缩进两格
    private func buildRows(cols: Int) -> [[Character]] {
        var result: [[Character]] = []

        // 标题行：居中
        let titleChars = Array(essay.title)
        let titlePad = max(0, (cols - titleChars.count) / 2)
        var titleRow: [Character] = Array(repeating: "　", count: titlePad)
        titleRow.append(contentsOf: titleChars.prefix(cols - titlePad))
        result.append(titleRow)

        // 标题和正文之间空一行
        result.append([])

        // 清理 content：去掉开头的「《标题》\n年级 | 体裁 | 字数\n」
        var content = essay.content
        // 去掉 《标题》\n 或 标题\n
        if content.hasPrefix("《\(essay.title)》") {
            content = String(content.dropFirst(essay.title.count + 2))
        } else if content.hasPrefix(essay.title) {
            content = String(content.dropFirst(essay.title.count))
        }
        // 去掉紧随的换行
        while content.hasPrefix("\n") || content.hasPrefix("\r") {
            content = String(content.dropFirst())
        }
        // 去掉第二行的 "年级 | 体裁 | 字数"
        if let firstNewline = content.firstIndex(where: { $0 == "\n" || $0 == "\r" }) {
            let firstLine = String(content[content.startIndex..<firstNewline])
            if firstLine.contains("|") {
                content = String(content[content.index(after: firstNewline)...])
            }
        }
        // 去掉末尾多余换行
        while content.hasSuffix("\n") || content.hasSuffix("\r") {
            content = String(content.dropLast())
        }

        // 按段落分割
        let paragraphs = content.components(separatedBy: CharacterSet.newlines).filter { !$0.isEmpty }

        for para in paragraphs {
            var row: [Character] = []
            // 去掉段首已有的全角空格，统一加两格缩进
            let trimmed = para.drop { $0 == "　" || $0 == "\t" || $0 == " " }
            row.append("　")
            row.append("　")

            for ch in trimmed {
                row.append(ch)
                if row.count == cols {
                    result.append(row)
                    row = []
                }
            }
            // 段末不满一行也要追加（左对齐）
            if !row.isEmpty { result.append(row) }
        }

        return result
    }
}

// MARK: - 筛选弹框（书野竹青）

private struct ZuowenFilterSheet: View {
    let section: ZuowenSection
    @Binding var gradeOrCategory: String
    @Binding var selectedType: String
    @Binding var selectedCount: String
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Text("筛选条件")
                    .font(.system(size: 18, weight: .heavy, design: .serif))
                    .foregroundStyle(ZuowenStyle.inkGreen)
                Spacer()
            }
            .overlay(alignment: .trailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(ZuowenStyle.sage)
                        .frame(width: 28, height: 28)
                        .background(ZuowenStyle.strokeGreen.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
            }

            // 年级/分类
            filterSection(title: section.gradeLabel, options: [""] + section.grades, selected: $gradeOrCategory, allLabel: "全部")

            // 体裁
            if !section.types.isEmpty {
                filterSection(title: "体裁", options: [""] + section.types, selected: $selectedType, allLabel: "全部")
            }

            // 字数
            if section == .xiaoxue {
                filterSection(title: "字数", options: ["", "100字", "200字", "300字", "400字", "500字", "600字", "800字"], selected: $selectedCount, allLabel: "不限")
            }

            Spacer()

            Button {
                dismiss()
                onApply()
            } label: {
                Text("确定")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(ZuowenStyle.greenGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(ZuowenStyle.inkGreen, lineWidth: 2)
                    )
                    .shadow(color: ZuowenStyle.bambooGreen.opacity(0.35), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .background(Color.white)
    }

    private func filterSection(title: String, options: [String], selected: Binding<String>, allLabel: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(ZuowenStyle.bambooGreen)
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { opt in
                    let label = opt.isEmpty ? (allLabel ?? "全部") : opt
                    let isOn = selected.wrappedValue == opt
                    Button {
                        selected.wrappedValue = opt
                    } label: {
                        Text(label)
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(isOn ? .white : ZuowenStyle.chipText)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 7)
                            .background(isOn ? ZuowenStyle.bambooGreen : Color(red: 241/255, green: 246/255, blue: 236/255), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(isOn ? ZuowenStyle.inkGreen : ZuowenStyle.strokeGreen.opacity(0.25), lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - FlowLayout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, offset) in result.offsets.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (offsets: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            offsets.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }
        return (offsets, CGSize(width: maxX, height: y + rowHeight))
    }
}

// MARK: - 数据模型

struct ZuowenEssay: Identifiable, Hashable {
    let id: String
    let grade: String
    let type: String
    let count: String
    let title: String
    let cttip: String
    let content: String
}

enum ZuowenSection: CaseIterable {
    case xiaoxue, chuzhong, gaozhong

    var label: String {
        switch self {
        case .xiaoxue: return "小学"
        case .chuzhong: return "初中"
        case .gaozhong: return "高中"
        }
    }

    var gradeLabel: String {
        switch self {
        case .xiaoxue: return "年级"
        case .chuzhong: return "年级"
        case .gaozhong: return "年级"
        }
    }

    var grades: [String] {
        switch self {
        case .xiaoxue: return ["一年级", "二年级", "三年级", "四年级", "五年级", "六年级", "小升初"]
        case .chuzhong: return ["初一", "初二", "初三", "中考作文"]
        case .gaozhong: return ["高一", "高二", "高三", "高考作文"]
        }
    }

    var defaultGrade: String { grades[0] }

    var types: [String] {
        switch self {
        case .xiaoxue: return ["叙事", "散文诗歌", "日记", "读后感", "想象", "写景", "状物", "书信", "写人", "话题", "议论文", "看图", "童话寓言", "演讲稿", "说明文", "满分作文"]
        case .chuzhong: return ["叙事", "散文诗歌", "日记", "读后感", "想象", "写景", "状物", "书信", "写人", "话题", "议论文", "说明文", "小说", "满分作文"]
        case .gaozhong: return ["叙事", "散文诗歌", "读后感", "想象", "写景", "写人", "话题", "议论文", "说明文", "小说", "满分作文"]
        }
    }

    /// API 参数 key
    var paramKey: String {
        switch self {
        case .xiaoxue: return "xx"
        case .chuzhong: return "cz"
        case .gaozhong: return "gz"
        }
    }
}

// MARK: - API

enum ZuowenAPI {
    private static let baseURL = "http://newos.glassmarket.cn/index.php?main_page=zuowen_handler"

    static func fetchList(section: ZuowenSection, gradeOrCategory: String, type: String, count: String, page: Int) async -> [ZuowenEssay] {
        var params: [String: String] = [
            "actiontype": "2",
            "appname": "AI作文大全",
            "bid": "zw",
            "channel": "zuowen",
            "page": "\(page)",
            "systemName": "iOS",
            "systemVersion": "18.0",
            "userid": "568426",
            "useridstr": "8f5af5773cc44a20bd6d6cbbf8da6ba4",
            "version": "2.2.1"
        ]
        if !gradeOrCategory.isEmpty { params[section.paramKey] = gradeOrCategory }
        if !type.isEmpty { params["lx"] = type }
        if !count.isEmpty { params["zs"] = count }

        return await post(params: params)
    }

    private static func post(params: [String: String]) async -> [ZuowenEssay] {
        guard let url = URL(string: baseURL) else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = params.map { k, v in
            "\(k)=\(v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? v)"
        }.joined(separator: "&").data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let resp = try JSONDecoder().decode(ZuowenResponse.self, from: data)
            guard resp.result == 1, let infos = resp.infos else { return [] }
            return infos.map {
                ZuowenEssay(
                    id: $0.id,
                    grade: $0.grade ?? "",
                    type: $0.type ?? "",
                    count: $0.count ?? "",
                    title: $0.title,
                    cttip: $0.cttip ?? "",
                    content: $0.content ?? ""
                )
            }
        } catch {
            return []
        }
    }

    private struct ZuowenResponse: Decodable {
        let result: Int
        let infos: [RawEssay]?
    }

    private struct RawEssay: Decodable {
        let id: String
        let grade: String?
        let type: String?
        let count: String?
        let title: String
        let cttip: String?
        let content: String?
    }
}
