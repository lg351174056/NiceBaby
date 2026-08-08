import SwiftUI

// MARK: - 小老师批改屋 · 四宫格入口

struct TeacherCorrectionHouseView: View {
    let onExit: () -> Void

    @State private var showChineseHomework = false

    var body: some View {
        ZStack {
            teacherBackground

            if showChineseHomework {
                ChineseHomeworkView(onExit: { showChineseHomework = false })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                houseContent
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.28), value: showChineseHomework)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var houseContent: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    GracefulBackButton(action: onExit)
                    Spacer()
                }
                Text("")
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    blackboard
                    levelCard

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        correctionCard(
                            icon: "📖",
                            title: "数学 · 批改作业",
                            subtitle: "等式判对错",
                            color: Color(red: 255/255, green: 227/255, blue: 239/255),
                            available: false
                        )
                        correctionCard(
                            icon: "✍️",
                            title: "语文 · 批改作业",
                            subtitle: "田字格找错别字",
                            color: Color(red: 231/255, green: 243/255, blue: 252/255),
                            available: true
                        )
                        correctionCard(
                            icon: "📋",
                            title: "数学 · 批改试卷",
                            subtitle: "一年级上册期末卷",
                            color: Color(red: 255/255, green: 240/255, blue: 216/255),
                            available: false
                        )
                        correctionCard(
                            icon: "🗒️",
                            title: "语文 · 批改试卷",
                            subtitle: "一年级上册期末卷",
                            color: Color(red: 239/255, green: 245/255, blue: 255/255),
                            available: false
                        )
                    }

                    Text("🌱 批改越仔细，小老师等级越高")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private var blackboard: some View {
        VStack(spacing: 5) {
            Text("欢迎小老师")
                .font(.system(size: 23, weight: .heavy, design: .serif))
                .foregroundStyle(Color(red: 247/255, green: 243/255, blue: 227/255))
            Text("拿起红笔，帮同学们批改作业吧")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.82))
            Text("⭐  ⭐  ⭐")
                .font(.system(size: 12))
                .foregroundStyle(Color(red: 255/255, green: 227/255, blue: 155/255))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 17)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 62/255, green: 107/255, blue: 92/255), Color(red: 47/255, green: 93/255, blue: 74/255)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color(red: 217/255, green: 164/255, blue: 91/255).opacity(0.75), lineWidth: 3)
                        .padding(7)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
        )
    }

    private var levelCard: some View {
        HStack(spacing: 10) {
            Text("🧑‍🏫")
                .font(.system(size: 25))
                .frame(width: 42, height: 42)
                .background(Color(red: 255/255, green: 233/255, blue: 200/255), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("实习老师")
                    .font(.system(size: 13, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Text("再批 3 本作业 · 升级助教")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                Capsule()
                    .fill(Color(red: 238/255, green: 245/255, blue: 230/255))
                    .frame(height: 7)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(LinearGradient(colors: [Color(red: 126/255, green: 211/255, blue: 160/255), Color(red: 76/255, green: 175/255, blue: 125/255)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 90, height: 7)
                    }
            }
            Spacer()
            VStack(spacing: 2) {
                Text("20")
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 245/255, green: 166/255, blue: 35/255))
                Text("批改积分")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
            }
        }
        .padding(11)
        .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2))
    }

    @ViewBuilder
    private func correctionCard(icon: String, title: String, subtitle: String, color: Color, available: Bool) -> some View {
        Button {
            if available { showChineseHomework = true }
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(icon).font(.system(size: 28))
                    Spacer()
                    if !available {
                        Text("即将开放")
                            .font(.system(size: 8, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(red: 168/255, green: 184/255, blue: 154/255), in: Capsule())
                    }
                }
                Text(title)
                    .font(.system(size: 13, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 124/255, green: 140/255, blue: 110/255))
                HStack {
                    Text(available ? "开始批改" : "敬请期待")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(available ? Color(red: 58/255, green: 119/255, blue: 176/255) : Color(red: 168/255, green: 184/255, blue: 154/255))
                    Spacer()
                    Text("›")
                        .foregroundStyle(Color(red: 160/255, green: 176/255, blue: 152/255))
                }
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(available ? 1 : 0.65), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(!available)
    }

    private var teacherBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 190/255, green: 227/255, blue: 245/255),
                Color(red: 220/255, green: 242/255, blue: 220/255),
                Color(red: 207/255, green: 235/255, blue: 196/255)
            ],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
