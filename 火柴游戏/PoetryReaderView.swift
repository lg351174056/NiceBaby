import SwiftUI

struct PoetryReaderView: View {
    let poem: Poem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var speechService: PoemSpeechService
    @State private var bgImageName: String = ""
    
    init(poem: Poem) {
        self.poem = poem
        _bgImageName = State(initialValue: "bg_poetry_\(String(format: "%03d", Int.random(in: 1...113)))")
    }
    
    var body: some View {
        ZStack {
            // 背景图与毛玻璃效果
            if let uiImage = UIImage(named: bgImageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .overlay(.black.opacity(0.4))
                    .overlay(.ultraThinMaterial.opacity(0.8))
            } else {
                AppTheme.background.ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // 顶部导航
                HStack {
                    Button {
                        speechService.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(.horizontal, AppTheme.paddingScreen)
                .padding(.top, 16)
                
                Spacer()
                
                // 诗词内容
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Text(poem.title)
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("\(poem.type) · \(poem.author)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        VStack(spacing: 16) {
                            ForEach(poem.contents.components(separatedBy: "\n"), id: \.self) { line in
                                if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text(line)
                                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .lineSpacing(8)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 40)
                }
                
                Spacer()
                
                // 底部果冻播放按钮
                Button {
                    speechService.toggleSpeak(poem: poem)
                } label: {
                    ZStack {
                        if speechService.activePoemId == poem.id {
                            Circle()
                                .fill(AppTheme.accentBlue.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .scaleEffect(1.2)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: speechService.activePoemId == poem.id)
                        }
                        
                        Circle()
                            .fill(AppTheme.accentBlue)
                            .frame(width: 64, height: 64)
                            .shadow(color: AppTheme.accentBlue.opacity(0.5), radius: 10, y: 5)
                        
                        Image(systemName: speechService.activePoemId == poem.id ? "stop.fill" : "play.fill")
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
        }
    }
}
