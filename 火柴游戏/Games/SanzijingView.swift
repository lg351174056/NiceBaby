import SwiftUI

// MARK: - Model

struct SanzijingItem: Codable {
    let title: String
    let author: String
    let notes: [String]?
    let paragraphs: [String]
}

// MARK: - View

struct SanzijingView: View {
    let onExit: () -> Void
    @State private var item: SanzijingItem?
    @State private var isLoading = true
    
    private let kind: GameKind = .sanzijing
    
    var body: some View {
        VStack(spacing: 0) {
            GameTopBar(
                title: kind.title,
                progressText: item?.author ?? "加载中...",
                palette: kind.palette,
                onExit: onExit
            )
            
            if isLoading {
                ProgressView().controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let item = item {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Title & Author
                        VStack(spacing: 8) {
                            Text(item.title)
                                .font(.system(size: 28, weight: .heavy, design: .serif))
                                .foregroundStyle(AppTheme.textPrimary)
                            
                            Text("[\(item.author)]")
                                .font(.system(size: 16, weight: .medium, design: .serif))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.top, 24)
                        
                        // Paragraphs
                        VStack(spacing: 16) {
                            ForEach(Array(item.paragraphs.enumerated()), id: \.offset) { _, para in
                                Text(para)
                                    .font(.system(size: 22, weight: .semibold, design: .serif))
                                    .lineSpacing(8)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(AppTheme.textPrimary.opacity(0.9))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                Text("数据加载失败")
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = Bundle.main.url(forResource: "三字经 - 新版", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let items = try? JSONDecoder().decode([SanzijingItem].self, from: data),
                  let first = items.first else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            
            DispatchQueue.main.async {
                self.item = first
                self.isLoading = false
            }
        }
    }
}