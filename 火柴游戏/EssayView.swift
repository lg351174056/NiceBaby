import SwiftUI

// MARK: - 导航类型

enum EssayNavTarget: Hashable {
    case list
}

// MARK: - 作文数据

struct Essay: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let content: String
}

enum EssayStore {
    static let gradeNames = ["一年级", "二年级", "三年级", "四年级", "五年级", "六年级"]

    static func load(grade: String) -> [Essay] {
        guard let url = Bundle.main.url(forResource: "\(grade)作文", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let arr = try? JSONDecoder().decode([[String: String]].self, from: data) else {
            return []
        }
        return arr.compactMap { dict in
            guard let title = dict["title"], let content = dict["content"] else { return nil }
            return Essay(title: title, content: content)
        }
    }
}

// MARK: - 作文列表页

struct EssayListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var grade = "三年级"
    @State private var essays: [Essay] = []
    @State private var selectedEssay: Essay?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 255/255, green: 248/255, blue: 235/255),
                    Color(red: 255/255, green: 253/255, blue: 246/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                gradeSelector
                essayList
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { essays = EssayStore.load(grade: grade) }
        .onChange(of: grade) { _, _ in essays = EssayStore.load(grade: grade) }
        .fullScreenCover(item: $selectedEssay) { essay in
            EssayReaderView(essay: essay)
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.8)))
            }
            .buttonStyle(.plain)
            Spacer()
            VStack(spacing: 2) {
                Text("小学作文精选")
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Text("\(essays.count) 篇范文")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var gradeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EssayStore.gradeNames, id: \.self) { g in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { grade = g }
                    } label: {
                        Text(g)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(grade == g ? .white : Color(red: 130/255, green: 100/255, blue: 50/255))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(grade == g
                                        ? AnyShapeStyle(LinearGradient(colors: [
                                            Color(red: 245/255, green: 190/255, blue: 90/255),
                                            Color(red: 220/255, green: 150/255, blue: 50/255)
                                        ], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        : AnyShapeStyle(Color.white.opacity(0.9)))
                                    .overlay(
                                        Capsule().strokeBorder(
                                            grade == g
                                                ? Color(red: 200/255, green: 140/255, blue: 30/255)
                                                : Color(red: 200/255, green: 170/255, blue: 120/255).opacity(0.4),
                                            lineWidth: 2)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    private var essayList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(essays) { essay in
                    Button { selectedEssay = essay } label: {
                        essayCard(essay)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    private func essayCard(_ essay: Essay) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(essay.title)
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .lineLimit(1)
                Spacer()
                Text("\(essay.content.count) 字")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 180/255, green: 150/255, blue: 90/255))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(Color(red: 255/255, green: 243/255, blue: 214/255))
                    )
            }
            Text(essay.content.prefix(60) + "…")
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundStyle(Color(red: 100/255, green: 100/255, blue: 100/255))
                .lineLimit(2)
                .lineSpacing(3)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(red: 200/255, green: 180/255, blue: 130/255).opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color(red: 150/255, green: 120/255, blue: 60/255).opacity(0.06), radius: 6, y: 3)
        )
    }
}

// MARK: - 作文阅读页

struct EssayReaderView: View {
    let essay: Essay
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 255/255, green: 253/255, blue: 246/255).ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部栏
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(red: 100/255, green: 100/255, blue: 100/255))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(red: 240/255, green: 238/255, blue: 230/255)))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("\(essay.content.count) 字")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 160/255, green: 140/255, blue: 90/255))
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(essay.title)
                            .font(.system(size: 22, weight: .heavy, design: .serif))
                            .foregroundStyle(Color(red: 40/255, green: 40/255, blue: 40/255))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)

                        Rectangle()
                            .fill(Color(red: 200/255, green: 180/255, blue: 130/255).opacity(0.4))
                            .frame(height: 1)
                            .padding(.horizontal, 20)

                        Text(essay.content)
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .foregroundStyle(Color(red: 50/255, green: 50/255, blue: 50/255))
                            .lineSpacing(10)
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 60)
                }
            }
        }
    }
}
