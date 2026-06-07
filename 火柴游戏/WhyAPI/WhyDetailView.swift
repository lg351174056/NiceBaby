import SwiftUI

// MARK: - 问题详情

struct WhyDetailView: View {
    let questionId: Int
    let initialTitle: String

    @StateObject private var service = WhyAPIService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var question: WhyQuestion?
    @State private var related: [WhyQuestion] = []
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var didFavorite = false

    private static let favoriteKey = "why_favorite_ids"

    var body: some View {
        ZStack {
            backgroundLayer

            if isLoading {
                loadingView
            } else if let q = question {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        heroCard(q)
                        if let answer = nonEmpty(q.answer) {
                            answerCard(title: "答案", content: answer, accent: categoryColor(q))
                        }
                        if let content = nonEmpty(q.content) {
                            answerCard(title: "小提示", content: content, accent: AppTheme.accentSage, icon: "lightbulb.fill")
                        }
                        if !q.tagList.isEmpty {
                            tagsCard(q)
                        }
                        if !related.isEmpty {
                            relatedCard
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, AppTheme.paddingScreen)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .safeAreaInset(edge: .top) {
                    topBar
                }
            } else if let err = loadError {
                errorView(err)
            } else {
                errorView("未找到该问题")
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden()
        .enableSwipeBack()
        .task { await load() }
    }

    // MARK: - 背景

    private var backgroundLayer: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.95).ignoresSafeArea()
            if let q = question {
                LinearGradient(
                    colors: [categoryColor(q).opacity(0.18), .clear],
                    startPoint: .top, endPoint: .center
                )
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - 顶部

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.4))
                        .background(.ultraThinMaterial, in: Circle())
                        .frame(width: 40, height: 40)
                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }

            Spacer()

            if question != nil {
                Button {
                    toggleFavorite()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.4))
                            .background(.ultraThinMaterial, in: Circle())
                            .frame(width: 40, height: 40)
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                        Image(systemName: didFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(didFavorite ? AppTheme.accentTerracotta : AppTheme.textPrimary)
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.vertical, 8)
    }

    // MARK: - 状态视图

    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView().controlSize(.large)
            Text("正在加载详情…")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.accentYellow)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            Button {
                Task { await load() }
            } label: {
                Text("重新加载")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(AppTheme.accentBlue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    // MARK: - 内容卡

    private func heroCard(_ q: WhyQuestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                if let cat = q.category {
                    HStack(spacing: 4) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 11))
                        Text(cat.name)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(categoryColor(q).opacity(0.15))
                    .foregroundStyle(categoryColor(q))
                    .clipShape(Capsule())
                }
                Spacer()
                if let dt = q.difficultyText {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 10))
                        Text(dt)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(difficultyColor(q.difficultyLevel).opacity(0.15))
                    .foregroundStyle(difficultyColor(q.difficultyLevel))
                    .clipShape(Capsule())
                }
            }

            Text(q.title)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                if let age = nonEmpty(q.ageRange) {
                    metaItem(icon: "person.fill", text: age, color: AppTheme.accentSage)
                }
                if q.viewCount > 0 {
                    metaItem(icon: "eye.fill", text: "\(q.viewCount) 次浏览", color: AppTheme.accentBlue)
                }
                if q.recommended {
                    metaItem(icon: "star.fill", text: "精选", color: AppTheme.accentYellow)
                }
                Spacer()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: categoryColor(q).opacity(0.12), radius: 15, y: 8)
    }

    private func answerCard(title: String, content: String, accent: Color, icon: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accent)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accent)
                }
                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(accent)
            }
            Text(content)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(8)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(accent.opacity(0.15), lineWidth: 1.5)
        )
    }

    private func tagsCard(_ q: WhyQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "number")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.accentPurple)
                Text("关键词")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.accentPurple)
            }
            WhyFlowLayout(spacing: 10) {
                ForEach(q.tagList, id: \.self) { tag in
                    Text("# \(tag)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.accentPurple.opacity(0.1))
                        .foregroundStyle(AppTheme.accentPurple)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var relatedCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.accentBlue)
                Text("相关问题")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.accentBlue)
                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(related) { q in
                    NavigationLink(value: WhyQuestionRef(id: q.id, title: q.title)) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.accentBlue)
                                .padding(.top, 4)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(q.title)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(2)
                                if let preview = nonEmpty(q.answer) {
                                    Text(preview)
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                        .lineLimit(2)
                                        .lineSpacing(4)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                                .padding(.top, 4)
                        }
                        .padding(16)
                        .background(AppTheme.accentBlue.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func metaItem(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(color)
    }

    // MARK: - 网络

    private func load() async {
        isLoading = true
        loadError = nil
        async let detailTask = service.fetchQuestionDetail(id: questionId)
        async let relatedTask = service.fetchRelatedQuestions(id: questionId, limit: 3)
        let (d, r) = await (detailTask, relatedTask)
        await MainActor.run {
            self.question = d
            self.related = r
            self.isLoading = false
            if d == nil { self.loadError = "未能加载到该问题" }
            self.didFavorite = isFavorite(questionId)
        }
    }

    private func categoryColor(_ q: WhyQuestion) -> Color {
        q.category?.swiftUIColor ?? AppTheme.accentBlue
    }

    private func difficultyColor(_ level: String?) -> Color {
        switch level?.uppercased() {
        case "EASY": return AppTheme.accentMint
        case "MEDIUM": return AppTheme.accentYellow
        case "HARD": return AppTheme.accentTerracotta
        default: return AppTheme.accentBlue
        }
    }

    private func nonEmpty(_ s: String?) -> String? {
        guard let s = s else { return nil }
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    // MARK: - 收藏（本地）

    private func isFavorite(_ id: Int) -> Bool {
        let arr = UserDefaults.standard.array(forKey: Self.favoriteKey) as? [Int] ?? []
        return arr.contains(id)
    }

    private func toggleFavorite() {
        var arr = UserDefaults.standard.array(forKey: Self.favoriteKey) as? [Int] ?? []
        if arr.contains(questionId) {
            arr.removeAll { $0 == questionId }
            didFavorite = false
        } else {
            arr.append(questionId)
            didFavorite = true
        }
        UserDefaults.standard.set(arr, forKey: Self.favoriteKey)
    }
}

// MARK: - 简单流式布局（标签换行）

struct WhyFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth {
                totalWidth = max(totalWidth, rowWidth - spacing)
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalWidth = max(totalWidth, rowWidth - spacing)
        totalHeight += rowHeight
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
