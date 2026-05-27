import SwiftUI

struct PMPoetryDetailView: View {
    let poetryId: String
    let initialName: String

    @State private var detail: PMPoetryDetail?
    @State private var isLoading = true
    @State private var showContent = false
    @State private var selectedTab: DetailTab = .original
    @Environment(\.dismiss) private var dismiss

    private let textDark = Color(red: 48/255, green: 42/255, blue: 36/255)
    private let textMid = Color(red: 110/255, green: 98/255, blue: 80/255)
    private let inkAccent = Color(red: 160/255, green: 82/255, blue: 45/255)

    enum DetailTab: String, CaseIterable {
        case original = "原文"
        case yizhu = "译注"
        case shangxi = "赏析"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if isLoading {
                VStack(spacing: 16) {
                    Spacer(minLength: 100)
                    ProgressView()
                        .controlSize(.large)
                    Text("加载中...")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else if let detail {
                VStack(spacing: 0) {
                    headerSection(detail)
                    tabSelector
                    contentSection(detail)
                    if let poet = detail.poet {
                        poetSection(poet)
                    }
                    Spacer(minLength: 60)
                }
            }
        }
        .background(
            ZStack {
                Color(red: 0.98, green: 0.97, blue: 0.94)
                LinearGradient(
                    colors: [inkAccent.opacity(0.03), .clear],
                    startPoint: .top, endPoint: .center
                )
            }
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(initialName)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(textDark)
            }
        }
        .task {
            await loadDetail()
        }
    }

    // MARK: - Header

    private func headerSection(_ detail: PMPoetryDetail) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 20)

            HStack(spacing: 8) {
                ForEach(detail.tags.prefix(4)) { tag in
                    Text(tag.name)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(inkAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(inkAccent.opacity(0.08), in: Capsule())
                }
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 10)

            Text(detail.name)
                .font(.system(size: 28, weight: .heavy, design: .serif))
                .foregroundStyle(textDark)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)

            HStack(spacing: 12) {
                Text("[\(detail.dynasty)]")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(textMid)
                Text(detail.poetName)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(inkAccent)
            }
            .opacity(showContent ? 1 : 0)

            HStack(spacing: 20) {
                StatBadge(icon: "heart.fill", count: detail.upCount, color: .red.opacity(0.6))
                StatBadge(icon: "eye.fill", count: detail.viewCount, color: AppTheme.accentBlue.opacity(0.7))
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 10)

            decorativeDivider
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showContent)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                let isAvailable = tabAvailable(tab)
                Button {
                    if isAvailable {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: selectedTab == tab ? .heavy : .bold, design: .rounded))
                            .foregroundStyle(
                                selectedTab == tab ? inkAccent :
                                isAvailable ? AppTheme.textSecondary : AppTheme.textSecondary.opacity(0.4)
                            )

                        RoundedRectangle(cornerRadius: 2)
                            .fill(selectedTab == tab ? inkAccent : .clear)
                            .frame(height: 3)
                            .frame(width: 24)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .disabled(!isAvailable)
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 8)
    }

    // MARK: - Content Section

    @ViewBuilder
    private func contentSection(_ detail: PMPoetryDetail) -> some View {
        VStack(spacing: 0) {
            switch selectedTab {
            case .original:
                originalContent(detail.content)
            case .yizhu:
                if let yizhu = detail.abouts.yizhu {
                    annotationContent(yizhu)
                }
            case .shangxi:
                if let shangxi = detail.abouts.shangxi {
                    annotationContent(shangxi)
                }
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 20)
    }

    private func originalContent(_ htmlContent: String) -> some View {
        let cleanText = htmlContent
            .replacingOccurrences(of: "<br />", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>", with: "\n")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let lines = cleanText.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return VStack(spacing: 14) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                Text(line)
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundStyle(textDark)
                    .lineSpacing(8)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 15)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.04),
                        value: showContent
                    )
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.6))
                .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
        )
    }

    private func annotationContent(_ item: PMAboutItem) -> some View {
        let cleanText = item.content
            .replacingOccurrences(of: "<br />", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>", with: "\n")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(inkAccent)
                Spacer()
                if !item.author.isEmpty {
                    Text(item.author)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(textMid)
                }
            }

            Text(cleanText)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundStyle(textDark.opacity(0.9))
                .lineSpacing(8)
                .textSelection(.enabled)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.6))
                .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
        )
    }

    // MARK: - Poet Section

    private func poetSection(_ poet: PMPoetInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(inkAccent.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(poet.name.prefix(1)))
                            .font(.system(size: 16, weight: .heavy, design: .serif))
                            .foregroundStyle(inkAccent)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(poet.name)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundStyle(textDark)
                    Text(poet.dynasty)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(textMid)
                }
            }

            let cleanBio = poet.content
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            Text(cleanBio)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .foregroundStyle(textMid)
                .lineSpacing(6)
                .lineLimit(5)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(inkAccent.opacity(0.04))
        )
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 24)
    }

    // MARK: - Helpers

    private var decorativeDivider: some View {
        HStack(spacing: 10) {
            Rectangle().fill(inkAccent.opacity(0.15)).frame(width: 30, height: 1)
            Circle().fill(inkAccent.opacity(0.3)).frame(width: 4, height: 4)
            Rectangle().fill(inkAccent.opacity(0.15)).frame(width: 30, height: 1)
        }
        .padding(.top, 12)
    }

    private func tabAvailable(_ tab: DetailTab) -> Bool {
        guard let detail else { return tab == .original }
        switch tab {
        case .original: return true
        case .yizhu: return detail.abouts.yizhu != nil
        case .shangxi: return detail.abouts.shangxi != nil
        }
    }

    private func loadDetail() async {
        isLoading = true
        detail = try? await PoetryAPIService.shared.fetchPoetryDetail(id: poetryId)
        isLoading = false
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            showContent = true
        }
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let icon: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text("\(count)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}
