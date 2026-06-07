import SwiftUI

// MARK: - 分类下问题列表

struct WhyCategoryListView: View {
    let category: WhyCategory

    @StateObject private var service = WhyAPIService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var questions: [WhyQuestion] = []
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var loadError: String?
    @State private var currentPage = 0
    @State private var totalPages = 1

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                header
                content
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .enableSwipeBack()
        .task { await loadFirstPage() }
    }

    // MARK: - 背景

    private var backgroundLayer: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.95).ignoresSafeArea()
            // 顶部色带
            LinearGradient(
                colors: [category.swiftUIColor.opacity(0.25), .clear],
                startPoint: .top, endPoint: .center
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - 顶部

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.85))
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("共 \(category.questionCount) 个小问题")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(category.swiftUIColor.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(category.swiftUIColor)
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color.white.opacity(0.5))
    }

    // MARK: - 内容

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 12) {
                Spacer()
                ProgressView().controlSize(.large)
                Text("正在加载问题…")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
        } else if let err = loadError, questions.isEmpty {
            errorView(err)
        } else if questions.isEmpty {
            errorView("该分类下暂无问题")
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(questions) { q in
                        NavigationLink(value: WhyQuestionRef(id: q.id, title: q.title)) {
                            WhyQuestionRow(question: q, accent: category.swiftUIColor)
                        }
                        .buttonStyle(WhyBounceButtonStyle())
                        .onAppear {
                            // 触底分页
                            if q.id == questions.last?.id, currentPage + 1 < totalPages, !isLoadingMore {
                                Task { await loadMore() }
                            }
                        }
                    }

                    if isLoadingMore {
                        ProgressView()
                            .padding(.vertical, 12)
                    } else if currentPage + 1 >= totalPages && !questions.isEmpty {
                        Text("已经到底啦～")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                            .padding(.vertical, 18)
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .refreshable { await reload() }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "questionmark.app.dashed")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.accentYellow)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            Button {
                Task { await loadFirstPage() }
            } label: {
                Text("重新加载")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(category.swiftUIColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    // MARK: - 网络

    private func loadFirstPage() async {
        isLoading = true
        loadError = nil
        currentPage = 0
        let page = await service.fetchQuestionsByCategory(categoryId: category.id, page: 0, size: 10)
        await MainActor.run {
            self.questions = page.content
            self.totalPages = max(1, page.totalPages)
            self.currentPage = page.number
            self.isLoading = false
            if page.content.isEmpty { self.loadError = "该分类下暂无问题" }
        }
    }

    private func reload() async {
        currentPage = 0
        let page = await service.fetchQuestionsByCategory(categoryId: category.id, page: 0, size: 10)
        await MainActor.run {
            self.questions = page.content
            self.totalPages = max(1, page.totalPages)
            self.currentPage = page.number
        }
    }

    private func loadMore() async {
        guard !isLoadingMore, currentPage + 1 < totalPages else { return }
        isLoadingMore = true
        let next = currentPage + 1
        let page = await service.fetchQuestionsByCategory(categoryId: category.id, page: next, size: 10)
        await MainActor.run {
            self.questions.append(contentsOf: page.content)
            self.currentPage = page.number
            self.totalPages = max(1, page.totalPages)
            self.isLoadingMore = false
        }
    }
}

// MARK: - 列表行

struct WhyQuestionRow: View {
    let question: WhyQuestion
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: "questionmark")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(question.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                if let preview = previewText(), !preview.isEmpty {
                    Text(preview)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let dt = question.difficultyText, !dt.isEmpty {
                        tagPill(text: dt, color: difficultyColor(question.difficultyLevel), icon: "chart.bar.fill")
                    }
                    if let age = question.ageRange, !age.isEmpty {
                        tagPill(text: age, color: AppTheme.accentSage, icon: "person.fill")
                    }
                    if question.viewCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 9))
                            Text("\(formatCount(question.viewCount))")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                .padding(.top, 6)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: accent.opacity(0.08), radius: 6, y: 3)
    }

    private func tagPill(text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }

    private func previewText() -> String? {
        if let a = question.answer, !a.isEmpty { return a }
        if let c = question.content, !c.isEmpty { return c }
        return nil
    }

    private func difficultyColor(_ level: String?) -> Color {
        switch level?.uppercased() {
        case "EASY": return AppTheme.accentMint
        case "MEDIUM": return AppTheme.accentYellow
        case "HARD": return AppTheme.accentTerracotta
        default: return AppTheme.accentBlue
        }
    }

    private func formatCount(_ n: Int) -> String {
        if n >= 10000 { return String(format: "%.1f万", Double(n) / 10000.0) }
        return "\(n)"
    }
}
