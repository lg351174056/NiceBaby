import SwiftUI

struct PMGujiListView: View {
    @State private var gujiList: [PMGuji] = []
    @State private var currentPage = 1
    @State private var isLoading = false
    @State private var hasMorePages = true
    @State private var appearAnimation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                ForEach(Array(gujiList.enumerated()), id: \.element.id) { index, guji in
                    NavigationLink(destination: PMGujiChapterListView(gujiId: guji.id, gujiName: guji.name)) {
                        GujiCard(guji: guji, index: index)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8).delay(Double(min(index, 8)) * 0.06),
                                value: appearAnimation
                            )
                    }
                    .buttonStyle(GujiBounceStyle())
                    .onAppear {
                        if index == gujiList.count - 3, hasMorePages, !isLoading {
                            Task { await loadMore() }
                        }
                    }
                }

                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("加载中...")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            await loadInitial()
            withAnimation(.easeOut(duration: 0.5)) {
                appearAnimation = true
            }
        }
    }

    private func loadInitial() async {
        isLoading = true
        gujiList = (try? await PoetryAPIService.shared.fetchGujiList(page: 1)) ?? []
        hasMorePages = gujiList.count >= 10
        isLoading = false
    }

    private func loadMore() async {
        guard !isLoading else { return }
        isLoading = true
        currentPage += 1
        let more = (try? await PoetryAPIService.shared.fetchGujiList(page: currentPage)) ?? []
        gujiList.append(contentsOf: more)
        hasMorePages = more.count >= 10
        isLoading = false
    }
}

// MARK: - Guji Card

private struct GujiCard: View {
    let guji: PMGuji
    let index: Int

    private let bookColors: [(Color, Color)] = [
        (Color(red: 0.55, green: 0.27, blue: 0.07), Color(red: 0.8, green: 0.5, blue: 0.2)),
        (Color(red: 0.15, green: 0.35, blue: 0.25), Color(red: 0.25, green: 0.55, blue: 0.4)),
        (Color(red: 0.25, green: 0.2, blue: 0.5), Color(red: 0.45, green: 0.35, blue: 0.7)),
        (Color(red: 0.5, green: 0.15, blue: 0.2), Color(red: 0.75, green: 0.3, blue: 0.35)),
        (Color(red: 0.1, green: 0.3, blue: 0.5), Color(red: 0.2, green: 0.5, blue: 0.7)),
    ]

    private var colors: (Color, Color) { bookColors[index % bookColors.count] }

    private let bookIcons = ["book.closed.fill", "text.book.closed.fill", "books.vertical.fill", "scroll.fill", "book.pages.fill"]
    private var icon: String { bookIcons[index % bookIcons.count] }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(colors: [colors.0, colors.1], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 54, height: 54)
                    .shadow(color: colors.0.opacity(0.3), radius: 4, y: 2)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(.white.opacity(0.9))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(guji.name)
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                Text(guji.poetName)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                if !guji.excerpt.isEmpty {
                    Text(guji.excerpt)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
                        .lineLimit(2)
                        .lineSpacing(2)
                }
            }

            Spacer()

            VStack(spacing: 4) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                Text("\(guji.viewCount)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}

private struct GujiBounceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
