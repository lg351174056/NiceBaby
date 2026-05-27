import SwiftUI

struct TutuHomeView: View {
    @StateObject private var api = TutuAPIService.shared
    @State private var tags: [TutuTag] = []
    @State private var categories: [TutuCategory] = []
    @State private var banners: [TutuBanner] = []
    @State private var plans: [TutuPlan] = []
    @State private var isLoading = false
    @State private var showTokenInput = false
    @State private var showTagPicker = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var selectedTag: TutuTag? {
        tags.first { $0.id == api.selectedTagId }
    }

    var body: some View {
        Group {
            if api.token.isEmpty {
                tokenEmptyView
            } else if isLoading && categories.isEmpty {
                loadingView
            } else {
                homeContent
            }
        }
        .navigationTitle("学习资料")
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showTokenInput = true } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showTokenInput) {
            TutuTokenInputView()
        }
        .sheet(isPresented: $showTagPicker) {
            TutuTagPickerSheet(tags: tags, selectedId: api.selectedTagId) { tagId in
                api.selectedTagId = tagId
                showTagPicker = false
                Task { await loadContent() }
            }
        }
        .task {
            if tags.isEmpty && !api.token.isEmpty {
                await loadAll()
            }
        }
    }

    // MARK: - Home Content

    private var homeContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                tagSelector
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                if !banners.isEmpty {
                    bannerCarousel
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)
                        .animation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: appeared)
                }

                if !categories.isEmpty {
                    categoriesGrid
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)
                        .animation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)
                }

                if !plans.isEmpty {
                    plansSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)
                        .animation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)
                }
            }
            .padding(.bottom, 40)
        }
        .background(AppTheme.background)
    }

    // MARK: - Tag Selector

    private var tagSelector: some View {
        HStack(spacing: 12) {
            Button { showTagPicker = true } label: {
                HStack(spacing: 6) {
                    Text(selectedTag?.name ?? "选择年级")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.accentBlue)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.card)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 4)
    }

    // MARK: - Banner

    private var bannerCarousel: some View {
        TabView {
            ForEach(banners.filter { $0.imageUrl.contains("轮播") || $0.title.contains("轮播") || !$0.imageUrl.isEmpty }) { banner in
                AsyncImage(url: URL(string: api.fullImageURL(banner.imageUrl))) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.accentYellow.opacity(0.1))
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, AppTheme.paddingScreen)
            }
        }
        .frame(height: 150)
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }

    // MARK: - Categories Grid

    private var categoriesGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible()),
                GridItem(.flexible()), GridItem(.flexible())
            ], spacing: 16) {
                ForEach(categories) { cat in
                    NavigationLink(destination: TutuSubCategoryListView(category: cat, tag: selectedTag ?? TutuTag(id: api.selectedTagId, name: "", stage: 1, abbr: "", sort: 0))) {
                        CategoryIcon(category: cat)
                    }
                    .buttonStyle(TutuCardBounceStyle())
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
        }
    }

    // MARK: - Plans

    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(AppTheme.accentYellow)
                Text("推荐计划")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, AppTheme.paddingScreen)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(plans) { plan in
                        PlanCard(plan: plan)
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
            }
        }
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
            Text("正在加载...")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tokenEmptyView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentMint.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "key.horizontal.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AppTheme.accentMint)
            }
            Text("请先设置 Token")
                .font(AppTheme.titleSection())
                .foregroundStyle(AppTheme.textPrimary)
            Text("从兔兔资料库小程序抓包获取\nAuthorization 中的 Token")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button { showTokenInput = true } label: {
                Text("设置 Token")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(AppTheme.accentBlue)
                    .clipShape(Capsule())
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data

    private func loadAll() async {
        isLoading = true
        tags = await api.fetchTags()
        await loadContent()
        isLoading = false
        withAnimation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8)) {
            appeared = true
        }
    }

    private func loadContent() async {
        async let catsTask = api.fetchCategoriesV2(tagId: api.selectedTagId)
        async let bannersTask = api.fetchBanners()
        async let plansTask = api.fetchPlans(tagId: api.selectedTagId)
        categories = await catsTask
        banners = await bannersTask
        plans = await plansTask
    }
}

// MARK: - Category Icon

private struct CategoryIcon: View {
    let category: TutuCategory

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(AppTheme.card)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                    .overlay(
                        Circle().stroke(.white.opacity(0.8), lineWidth: 1.5)
                    )

                if !category.icon.isEmpty {
                    AsyncImage(url: URL(string: TutuAPIService.shared.fullImageURL(category.icon))) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppTheme.accentBlue.opacity(0.5))
                    }
                    .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.accentBlue.opacity(0.5))
                }
            }

            Text(category.name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
        }
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let plan: TutuPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !plan.cover.isEmpty, let url = URL(string: plan.cover) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.accentYellow.opacity(0.1))
                }
                .frame(width: 240, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(plan.introduce)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                    Text("\(plan.virtualUsers) 人参与")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                }
                .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 240)
        .padding(10)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.6), lineWidth: 1.5)
        )
    }
}

// MARK: - Tag Picker Sheet

struct TutuTagPickerSheet: View {
    let tags: [TutuTag]
    let selectedId: Int
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    private var grouped: [(stage: Int, title: String, tags: [TutuTag])] {
        let dict = Dictionary(grouping: tags) { $0.stage }
        return [
            (1, "小学", (dict[1] ?? []).sorted { $0.sort < $1.sort }),
            (2, "初中", (dict[2] ?? []).sorted { $0.sort < $1.sort }),
            (3, "高中", (dict[3] ?? []).sorted { $0.sort < $1.sort })
        ].filter { !$0.tags.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(grouped, id: \.stage) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(group.title)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)

                            FlowLayoutPicker(spacing: 10) {
                                ForEach(group.tags) { tag in
                                    Button {
                                        onSelect(tag.id)
                                    } label: {
                                        Text(tag.abbr.isEmpty ? tag.name : tag.abbr)
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundStyle(tag.id == selectedId ? .white : AppTheme.textPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                tag.id == selectedId
                                                    ? AnyShapeStyle(LinearGradient(colors: [AppTheme.accentBlue, AppTheme.accentPurple], startPoint: .leading, endPoint: .trailing))
                                                    : AnyShapeStyle(AppTheme.card)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .shadow(color: tag.id == selectedId ? AppTheme.accentBlue.opacity(0.3) : .black.opacity(0.03), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(AppTheme.paddingScreen)
            }
            .navigationTitle("选择年级")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Flow Layout (reused)

struct FlowLayoutPicker: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangeSubviews(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }
        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
