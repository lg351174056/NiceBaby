import SwiftUI

// MARK: - 主页面（分类网格）

struct WhyMainView: View {
    @StateObject private var service = WhyAPIService.shared
    @State private var categories: [WhyCategory] = []
    @State private var isLoading = true
    @State private var loadError: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                header
                content
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar) // 隐藏TabBar
        .navigationDestination(for: WhyCategory.self) { cat in
            WhyCategoryListView(category: cat)
        }
        .navigationDestination(for: WhyQuestionRef.self) { ref in
            WhyDetailView(questionId: ref.id, initialTitle: ref.title)
        }
        .task { await loadCategories() }
    }

    // MARK: - 背景

    private var backgroundLayer: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.95).ignoresSafeArea()
            // 顶部装饰渐变
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.94, blue: 0.86).opacity(0.5), .clear],
                startPoint: .top, endPoint: .center
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - 顶部

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }

            Spacer()

            VStack(spacing: 2) {
                Text("十万个为什么")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Why? Why? Why?")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
                    .tracking(1.2)
            }

            Spacer()

            Button {
                Task { await loadCategories(force: true) }
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.accentBlue)
                }
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color.white.opacity(0.6))
    }

    // MARK: - 内容

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                Spacer()
                ProgressView().controlSize(.large)
                Text("正在加载分类…")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
        } else if let err = loadError, categories.isEmpty {
            emptyOrError(err)
        } else if categories.isEmpty {
            emptyOrError("暂无分类")
        } else {
            ScrollView(showsIndicators: false) {
                let chunks = categories.chunked(into: 3)
                VStack(spacing: 16) {
                    ForEach(0..<chunks.count, id: \.self) { i in
                        let chunk = chunks[i]
                        if chunk.count == 1 {
                            NavigationLink(value: chunk[0]) {
                                WhyCategoryBentoHero(category: chunk[0])
                            }
                            .buttonStyle(WhyBounceButtonStyle())
                        } else if chunk.count == 2 {
                            HStack(spacing: 16) {
                                NavigationLink(value: chunk[0]) {
                                    WhyCategoryBentoHalf(category: chunk[0])
                                }
                                .buttonStyle(WhyBounceButtonStyle())
                                NavigationLink(value: chunk[1]) {
                                    WhyCategoryBentoHalf(category: chunk[1])
                                }
                                .buttonStyle(WhyBounceButtonStyle())
                            }
                        } else if chunk.count == 3 {
                            if i % 2 == 0 {
                                VStack(spacing: 16) {
                                    NavigationLink(value: chunk[0]) {
                                        WhyCategoryBentoHero(category: chunk[0])
                                    }
                                    .buttonStyle(WhyBounceButtonStyle())
                                    HStack(spacing: 16) {
                                        NavigationLink(value: chunk[1]) {
                                            WhyCategoryBentoHalf(category: chunk[1])
                                        }
                                        .buttonStyle(WhyBounceButtonStyle())
                                        NavigationLink(value: chunk[2]) {
                                            WhyCategoryBentoHalf(category: chunk[2])
                                        }
                                        .buttonStyle(WhyBounceButtonStyle())
                                    }
                                }
                            } else {
                                VStack(spacing: 16) {
                                    HStack(spacing: 16) {
                                        NavigationLink(value: chunk[0]) {
                                            WhyCategoryBentoHalf(category: chunk[0])
                                        }
                                        .buttonStyle(WhyBounceButtonStyle())
                                        NavigationLink(value: chunk[1]) {
                                            WhyCategoryBentoHalf(category: chunk[1])
                                        }
                                        .buttonStyle(WhyBounceButtonStyle())
                                    }
                                    NavigationLink(value: chunk[2]) {
                                        WhyCategoryBentoHero(category: chunk[2])
                                    }
                                    .buttonStyle(WhyBounceButtonStyle())
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .refreshable {
                await loadCategories(force: true)
            }
        }
    }

    private func emptyOrError(_ message: String) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.accentYellow)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            Button {
                Task { await loadCategories(force: true) }
            } label: {
                Text("重新加载")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(AppTheme.accentBlue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    // MARK: - Load

    private func loadCategories(force: Bool = false) async {
        isLoading = true
        loadError = nil
        let list = await service.fetchCategories(force: force)
        await MainActor.run {
            self.categories = list
            self.isLoading = false
            if list.isEmpty {
                self.loadError = "未能加载到分类数据"
            }
        }
    }
}

// MARK: - Bento 卡片

struct WhyCategoryBentoHero: View {
    let category: WhyCategory

    var body: some View {
        ZStack(alignment: .leading) {
            // 背景
            LinearGradient(
                colors: [
                    category.swiftUIColor,
                    category.swiftUIColor.opacity(0.8)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            
            // 装饰图标 (右侧半隐)
            HStack {
                Spacer()
                Image(systemName: "book.fill")
                    .font(.system(size: 140))
                    .foregroundStyle(.white.opacity(0.15))
                    .offset(x: 20, y: 20)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.3))
                            .background(.ultraThinMaterial, in: Circle())
                            .frame(width: 44, height: 44)
                        Image(systemName: "book.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }

                Spacer(minLength: 8)

                Text(category.name)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                HStack(spacing: 6) {
                    Text("开始探索")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(category.swiftUIColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: category.swiftUIColor.opacity(0.3), radius: 15, x: 0, y: 8)
    }
}

struct WhyCategoryBentoHalf: View {
    let category: WhyCategory

    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [
                    category.swiftUIColor.opacity(0.9),
                    category.swiftUIColor.opacity(0.7)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.25))
                            .background(.ultraThinMaterial, in: Circle())
                            .frame(width: 38, height: 38)
                        Image(systemName: "book.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer(minLength: 12)

                Text(category.name)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                Text("\(category.questionCount) 个问题")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: category.swiftUIColor.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

// MARK: - 共享按钮样式

struct WhyBounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

/// 仅携带 id / title 的问题引用（用于导航，避免传整条数据）
struct WhyQuestionRef: Identifiable, Hashable {
    let id: Int
    let title: String
}

// MARK: - Helper

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
