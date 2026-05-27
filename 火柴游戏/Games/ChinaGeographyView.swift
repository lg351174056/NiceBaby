import SwiftUI
import Combine

// MARK: - Models

struct GeoFeatureCollection: Decodable {
    let features: [GeoFeature]
}

struct GeoFeature: Decodable, Identifiable {
    var id: String { properties.id ?? properties.name }
    let properties: GeoProperties
    let geometry: GeoGeometry
}

struct GeoProperties: Decodable {
    let id: String?
    let name: String
    let cp: [Double]?
    let childNum: Int?
}

struct GeoPolygon: Decodable {
    let rings: [[[Double]]]
}

struct GeoGeometry: Decodable {
    let type: String
    let polygons: [GeoPolygon]
    
    enum CodingKeys: String, CodingKey {
        case type, coordinates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        
        if type == "Polygon" {
            let coords = try container.decode([[[Double]]].self, forKey: .coordinates)
            self.polygons = [GeoPolygon(rings: coords)]
        } else if type == "MultiPolygon" {
            let coords = try container.decode([[[[Double]]]].self, forKey: .coordinates)
            self.polygons = coords.map { GeoPolygon(rings: $0) }
        } else {
            self.polygons = []
        }
    }
}

// MARK: - Map Engine

class ChinaMapEngine: ObservableObject {
    @Published var features: [GeoFeature] = []
    @Published var isLoading = true
    
    var minLon: Double = 180
    var maxLon: Double = -180
    var minLat: Double = 90
    var maxLat: Double = -90
    
    init() {
        loadData()
    }
    
    func loadData() {
        DispatchQueue.global(qos: .userInitiated).async {
            var targetURL: URL? = nil
            
            // 1. 先尝试直接从根目录或常见相对路径获取
            if let url = Bundle.main.url(forResource: "china", withExtension: "json") {
                targetURL = url
            } else if let url = Bundle.main.url(forResource: "china", withExtension: "json", subdirectory: "JSON/China") {
                targetURL = url
            } else if let url = Bundle.main.url(forResource: "china", withExtension: "json", subdirectory: "Datas/JSON/China") {
                targetURL = url
            } else if let resourceURL = Bundle.main.resourceURL {
                // 2. 如果常规路径没找到，使用深度遍历寻找 china.json
                let fm = FileManager.default
                if let enumerator = fm.enumerator(at: resourceURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                    for case let fileURL as URL in enumerator {
                        if fileURL.lastPathComponent == "china.json" {
                            targetURL = fileURL
                            break
                        }
                    }
                }
            }
            
            guard let url = targetURL, let data = try? Data(contentsOf: url) else {
                print("未找到 china.json 文件或加载失败。请确保 china.json 已经被添加到了 Xcode 的 Target Membership (Copy Bundle Resources) 中。")
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            
            do {
                let collection = try JSONDecoder().decode(GeoFeatureCollection.self, from: data)
                
                var localMinLon: Double = 180
                var localMaxLon: Double = -180
                var localMinLat: Double = 90
                var localMaxLat: Double = -90
                
                for feature in collection.features {
                    for polygon in feature.geometry.polygons {
                        for ring in polygon.rings {
                            for coord in ring {
                                if coord.count >= 2 {
                                    let lon = coord[0]
                                    let lat = coord[1]
                                    localMinLon = min(localMinLon, lon)
                                    localMaxLon = max(localMaxLon, lon)
                                    localMinLat = min(localMinLat, lat)
                                    localMaxLat = max(localMaxLat, lat)
                                }
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.minLon = localMinLon
                    self.maxLon = localMaxLon
                    self.minLat = localMinLat
                    self.maxLat = localMaxLat
                    self.features = collection.features
                    self.isLoading = false
                }
            } catch {
                print("GeoJSON Decode Error: \(error)")
                DispatchQueue.main.async { self.isLoading = false }
            }
        }
    }
    
    func getTransform(in rect: CGRect) -> (scale: CGFloat, offsetX: CGFloat, offsetY: CGFloat, avgLat: Double) {
        let lonRange = maxLon - minLon
        let latRange = maxLat - minLat
        
        let avgLat = (minLat + maxLat) / 2.0 * .pi / 180.0
        let aspectRatio = (lonRange * cos(avgLat)) / latRange
        
        let rectAspect = rect.width / rect.height
        
        var scale: CGFloat
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        
        let padding: CGFloat = 20
        let availableRect = rect.insetBy(dx: padding, dy: padding)
        
        if rectAspect > aspectRatio {
            scale = availableRect.height / CGFloat(latRange)
            let drawnWidth = CGFloat(lonRange) * scale * CGFloat(cos(avgLat))
            offsetX = (rect.width - drawnWidth) / 2.0
            offsetY = padding
        } else {
            scale = availableRect.width / (CGFloat(lonRange) * CGFloat(cos(avgLat)))
            let drawnHeight = CGFloat(latRange) * scale
            offsetX = padding
            offsetY = (rect.height - drawnHeight) / 2.0
        }
        return (scale, offsetX, offsetY, avgLat)
    }
    
    func createPath(for feature: GeoFeature, in rect: CGRect) -> Path {
        var path = Path()
        let t = getTransform(in: rect)
        
        for polygon in feature.geometry.polygons {
            for (index, ring) in polygon.rings.enumerated() {
                var ringPath = Path()
                for (i, coord) in ring.enumerated() {
                    if coord.count >= 2 {
                        let lon = coord[0]
                        let lat = coord[1]
                        
                        let x = CGFloat(lon - minLon) * t.scale * CGFloat(cos(t.avgLat)) + t.offsetX
                        let y = rect.height - (CGFloat(lat - minLat) * t.scale + t.offsetY)
                        
                        let point = CGPoint(x: x, y: y)
                        if i == 0 {
                            ringPath.move(to: point)
                        } else {
                            ringPath.addLine(to: point)
                        }
                    }
                }
                ringPath.closeSubpath()
                path.addPath(ringPath)
            }
        }
        
        return path
    }
    
    func project(lon: Double, lat: Double, in rect: CGRect) -> CGPoint {
        let t = getTransform(in: rect)
        let x = CGFloat(lon - minLon) * t.scale * CGFloat(cos(t.avgLat)) + t.offsetX
        let y = rect.height - (CGFloat(lat - minLat) * t.scale + t.offsetY)
        return CGPoint(x: x, y: y)
    }
}

// MARK: - View

struct ChinaGeographyView: View {
    @StateObject private var engine = ChinaMapEngine()
    @Environment(\.dismiss) private var dismiss
    
    // 交互状态 - 图鉴模式
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var finalOffset: CGSize = .zero
    @State private var selectedProvince: GeoFeature? = nil
    
    // 拼图模式状态
    @State private var isPuzzleMode: Bool = false
    @State private var puzzleQueue: [GeoFeature] = []
    @State private var placedProvinces: Set<String> = []
    @State private var wrongProvinceId: String? = nil
    @State private var mapRect: CGRect = .zero
    
    // 胜利状态
    @State private var showVictory: Bool = false
    
    private let oceanColor = Color(red: 224/255, green: 242/255, blue: 254/255)
    
    var body: some View {
        GeometryReader { windowGeo in
            let isLandscape = windowGeo.size.width > windowGeo.size.height
            let width = isLandscape ? windowGeo.size.width : windowGeo.size.height
            let height = isLandscape ? windowGeo.size.height : windowGeo.size.width
            
            mainContent(width: width, height: height)
                .frame(width: width, height: height)
                .rotationEffect(.degrees(isLandscape ? 0 : 90))
                .position(x: windowGeo.size.width / 2, y: windowGeo.size.height / 2)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
    }
    
    private func mainContent(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            oceanColor.ignoresSafeArea()
            
            if engine.isLoading {
                VStack(spacing: 16) {
                    ProgressView().scaleEffect(1.5)
                    Text("正在生成中国地图...")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            } else {
                VStack(spacing: 0) {
                    topBar
                    
                    GeometryReader { geo in
                        ZStack {
                            ForEach(Array(engine.features.enumerated()), id: \.element.id) { index, feature in
                                let path = engine.createPath(for: feature, in: geo.frame(in: .local))
                                let isSelected = selectedProvince?.id == feature.id
                                let isPlaced = !isPuzzleMode || placedProvinces.contains(feature.id)
                                let isWrong = wrongProvinceId == feature.id
                                
                                let baseColor = Color.macaronColors[index % Color.macaronColors.count]
                                let fillColor = isWrong ? Color.red.opacity(0.8) : baseColor
                                
                                if isPlaced {
                                    path
                                        .fill(fillColor, style: FillStyle(eoFill: true))
                                        .shadow(color: .black.opacity(isSelected ? 0.3 : 0.08), radius: isSelected ? 8 : 2, x: 0, y: isSelected ? 4 : 2)
                                        .overlay(
                                            path.stroke(Color.white, lineWidth: isSelected ? 2.5 : 0.8)
                                        )
                                        .scaleEffect(isSelected ? 1.03 : 1.0)
                                        .zIndex(isSelected ? 1 : 0)
                                        .onTapGesture {
                                            handleTap(feature: feature)
                                        }
                                } else {
                                    path
                                        .fill(isWrong ? Color.red.opacity(0.5) : Color.white.opacity(0.4), style: FillStyle(eoFill: true))
                                        .overlay(
                                            path.stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                        )
                                        .zIndex(0)
                                        .onTapGesture {
                                            handleTap(feature: feature)
                                        }
                                }
                            }
                        }
                        .scaleEffect(finalScale * currentScale)
                        .offset(x: finalOffset.width + currentOffset.width,
                                y: finalOffset.height + currentOffset.height)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { val in currentScale = val }
                                .onEnded { val in
                                    finalScale *= val
                                    currentScale = 1.0
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { val in currentOffset = val.translation }
                                .onEnded { val in
                                    finalOffset.width += val.translation.width
                                    finalOffset.height += val.translation.height
                                    currentOffset = .zero
                                }
                        )
                    }
                    .coordinateSpace(name: "MapSpace")
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                }
            }
            
            // Center prompts
            if !engine.isLoading {
                if !isPuzzleMode, let p = selectedProvince {
                    atlasPrompt(for: p)
                }
                
                if isPuzzleMode, let target = puzzleQueue.first {
                    puzzlePrompt(for: target)
                }
            }
            
            if showVictory {
                victoryOverlay
            }
        }
    }
    
    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("返回")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.white, in: Capsule())
                .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
                .foregroundStyle(AppTheme.textPrimary)
            }
            
            Spacer()
            
            HStack(spacing: 0) {
                ModeButton(title: "图鉴", icon: "map.fill", isSelected: !isPuzzleMode) {
                    withAnimation(.spring()) {
                        isPuzzleMode = false
                        selectedProvince = nil
                    }
                }
                ModeButton(title: "拼图", icon: "puzzlepiece.fill", isSelected: isPuzzleMode) {
                    startPuzzle()
                }
            }
            .background(Color.white.opacity(0.6), in: Capsule())
            .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
            
            Spacer()
            
            if isPuzzleMode {
                Text("进度: \(placedProvinces.count) / \(engine.features.count)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.white, in: Capsule())
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
            } else {
                Color.clear.frame(width: 100, height: 40)
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 24)
        .padding(.bottom, 8)
        .zIndex(10)
    }
    
    private func atlasPrompt(for p: GeoFeature) -> some View {
        VStack {
            Spacer()
            Text(p.properties.name)
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.accentBlue)
                .padding(.horizontal, 48)
                .padding(.vertical, 24)
                .background(Color.white.opacity(0.95), in: Capsule())
                .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                .transition(.scale.combined(with: .opacity))
            Spacer()
        }
        .zIndex(50)
        .allowsHitTesting(false)
    }
    
    private func puzzlePrompt(for target: GeoFeature) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 28))
                Text("请找出并点击：\(target.properties.name)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(AppTheme.accentMint.opacity(0.95), in: Capsule())
            .shadow(color: AppTheme.accentMint.opacity(0.4), radius: 15, y: 8)
            .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .bottom)))
            
            Spacer().frame(height: 40)
        }
        .zIndex(50)
        .allowsHitTesting(false)
    }
    
    private var victoryOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("🎉 拼图完成！")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 10)
                
                Button {
                    withAnimation {
                        showVictory = false
                        isPuzzleMode = false
                    }
                } label: {
                    Text("太棒了")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.accentBlue)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 20)
                        .background(Color.white, in: Capsule())
                }
            }
        }
        .zIndex(1000)
    }
    
    // MARK: - Logic
    
    private func handleTap(feature: GeoFeature) {
        if isPuzzleMode {
            if let target = puzzleQueue.first {
                if feature.id == target.id {
                    snapSuccess(target: target)
                } else {
                    showWrong(feature: feature)
                }
            }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                if selectedProvince?.id == feature.id {
                    selectedProvince = nil
                } else {
                    selectedProvince = feature
                }
            }
        }
    }
    
    private func showWrong(feature: GeoFeature) {
        withAnimation(.easeInOut(duration: 0.1)) {
            wrongProvinceId = feature.id
        }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.2)) {
                if wrongProvinceId == feature.id {
                    wrongProvinceId = nil
                }
            }
        }
    }
    
    private func startPuzzle() {
        withAnimation(.spring()) {
            isPuzzleMode = true
            selectedProvince = nil
            currentScale = 1.0
            finalScale = 1.0
            currentOffset = .zero
            finalOffset = .zero
            wrongProvinceId = nil
            
            puzzleQueue = engine.features.shuffled()
            placedProvinces.removeAll()
        }
    }
    
    private func snapSuccess(target: GeoFeature) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            placedProvinces.insert(target.id)
            if !puzzleQueue.isEmpty {
                puzzleQueue.removeFirst()
            }
            
            if puzzleQueue.isEmpty {
                showVictory = true
            }
        }
    }
}

private struct ModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(isSelected ? AppTheme.accentBlue : Color.clear, in: Capsule())
        }
    }
}

// MARK: - Macaron Colors Extension

extension Color {
    static let macaronColors: [Color] = [
        Color(red: 255/255, green: 183/255, blue: 178/255), // Pastel Pink
        Color(red: 255/255, green: 218/255, blue: 185/255), // Peach
        Color(red: 226/255, green: 240/255, blue: 203/255), // Mint
        Color(red: 181/255, green: 234/255, blue: 215/255), // Aqua
        Color(red: 199/255, green: 206/255, blue: 234/255), // Periwinkle
        Color(red: 255/255, green: 204/255, blue: 229/255), // Light Pink
        Color(red: 255/255, green: 238/255, blue: 147/255), // Light Yellow
        Color(red: 160/255, green: 232/255, blue: 175/255), // Light Green
        Color(red: 250/255, green: 208/255, blue: 201/255), // Rose
        Color(red: 209/255, green: 232/255, blue: 226/255), // Pale Cyan
        Color(red: 255/255, green: 223/255, blue: 211/255), // Light Apricot
        Color(red: 212/255, green: 240/255, blue: 240/255)  // Ice Blue
    ]
}
