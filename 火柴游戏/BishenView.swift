import SwiftUI

// MARK: - 导航类型

enum BishenNavTarget: Hashable {
    case list
}

// MARK: - 数据模型

struct BishenLine: Identifiable, Hashable {
    let id: String
    let content: String
}

struct BishenSubcategory: Identifiable, Hashable {
    var id: String { "\(category)_\(name)" }
    let category: String
    let name: String
    let lines: [BishenLine]
}

enum BishenStore {
    private static var cached: [BishenSubcategory]?

    static func loadAll() -> [BishenSubcategory] {
        if let cached { return cached }
        guard let url = Bundle.main.url(forResource: "笔神精选", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        let result: [BishenSubcategory] = arr.compactMap { dict in
            guard let category = dict["category"] as? String,
                  let subcategory = dict["subcategory"] as? String,
                  let lines = dict["lines"] as? [[String: String]] else { return nil }
            let items = lines.compactMap { l -> BishenLine? in
                guard let id = l["id"], let content = l["content"] else { return nil }
                return BishenLine(id: id, content: content)
            }
            return BishenSubcategory(category: category, name: subcategory, lines: items)
        }
        cached = result
        return result
    }

    static var categories: [String] {
        let all = loadAll()
        var seen: [String] = []
        for sub in all where !seen.contains(sub.category) {
            seen.append(sub.category)
        }
        return seen
    }

    static func subcategories(for category: String) -> [BishenSubcategory] {
        loadAll().filter { $0.category == category }
    }
}

// MARK: - 笔神精选主页（L1 · 书野营地竹青风）

struct BishenListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String = ""
    @State private var selectedSub: BishenSubcategory?

    private let categories = BishenStore.categories

    private var totalLines: Int {
        BishenStore.loadAll().reduce(0) { $0 + $1.lines.count }
    }

    var body: some View {
        ZStack {
            // 蓝天草地背景（固定）
            LinearGradient(
                colors: [
                    Color(red: 190/255, green: 227/255, blue: 245/255),
                    Color(red: 220/255, green: 242/255, blue: 220/255),
                    Color(red: 207/255, green: 235/255, blue: 196/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            bishenSun
            bishenCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            bishenCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text("笔神精选")
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                // 主题头
                heroHeader

                // 分类标签
                categoryTabs

                // 子分类列表
                subcategoryGrid
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .onAppear {
            if selectedCategory.isEmpty, let first = categories.first {
                selectedCategory = first
            }
        }
        .fullScreenCover(item: $selectedSub) { sub in
            BishenLinesView(subcategory: sub)
        }
    }

    // 主题头（🖋 竹青）
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
                Text("🖋")
                    .font(.system(size: 24))
                    .modifier(Bob(delay: 0.3))
            }
            .frame(width: 52, height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.4), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("笔神精选")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Text("小学好词好句好段")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                HStack(spacing: 12) {
                    Text("📚 \(categories.count) 大主题")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                    Text("✨ \(totalLines) 段好句")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 176/255, green: 138/255, blue: 62/255))
                }
                .padding(.top, 1)
            }
            Spacer()
            // 叶片 + 蝴蝶动效
            HStack(spacing: 6) {
                Text("🍃").font(.system(size: 15)).modifier(Bob(delay: 0))
                Text("🦋").font(.system(size: 14)).modifier(Flutter(delay: 0.9))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.12), radius: 8, y: 4)
        )
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    // 分类标签（竹青选中）
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { selectedCategory = cat }
                    } label: {
                        Text(cat)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(selectedCategory == cat ? .white : Color(red: 74/255, green: 92/255, blue: 66/255))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == cat
                                        ? AnyShapeStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                                        : AnyShapeStyle(Color.white.opacity(0.9)))
                                    .overlay(
                                        Capsule().strokeBorder(
                                            selectedCategory == cat
                                                ? Color(red: 61/255, green: 74/255, blue: 54/255)
                                                : Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35),
                                            lineWidth: 2)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
    }

    private var subcategoryGrid: some View {
        let subs = BishenStore.subcategories(for: selectedCategory)
        return ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(subs) { sub in
                    Button { selectedSub = sub } label: {
                        subcategoryCard(sub)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 40)
        }
    }

    private func subcategoryCard(_ sub: BishenSubcategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(sub.name)
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Spacer()
                Text("\(sub.lines.count) 段")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color(red: 227/255, green: 242/255, blue: 234/255), in: Capsule())
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(red: 160/255, green: 176/255, blue: 152/255))
            }

            if let first = sub.lines.first {
                Text(first.content.prefix(80) + "…")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(Color(red: 85/255, green: 112/255, blue: 95/255))
                    .lineLimit(2)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.25), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.08), radius: 5, y: 3)
        )
    }

    // MARK: - 背景装饰（太阳/云）

    private var bishenSun: some View {
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

    private func bishenCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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

    private struct Bob: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(y: CGFloat(sin(t * 2.2) * 4.0))
            }
        }
    }

    private struct Flutter: ViewModifier {
        let delay: Double
        func body(content: Content) -> some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate + delay
                content
                    .offset(x: CGFloat(sin(t * 1.8) * 3), y: CGFloat(sin(t * 2.4) * 4))
                    .rotationEffect(.degrees(sin(t * 3) * 6))
            }
        }
    }
}

// MARK: - 好句好段列表（L2 · 书野营地竹青风）

struct BishenLinesView: View {
    let subcategory: BishenSubcategory
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // 蓝天草地背景（固定）
            LinearGradient(
                colors: [
                    Color(red: 190/255, green: 227/255, blue: 245/255),
                    Color(red: 220/255, green: 242/255, blue: 220/255),
                    Color(red: 207/255, green: 235/255, blue: 196/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            linesSun
            linesCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            linesCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text("\(subcategory.category) · \(subcategory.name)")
                        .font(.system(size: 15, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                        .lineLimit(1)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                // 分区标题
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color(red: 76/255, green: 175/255, blue: 125/255))
                        .frame(width: 6, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    Text("好句好段")
                        .font(.system(size: 15, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    Spacer()
                    Text("共 \(subcategory.lines.count) 段")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 10)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(subcategory.lines.enumerated()), id: \.element.id) { idx, line in
                            lineCard(line, index: idx)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
    }

    private func lineCard(_ line: BishenLine, index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle().fill(
                        LinearGradient(colors: [
                            Color(red: 126/255, green: 211/255, blue: 160/255),
                            Color(red: 76/255, green: 175/255, blue: 125/255)
                        ], startPoint: .top, endPoint: .bottom)
                    )
                )

            Text(line.content)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.25), lineWidth: 2)
                )
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 50/255).opacity(0.06), radius: 4, y: 2)
        )
    }

    // MARK: - 背景装饰（太阳/云）

    private var linesSun: some View {
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

    private func linesCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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
