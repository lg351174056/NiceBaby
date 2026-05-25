import SwiftUI

struct TutuTagSelectionView: View {
    @StateObject private var api = TutuAPIService.shared
    @State private var tags: [TutuTag] = []
    @State private var isLoading = false
    @State private var showTokenInput = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if api.token.isEmpty {
                tutuTokenEmptyView
            } else if isLoading {
                loadingView
            } else if tags.isEmpty {
                errorView
            } else {
                tagContent
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
        .task {
            if tags.isEmpty && !api.token.isEmpty {
                await loadTags()
            }
        }
    }

    // MARK: - Content

    private var tagContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                heroHeader
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                ForEach(Array(stageGroups.enumerated()), id: \.element.stage) { index, group in
                    StageCard(
                        group: group,
                        selectedTagId: api.selectedTagId,
                        stageIndex: index,
                        appeared: appeared
                    )
                }
            }
            .padding(.bottom, 60)
        }
        .background(AppTheme.background)
        .onAppear {
            guard !appeared else { return }
            withAnimation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var heroHeader: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("选择年级")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("点选年级，开启学习之旅")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentMint, AppTheme.accentSage],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: AppTheme.accentMint.opacity(0.4), radius: 12, x: 0, y: 6)
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 8)
    }

    // MARK: - State views

    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(AppTheme.accentBlue.opacity(0.3 - Double(i) * 0.1))
                        .frame(width: 60 + CGFloat(i) * 20, height: 60 + CGFloat(i) * 20)
                        .scaleEffect(isLoading ? 1.1 : 0.9)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                            value: isLoading
                        )
                }
                Image(systemName: "book.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.accentBlue)
            }
            Text("正在加载资料库...")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.accentTerracotta)
            Text("加载失败")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text("请检查网络或 Token 是否有效")
                .font(AppTheme.captionMuted())
                .foregroundStyle(AppTheme.textSecondary)
            Button {
                Task { await loadTags() }
            } label: {
                Text("重新加载")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(AppTheme.accentBlue)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tutuTokenEmptyView: some View {
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
            Button {
                showTokenInput = true
            } label: {
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

    private var stageGroups: [StageGroup] {
        let grouped = Dictionary(grouping: tags) { $0.stage }
        return [
            StageGroup(
                stage: 1, title: "小学", tags: (grouped[1] ?? []).sorted { $0.sort < $1.sort },
                icon: "star.fill", colors: (AppTheme.accentYellow, Color(hex: "f97316"))
            ),
            StageGroup(
                stage: 2, title: "初中", tags: (grouped[2] ?? []).sorted { $0.sort < $1.sort },
                icon: "flame.fill", colors: (AppTheme.accentBlue, AppTheme.accentPurple)
            ),
            StageGroup(
                stage: 3, title: "高中", tags: (grouped[3] ?? []).sorted { $0.sort < $1.sort },
                icon: "graduationcap.fill", colors: (AppTheme.accentPink, Color(hex: "a855f7"))
            )
        ].filter { !$0.tags.isEmpty }
    }

    private func loadTags() async {
        isLoading = true
        tags = await api.fetchTags()
        isLoading = false
    }
}

// MARK: - Stage Group Model

private struct StageGroup: Identifiable {
    let stage: Int
    let title: String
    let tags: [TutuTag]
    let icon: String
    let colors: (Color, Color)
    var id: Int { stage }
}

// MARK: - Stage Card (每个学段一个独立卡片)

private struct StageCard: View {
    let group: StageGroup
    let selectedTagId: Int
    let stageIndex: Int
    let appeared: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var staggerDelay: Double {
        reduceMotion ? 0 : Double(stageIndex) * 0.15 + 0.1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [group.colors.0, group.colors.1],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    Image(systemName: group.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text(group.title)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(group.tags.count) 册")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.background)
                    .clipShape(Capsule())
            }

            FlowLayout(spacing: 10) {
                ForEach(Array(group.tags.enumerated()), id: \.element.id) { tagIndex, tag in
                    NavigationLink(destination: TutuCategoryListView(tag: tag)) {
                        GradeChip(
                            tag: tag,
                            isSelected: tag.id == selectedTagId,
                            stageColors: group.colors,
                            appeared: appeared,
                            delay: staggerDelay + Double(tagIndex) * 0.04
                        )
                    }
                    .buttonStyle(ChipBounceStyle())
                }
            }
        }
        .padding(18)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.8), lineWidth: 2)
        )
        .padding(.horizontal, AppTheme.paddingScreen)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .animation(
            reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.75).delay(staggerDelay),
            value: appeared
        )
    }
}

// MARK: - Grade Chip (单个年级标签)

private struct GradeChip: View {
    let tag: TutuTag
    let isSelected: Bool
    let stageColors: (Color, Color)
    let appeared: Bool
    let delay: Double
    @State private var isHovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var displayName: String {
        tag.abbr.isEmpty ? tag.name : tag.abbr
    }

    var body: some View {
        Text(displayName)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(chipBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? Color.clear : AppTheme.textPrimary.opacity(0.08),
                        lineWidth: 2
                    )
            )
            .shadow(
                color: isSelected ? stageColors.0.opacity(0.35) : .black.opacity(0.04),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)
            .animation(
                reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.7).delay(delay),
                value: appeared
            )
    }

    @ViewBuilder
    private var chipBackground: some View {
        if isSelected {
            LinearGradient(
                colors: [stageColors.0, stageColors.1],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [AppTheme.card, AppTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Flow Layout (自适应换行布局)

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
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

// MARK: - Button Style

private struct ChipBounceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

