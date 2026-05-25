import SwiftUI

struct TutuSubCategoryListView: View {
    let category: TutuCategory
    let tag: TutuTag
    @State private var subCategories: [TutuSubCategory] = []
    @State private var isLoading = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if isLoading {
                ProgressView("正在加载...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if subCategories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                    Text("暂无内容")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                subCategoryContent
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .background(AppTheme.background)
        .task {
            if subCategories.isEmpty {
                isLoading = true
                subCategories = await TutuAPIService.shared.fetchSubCategories(parentId: category.id, tagId: tag.id)
                isLoading = false
                withAnimation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
        }
    }

    private var subCategoryContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.name)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(subCategories.count) 个章节")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 8)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)

                LazyVStack(spacing: 10) {
                    ForEach(Array(subCategories.enumerated()), id: \.element.id) { index, sub in
                        NavigationLink(destination: TutuResourceListView(subCategory: sub, tag: tag)) {
                            SubCategoryRow(subCategory: sub, index: index)
                        }
                        .buttonStyle(.plain)
                        .opacity(appeared ? 1 : 0)
                        .offset(x: appeared ? 0 : -20)
                        .animation(
                            reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.05),
                            value: appeared
                        )
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
            }
            .padding(.bottom, 40)
        }
    }
}

private struct SubCategoryRow: View {
    let subCategory: TutuSubCategory
    let index: Int
    @State private var isPressed = false

    private var accentColor: Color {
        let colors: [Color] = [
            AppTheme.accentBlue, AppTheme.accentMint, AppTheme.accentPurple,
            AppTheme.accentSage, AppTheme.accentPink, AppTheme.accentYellow
        ]
        return colors[index % colors.count]
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.15), accentColor.opacity(0.05)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                if !subCategory.image.isEmpty, let url = URL(string: TutuAPIService.shared.fullImageURL(subCategory.image)) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(accentColor.opacity(0.6))
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(accentColor.opacity(0.6))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(subCategory.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text("点击查看资料")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accentColor)
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.6), lineWidth: 1.5)
        )
        .scaleEffect(isPressed ? 0.97 : 1)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
