import SwiftUI

struct PoetryListView: View {
    let category: String
    let poems: [Poem]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPoem: Poem?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(poems) { poem in
                        Button {
                            selectedPoem = poem
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(poem.title)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .lineLimit(1)
                                    
                                    Text(poem.author)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                            }
                            .padding()
                            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppTheme.paddingScreen)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(category)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
            .fullScreenCover(item: $selectedPoem) { poem in
                PoetryReaderView(poem: poem)
                    .environmentObject(PoemSpeechService.shared)
            }
        }
    }
}
