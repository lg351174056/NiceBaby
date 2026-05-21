import SwiftUI

/// 旧版 PoetryListView 保留兼容（用于其他地方可能的引用）
/// 新版诗库导航已使用 PoetryPoemListView + PoetryDetailView
struct PoetryListView: View {
    let category: String
    let poems: [Poem]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPoem: Poem?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(poems) { poem in
                    Button {
                        selectedPoem = poem
                    } label: {
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(
                                    LinearGradient(colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
                                                   startPoint: .top, endPoint: .bottom)
                                )
                                .frame(width: 4, height: 36)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(poem.title)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(1)
                                Text(poem.author)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedPoem) { poem in
            PoetryReaderView(poem: poem)
                .environmentObject(PoemSpeechService.shared)
        }
    }
}
