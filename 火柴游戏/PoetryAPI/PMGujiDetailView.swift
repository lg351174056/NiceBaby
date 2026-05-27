import SwiftUI

struct PMGujiChapterListView: View {
    let gujiId: String
    let gujiName: String

    @State private var book: PMGujiBook?
    @State private var chapters: [PMGujiChapter] = []
    @State private var isLoading = true
    @State private var appearAnimation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            if isLoading {
                VStack {
                    Spacer(minLength: 100)
                    ProgressView()
                        .controlSize(.large)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                VStack(spacing: 16) {
                    if let book {
                        bookHeader(book)
                    }

                    ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                        NavigationLink(destination: PMGujiContentView(chapterId: chapter.id, chapterName: chapter.name)) {
                            ChapterRow(chapter: chapter, index: index)
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(x: appearAnimation ? 0 : 20)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.8).delay(Double(min(index, 12)) * 0.04),
                                    value: appearAnimation
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(gujiName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await loadChapters()
            withAnimation(.easeOut(duration: 0.5)) {
                appearAnimation = true
            }
        }
    }

    private func bookHeader(_ book: PMGujiBook) -> some View {
        let cleanContent = book.content
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.55, green: 0.27, blue: 0.07), Color(red: 0.8, green: 0.5, blue: 0.2)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.name)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(book.poetName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                HStack(spacing: 12) {
                    StatBadgeSmall(icon: "heart.fill", count: book.upCount)
                    StatBadgeSmall(icon: "eye.fill", count: book.viewCount)
                }
            }

            if !cleanContent.isEmpty {
                Text(cleanContent)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(5)
                    .lineLimit(4)
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }

    private func loadChapters() async {
        isLoading = true
        let result = try? await PoetryAPIService.shared.fetchGujiChapters(id: gujiId)
        book = result?.book
        chapters = result?.chapters ?? []
        isLoading = false
    }
}

// MARK: - Chapter Row

private struct ChapterRow: View {
    let chapter: PMGujiChapter
    let index: Int

    private let accent = Color(red: 0.55, green: 0.27, blue: 0.07)

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)
                .background(accent.opacity(0.08), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(chapter.name)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                if !chapter.type.isEmpty || !chapter.genre.isEmpty {
                    HStack(spacing: 6) {
                        if !chapter.genre.isEmpty {
                            Text(chapter.genre)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        if !chapter.type.isEmpty {
                            Text(chapter.type)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }
}

// MARK: - Guji Content Detail View

struct PMGujiContentView: View {
    let chapterId: String
    let chapterName: String

    @State private var detail: PMGujiDetail?
    @State private var isLoading = true
    @State private var showContent = false
    @State private var selectedTab: GujiDetailTab = .original

    private let textDark = Color(red: 48/255, green: 42/255, blue: 36/255)
    private let textMid = Color(red: 110/255, green: 98/255, blue: 80/255)
    private let inkAccent = Color(red: 0.55, green: 0.27, blue: 0.07)

    enum GujiDetailTab: String, CaseIterable {
        case original = "原文"
        case fanyi = "译文"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if isLoading {
                VStack {
                    Spacer(minLength: 100)
                    ProgressView().controlSize(.large)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else if let detail {
                VStack(spacing: 16) {
                    gujiHeader(detail)
                    gujiTabSelector
                    gujiContentSection(detail)
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, AppTheme.paddingScreen)
            }
        }
        .background(
            Color(red: 0.98, green: 0.97, blue: 0.94).ignoresSafeArea()
        )
        .navigationTitle(chapterName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await loadDetail()
        }
    }

    private func gujiHeader(_ detail: PMGujiDetail) -> some View {
        VStack(spacing: 10) {
            Text(detail.name)
                .font(.system(size: 24, weight: .heavy, design: .serif))
                .foregroundStyle(textDark)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)

            HStack(spacing: 8) {
                Text(detail.poetName)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(inkAccent)
                if !detail.parentName.isEmpty {
                    Text("·")
                        .foregroundStyle(textMid)
                    Text(detail.parentName)
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundStyle(textMid)
                }
            }
            .opacity(showContent ? 1 : 0)
        }
        .padding(.top, 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showContent)
    }

    private var gujiTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(GujiDetailTab.allCases, id: \.self) { tab in
                let available = gujiTabAvailable(tab)
                Button {
                    if available {
                        withAnimation(.spring(response: 0.3)) { selectedTab = tab }
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: selectedTab == tab ? .heavy : .bold, design: .rounded))
                            .foregroundStyle(
                                selectedTab == tab ? inkAccent :
                                available ? AppTheme.textSecondary : AppTheme.textSecondary.opacity(0.4)
                            )
                        RoundedRectangle(cornerRadius: 2)
                            .fill(selectedTab == tab ? inkAccent : .clear)
                            .frame(height: 3).frame(width: 24)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .disabled(!available)
            }
        }
    }

    private func gujiContentSection(_ detail: PMGujiDetail) -> some View {
        let rawText: String = {
            switch selectedTab {
            case .original: return detail.content
            case .fanyi: return detail.abouts.fanyi?.content ?? ""
            }
        }()

        let cleanText = rawText
            .replacingOccurrences(of: "<br />", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>", with: "\n")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Text(cleanText)
            .font(.system(size: 16, weight: .regular, design: .serif))
            .foregroundStyle(textDark)
            .lineSpacing(10)
            .textSelection(.enabled)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.6))
                    .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
            )
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.4), value: showContent)
    }

    private func gujiTabAvailable(_ tab: GujiDetailTab) -> Bool {
        guard let detail else { return tab == .original }
        switch tab {
        case .original: return true
        case .fanyi: return detail.abouts.fanyi != nil
        }
    }

    private func loadDetail() async {
        isLoading = true
        detail = try? await PoetryAPIService.shared.fetchGujiDetail(id: chapterId)
        isLoading = false
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            showContent = true
        }
    }
}

// MARK: - Small Stat Badge

private struct StatBadgeSmall: View {
    let icon: String
    let count: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
            Text("\(count)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}
