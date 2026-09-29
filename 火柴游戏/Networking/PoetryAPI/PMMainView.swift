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
            case .poetry: return "📜"
            case .guji: return "📚"
            case .search: return "🔍"
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
        ZStack {
            // 蓝天草地背景（书野营地竹青风）
            FieldBackground()

            gardenSun
            gardenCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            gardenCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text("诗词古文大全")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                // 主题头
                heroHeader

                // Section 切换卡
                sectionPicker
                    .padding(.top, 12)

                tabContent
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar, .tabBar)
        .enableSwipeBack()
    }

    // 主题头（📜 竹青）
    private var heroHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 227/255, green: 242/255, blue: 234/255),
                            Color(red: 189/255, green: 232/255, blue: 211/255)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("📜")
                    .font(.system(size: 24))
                    .modifier(FieldBob(delay: 0.3))
            }
            .frame(width: 52, height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.fieldMint.opacity(0.4), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("诗词文学")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("唐诗宋词 · 文言古籍 · 一网打尽")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                HStack(spacing: 12) {
                    Text("📖 30000+ 首")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMint)
                    Text("🏛 12 部古籍")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.fieldGold)
                }
                .padding(.top, 1)
            }
            Spacer()
            HStack(spacing: 6) {
                Text("🍃").font(.system(size: 15)).modifier(FieldBob(delay: 0))
                Text("🦋").font(.system(size: 14)).modifier(FieldFlutter(delay: 0.9))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppTheme.fieldMint.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.12), radius: 8, y: 4)
        )
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    // MARK: - Section Picker（竹青三卡）

    private var sectionPicker: some View {
        HStack(spacing: 10) {
            ForEach(PMSection.allCases, id: \.self) { section in
                sectionTab(section)
            }
        }
        .padding(.horizontal, 18)
    }

    private func sectionTab(_ section: PMSection) -> some View {
        let isSelected = selectedSection == section
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedSection = section
            }
        } label: {
            VStack(spacing: 4) {
                Text(section.icon)
                    .font(.system(size: 22))
                    .modifier(FieldBob(delay: isSelected ? 0 : 100))

                Text(section.rawValue)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(isSelected ? Color(red: 46/255, green: 125/255, blue: 91/255) : AppTheme.fieldOliveDeep)

                Text(section.subtitle)
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected
                        ? Color(red: 238/255, green: 247/255, blue: 238/255)
                        : Color.white.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(isSelected
                                ? AppTheme.fieldMint
                                : AppTheme.fieldOlive.opacity(0.25),
                                lineWidth: 2)
                    )
            )
            .shadow(color: AppTheme.fieldGrassShadow.opacity(isSelected ? 0.12 : 0.06), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
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

    // MARK: - 背景装饰（太阳/云）

    private var gardenSun: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breathe = 1 + 0.03 * sin(t * 1.2)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 214/255, blue: 110/255).opacity(0.4),
                            Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.14),
                            .clear
                        ], center: .center, startRadius: 10, endRadius: 50)
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(breathe)
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            Color(red: 255/255, green: 246/255, blue: 205/255),
                            Color(red: 255/255, green: 214/255, blue: 100/255),
                            Color(red: 247/255, green: 188/255, blue: 55/255)
                        ], center: .init(x: 0.38, y: 0.3), startRadius: 2, endRadius: 18)
                    )
                    .frame(width: 32, height: 32)
                    .scaleEffect(breathe)
                    .shadow(color: Color(red: 255/255, green: 201/255, blue: 61/255).opacity(0.8), radius: 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.trailing, 20)
            .padding(.top, 30)
        }
        .allowsHitTesting(false)
    }

    private func gardenCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate + delay
            let drift = 14 * sin(t * 0.42)
            let bob = 3 * sin(t * 0.85 + 1.2)
            ZStack {
                ZStack {
                    Capsule().fill(Color.white.opacity(0.95)).frame(width: 42, height: 15).offset(y: 4)
                    Circle().fill(Color.white.opacity(0.95)).frame(width: 25, height: 25).offset(x: -9, y: -6)
                    Circle().fill(Color.white.opacity(0.9)).frame(width: 21, height: 21).offset(x: 7, y: -4)
                    Circle().fill(Color.white.opacity(0.9)).frame(width: 15, height: 15).offset(x: 0, y: -10)
                }
                .frame(width: 52, height: 30)
                .scaleEffect(scale)
                .offset(x: drift, y: bob)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, 390 * x - 10)
            .padding(.top, 390 * y)
        }
        .allowsHitTesting(false)
    }}

#Preview {
    NavigationStack {
        PMMainView()
    }
}
