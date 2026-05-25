import SwiftUI

struct TutuCategoryListView: View {
    let tag: TutuTag
    @State private var categories: [TutuCategory] = []
    @State private var isLoading = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        Group {
            if isLoading {
                ProgressView("正在加载...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if categories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                    Text("暂无分类")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                categoryContent
            }
        }
        .navigationTitle(tag.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .background(AppTheme.background)
        .task {
            if categories.isEmpty {
                isLoading = true
                categories = await TutuAPIService.shared.fetchCategories(tagId: tag.id)
                TutuAPIService.shared.selectedTagId = tag.id
                isLoading = false
                withAnimation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
        }
    }

    private var categoryContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("选择学科")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(tag.name) · 共 \(categories.count) 个学科")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.accentBlue, AppTheme.accentPurple],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .shadow(color: AppTheme.accentBlue.opacity(0.3), radius: 10, x: 0, y: 4)
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 8)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        NavigationLink(destination: TutuSubCategoryListView(category: category, tag: tag)) {
                            TutuCategoryCard(
                                category: category,
                                style: TutuCategoryCardStyle.forIndex(index),
                                appeared: appeared,
                                index: index,
                                reduceMotion: reduceMotion
                            )
                        }
                        .buttonStyle(TutuCardBounceStyle())
                    }
                }
                .padding(.horizontal, AppTheme.paddingScreen)
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Card Style

struct TutuCategoryCardStyle {
    let gradient: [Color]
    let icon: String

    static let styles: [TutuCategoryCardStyle] = [
        .init(gradient: [Color(hex: "667eea"), Color(hex: "764ba2")], icon: "text.book.closed.fill"),
        .init(gradient: [Color(hex: "4facfe"), Color(hex: "00f2fe")], icon: "function"),
        .init(gradient: [Color(hex: "43e97b"), Color(hex: "38f9d7")], icon: "textformat.abc"),
        .init(gradient: [Color(hex: "fa709a"), Color(hex: "fee140")], icon: "atom"),
        .init(gradient: [Color(hex: "a18cd1"), Color(hex: "fbc2eb")], icon: "flask.fill"),
        .init(gradient: [Color(hex: "fccb90"), Color(hex: "d57eeb")], icon: "globe.asia.australia.fill"),
        .init(gradient: [Color(hex: "f093fb"), Color(hex: "f5576c")], icon: "music.note"),
        .init(gradient: [Color(hex: "89f7fe"), Color(hex: "66a6ff")], icon: "paintpalette.fill"),
        .init(gradient: [Color(hex: "fddb92"), Color(hex: "d1fdff")], icon: "leaf.fill"),
        .init(gradient: [Color(hex: "e0c3fc"), Color(hex: "8ec5fc")], icon: "sportscourt.fill"),
    ]

    static func forIndex(_ index: Int) -> TutuCategoryCardStyle {
        styles[index % styles.count]
    }
}

private struct TutuCategoryCard: View {
    let category: TutuCategory
    let style: TutuCategoryCardStyle
    let appeared: Bool
    let index: Int
    let reduceMotion: Bool

    private var staggerDelay: Double {
        reduceMotion ? 0 : Double(index) * 0.08
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.25))
                        .frame(width: 44, height: 44)
                    if !category.icon.isEmpty {
                        AsyncImage(url: URL(string: TutuAPIService.shared.fullImageURL(category.icon))) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: style.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 26, height: 26)
                    } else {
                        Image(systemName: style.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Text(category.name)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 120)
        .background(
            ZStack {
                LinearGradient(
                    colors: style.gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                // Claymorphism 内光效果
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white.opacity(0.08))
                    .padding(2)
                    .blur(radius: 1)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: style.gradient[0].opacity(0.4), radius: 12, x: 0, y: 8)
        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.4), lineWidth: 2)
        )
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .animation(
            reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.7).delay(staggerDelay),
            value: appeared
        )
    }
}

struct TutuCardBounceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .rotation3DEffect(
                .degrees(configuration.isPressed ? 2 : 0),
                axis: (x: 1, y: 0, z: 0)
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
