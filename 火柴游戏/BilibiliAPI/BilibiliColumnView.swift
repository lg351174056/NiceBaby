import SwiftUI

// MARK: - B站专栏（精选分类列表）

struct BilibiliColumnView: View {
    private let categories = BilibiliCategory.all

    var body: some View {
        ZStack {
            FieldBackground()
            columnSun
            columnCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            columnCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text("B站专栏")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                        .lineLimit(1)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        heroCard
                        sectionTitle
                        categoryList
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
    }

    // MARK: - 顶部头卡

    private var heroCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 255/255, green: 228/255, blue: 238/255),
                            Color(red: 251/255, green: 180/255, blue: 205/255)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("📺")
                    .font(.system(size: 26))
                    .modifier(FieldBob(delay: 0.3))
            }
            .frame(width: 56, height: 56)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(red: 251/255, green: 114/255, blue: 153/255).opacity(0.4), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("哔哩哔哩 · 精选专栏")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("数学思维 · 趣味百科 · 国学语文")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(red: 251/255, green: 114/255, blue: 153/255).opacity(0.3), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.12), radius: 8, y: 4)
        )
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    // MARK: - 分类标题

    private var sectionTitle: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color(red: 251/255, green: 114/255, blue: 153/255))
                .frame(width: 6, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            Text("精选分类")
                .font(.system(size: 15, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.fieldInk)
            Spacer()
            Text("\(categories.count) 类")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.fieldMoss)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - 分类列表

    private var categoryList: some View {
        LazyVStack(spacing: 10) {
            ForEach(categories) { category in
                NavigationLink(destination: BilibiliTopicListView(category: category)) {
                    categoryCard(category)
                        .contentShape(Rectangle())
                }
                .buttonStyle(GalleryCardBounceStyle())
            }
        }
        .padding(.horizontal, 18)
    }

    private func categoryCard(_ category: BilibiliCategory) -> some View {
        HStack(spacing: 14) {
            // 分类图标
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 255/255, green: 240/255, blue: 246/255))
                Text(category.icon)
                    .font(.system(size: 22))
            }
            .frame(width: 48, height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(red: 251/255, green: 114/255, blue: 153/255).opacity(0.35), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(category.name)
                        .font(.system(size: 15, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                    Text(category.tag)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 251/255, green: 114/255, blue: 153/255))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 251/255, green: 114/255, blue: 153/255).opacity(0.12))
                        .clipShape(Capsule())
                }
                Text(category.subtitle)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.fieldMossLight)
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.25), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 5, y: 3)
        )
    }

    // MARK: - 背景装饰（太阳/云）

    private var columnSun: some View {
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

    private func columnCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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
    }
}
