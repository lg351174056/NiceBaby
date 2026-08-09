import SwiftUI

// MARK: - 语文作业 · 田字格找错别字

// MARK: 易错字表（正确字 -> 错字 + 讲解）

enum ChineseCharConfusable {
    /// 正确字 -> (错字, 讲解)
    static let table: [Character: (Character, String)] = [
        "花": ("化", "花朵的“花”是草字头"),
        "园": ("圆", "公园的“园”外面是国字框"),
        "漂": ("飘", "飘落用风字旁的“飘”"),
        "蜜": ("密", "蜂蜜是虫字底的“蜜”"),
        "晨": ("辰", "早晨是日字头的“晨”"),
        "坐": ("做", "坐下是“坐”，做事的“做”带人旁"),
        "家": ("加", "家的宝盖头像屋顶"),
        "见": ("建", "看见的“见”没有走之底"),
        "玩": ("完", "玩的王字旁表示游戏"),
        "店": ("点", "书店的“店”是广字头"),
        "候": ("侯", "时候的“候”有一竖"),
        "晴": ("情", "晴天是日字旁的“晴”"),
        "蓝": ("兰", "蓝天的“蓝”是草字头"),
        "绿": ("录", "绿色的“绿”是绞丝旁"),
        "已": ("己", "“已”竖不封口，表示已经"),
        "未": ("末", "“未”上横短下横长，表示还没"),
        "在": ("再", "在哪里用“在”，再一次用“再”"),
        "做": ("作", "做事的“做”，作业的“作”"),
        "得": ("的", "跑得快用双人旁的“得”"),
        "地": ("的", "快乐地唱歌用土字旁的“地”"),
        "像": ("象", "好像的“像”有单人旁"),
        "近": ("进", "远近的“近”，进出的“进”"),
        "请": ("清", "请求用言字旁的“请”"),
        "鸟": ("乌", "小鸟的“鸟”有一点"),
        "兔": ("免", "兔子的“兔”有小尾巴一点"),
        "他": ("她", "男生用单人旁的“他”"),
        "她": ("他", "女生用女字旁的“她”"),
        "它": ("他", "小动物用“它”"),
        "妈": ("吗", "妈妈是女字旁的“妈”"),
        "吗": ("妈", "问句末尾用“吗”"),
        "时": ("是", "时候的“时”，对错的“是”"),
        "是": ("时", "“是”表示对，时间的“时”"),
        "太": ("大", "太阳的“太”多一点"),
        "大": ("太", "大小的“大”没有点"),
        "天": ("夫", "天上的“天”"),
        "人": ("入", "“人”撇捺分开，“入”撇低捺高"),
        "土": ("士", "“土”上横短下横长"),
        "王": ("玉", "玉石的“玉”多一点"),
        "日": ("目", "太阳是“日”，眼睛是“目”"),
        "目": ("日", "眼睛的“目”里面两横"),
        "本": ("木", "本子的“本”多一点"),
        "木": ("本", "树木的“木”没有点"),
        "午": ("牛", "中午的“午”，牛羊的“牛”"),
        "开": ("井", "打开的开，水井的井"),
        "无": ("元", "没有用“无”，一元钱的“元”"),
        "云": ("去", "白云的“云”，来去的“去”"),
        "白": ("百", "白色是“白”，一百是“百”"),
        "自": ("目", "自己的“自”多一撇"),
        "田": ("由", "田地的“田”，理由的“由”"),
        "果": ("过", "水果的“果”"),
        "过": ("果", "走过的“过”是走之底"),
        "常": ("长", "经常的“常”，长短的“长”"),
        "长": ("常", "长短的“长”"),
        "知": ("只", "知道的“知”有口"),
        "只": ("知", "“只”表示仅仅"),
        "声": ("生", "声音的“声”"),
        "生": ("声", "学生的“生”"),
        "干": ("千", "干活的“干”，一千的“千”"),
        "和": ("合", "和好的“和”是禾字旁"),
        "合": ("和", "合拢的“合”"),
        "可": ("河", "可以的“可”，小河的“河”"),
        "河": ("可", "河水是三点水的“河”"),
        "到": ("道", "到处的“到”，道路的“道”"),
        "道": ("到", "道理的“道”"),
        "从": ("丛", "从前的“从”，草丛的“丛”"),
        "丛": ("从", "草丛的“丛”"),
        "以": ("已", "可以、以为的“以”"),
        "打": ("大", "打球的“打”是提手旁"),
        "吹": ("吃", "吹风的“吹”是口字旁"),
        "吃": ("吹", "吃饭的“吃”是口字旁"),
        "叫": ("叶", "喊叫的“叫”是口字旁"),
        "叶": ("叫", "树叶的“叶”是口字旁"),
        "青": ("清", "青色的“青”"),
        "清": ("青", "清水的“清”三点水"),
        "情": ("晴", "心情的“情”是竖心旁"),
        "凉": ("晾", "凉快的“凉”是两点水"),
        "少": ("小", "多少的“少”，大小的“小”"),
        "小": ("少", "大小的小"),
        "毛": ("手", "毛茸茸的“毛”"),
        "手": ("毛", "小手的“手”"),
        "求": ("球", "雪球的“球”是王字旁"),
        "气": ("汽", "空气的“气”，汽水的“汽”"),
        "里": ("理", "心里的“里”"),
        "理": ("里", "道理的“理”是王字旁"),
        "听": ("厅", "听见的“听”是口字旁"),
        "立": ("力", "站立的“立”，力气的“力”"),
        "力": ("立", "力气的“力”"),
        "冬": ("东", "冬天的“冬”，东西的“东”"),
        "东": ("冬", "东方的“东”"),
        "风": ("丰", "刮风的“风”"),
        "成": ("诚", "成长、完成的“成”"),
        "会": ("回", "开会的“会”，回家的“回”"),
        "回": ("会", "回来的“回”"),
        "高": ("糕", "高高的“高”，蛋糕的“糕”"),
        "办": ("半", "办法的“办”，一半的“半”"),
        "半": ("办", "一半的“半”"),
        "岁": ("多", "几岁的“岁”"),
        "再": ("在", "再见的“再”"),
        "写": ("雪", "写字的“写”，雪花的“雪”"),
        "雪": ("写", "雪花的“雪”"),
        "荷": ("河", "荷叶的“荷”是草字头"),
        "鞠": ("居", "鞠躬的“鞠”，不是居住的“居”"),
        "顽": ("玩", "顽皮的“顽”是页字旁"),
        "着": ("这", "“着”表示动作进行，鞠着躬的“着”"),
    ]

    static func isHanzi(_ ch: Character) -> Bool {
        guard let s = ch.unicodeScalars.first else { return false }
        return s.value >= 0x4E00 && s.value <= 0x9FFF
    }

    static func isValidPunct(_ ch: Character) -> Bool {
        guard let s = ch.unicodeScalars.first else { return false }
        let v = s.value
        // 常见中文标点（跳过 0x3000 全角空格）
        if v >= 0x3001 && v <= 0x303F { return true }
        if v >= 0xFF01 && v <= 0xFF60 { return true }
        if v == 0x201C || v == 0x201D { return true }
        if v == 0x2018 || v == 0x2019 { return true }
        if v == 0x300A || v == 0x300B { return true }
        if v == 0x2026 || v == 0x2014 { return true }
        return false
    }
}

// MARK: - 数据模型

struct YwTextbook: Codable {
    let title: String
    let content: String
}

enum ChineseHomeworkStore {
    struct SourceGroup {
        let label: String
        let emoji: String
        let items: [String]
    }

    static var sourceGroups: [SourceGroup] {
        let bishenItems = BishenStore.loadAll().map { $0.name }
        return [
            SourceGroup(label: "课本课文", emoji: "📖", items: [
                "一年级上册", "一年级下册", "二年级上册", "二年级下册", "三年级上册", "三年级下册",
                "四年级上册", "四年级下册", "五年级上册", "五年级下册", "六年级上册", "六年级下册"
            ]),
            SourceGroup(label: "作文精选", emoji: "✍️", items: [
                "一年级作文", "二年级作文", "三年级作文", "四年级作文", "五年级作文", "六年级作文"
            ]),
            SourceGroup(label: "AI作文大全", emoji: "🤖", items: [
                "AI一年级", "AI二年级", "AI三年级", "AI四年级", "AI五年级", "AI六年级"
            ]),
            SourceGroup(label: "笔神精选", emoji: "🖋", items: bishenItems)
        ]
    }

    static let gradeNames: [String] = sourceGroups.flatMap { $0.items }

    static func loadTextbooks(grade: String) -> [YwTextbook] {
        // AI作文大全：从缓存加载
        if grade.hasPrefix("AI") {
            return loadAIZuowenTextbooks(grade: grade)
        }
        if let url = Bundle.main.url(forResource: grade, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let arr = try? JSONDecoder().decode([YwTextbook].self, from: data) {
            return arr
        }
        // 笔神精选：按子分类名取好句，拼成一篇文章
        if let sub = BishenStore.loadAll().first(where: { $0.name == grade }),
           !sub.lines.isEmpty {
            let content = sub.lines.map(\.content).joined(separator: "。")
            return [YwTextbook(title: sub.name, content: content)]
        }
        return []
    }

    /// 从 AI作文大全 API 同步加载（有本地缓存）
    private static func loadAIZuowenTextbooks(grade: String) -> [YwTextbook] {
        let apiGrade = grade.replacingOccurrences(of: "AI", with: "")
        let cacheKey = "ai_zuowen_v2_\(apiGrade)"

        // 清除旧版缓存
        UserDefaults.standard.removeObject(forKey: "ai_zuowen_cache_\(apiGrade)")

        // 尝试读缓存
        if let cached = UserDefaults.standard.data(forKey: cacheKey),
           let arr = try? JSONDecoder().decode([YwTextbook].self, from: cached),
           !arr.isEmpty {
            return arr
        }

        // 同步请求（首次加载）
        let urlStr = "http://newos.glassmarket.cn/index.php?main_page=zuowen_handler"
        guard let url = URL(string: urlStr) else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        let params = "actiontype=2&appname=AI作文大全&bid=zw&channel=zuowen&page=1&systemName=iOS&systemVersion=18.0&userid=568426&useridstr=8f5af5773cc44a20bd6d6cbbf8da6ba4&version=2.2.1&xx=\(apiGrade.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? apiGrade)"
        request.httpBody = params.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        guard let (data, _) = try? synchronousData(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let infos = json["infos"] as? [[String: Any]] else { return [] }

        let textbooks: [YwTextbook] = infos.compactMap { item in
            guard let title = item["title"] as? String,
                  let rawContent = item["content"] as? String,
                  !rawContent.isEmpty else { return nil }
            let content = Self.cleanAIZuowenContent(rawContent, title: title)
            guard !content.isEmpty else { return nil }
            return YwTextbook(title: title, content: content)
        }

        // 写入缓存
        if let encoded = try? JSONEncoder().encode(textbooks) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
        return textbooks
    }

    /// 清理 AI 作文 content：去掉开头的《标题》和"年级 | 体裁 | 字数"行，保留换行
    private static func cleanAIZuowenContent(_ raw: String, title: String) -> String {
        var content = raw
        // 去掉 《标题》\n
        if content.hasPrefix("《\(title)》") {
            content = String(content.dropFirst(title.count + 2))
        } else if content.hasPrefix(title) {
            content = String(content.dropFirst(title.count))
        }
        // 去掉紧随的换行
        while content.hasPrefix("\n") || content.hasPrefix("\r") {
            content = String(content.dropFirst())
        }
        // 去掉第二行的 "年级 | 体裁 | 字数"
        if let idx = content.firstIndex(where: { $0 == "\n" || $0 == "\r" }) {
            let firstLine = String(content[content.startIndex..<idx])
            if firstLine.contains("|") {
                content = String(content[content.index(after: idx)...])
            }
        }
        // 去掉末尾多余换行
        while content.hasSuffix("\n") || content.hasSuffix("\r") {
            content = String(content.dropLast())
        }
        return content
    }

    private static func synchronousData(for request: URLRequest) throws -> (Data, URLResponse) {
        var result: (Data, URLResponse)?
        var error: Error?
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { d, r, e in
            if let d, let r { result = (d, r) }
            error = e
            semaphore.signal()
        }.resume()
        semaphore.wait()
        if let result { return result }
        throw error ?? URLError(.unknown)
    }

    /// 错别字数量：最少 5 个，最多 30 个，随文章长度自适应
    static func wrongNeed(hanziCount: Int) -> Int {
        if hanziCount < 100 { return 5 }
        if hanziCount < 200 { return 8 }
        if hanziCount < 320 { return 12 }
        if hanziCount < 500 { return 18 }
        return min(30, 24 + (hanziCount - 500) / 150)
    }

    static func hanziCount(of text: String) -> Int {
        text.filter { ChineseCharConfusable.isHanzi($0) }.count
    }
}

// MARK: - 格子状态与 Token

enum TianCellState: Equatable {
    case normal
    case found
    case checked
    case hintFlash
}

struct TianToken: Identifiable {
    let id = UUID()
    let kind: Kind

    enum Kind {
        case indent
        case char(Character, isWrong: Bool, fix: Character, exp: String)
        case punct(Character)
        case blank
        case newline
    }

    var widthUnit: CGFloat {
        switch kind {
        case .indent: return 1
        case .char: return 1
        case .punct: return 1
        case .blank: return 1
        case .newline: return 0
        }
    }
}

/// 一局游戏的固定数据（生成一次，token id 稳定）
struct HomeworkSession {
    let textbook: YwTextbook
    let gradeName: String
    /// token index -> (错字, 正确字, 讲解)：只有被选中的位置才错
    let errorSpots: [Int: (wrong: Character, fix: Character, exp: String)]
    let totalWrong: Int
    let maxChances: Int
    let lines: [[TianToken]]
    let tokenIDs: [UUID: Int]
    let tokenByIndex: [Int: TianToken]

    init(textbook: YwTextbook, gradeName: String) {
        self.textbook = textbook
        self.gradeName = gradeName

        // 1. 构建全局 token 序列（只保留汉字+中文标点）
        var tokens: [TianToken] = []
        var posByChar: [Character: [Int]] = [:]
        for ch in textbook.content {
            if ch == "\n" {
                tokens.append(TianToken(kind: .newline))
            } else if ch == "\r" || ch == "\u{3000}" || ch == "\t" {
                // 跳过回车、全角空格（段首缩进由 newline 后自动添加）、制表符
                continue
            } else if ChineseCharConfusable.isHanzi(ch) {
                let token = TianToken(kind: .char(ch, isWrong: false, fix: ch, exp: ""))
                tokens.append(token)
                posByChar[ch, default: []].append(tokens.count - 1)
            } else if ChineseCharConfusable.isValidPunct(ch) {
                tokens.append(TianToken(kind: .punct(ch)))
            }
        }

        // 2. 严格选错：命中易错表的字 -> 随机抽 need 个 -> 每个字只错一处（随机位置）
        let han = ChineseHomeworkStore.hanziCount(of: textbook.content)
        let need = ChineseHomeworkStore.wrongNeed(hanziCount: han)
        let candidates = posByChar.keys
            .filter { ChineseCharConfusable.table[$0] != nil }
            .shuffled()
        let chosen = Array(candidates.prefix(max(2, min(need, candidates.count))))

        var spots: [Int: (wrong: Character, fix: Character, exp: String)] = [:]
        for ch in chosen {
            guard let pair = ChineseCharConfusable.table[ch],
                  let positions = posByChar[ch],
                  let pos = positions.randomElement() else { continue }
            spots[pos] = (pair.0, ch, pair.1)
        }

        // 3. 回填 token（仅错位标记 isWrong）
        for (i, t) in tokens.enumerated() {
            if let spot = spots[i], case .char(_, _, _, _) = t.kind {
                tokens[i] = TianToken(kind: .char(spot.wrong, isWrong: true, fix: spot.fix, exp: spot.exp))
            }
        }

        // 4. 按行宽拆行（一行 8 格），遇到换行标记强制断行
        var result: [[TianToken]] = []
        var line: [TianToken] = []
        var width: CGFloat = 0

        // 第一行：如果首个 token 不是换行，自动缩进两格
        if let first = tokens.first {
            if case .newline = first.kind { } else {
                line.append(TianToken(kind: .blank))
                line.append(TianToken(kind: .blank))
                width = 2
            }
        }

        for token in tokens {
            if case .newline = token.kind {
                if !line.isEmpty {
                    while line.count < 8 { line.append(TianToken(kind: .blank)) }
                    result.append(line)
                    line = []
                    width = 0
                }
                // 新段首空两格
                line.append(TianToken(kind: .blank))
                line.append(TianToken(kind: .blank))
                width = 2
                continue
            }
            if width + token.widthUnit > 8, !line.isEmpty {
                while line.count < 8 {
                    line.append(TianToken(kind: .blank))
                }
                result.append(line)
                line = []
                width = 0
            }
            line.append(token)
            width += token.widthUnit
        }
        if !line.isEmpty {
            while line.count < 8 {
                line.append(TianToken(kind: .blank))
            }
            result.append(line)
        }

        self.lines = result

        var ids: [UUID: Int] = [:]
        var byIndex: [Int: TianToken] = [:]
        var idx = 0
        for l in result {
            for token in l {
                ids[token.id] = idx
                byIndex[idx] = token
                idx += 1
            }
        }
        self.tokenIDs = ids
        self.tokenByIndex = byIndex
        self.errorSpots = spots
        self.totalWrong = spots.count
        self.maxChances = spots.count + 3
    }
}
import SwiftUI

// MARK: - 田字格单元格

struct TianGeCell: View {
    let char: Character
    let fix: Character?
    let state: TianCellState
    let onTap: () -> Void

    @State private var pop = false
    @State private var fixShow = false
    @State private var checkShow = false
    @State private var flash = false

    private let green = Color(red: 127/255, green: 168/255, blue: 78/255)
    private let greenDash = Color(red: 120/255, green: 160/255, blue: 70/255).opacity(0.45)

    var body: some View {
        GeometryReader { geo in
            let size = geo.size.width
            ZStack {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: borderWidth)
                    )
                    .overlay {
                        Rectangle()
                            .fill(greenDash)
                            .frame(height: 1)
                            .offset(y: -0.5)
                        Rectangle()
                            .fill(greenDash)
                            .frame(width: 1)
                            .offset(x: -0.5)
                    }

                Text(String(char))
                    .font(.system(size: size * 0.55, weight: .bold, design: .serif))
                    .foregroundStyle(textColor)
                    .strikethrough(state == .found, color: Color(red: 232/255, green: 100/255, blue: 82/255))

                if state == .found, let fix {
                    Text(String(fix))
                        .font(.system(size: size * 0.36, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(Color(red: 223/255, green: 245/255, blue: 231/255))
                                .overlay(Capsule().strokeBorder(Color(red: 76/255, green: 175/255, blue: 125/255), lineWidth: 1.2))
                        )
                        .offset(y: -size * 0.9)
                        .scaleEffect(fixShow ? 1 : 0.3)
                        .opacity(fixShow ? 1 : 0)
                        .shadow(color: Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.3), radius: 3, y: 1)
                }

                if state == .found {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 14, height: 14)
                        .background(Circle().fill(Color(red: 76/255, green: 175/255, blue: 125/255)))
                        .overlay(Circle().strokeBorder(.white, lineWidth: 1.2))
                        .offset(x: size * 0.45, y: -size * 0.45)
                        .scaleEffect(checkShow ? 1 : 0.2)
                        .opacity(checkShow ? 1 : 0)
                }

                if state == .checked {
                    Circle()
                        .fill(Color(red: 168/255, green: 184/255, blue: 154/255))
                        .frame(width: 4, height: 4)
                        .offset(x: size * 0.42, y: -size * 0.42)
                        .opacity(checkShow ? 1 : 0)
                }
            }
            .scaleEffect(scaleEffect)
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .onTapGesture {
            guard state == .normal else { return }
            onTap()
        }
        .onChange(of: state) { _, newState in
            switch newState {
            case .found:
                withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) { pop = true }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.12)) { fixShow = true }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55).delay(0.22)) { checkShow = true }
            case .checked:
                withAnimation(.easeOut(duration: 0.25)) { checkShow = true }
            case .hintFlash:
                withAnimation(.easeInOut(duration: 0.35).repeatCount(4, autoreverses: true)) { flash = true }
            case .normal:
                break
            }
        }
        .overlay {
            if state == .hintFlash {
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(Color(red: 245/255, green: 166/255, blue: 35/255), lineWidth: 3)
                        .scaleEffect(flash ? 1.25 : 1)
                        .opacity(flash ? 0 : 0.9)
                }
                .aspectRatio(1, contentMode: .fit)
            }
        }
    }

    private var scaleEffect: CGFloat {
        state == .found ? (pop ? 1 : 0.6) : 1
    }

    private var background: Color {
        switch state {
        case .found: return Color(red: 255/255, green: 233/255, blue: 229/255)
        case .checked: return Color(red: 242/255, green: 246/255, blue: 234/255)
        case .hintFlash: return Color(red: 255/255, green: 248/255, blue: 225/255)
        case .normal: return .white
        }
    }

    private var borderColor: Color {
        switch state {
        case .found: return Color(red: 232/255, green: 100/255, blue: 82/255)
        case .hintFlash: return Color(red: 245/255, green: 166/255, blue: 35/255)
        default: return green
        }
    }

    private var borderWidth: CGFloat {
        state == .normal ? 1.2 : 2
    }

    private var textColor: Color {
        switch state {
        case .found: return Color(red: 232/255, green: 100/255, blue: 82/255)
        case .checked: return Color(red: 74/255, green: 90/255, blue: 66/255).opacity(0.75)
        default: return Color(red: 74/255, green: 90/255, blue: 66/255)
        }
    }
}

// MARK: - 提示 Toast

struct HomeworkToastItem: Equatable, Hashable {
    enum Kind { case good, bad, hint }
    let kind: Kind
    let fix: Character?
    let message: String
    let exp: String
}

struct HomeworkToast: View {
    let item: HomeworkToastItem

    private var isGood: Bool { item.kind == .good }
    private var isHint: Bool { item.kind == .hint }

    private var main: Color {
        isGood ? Color(red: 76/255, green: 175/255, blue: 125/255)
            : isHint ? Color(red: 245/255, green: 166/255, blue: 35/255)
            : Color(red: 232/255, green: 100/255, blue: 82/255)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(item.message)
                .font(.system(size: 16, weight: .heavy, design: .serif))
                .foregroundStyle(.white)
            if let fix = item.fix {
                Text(String(fix))
                    .font(.system(size: 30, weight: .heavy, design: .serif))
                    .foregroundStyle(.white)
            }
            Text(item.exp)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(colors: isGood
                        ? [Color(red: 126/255, green: 211/255, blue: 160/255), main]
                        : isHint ? [Color(red: 255/255, green: 205/255, blue: 120/255), main]
                        : [Color(red: 244/255, green: 141/255, blue: 120/255), main],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.55), lineWidth: 2.5)
                )
                .shadow(color: main.opacity(0.5), radius: 16, y: 8)
        )
        .padding(.bottom, 80)
    }
}

// MARK: - 结算弹层

struct HomeworkResultOverlay: View {
    enum Outcome {
        case win(flowers: Int)
        case lose(missing: [(wrong: Character, fix: Character, exp: String)])
    }

    let outcome: Outcome
    let title: String
    let onReplay: () -> Void
    let onExit: () -> Void
    let onPick: () -> Void

    @State private var appear = false

    var body: some View {
        ZStack {
            Color(red: 30/255, green: 40/255, blue: 28/255).opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                switch outcome {
                case .win(let flowers):
                    Text("🎉")
                        .font(.system(size: 46))
                        .scaleEffect(appear ? 1 : 0.3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appear)

                    Text("全部找齐！")
                        .font(.system(size: 20, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                        .opacity(appear ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(0.15), value: appear)

                    Text("《\(title)》被小老师改得干干净净")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                        .opacity(appear ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(0.25), value: appear)

                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { i in
                            Text("🌸")
                                .font(.system(size: 20))
                                .opacity(i < flowers ? 1 : 0.15)
                                .grayscale(i < flowers ? 0 : 1)
                                .scaleEffect(appear ? 1 : 0.2)
                                .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.35 + Double(i) * 0.09), value: appear)
                        }
                    }
                    .padding(.top, 4)

                    Text("评语：火眼金睛，真厉害！")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 181/255, green: 118/255, blue: 10/255))
                        .padding(.top, 4)
                        .opacity(appear ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(0.7), value: appear)

                case .lose(let missing):
                    Text("😅")
                        .font(.system(size: 46))
                        .scaleEffect(appear ? 1 : 0.3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appear)

                    Text("机会用完啦")
                        .font(.system(size: 20, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                        .opacity(appear ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(0.15), value: appear)

                    Text("还有 \(missing.count) 处没找到，看看正确答案：")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                        .padding(.top, 2)
                        .opacity(appear ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(0.25), value: appear)

                    VStack(spacing: 7) {
                        ForEach(Array(missing.enumerated()), id: \.offset) { index, item in
                            HStack(spacing: 8) {
                                Text(String(item.wrong))
                                    .font(.system(size: 16, weight: .heavy, design: .serif))
                                    .foregroundStyle(Color(red: 232/255, green: 100/255, blue: 82/255))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color(red: 160/255, green: 176/255, blue: 152/255))
                                Text(String(item.fix))
                                    .font(.system(size: 16, weight: .heavy, design: .serif))
                                    .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                                Text(item.exp)
                                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(red: 255/255, green: 248/255, blue: 240/255))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(Color(red: 232/255, green: 100/255, blue: 82/255).opacity(0.3), lineWidth: 1.5)
                                    )
                            )
                            .offset(y: appear ? 0 : 14)
                            .opacity(appear ? 1 : 0)
                            .animation(.easeOut(duration: 0.3).delay(0.35 + Double(index) * 0.07), value: appear)
                        }
                    }
                    .padding(.top, 6)
                }

                HStack(spacing: 10) {
                    Button(action: onReplay) {
                        Text("再试一次")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(colors: [Color(red: 126/255, green: 211/255, blue: 160/255), Color(red: 76/255, green: 175/255, blue: 125/255)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .shadow(color: Color(red: 76/255, green: 175/255, blue: 125/255).opacity(0.4), radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)

                    Button(action: onPick) {
                        Text("换一篇")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Color.white,
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.32), lineWidth: 2.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 14)
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.5), value: appear)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 22)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 255/255, green: 253/255, blue: 246/255))
                    .shadow(color: Color(red: 30/255, green: 40/255, blue: 28/255).opacity(0.35), radius: 20, y: 8)
            )
            .scaleEffect(appear ? 1 : 0.85)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appear)
        }
        .onAppear { appear = true }
    }
}
import SwiftUI

// MARK: - 主容器（年级 + 随机出题）

struct ChineseHomeworkView: View {
    let onExit: () -> Void

    @State private var grade = "二年级上册"
    @State private var textbooks: [YwTextbook] = []
    @State private var currentTextbook: YwTextbook?
    @State private var gameKey = UUID()

    var body: some View {
        ZStack {
            backgroundGradient

            ChineseHomeworkGameView(
                grade: $grade,
                gradeNames: ChineseHomeworkStore.gradeNames,
                textbook: currentTextbook,
                onExit: onExit,
                onRefresh: refreshRandom
            )
            .id(gameKey)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { load() }
        .onChange(of: grade) { _, _ in load() }
    }

    private func load() {
        textbooks = ChineseHomeworkStore.loadTextbooks(grade: grade)
        refreshRandom()
    }

    /// 从当前册随机挑一篇可用的课文
    private func refreshRandom() {
        let usable = textbooks.filter { ChineseHomeworkStore.hanziCount(of: $0.content) >= 10 }
        currentTextbook = usable.randomElement()
        gameKey = UUID()
    }

    private var backgroundGradient: some View {
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

            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let drift = 12 * sin(t * 0.42)
                let bob = 2.5 * sin(t * 0.8 + 1.0)
                ZStack {
                    Capsule().fill(Color.white.opacity(0.92)).frame(width: 38, height: 13).offset(y: 3)
                    Circle().fill(Color.white.opacity(0.92)).frame(width: 22, height: 22).offset(x: -8, y: -5)
                    Circle().fill(Color.white.opacity(0.88)).frame(width: 18, height: 18).offset(x: 6, y: -3)
                }
                .frame(width: 46, height: 26)
                .offset(x: drift, y: bob)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, -10)
                .padding(.top, 44)
            }
            .allowsHitTesting(false)
        }
    }
}
import SwiftUI

// MARK: - 批改页（自动随机出题 + 年级切换）

struct ChineseHomeworkGameView: View {
    @Binding var grade: String
    let gradeNames: [String]
    let textbook: YwTextbook?
    let onExit: () -> Void
    let onRefresh: () -> Void

    @State private var session: HomeworkSession?
    @State private var cellStates: [Int: TianCellState] = [:]
    @State private var foundCount = 0
    @State private var chances = 8
    @State private var toast: HomeworkToastItem?
    @State private var result: HomeworkResultOverlay.Outcome?
    @State private var hintTarget: Int?
    @State private var hintBusy = false

    @State private var showGradePicker = false

    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            HStack {
                GracefulBackButton(action: onExit)
                Spacer()
                Text("找错别字")
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                Spacer()
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 74/255, green: 92/255, blue: 66/255))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.8)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            // 信息行：年级选择 + 进度 + 提示
            HStack(spacing: 10) {
                Button { showGradePicker = true } label: {
                    HStack(spacing: 4) {
                        Text(grade)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundStyle(Color(red: 74/255, green: 92/255, blue: 66/255))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.85))
                            .overlay(Capsule().strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.35), lineWidth: 1.5))
                    )
                }
                .buttonStyle(.plain)

                Text("🔍 \(foundCount)/\(session?.totalWrong ?? 0)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 125/255))
                    .contentTransition(.numericText())

                Spacer()

                Text("🎯 \(chances) 次")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 232/255, green: 100/255, blue: 82/255))
                    .contentTransition(.numericText())

                Button(action: hintOnce) {
                    Text("💡 提示")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 181/255, green: 118/255, blue: 10/255))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(red: 255/255, green: 243/255, blue: 214/255))
                                .overlay(Capsule().strokeBorder(Color(red: 245/255, green: 166/255, blue: 35/255).opacity(0.5), lineWidth: 1.5))
                        )
                }
                .buttonStyle(.plain)
                .disabled(foundCount >= (session?.totalWrong ?? 0) || hintBusy)
                .opacity(foundCount >= (session?.totalWrong ?? 0) ? 0.4 : 1)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // 田字格正文（含课文信息头）
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 课文信息
                        HStack(spacing: 8) {
                            Text("👧")
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(textbook?.title ?? "正在出题…")
                                    .font(.system(size: 12, weight: .heavy, design: .serif))
                                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                                    .lineLimit(1)
                                Text("\(grade) · 田字格找错别字")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(red: 138/255, green: 154/255, blue: 122/255))
                            }
                            Spacer()
                            Text("语文")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color(red: 74/255, green: 163/255, blue: 223/255)))
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                        .padding(.bottom, 8)

                        Divider()
                            .padding(.horizontal, 10)

                        Text(textbook?.title ?? "")
                            .font(.system(size: 16, weight: .heavy, design: .serif))
                            .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                            .padding(.top, 12)
                            .padding(.bottom, 10)

                        gridPaper
                    }
                }
                .onChange(of: hintTarget) { _, target in
                    if let target {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            proxy.scrollTo(target, anchor: .center)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 255/255, green: 253/255, blue: 246/255))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .overlay {
            if let toast {
                HomeworkToast(item: toast)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                    .id(toast)
            }
        }
        .overlay {
            if let result {
                HomeworkResultOverlay(outcome: result,
                                      title: textbook?.title ?? "",
                                      onReplay: replay,
                                      onExit: onExit,
                                      onPick: onRefresh)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: toast != nil)
        .animation(.easeInOut(duration: 0.3), value: result != nil)
        .onAppear { setupGame() }
        .sheet(isPresented: $showGradePicker) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("选择文本来源")
                        .font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 22)

                    ForEach(Array(ChineseHomeworkStore.sourceGroups.enumerated()), id: \.offset) { _, group in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Text(group.emoji)
                                    .font(.system(size: 16))
                                Text(group.label)
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                            }
                            .padding(.leading, 4)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(group.items, id: \.self) { item in
                                    Button {
                                        grade = item
                                        showGradePicker = false
                                    } label: {
                                        Text(item)
                                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                                            .foregroundStyle(grade == item ? .white : Color(red: 74/255, green: 92/255, blue: 66/255))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 11)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(grade == item
                                                        ? Color(red: 76/255, green: 175/255, blue: 125/255)
                                                        : Color(red: 244/255, green: 248/255, blue: 238/255))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                            .strokeBorder(grade == item
                                                                ? Color(red: 76/255, green: 175/255, blue: 125/255)
                                                                : Color(red: 110/255, green: 140/255, blue: 90/255).opacity(0.3),
                                                                lineWidth: 1.5)
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var progress: Double {
        guard let session, session.totalWrong > 0 else { return 0 }
        return min(Double(foundCount) / Double(session.totalWrong), 1.0)
    }

    // MARK: 田字格网格

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)

    private var gridPaper: some View {
        LazyVGrid(columns: gridColumns, spacing: 4) {
            if let session {
                ForEach(session.lines.flatMap { $0 }) { token in
                    tokenView(token, session: session)
                }
            }
        }
    }

    @ViewBuilder
    private func tokenView(_ token: TianToken, session: HomeworkSession) -> some View {
        switch token.kind {
        case .indent:
            Color.clear.aspectRatio(1, contentMode: .fit)
        case .punct(let ch):
            GeometryReader { geo in
                let s = geo.size.width
                ZStack {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .strokeBorder(Color(red: 120/255, green: 160/255, blue: 70/255).opacity(0.5), lineWidth: 1.2)
                    Text(String(ch))
                        .font(.system(size: s * 0.55, weight: .heavy, design: .serif))
                        .foregroundStyle(Color(red: 61/255, green: 74/255, blue: 54/255))
                }
            }
            .aspectRatio(1, contentMode: .fit)
        case .blank:
            TianGeCell(char: " ", fix: nil, state: .normal) {}
        case .char(let ch, let isWrong, let fix, _):
            let index = session.tokenIDs[token.id] ?? 0
            TianGeCell(char: ch,
                       fix: isWrong ? fix : nil,
                       state: cellStates[index] ?? .normal) {
                tapChar(index: index, isWrong: isWrong, fix: fix, session: session)
            }
            .id(index)
        case .newline:
            EmptyView()
        }
    }

    // MARK: 游戏逻辑

    private func setupGame() {
        guard let textbook else { return }
        let newSession = HomeworkSession(textbook: textbook, gradeName: grade)
        session = newSession
        cellStates = [:]
        foundCount = 0
        chances = newSession.maxChances
        toast = nil
        result = nil
        hintTarget = nil
        hintBusy = false
    }

    private func tapChar(index: Int, isWrong: Bool, fix: Character, session: HomeworkSession) {
        guard result == nil else { return }
        let state = cellStates[index] ?? .normal
        guard state == .normal else { return }

        if isWrong {
            withAnimation(.easeInOut(duration: 0.25)) {
                cellStates[index] = .found
            }
            foundCount += 1
// 找对：直接格子上做动画，不再中央弹框
            if foundCount == session.totalWrong {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    guard foundCount == (self.session?.totalWrong ?? 0) else { return }
                    let flowers = chances >= session.maxChances - 1 ? 5 : (chances >= 1 ? 3 : 1)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        result = .win(flowers: flowers)
                    }
                    GameBestScoreStore.update(.chineseHomework, score: foundCount + session.totalWrong * 100)
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                cellStates[index] = .checked
            }
            chances -= 1
// 点错：不做中央提示
            if chances <= 0 && foundCount < session.totalWrong {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    guard chances <= 0, foundCount < (self.session?.totalWrong ?? 0) else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        result = .lose(missing: missingList())
                    }
                }
            }
        }
    }

    private func exp(of index: Int, session: HomeworkSession) -> String {
        guard case .char(_, let isWrong, _, let exp) = (session.tokenByIndex[index]?.kind ?? .punct("？")) else { return "" }
        return isWrong ? exp : ""
    }

    private func missingList() -> [(wrong: Character, fix: Character, exp: String)] {
        guard let session else { return [] }
        var out: [(Character, Character, String)] = []
        for line in session.lines {
            for token in line {
                guard case .char(let ch, let isWrong, let fix, let exp) = token.kind else { continue }
                let idx = session.tokenIDs[token.id] ?? 0
                let state = cellStates[idx] ?? .normal
                if isWrong, state == .normal {
                    out.append((ch, fix, exp))
                }
            }
        }
        return out
    }

    private func hintOnce() {
        guard let session, result == nil, !hintBusy, foundCount < session.totalWrong else { return }
        guard let first = firstMissingIndex(session: session) else { return }

        hintBusy = true
        withAnimation(.easeInOut(duration: 0.4)) {
            cellStates[first] = .hintFlash
        }
        hintTarget = first

        let fix: Character
        let exp: String
        if case .char(_, _, let f, let e) = (session.tokenByIndex[first]?.kind ?? .punct("？")) {
            fix = f
            exp = e
        } else {
            fix = "？"
            exp = ""
        }
        showToast(.hint, fix: fix, message: "提示：这个字写错了", exp: exp)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            hintBusy = false
            guard result == nil else { return }
            let state = cellStates[first] ?? .normal
            guard state != .found else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                cellStates[first] = .found
            }
            foundCount += 1
            chances -= 1
            if foundCount == session.totalWrong {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    let flowers = chances >= session.maxChances - 1 ? 5 : (chances >= 1 ? 3 : 1)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        result = .win(flowers: flowers)
                    }
                    GameBestScoreStore.update(.chineseHomework, score: foundCount + session.totalWrong * 100)
                }
            } else if chances <= 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        result = .lose(missing: missingList())
                    }
                }
            }
        }
    }

    private func firstMissingIndex(session: HomeworkSession) -> Int? {
        for line in session.lines {
            for token in line {
                guard case .char(_, let isWrong, _, _) = token.kind else { continue }
                let idx = session.tokenIDs[token.id] ?? 0
                let state = cellStates[idx] ?? .normal
                if isWrong, state == .normal {
                    return idx
                }
            }
        }
        return nil
    }

    private func replay() {
        setupGame()
    }

    // MARK: Toast

    private func showToast(_ kind: HomeworkToastItem.Kind, fix: Character?, message: String, exp: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            toast = HomeworkToastItem(kind: kind, fix: fix, message: message, exp: exp)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (kind == .hint ? 1.5 : 1.3)) {
            if self.toast?.kind == kind {
                withAnimation(.easeOut(duration: 0.2)) {
                    toast = nil
                }
            }
        }
    }
}
