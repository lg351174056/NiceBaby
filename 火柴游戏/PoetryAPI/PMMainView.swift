import SwiftUI

enum PMNavigationTarget: Hashable {
    case home
}

struct PMMainView: View {
    @State private var selectedSection: PMSection = .poetry
    @Environment(\.dismiss) private var dismiss

    enum PMSection: String, CaseIterable {
        case poetry = "诗文"
        case guji = "古籍"
        case search = "搜索"

        var icon: String {
            switch self {
            case .poetry: return "text.book.closed.fill"
            case .guji: return "books.vertical.fill"
            case .search: return "magnifyingglass"
            }
        }

        var subtitle: String {
            switch self {
            case .poetry: return "唐诗宋词文言文"
            case .guji: return "经典古籍原文"
            case .search: return "搜索诗词诗人"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerArea
            tabContent
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar, .tabBar)
    }

    // MARK: - Header Area

    private var headerArea: some View {
        VStack(spacing: 14) {
            // 顶部导航（返回 + 标题）
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial, in: Circle())
                }

                Text("诗词古文大全")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 8)

            // Section 切换卡片
            sectionPicker
        }
        .padding(.bottom, 6)
        .background(AppTheme.background)
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        HStack(spacing: 8) {
            ForEach(PMSection.allCases, id: \.self) { section in
                sectionTab(section)
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    private func sectionTab(_ section: PMSection) -> some View {
        let isSelected = selectedSection == section
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedSection = section
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: section.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(
                                colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            : AnyShapeStyle(AppTheme.separator.opacity(0.5))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(section.rawValue)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? AppTheme.card
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? AppTheme.accentBlue.opacity(0.2) : Color.clear, lineWidth: 1.5)
            )
            .shadow(color: isSelected ? AppTheme.accentBlue.opacity(0.1) : .clear, radius: 8, y: 4)
        }
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
    NavigationStack {
        PMMainView()
    }
}
