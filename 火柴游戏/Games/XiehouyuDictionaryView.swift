import SwiftUI
import Combine

// MARK: - Model

struct Xiehouyu: Codable, Identifiable, Hashable {
    let riddle: String
    let answer: String
    
    var id: String { riddle + answer }
}

// MARK: - ViewModel

@MainActor
final class XiehouyuViewModel: ObservableObject {
    @Published var allItems: [Xiehouyu] = []
    
    // 盲盒游戏状态
    @Published var challengeDeck: [Xiehouyu] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading = true
    
    // 搜索词典状态
    @Published var filteredItems: [Xiehouyu] = []
    @Published var searchQuery: String = ""
    @Published var isShowingDictionary = false
    
    private var cancellables: Set<AnyCancellable> = []
    let challengeSize = 10
    
    init() {
        $searchQuery
            .removeDuplicates()
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyFilter() }
            .store(in: &cancellables)
    }
    
    func loadData() {
        guard isLoading else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            guard let url = Bundle.main.url(forResource: "歇后语", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let raw = try? JSONDecoder().decode([Xiehouyu].self, from: data) else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            
            DispatchQueue.main.async {
                self.allItems = raw
                self.startNewChallenge()
                self.applyFilter()
                self.isLoading = false
            }
        }
    }
    
    func startNewChallenge() {
        guard !allItems.isEmpty else { return }
        challengeDeck = Array(allItems.shuffled().prefix(challengeSize))
        currentIndex = 0
    }
    
    private func applyFilter() {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            filteredItems = []
        } else {
            filteredItems = Array(allItems.filter {
                $0.riddle.contains(trimmed) || $0.answer.contains(trimmed)
            }.prefix(100)) // 限制最多展示 100 条保证性能
        }
    }
    
    var totalCount: Int { allItems.count }
}

// MARK: - Main View

struct XiehouyuDictionaryView: View {
    let onExit: () -> Void
    @StateObject private var viewModel = XiehouyuViewModel()
    
    private let kind: GameKind = .xiehouyuDictionary
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
            // 自定义 TopBar，带右上角字典入口
            GameTopBar(
                title: "盲盒歇后语",
                progressText: progressText,
                palette: kind.palette,
                onExit: onExit,
                trailing: AnyView(
                    Button(action: {
                        viewModel.isShowingDictionary = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(kind.palette.0)
                            .padding(10)
                            .background(kind.palette.0.opacity(0.15), in: Circle())
                    }
                )
            )
                
                Spacer()
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().controlSize(.large)
                    Spacer()
                } else if !viewModel.challengeDeck.isEmpty {
                    TabView(selection: $viewModel.currentIndex) {
                        ForEach(Array(viewModel.challengeDeck.enumerated()), id: \.element.id) { index, item in
                            XiehouyuCard(item: item)
                                .tag(index)
                        }
                        
                        // 最后一页：挑战完成
                        ChallengeCompleteView(onRestart: {
                            viewModel.startNewChallenge()
                        })
                        .tag(viewModel.challengeDeck.count)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                } else {
                    Spacer()
                }
            }
        }
        .onAppear { viewModel.loadData() }
        .sheet(isPresented: $viewModel.isShowingDictionary) {
            XiehouyuSearchSheet(viewModel: viewModel)
        }
    }
    
    private var progressText: String {
        if viewModel.isLoading { return "准备盲盒中..." }
        if viewModel.currentIndex == viewModel.challengeDeck.count { return "挑战完成！" }
        return "进度：\(viewModel.currentIndex + 1) / \(viewModel.challengeDeck.count)"
    }
}

// MARK: - Card Component

struct XiehouyuCard: View {
    let item: Xiehouyu
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.orange.opacity(0.8))
            
            Text(item.riddle)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 20)
            
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(Color.gray.opacity(0.2))
                .padding(.vertical, 8)
            
            Text(item.answer)
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.red)
                .padding(.horizontal, 20)
            
            Spacer()
            
            Text("左右滑动切换")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: Color.orange.opacity(0.15), radius: 20, x: 0, y: 15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
        )
        .padding(30)
    }
}

// MARK: - Challenge Complete View

struct ChallengeCompleteView: View {
    let onRestart: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
            
            Text("今日歇后语大师！")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            
            Text("你又掌握了 10 个幽默的歇后语")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.textSecondary)
            
            Button(action: onRestart) {
                Text("再来一组")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 56)
                    .background(Color.orange.gradient, in: Capsule())
                    .shadow(color: .orange.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.top, 20)
        }
    }
}

// MARK: - Dictionary Search Sheet

struct XiehouyuSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: XiehouyuViewModel
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索框
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("输入关键字搜索全部歇后语...", text: $viewModel.searchQuery)
                        .focused($isFocused)
                        .submitLabel(.search)
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: { viewModel.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(uiColor: .systemGray6), in: RoundedRectangle(cornerRadius: 12))
                .padding()
                
                if viewModel.searchQuery.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.orange.opacity(0.3))
                        Text("共收录 \(viewModel.totalCount) 条歇后语")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredItems.isEmpty {
                    Text("没有找到相关结果")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.filteredItems) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.riddle)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                            Text("👉 \(item.answer)")
                                .font(.system(size: 16))
                                .foregroundStyle(.orange)
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("歇后语大辞典")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}