import SwiftUI

// MARK: - Model（带释义）

struct SanzijingLine: Codable, Hashable {
    let text: String
    let explain: String
}

struct SanzijingPart: Codable, Hashable {
    let part: String
    let lines: [SanzijingLine]
}

// MARK: - View（书野营地竹青风 · 部分切换 + 释义）

struct SanzijingView: View {
    let onExit: () -> Void
    @State private var parts: [SanzijingPart] = []
    @State private var selectedIndex = 0
    @State private var isLoading = true

    private var totalLines: Int {
        parts.reduce(0) { $0 + $1.lines.count }
    }

    var body: some View {
        ZStack {
            // 蓝天草地背景（固定）
            FieldBackground()

            bambooSun
            bambooCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            bambooCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
                // 透明导航条
                ZStack {
                    HStack {
                        GracefulBackButton(action: onExit)
                        Spacer()
                    }
                    Text("三字经")
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                if isLoading {
                    ProgressView()
                        .controlSize(.large)
                        .tint(AppTheme.fieldMint)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if parts.isEmpty {
                    Text("数据加载失败")
                        .foregroundStyle(AppTheme.fieldMoss)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    heroHeader
                    partSelector
                    bambooScroll
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .onAppear {
            loadData()
        }
    }

    // 主题头（📖 竹青）
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
                Text("📖")
                    .font(.system(size: 24))
                    .modifier(FieldBob(delay: 0.3))
            }
            .frame(width: 52, height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.fieldMint.opacity(0.4), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("三字经")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                Text("人之初，性本善 · 蒙学第一书")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.fieldMoss)
                HStack(spacing: 12) {
                    Text("📚 \(parts.count) 部分")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMint)
                    Text("✨ \(totalLines) 段 · 全带释义")
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
        .padding(.top, 10)
    }

    // 部分切换 chips
    private var partSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    let short = shortTitle(part.part)
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedIndex = index
                        }
                    } label: {
                        Text(short)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(selectedIndex == index ? .white : AppTheme.fieldOliveDeep)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(selectedIndex == index
                                        ? AppTheme.fieldMint
                                        : Color.white.opacity(0.85))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(
                                        selectedIndex == index ? AppTheme.fieldInk
                                            : AppTheme.fieldOlive.opacity(0.35),
                                        lineWidth: 2
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

    private func shortTitle(_ full: String) -> String {
        if let sep = full.firstIndex(of: "·") {
            return String(full[full.index(after: sep)...]).trimmingCharacters(in: .whitespaces)
        }
        return full
    }

    // 竹简阅读卡（当前部分）
    private var bambooScroll: some View {
        let part = parts[selectedIndex]
        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // 部分标题 + 分隔
                VStack(spacing: 6) {
                    Text(part.part)
                        .font(.system(size: 20, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                        .tracking(1)
                    Text("共 \(part.lines.count) 段")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, AppTheme.fieldMint.opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 1.5)
                        Text("· 竹简开卷 ·")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(AppTheme.fieldMint)
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, AppTheme.fieldMint.opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 1.5)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)

                // 逐句竹简卡（原文 + 释义）
                VStack(spacing: 10) {
                    ForEach(Array(part.lines.enumerated()), id: \.offset) { index, line in
                        slatCard(index: index, line: line)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 6)

                Text("本部分已全部展示 ✓")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 168/255, green: 184/255, blue: 154/255))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 18)
        }
    }

    private func slatCard(index: Int, line: SanzijingLine) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(
                        LinearGradient(colors: [
                            Color(red: 126/255, green: 211/255, blue: 160/255),
                            AppTheme.fieldMint
                        ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle()
                    )
                    .overlay(Circle().strokeBorder(AppTheme.fieldInk, lineWidth: 2))
                    .shadow(color: AppTheme.fieldMint.opacity(0.35), radius: 4, y: 2)

                Text(line.text)
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.fieldInk)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 释义
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.fieldGold)
                    .padding(.top, 2)
                Text(line.explain)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 85/255, green: 112/255, blue: 95/255))
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 255/255, green: 250/255, blue: 238/255).opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color(red: 217/255, green: 164/255, blue: 91/255).opacity(0.35), lineWidth: 1.5)
                    )
            )
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(colors: [Color(red: 246/255, green: 249/255, blue: 240/255), Color(red: 237/255, green: 244/255, blue: 228/255)],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 1.5)
                )
        )
    }

    // MARK: - 背景装饰（太阳/云）

    private var bambooSun: some View {
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

    private func bambooCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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

    private func loadData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let loaded: [SanzijingPart] = {
                if let url = Bundle.main.url(forResource: "三字经-释义", withExtension: "json"),
                   let data = try? Data(contentsOf: url),
                   let arr = try? JSONDecoder().decode([SanzijingPart].self, from: data) {
                    return arr
                }
                return []
            }()
            DispatchQueue.main.async {
                self.parts = loaded
                self.isLoading = false
            }
        }
    }
}
