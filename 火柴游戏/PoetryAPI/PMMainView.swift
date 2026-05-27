import SwiftUI

enum PMNavigationTarget: Hashable {
    case home
}

struct PMMainView: View {
    @State private var selectedSection: PMSection = .poetry

    enum PMSection: String, CaseIterable {
        case poetry = "诗文"
        case guji = "古籍"
        case search = "搜索"

        var icon: String {
            switch self {
            case .poetry: return "text.book.closed"
            case .guji: return "books.vertical"
            case .search: return "magnifyingglass"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionPicker
            tabContent
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        HStack(spacing: 4) {
            ForEach(PMSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedSection = section
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: section.icon)
                            .font(.system(size: 12, weight: .bold))
                        Text(section.rawValue)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(selectedSection == section ? .white : AppTheme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        selectedSection == section
                            ? AnyShapeStyle(LinearGradient(
                                colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            : AnyShapeStyle(Color.clear)
                    )
                    .clipShape(Capsule())
                }
            }
        }
        .padding(4)
        .background(AppTheme.card.opacity(0.8), in: Capsule())
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.vertical, 10)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedSection {
        case .poetry:
            PMPoetryHomeView()
        case .guji:
            PMGujiListView()
        case .search:
            PMSearchView()
        }
    }
}

#Preview {
    PMMainView()
}
