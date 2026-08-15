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
            // 蓝天草地背景（书野营地竹青风）
            FieldBackground()

            xhSun
            xhCloud(x: 0.02, y: 0.12, scale: 1.0, delay: 0)
            xhCloud(x: 0.72, y: 0.17, scale: 0.72, delay: 2.5)

            VStack(spacing: 0) {
            // 透明导航条（右上角字典入口）
            ZStack {
                HStack {
                    GracefulBackButton(action: onExit)
                    Spacer()
                    Button(action: {
                        viewModel.isShowingDictionary = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.fieldMint)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.9), in: Circle())
                            .overlay(Circle().strokeBorder(AppTheme.fieldMint.opacity(0.35), lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
                VStack(spacing: 2) {
                    Text("盲盒歇后语")
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                        .foregroundStyle(AppTheme.fieldInk)
                    Text(progressText)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.fieldMoss)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 6)
                
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
    

    // MARK: - 背景装饰（太阳/云）

    private var xhSun: some View {
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

    private func xhCloud(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
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
                .foregroundStyle(AppTheme.fieldMint)
            
            Text(item.riddle)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 20)
            
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(AppTheme.fieldMossLight.opacity(0.4))
                .padding(.vertical, 8)
            
            Text(item.answer)
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 232/255, green: 100/255, blue: 82/255))
                .padding(.horizontal, 20)
            
            Spacer()
            
            Text("左右滑动切换")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.12), radius: 14, y: 6)
        )
        .padding(26)
    }
}

// MARK: - Challenge Complete View

struct ChallengeCompleteView: View {
    let onRestart: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color(red: 245/255, green: 214/255, blue: 123/255))
            
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
                    .background(
                        LinearGradient(colors: [Color(red: 126/255, green: 211/255, blue: 160/255), AppTheme.fieldMint], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Capsule()
                    )
                    .overlay(Capsule().strokeBorder(AppTheme.fieldInk, lineWidth: 2))
                    .shadow(color: AppTheme.fieldMint.opacity(0.35), radius: 10, y: 5)
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
                .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppTheme.fieldMint.opacity(0.4), lineWidth: 2)
                )
                .padding()
                
                if viewModel.searchQuery.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(AppTheme.fieldMint.opacity(0.35))
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
                                .foregroundStyle(AppTheme.fieldMint)
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