import SwiftUI

struct TutuResourceListView: View {
    let subCategory: TutuSubCategory
    let tag: TutuTag
    @State private var resources: [TutuResource] = []
    @State private var isLoading = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if isLoading {
                ProgressView("正在加载...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if resources.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                    Text("暂无资料")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                resourceContent
            }
        }
        .navigationTitle(subCategory.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .background(AppTheme.background)
        .task {
            if resources.isEmpty {
                isLoading = true
                resources = await TutuAPIService.shared.fetchResources(categoryId: subCategory.id, tagId: tag.id)
                isLoading = false
                withAnimation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
        }
    }

    private var resourceContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subCategory.name)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(resources.count) 份资料")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.accentBlue.opacity(0.5))
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 8)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)

                LazyVStack(spacing: 12) {
                    ForEach(Array(resources.enumerated()), id: \.element.id) { index, resource in
                        NavigationLink(destination: TutuResourceDetailView(resource: resource)) {
                            ResourceCard(resource: resource, index: index)
                        }
                        .buttonStyle(TutuCardBounceStyle())
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(
                            reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.06),
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

private struct ResourceCard: View {
    let resource: TutuResource
    let index: Int

    private var accentColor: Color {
        let colors: [Color] = [
            Color(hex: "667eea"), Color(hex: "4facfe"), Color(hex: "43e97b"),
            Color(hex: "fa709a"), Color(hex: "a18cd1"), Color(hex: "fccb90")
        ]
        return colors[index % colors.count]
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.2), accentColor.opacity(0.05)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(accentColor.opacity(0.2), lineWidth: 1.5)
                    )

                if !resource.image.isEmpty, let url = URL(string: TutuAPIService.shared.fullImageURL(resource.image)) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "doc.richtext.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(accentColor.opacity(0.7))
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(accentColor.opacity(0.7))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(resource.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 11))
                        Text("\(resource.actualSales)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.textSecondary)

                    if resource.previewSupported == 1 {
                        Text("可预览")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [AppTheme.accentSage, AppTheme.accentMint],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                            )
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: accentColor.opacity(0.08), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.6), lineWidth: 1.5)
        )
    }
}
