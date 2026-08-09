import SwiftUI
import AVKit

// MARK: - Navigation Target

enum XiaoxueBibeiNavTarget: Hashable {
    case home
}

// MARK: - 小学生必背古诗

struct XiaoxueBibeiView: View {
    @State private var poems: [BibeiPoem] = []
    @State private var selectedGrade: String?
    @State private var selectedPoem: BibeiPoem?

    private var grades: [String] {
        var seen: [String] = []
        for p in poems where !seen.contains(p.grade) { seen.append(p.grade) }
        return seen
    }

    private var filteredPoems: [BibeiPoem] {
        guard let g = selectedGrade else { return poems }
        return poems.filter { $0.grade == g }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 190/255, green: 227/255, blue: 245/255),
                    Color(red: 220/255, green: 242/255, blue: 220/255),
                    Color(red: 207/255, green: 235/255, blue: 196/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        GracefulBackButton()
                        Spacer()
                    }
                    Text("小学生必背")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 6)

                // 年级筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        gradeChip(nil, label: "全部")
                        ForEach(grades, id: \.self) { grade in
                            gradeChip(grade, label: grade)
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 10)

                // 列表
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredPoems) { poem in
                            Button { selectedPoem = poem } label: {
                                poemRow(poem)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedPoem) { poem in
            BibeiDetailSheet(poem: poem)
        }
        .onAppear { loadPoems() }
    }

    private func gradeChip(_ grade: String?, label: String) -> some View {
        let isSelected = (grade == nil && selectedGrade == nil) || (grade == selectedGrade)
        return Button {
            withAnimation(.easeOut(duration: 0.15)) { selectedGrade = grade }
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(isSelected ? .white : Color(red: 76/255, green: 175/255, blue: 125/255))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color(red: 76/255, green: 175/255, blue: 125/255) : Color.white.opacity(0.8), in: Capsule())
                .overlay(Capsule().strokeBorder(Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func poemRow(_ poem: BibeiPoem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 253/255, green: 240/255, blue: 220/255),
                            Color(red: 245/255, green: 220/255, blue: 180/255)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("📜")
                    .font(.system(size: 18))
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(poem.title)
                    .font(.system(size: 14, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                HStack(spacing: 8) {
                    Text(poem.grade)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                    if !poem.video.isEmpty {
                        Label("视频", systemImage: "play.rectangle.fill")
                            .font(.system(size: 8, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 232/255, green: 106/255, blue: 82/255))
                    }
                    if !poem.sounds.isEmpty {
                        Label("音频", systemImage: "speaker.wave.2.fill")
                            .font(.system(size: 8, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(red: 160/255, green: 160/255, blue: 152/255))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.25), lineWidth: 1.5))
        )
    }

    private func loadPoems() {
        guard poems.isEmpty else { return }
        guard let url = Bundle.main.url(forResource: "小学必背古诗", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let arr = try? JSONDecoder().decode([BibeiPoem].self, from: data) else { return }
        poems = arr
    }
}

// MARK: - 详情弹层（图片 + 音频 + 视频）

private struct BibeiDetailSheet: View {
    let poem: BibeiPoem
    @Environment(\.dismiss) private var dismiss
    @State private var isPlayingAudio = false
    @State private var audioPlayer: AVPlayer?
    @State private var showVideo = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(poem.title)
                        .font(.system(size: 26, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                            .frame(width: 30, height: 30)
                            .background(Color(red: 240/255, green: 238/255, blue: 232/255), in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                Text(poem.grade)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))

                // 配图
                if let picURL = poem.pics.first, let url = URL(string: picURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        case .failure:
                            Color(red: 240/255, green: 238/255, blue: 232/255)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        default:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                        }
                    }
                }

                // 操作按钮
                HStack(spacing: 12) {
                    if !poem.sounds.isEmpty {
                        Button {
                            toggleAudio()
                        } label: {
                            Label(isPlayingAudio ? "停止朗读" : "朗读", systemImage: isPlayingAudio ? "stop.circle.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(red: 76/255, green: 175/255, blue: 125/255), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    if !poem.video.isEmpty {
                        Button {
                            showVideo = true
                        } label: {
                            Label("看视频", systemImage: "play.rectangle.fill")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(red: 232/255, green: 106/255, blue: 82/255), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(22)
            .padding(.bottom, 30)
        }
        .background(Color(red: 247/255, green: 245/255, blue: 240/255).ignoresSafeArea())
        .fullScreenCover(isPresented: $showVideo) {
            BibeiVideoPlayer(urlString: poem.video)
        }
        .onDisappear {
            audioPlayer?.pause()
        }
    }

    private func toggleAudio() {
        if isPlayingAudio {
            audioPlayer?.pause()
            isPlayingAudio = false
        } else {
            guard let soundURL = poem.sounds.first, let url = URL(string: soundURL) else { return }
            let player = AVPlayer(url: url)
            audioPlayer = player
            player.play()
            isPlayingAudio = true
        }
    }
}

// MARK: - 视频播放器

private struct BibeiVideoPlayer: View {
    let urlString: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let url = URL(string: urlString) {
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            Button { dismiss() } label: {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.5))
                        .frame(width: 40, height: 40)
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.leading, 20)
            .padding(.top, 54)
        }
    }
}

// MARK: - 数据模型

struct BibeiPoem: Identifiable, Hashable, Decodable {
    var id: String { grade + title }
    let grade: String
    let title: String
    let pics: [String]
    let sounds: [String]
    let video: String
}
