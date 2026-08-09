import SwiftUI

struct PMGujiListView: View {
    @State private var gujiList: [PMGuji] = []
    @State private var currentPage = 1
    @State private var isLoading = false
    @State private var hasMorePages = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(Array(gujiList.enumerated()), id: \.element.id) { index, guji in
                    NavigationLink(destination: PMGujiChapterListView(gujiId: guji.id, gujiName: guji.name)) {
                        GujiCard(guji: guji, index: index)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                if hasMorePages {
                    Color.clear
                        .frame(height: 1)
                        .id(currentPage)
                        .onAppear {
                            Task { await loadMore() }
                        }
                }

                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color(red: 76/255, green: 175/255, blue: 125/255))
                        Text("加载中...")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .task {
            await loadInitial()
        }
    }

    private func loadInitial() async {
        isLoading = true
        currentPage = 1
        gujiList = (try? await PoetryAPIService.shared.fetchGujiList(page: 1)) ?? []
        hasMorePages = gujiList.count >= 10
        isLoading = false
    }

    private func loadMore() async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true
        let nextPage = currentPage + 1
        let more = (try? await PoetryAPIService.shared.fetchGujiList(page: nextPage)) ?? []
        let existingIDs = Set(gujiList.map(\.id))
        gujiList.append(contentsOf: more.filter { !existingIDs.contains($0.id) })
        currentPage = nextPage
        hasMorePages = more.count >= 10
        isLoading = false
    }
}

// MARK: - Guji Card（书脊卡 · 书野竹青）

private struct GujiCard: View, Equatable {
    let guji: PMGuji
    let index: Int

    private let bookColors: [(Color, Color)] = [
        (Color(red: 217/255, green: 164/255, blue: 91/255), Color(red: 168/255, green: 122/255, blue: 48/255)),
        (Color(red: 92/255, green: 156/255, blue: 102/255), Color(red: 74/255, green: 124/255, blue: 89/255)),
        (Color(red: 74/255, green: 111/255, blue: 165/255), Color(red: 59/255, green: 142/255, blue: 165/255)),
        (Color(red: 201/255, green: 100/255, blue: 66/255), Color(red: 168/255, green: 72/255, blue: 50/255)),
        (Color(red: 92/255, green: 75/255, blue: 138/255), Color(red: 140/255, green: 115/255, blue: 195/255)),
    ]

    private var colors: (Color, Color) { bookColors[index % bookColors.count] }

    static func == (lhs: GujiCard, rhs: GujiCard) -> Bool {
        lhs.guji.id == rhs.guji.id && lhs.index == rhs.index
    }

    private var spineText: String {
        let name = guji.name
        if name.count >= 2 { return String(name.prefix(2)) }
        return name
    }

    var body: some View {
        HStack(spacing: 12) {
            // 书脊
            Text(spineText)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 44, height: 56)
                .background(
                    LinearGradient(colors: [colors.0, colors.1], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: colors.0.opacity(0.35), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(guji.name)
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .lineLimit(1)

                Text(guji.poetName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))

                if !guji.excerpt.isEmpty {
                    Text(guji.excerpt)
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .foregroundStyle(Color(red: 85/255, green: 112/255, blue: 95/255))
                        .lineLimit(2)
                        .lineSpacing(2)
                }
            }

            Spacer()

            VStack(spacing: 4) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(red: 160/255, green: 176/255, blue: 152/255))
                Text("\(guji.viewCount)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(red: 160/255, green: 176/255, blue: 152/255))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.25), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 5, y: 3)
        )
    }
}
