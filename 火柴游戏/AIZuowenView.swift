import SwiftUI

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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 190/255, green: 227/255, blue: 245/255),
                    Color(red: 220/255, green: 242/255, blue: 220/255),
                    Color(red: 207/255, green: 235/255, blue: 196/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 导航
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text("AI作文大全")
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                // 顶部：段位切换 + 当前筛选 + 筛选按钮
                VStack(spacing: 8) {
                    // 小学/初中/高中 段位
                    HStack(spacing: 6) {
                        ForEach(ZuowenSection.allCases, id: \.self) { s in
                            sectionChip(s)
                        }
                        Spacer()
                        Button { showFilter = true } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease")
                                    .font(.system(size: 11, weight: .heavy))
                                Text("筛选")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                            }
                            .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.9), in: Capsule())
                            .overlay(Capsule().strokeBorder(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.4), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 18)

                    // 当前筛选提示
                    HStack(spacing: 6) {
                        Text(filterSummary)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 8)

                // 列表
                if essays.isEmpty && !isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("📝")
                            .font(.system(size: 40))
                        Text("暂无结果，换个条件试试")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(essays) { essay in
                                NavigationLink(value: essay) {
                                    essayRow(essay)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    if essay.id == essays.last?.id { loadMore() }
                                }
                            }
                            if isLoading {
                                ProgressView()
                                    .tint(Color(red: 76/255, green: 175/255, blue: 125/255))
                                    .padding(.vertical, 16)
                            }
                            if !hasMore && !essays.isEmpty {
                                Text("— 已加载全部 —")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                                    .padding(.vertical, 12)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: ZuowenEssay.self) { essay in
            ZuowenDetailView(essay: essay)
        }
        .sheet(isPresented: $showFilter) {
            ZuowenFilterSheet(
                section: $section,
                gradeOrCategory: $gradeOrCategory,
                selectedType: $selectedType,
                selectedCount: $selectedCount,
                onApply: { refresh() }
            )
            .presentationDetents([.medium])
        }
        .onAppear { if essays.isEmpty { loadMore() } }
    }

    private var filterSummary: String {
        var parts = [gradeOrCategory]
        if !selectedType.isEmpty { parts.append(selectedType) }
        if !selectedCount.isEmpty { parts.append(selectedCount) }
        return parts.joined(separator: " · ")
    }

    private func sectionChip(_ s: ZuowenSection) -> some View {
        Button {
            section = s
            gradeOrCategory = s.defaultGrade
            selectedType = ""
            selectedCount = ""
            refresh()
        } label: {
            Text(s.label)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(section == s ? .white : Color(red: 76/255, green: 175/255, blue: 125/255))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(section == s ? Color(red: 76/255, green: 175/255, blue: 125/255) : Color.white.opacity(0.8), in: Capsule())
                .overlay(Capsule().strokeBorder(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func essayRow(_ essay: ZuowenEssay) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(essay.title)
                    .font(.system(size: 14, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .lineLimit(1)
                Spacer()
                Text(essay.count)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }
            Text(essay.cttip)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 100/255, green: 110/255, blue: 90/255))
                .lineLimit(2)
            HStack(spacing: 6) {
                if !essay.grade.isEmpty { tag(essay.grade) }
                if !essay.type.isEmpty { tag(essay.type) }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.25), lineWidth: 1.5))
        )
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.1), in: Capsule())
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

// MARK: - 详情页（二级页）

struct ZuowenDetailView: View {
    let essay: ZuowenEssay

    var body: some View {
        ZStack {
            Color(red: 247/255, green: 245/255, blue: 240/255).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(essay.title)
                        .font(.system(size: 22, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))

                    HStack(spacing: 8) {
                        if !essay.grade.isEmpty { Text(essay.grade) }
                        if !essay.type.isEmpty { Text("·"); Text(essay.type) }
                        if !essay.count.isEmpty { Text("·"); Text(essay.count) }
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))

                    Rectangle()
                        .fill(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.2))
                        .frame(height: 1)

                    Text(essay.content)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                        .lineSpacing(8)
                }
                .padding(22)
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            ZStack {
                HStack {
                    GracefulBackButton()
                    Spacer()
                }
                Text("作文详情")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Color(red: 247/255, green: 245/255, blue: 240/255))
        }
    }
}

// MARK: - 筛选弹框

private struct ZuowenFilterSheet: View {
    @Binding var section: ZuowenSection
    @Binding var gradeOrCategory: String
    @Binding var selectedType: String
    @Binding var selectedCount: String
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("筛选条件")
                    .font(.system(size: 18, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                        .frame(width: 30, height: 30)
                        .background(Color(red: 240/255, green: 238/255, blue: 232/255), in: Circle())
                }
                .buttonStyle(.plain)
            }

            // 年级/分类
            filterSection(title: section.gradeLabel, options: section.grades, selected: $gradeOrCategory)

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
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 76/255, green: 175/255, blue: 125/255), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(22)
    }

    private func filterSection(title: String, options: [String], selected: Binding<String>, allLabel: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            FlowLayout(spacing: 6) {
                ForEach(options, id: \.self) { opt in
                    let label = opt.isEmpty ? (allLabel ?? "全部") : opt
                    let isOn = selected.wrappedValue == opt
                    Button {
                        selected.wrappedValue = opt
                    } label: {
                        Text(label)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(isOn ? .white : Color(red: 76/255, green: 175/255, blue: 125/255))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isOn ? Color(red: 76/255, green: 175/255, blue: 125/255) : Color(red: 240/255, green: 238/255, blue: 232/255), in: Capsule())
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
        params[section.paramKey] = gradeOrCategory
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
