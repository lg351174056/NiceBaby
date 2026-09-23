import SwiftUI
import Combine

// MARK: - 生僻字大闯关（探索 · 学问营地）

struct RareChar: Identifiable, Hashable {
    let c: String
    let py: String
    let say: String
    let mean: String
    let near: [String]
    let parts: [String]
    let tier: Int
    var id: String { c }
}

private let kRareChars: [RareChar] = [
    // 入门
    .init(c: "隼", py: "sǔn", say: "鹰隼", mean: "一种猛禽，像鹰", near: ["集", "隹"], parts: ["隹", "十"], tier: 1),
    .init(c: "翕", py: "xī", say: "翕动", mean: "合拢、收敛", near: ["禽", "合"], parts: ["合", "羽"], tier: 1),
    .init(c: "觑", py: "qù", say: "面面相觑", mean: "看、瞧", near: ["虚"], parts: [], tier: 1),
    .init(c: "荏", py: "rěn", say: "荏苒", mean: "（荏苒）时间渐渐过去", near: ["任", "茬"], parts: ["艹", "任"], tier: 1),
    .init(c: "苒", py: "rǎn", say: "荏苒", mean: "（荏苒）时间悄悄过去", near: ["再", "冉"], parts: ["艹", "冉"], tier: 1),
    .init(c: "斛", py: "hú", say: "石斛", mean: "旧时量粮食的器具", near: ["斗", "解"], parts: ["角", "斗"], tier: 1),
    .init(c: "佞", py: "nìng", say: "奸佞", mean: "惯用花言巧语讨好", near: ["任", "侯"], parts: [], tier: 1),
    .init(c: "夙", py: "sù", say: "夙愿", mean: "早；一向有的", near: ["风", "凤"], parts: [], tier: 1),
    .init(c: "砭", py: "biān", say: "针砭", mean: "古代治病的石针", near: ["贬", "泛"], parts: ["石", "乏"], tier: 1),
    .init(c: "忡", py: "chōng", say: "忧心忡忡", mean: "忧愁的样子", near: ["冲", "种"], parts: ["忄", "中"], tier: 1),
    .init(c: "怅", py: "chàng", say: "惆怅", mean: "失意、不痛快", near: ["账", "胀"], parts: ["忄", "长"], tier: 1),
    .init(c: "峙", py: "zhì", say: "对峙", mean: "直立、耸立", near: ["持", "待"], parts: ["山", "寺"], tier: 1),
    // 进阶
    .init(c: "羸", py: "léi", say: "羸弱", mean: "瘦弱", near: ["赢", "嬴"], parts: [], tier: 2),
    .init(c: "窠", py: "kē", say: "鸟窠", mean: "鸟兽的窝", near: ["巢", "棵"], parts: ["穴", "果"], tier: 2),
    .init(c: "潸", py: "shān", say: "潸然泪下", mean: "流泪的样子", near: ["潜", "淋"], parts: [], tier: 2),
    .init(c: "撷", py: "xié", say: "采撷", mean: "摘下、取下", near: ["携", "颉"], parts: [], tier: 2),
    .init(c: "谙", py: "ān", say: "谙熟", mean: "熟悉", near: ["暗", "喑"], parts: ["讠", "音"], tier: 2),
    .init(c: "舛", py: "chuǎn", say: "舛误", mean: "违背、错乱", near: ["桀", "舞"], parts: [], tier: 2),
    .init(c: "毗", py: "pí", say: "毗邻", mean: "相邻", near: ["比", "昆"], parts: ["田", "比"], tier: 2),
    .init(c: "愠", py: "yùn", say: "愠怒", mean: "生气、恼怒", near: ["温", "蕴"], parts: ["忄", "昷"], tier: 2),
    .init(c: "濯", py: "zhuó", say: "洗濯", mean: "洗", near: ["擢", "灌"], parts: ["氵", "翟"], tier: 2),
    .init(c: "皴", py: "cūn", say: "皴裂", mean: "皮肤因冷而裂开", near: ["皱", "皲"], parts: ["夋", "皮"], tier: 2),
    .init(c: "垣", py: "yuán", say: "城垣", mean: "墙", near: ["恒", "桓"], parts: ["土", "亘"], tier: 2),
    .init(c: "砧", py: "zhēn", say: "砧板", mean: "切东西时垫在底下的板", near: ["沾", "玷"], parts: ["石", "占"], tier: 2),
    // 挑战
    .init(c: "饕", py: "tāo", say: "饕餮", mean: "贪吃（饕餮：贪吃的凶兽）", near: ["餐"], parts: ["号", "食"], tier: 3),
    .init(c: "餮", py: "tiè", say: "饕餮", mean: "（饕餮）贪食的凶兽", near: ["餐", "饕"], parts: [], tier: 3),
    .init(c: "耄", py: "mào", say: "耄耋", mean: "年老（八九十岁）", near: ["老", "髦"], parts: ["老", "毛"], tier: 3),
    .init(c: "耋", py: "dié", say: "耄耋", mean: "年老（七八十岁）", near: ["至", "耄"], parts: ["老", "至"], tier: 3),
    .init(c: "魑", py: "chī", say: "魑魅", mean: "传说山里的鬼怪", near: ["魅", "魍"], parts: ["鬼", "离"], tier: 3),
    .init(c: "魅", py: "mèi", say: "魅力", mean: "吸引人的力量", near: ["魑", "魁"], parts: ["鬼", "未"], tier: 3),
    .init(c: "魍", py: "wǎng", say: "魍魉", mean: "传说中的鬼怪", near: ["魉", "魑"], parts: ["鬼", "罔"], tier: 3),
    .init(c: "魉", py: "liǎng", say: "魍魉", mean: "传说中的鬼怪", near: ["魍", "魅"], parts: ["鬼", "两"], tier: 3),
    .init(c: "甑", py: "zèng", say: "甑子", mean: "古代蒸饭的瓦器", near: ["赠", "增"], parts: ["曾", "瓦"], tier: 3),
    .init(c: "缶", py: "fǒu", say: "击缶", mean: "古代盛水的瓦器", near: ["击", "缸"], parts: [], tier: 3),
    .init(c: "榫", py: "sǔn", say: "榫卯", mean: "木器接合处凸出的部分", near: ["隼", "准"], parts: ["木", "隼"], tier: 3),
    .init(c: "蟾", py: "chán", say: "蟾蜍", mean: "癞蛤蟆", near: ["瞻", "蝉"], parts: ["虫", "詹"], tier: 3),
    .init(c: "蜍", py: "chú", say: "蟾蜍", mean: "（蟾蜍）癞蛤蟆", near: ["余", "除"], parts: ["虫", "余"], tier: 3),
    .init(c: "燧", py: "suì", say: "燧石", mean: "取火的器具", near: ["隧", "遂"], parts: ["火", "遂"], tier: 3),
    .init(c: "胄", py: "zhòu", say: "甲胄", mean: "古代打仗戴的头盔", near: ["胃", "肖"], parts: ["由", "月"], tier: 3),
    .init(c: "曌", py: "zhào", say: "曌", mean: "武则天造的字，日月当空", near: ["照", "明"], parts: ["日", "月"], tier: 3),
]

private let kDecoyParts = ["氵", "忄", "艹", "扌", "木", "日", "月", "石", "虫", "鬼", "瓦", "舟", "竹", "土", "火", "讠", "山", "门", "亻", "女", "田", "目", "穴", "宀"]

enum RareQKind { case read, listen, assemble, meaning }

private struct RareQuestion {
    let kind: RareQKind
    let base: RareChar
}

enum RareStore {
    static func star(_ lv: Int) -> Int { UserDefaults.standard.integer(forKey: "rare.star.\(lv)") }
    static func setStar(_ lv: Int, _ s: Int) {
        if s > star(lv) { UserDefaults.standard.set(s, forKey: "rare.star.\(lv)") }
    }
    static func clearedCount() -> Int { (1...10).filter { star($0) > 0 }.count }
    static func allCleared() -> Bool { (1...10).allSatisfy { star($0) > 0 } }

    static func dex() -> [String] { UserDefaults.standard.stringArray(forKey: "rare.dex.v1") ?? [] }
    static func addDex(_ c: String) {
        var d = dex(); if !d.contains(c) { d.append(c); UserDefaults.standard.set(d, forKey: "rare.dex.v1") }
    }
    static func wrongs() -> [String] { UserDefaults.standard.stringArray(forKey: "rare.wrong.v1") ?? [] }
    static func addWrong(_ c: String) {
        var w = wrongs(); if !w.contains(c) { w.append(c); UserDefaults.standard.set(Array(w.suffix(60)), forKey: "rare.wrong.v1") }
    }
    static func removeWrong(_ c: String) {
        UserDefaults.standard.set(wrongs().filter { $0 != c }, forKey: "rare.wrong.v1")
    }
}

struct RareCharView: View {
    private enum Phase { case home, play, dex }

    @State private var phase: Phase = .home
    @State private var level = 1
    @State private var isBrawl = false
    @State private var list: [RareQuestion] = []
    @State private var qi = 0
    @State private var correct = 0
    @State private var wrongN = 0
    @State private var answered = false
    @State private var picked = ""
    @State private var fbText = ""
    @State private var fbOK = false
    @State private var nextVisible = false
    @State private var startDate = Date()

    // assemble
    @State private var asmSlot: [String] = []
    @State private var asmUsed: Set<Int> = []
    @State private var asmTiles: [String] = []

    @State private var showHelp = false
    @State private var showResult = false
    @State private var dexSel: RareChar? = nil
    @State private var dexVersion = 0

    @Namespace private var ns
    private let accent = Color(red: 0.42, green: 0.36, blue: 0.62)
    private let accentSoft = Color(red: 0.94, green: 0.92, blue: 0.97)

    var body: some View {
        ZStack {
            FieldBackground()
            decorations
            VStack(spacing: 0) {
                navBar
                Group {
                    switch phase {
                    case .home: homeView
                    case .play: playView
                    case .dex: dexView
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showResult { resultOverlay }
            if let sel = dexSel { dexModal(sel) }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .enableSwipeBack()
        .sheet(isPresented: $showHelp) { helpSheet }
        .onDisappear { PoemSpeechService.shared.stop() }
    }

    // MARK: 顶栏

    private var navBar: some View {
        HStack(spacing: 8) {
            GracefulBackButton()
            VStack(alignment: .leading, spacing: 0) {
                Text("生僻字大闯关").font(.system(size: 16, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                Text("认读音 · 辨字形 · 集字卡").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
            }
            Spacer()
            helpButton
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 2)
    }

    private var helpButton: some View {
        Button { showHelp = true } label: {
            Text("?").font(.system(size: 15, weight: .black)).foregroundStyle(accent)
                .frame(width: 34, height: 34).background(Circle().fill(accentSoft))
                .overlay(Circle().strokeBorder(accent.opacity(0.35), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: 首页

    private var homeView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                levelCard
                brawlCard
                dexButton
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 40)
        }
    }

    private var heroCard: some View {
        let got = RareStore.dex().count
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Text("🀄").font(.system(size: 32))
                    .frame(width: 62, height: 62)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(accentSoft))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(accent.opacity(0.3), lineWidth: 2))
                VStack(alignment: .leading, spacing: 3) {
                    Text("生僻字大闯关").font(.system(size: 20, weight: .black, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                    Text("认读音 · 辨字形 · 集字卡").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
                }
                Spacer()
            }
            VStack(spacing: 8) {
                HStack {
                    Text("字卡图鉴").font(.system(size: 12.5, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldOliveDeep)
                    Spacer()
                    Text("\(got) / \(kRareChars.count) 张").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(accent)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppTheme.fieldOlive.opacity(0.16))
                        Capsule().fill(LinearGradient(colors: [Color(red: 0.61, green: 0.55, blue: 0.82), accent], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(got) / CGFloat(kRareChars.count))
                    }
                }
                .frame(height: 10)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white.opacity(0.94))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(AppTheme.fieldOlive.opacity(0.22), lineWidth: 2))
            .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 8, y: 4))
    }

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("闯关").font(.system(size: 15, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                Text("每关 10 题").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
                Spacer()
                Text("已通关 \(RareStore.clearedCount())/10").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(accent)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                ForEach(1...10, id: \.self) { lv in levelCell(lv) }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white.opacity(0.94))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(AppTheme.fieldOlive.opacity(0.22), lineWidth: 2))
            .shadow(color: AppTheme.fieldGrassShadow.opacity(0.08), radius: 8, y: 4))
    }

    private var dexButton: some View {
        Button { phase = .dex } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2.fill").font(.system(size: 14, weight: .bold))
                Text("字卡图鉴").font(.system(size: 15, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 54)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.61, green: 0.55, blue: 0.82), accent], startPoint: .topLeading, endPoint: .bottomTrailing)))
            .shadow(color: accent.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func levelCell(_ lv: Int) -> some View {
        let s = RareStore.star(lv)
        let unlocked = lv == 1 || RareStore.star(lv - 1) > 0
        return Button { startLevel(lv) } label: {
            VStack(spacing: 3) {
                Text("\(lv)").font(.system(size: 19, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                Text(s > 0 ? String(repeating: "★", count: s) : " ").font(.system(size: 10)).foregroundStyle(AppTheme.fieldGold)
                Text(tierName(lv)).font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
            }
            .frame(maxWidth: .infinity).frame(height: 76)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(unlocked ? 0.95 : 0.5))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(s > 0 ? accent.opacity(0.6) : AppTheme.fieldOlive.opacity(0.25), lineWidth: 2)))
            .grayscale(unlocked ? 0 : 0.8).opacity(unlocked ? 1 : 0.55)
        }
        .buttonStyle(.plain).disabled(!unlocked)
    }

    private func tierName(_ lv: Int) -> String { lv <= 3 ? "入门" : (lv <= 7 ? "进阶" : "挑战") }

    private var brawlCard: some View {
        let ok = RareStore.allCleared()
        return Button { startBrawl() } label: {
            HStack(spacing: 14) {
                Text("⚔️").font(.system(size: 34))
                VStack(alignment: .leading, spacing: 2) {
                    Text("生僻字大乱斗").font(.system(size: 16, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                    Text(ok ? "全库随机 · 无限刷 · 不会通关" : "通关全部 10 关后解锁（已通关 \(RareStore.clearedCount())/10）")
                        .font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldOliveDeep)
                }
                Spacer()
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [accentSoft, Color(red: 0.89, green: 0.86, blue: 0.95)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(accent.opacity(ok ? 0.5 : 0.25), lineWidth: 2)))
            .grayscale(ok ? 0 : 0.6).opacity(ok ? 1 : 0.6)
        }
        .buttonStyle(.plain).disabled(!ok)
    }

    // MARK: 游戏

    private var playView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                chip(isBrawl ? "大乱斗" : "第 \(level) 关")
                chip("第 \(min(qi + 1, list.count))/\(list.count) 题")
                chip("得分 \(correct * 100)")
            }
            .padding(.top, 12)
            stageView
            footView
        }
    }

    private func chip(_ t: String) -> some View {
        Text(t).font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldOliveDeep)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.9)).overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.2), lineWidth: 1.5)))
    }

    private var stageView: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Spacer(minLength: 0)
                    if list.indices.contains(qi) { questionContent(list[qi]) }
                    Spacer(minLength: 0)
                }
                .frame(minHeight: geo.size.height)
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
            }
        }
    }

    @ViewBuilder
    private func questionContent(_ q: RareQuestion) -> some View {
        switch q.kind {
        case .read: readQ(q)
        case .listen: listenQ(q)
        case .meaning: meaningQ(q)
        case .assemble: assembleQ(q)
        }
    }

    private func askCard(_ html: String) -> some View {
        Text(html).font(.system(size: 15, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
            .multilineTextAlignment(.center).lineSpacing(4)
            .padding(.horizontal, 18).padding(.vertical, 15).frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(AppTheme.fieldOlive.opacity(0.22), lineWidth: 2)))
    }

    private func glyphBox(_ ch: String, py: String?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(accent.opacity(0.35), lineWidth: 3))
                .shadow(color: AppTheme.fieldGrassShadow.opacity(0.14), radius: 12, y: 6)
            VStack(spacing: 4) {
                Text(ch).font(.custom("Kaiti SC", size: 108)).foregroundStyle(AppTheme.fieldInk)
                if let py { Text(py).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(accent) }
            }
            VStack { HStack { Spacer(); speakerButton() }; Spacer() }.padding(10)
        }
        .frame(width: min(UIScreen.main.bounds.width - 120, 240), height: min(UIScreen.main.bounds.width - 120, 240))
    }

    private func speakerButton() -> some View {
        Button { if let b = list[safe: qi]?.base { PoemSpeechService.shared.speak(text: b.say) } } label: {
            Image(systemName: "speaker.wave.2.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(accent)
                .frame(width: 40, height: 40).background(Circle().fill(accentSoft))
                .overlay(Circle().strokeBorder(accent.opacity(0.35), lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func readQ(_ q: RareQuestion) -> some View {
        VStack(spacing: 16) {
            askCard("这个字读什么？")
            glyphBox(q.base.c, py: nil)
            optionsGrid(q.base.py, pinyins: true) { answer($0, q.base.py, "\(q.base.c) 读 \(q.base.py) · \(q.base.mean)") }
        }
    }

    private func listenQ(_ q: RareQuestion) -> some View {
        VStack(spacing: 16) {
            askCard("🔊 点喇叭听一听，是哪个字？")
            Button { PoemSpeechService.shared.speak(text: q.base.say) } label: {
                HStack(spacing: 8) { Image(systemName: "speaker.wave.3.fill"); Text("播放读音") }
                    .font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                    .padding(.horizontal, 34).padding(.vertical, 16)
                    .background(Capsule().fill(LinearGradient(colors: [Color(red: 0.61, green: 0.55, blue: 0.82), accent], startPoint: .topLeading, endPoint: .bottomTrailing)))
            }
            .buttonStyle(.plain)
            optionsGrid(q.base.c, pinyins: false) { answer($0, q.base.c, "读 \(q.base.py) 的是「\(q.base.c)」· \(q.base.mean)") }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { PoemSpeechService.shared.speak(text: q.base.say) }
        }
    }

    private func meaningQ(_ q: RareQuestion) -> some View {
        VStack(spacing: 16) {
            askCard("「\(q.base.mean)」是哪个字？")
            optionsGrid(q.base.c, pinyins: false) { answer($0, q.base.c, "「\(q.base.mean)」是「\(q.base.c)」（\(q.base.py)）") }
        }
    }

    private func assembleQ(_ q: RareQuestion) -> some View {
        VStack(spacing: 16) {
            askCard("把「\(q.base.mean)」拼出来（\(q.base.parts.count) 个部件）")
            HStack(spacing: 8) {
                ForEach(0..<q.base.parts.count, id: \.self) { i in
                    Text(asmSlot.indices.contains(i) ? asmSlot[i] : "")
                        .font(.custom("Kaiti SC", size: 30)).foregroundStyle(AppTheme.fieldInk)
                        .frame(width: 64, height: 64)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(asmSlot.indices.contains(i) ? Color.white : Color.white.opacity(0.7))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(accent.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: asmSlot.indices.contains(i) ? [] : [5, 4]))))
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(Array(asmTiles.enumerated()), id: \.offset) { i, p in
                    Button { asmTap(i, p, q) } label: {
                        Text(p).font(.custom("Kaiti SC", size: 32)).foregroundStyle(AppTheme.fieldInk)
                            .frame(maxWidth: .infinity).frame(height: 64)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white)
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)))
                            .opacity(asmUsed.contains(i) ? 0.3 : 1)
                    }
                    .buttonStyle(.plain).disabled(answered || asmUsed.contains(i))
                }
            }
        }
    }

    private func optionsGrid(_ correctAnswer: String, pinyins: Bool, _ onTap: @escaping (String) -> Void) -> some View {
        let opts = optionsFor(correctAnswer, pinyins: pinyins)
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(opts, id: \.self) { o in
                let isRight = answered && o == correctAnswer
                let isWrong = answered && picked == o && o != correctAnswer
                Button { onTap(o) } label: {
                    Text(o).font(.custom("Kaiti SC", size: pinyins ? 22 : 30))
                        .foregroundStyle(isRight || isWrong ? .white : AppTheme.fieldInk)
                        .frame(maxWidth: .infinity).frame(minHeight: 66)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isRight ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.49, green: 0.83, blue: 0.63), Color(red: 0.30, green: 0.69, blue: 0.49)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                  : isWrong ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.93, green: 0.54, blue: 0.45), Color(red: 0.80, green: 0.30, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                  : AnyShapeStyle(Color.white.opacity(0.92)))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder((isRight || isWrong) ? Color.clear : AppTheme.fieldOlive.opacity(0.28), lineWidth: 2)))
                }
                .buttonStyle(.plain).disabled(answered)
            }
        }
    }

    private func optionsFor(_ correct: String, pinyins: Bool) -> [String] {
        let base = list[safe: qi]?.base
        var distractors: [String] = []
        if let b = base, !pinyins {
            distractors = b.near + kRareChars.map(\.c).filter { $0 != correct && !b.near.contains($0) }
        } else if pinyins {
            distractors = kRareChars.map(\.py).filter { $0 != correct }
        }
        var out = [correct]
        for d in distractors.shuffled() where out.count < 4 { if !out.contains(d) { out.append(d) } }
        return out.shuffled()
    }

    private var footView: some View {
        VStack(spacing: 10) {
            if !fbText.isEmpty {
                Text(fbText).font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(fbOK ? Color(red: 0.18, green: 0.56, blue: 0.32) : Color(red: 0.78, green: 0.25, blue: 0.17))
                    .multilineTextAlignment(.center)
            }
            if nextVisible {
                Button { next() } label: {
                    Text(qi >= list.count - 1 ? "看看结果" : "下一题")
                        .font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                        .frame(width: 200, height: 48)
                        .background(Capsule().fill(LinearGradient(colors: [Color(red: 0.61, green: 0.55, blue: 0.82), accent], startPoint: .topLeading, endPoint: .bottomTrailing)))
                        .shadow(color: accent.opacity(0.35), radius: 8, y: 4)
                }.buttonStyle(.plain)
            }
        }
        .frame(height: 72).padding(.horizontal, 20)
    }

    // MARK: 图鉴

    private var dexView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text("字卡图鉴（点卡片看详情 / 听读音）").font(.system(size: 13, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(kRareChars) { x in
                        let got = RareStore.dex().contains(x.c)
                        Button { if got { dexSel = x; PoemSpeechService.shared.speak(text: x.say) } } label: {
                            VStack(spacing: 2) {
                                Text(got ? x.c : "？").font(.custom("Kaiti SC", size: 26)).foregroundStyle(AppTheme.fieldInk)
                                Text(got ? x.py : "未解锁").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
                            }
                            .frame(maxWidth: .infinity).frame(height: 82)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(got ? 0.92 : 0.5))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(AppTheme.fieldOlive.opacity(0.2), lineWidth: 2)))
                            .grayscale(got ? 0 : 1).opacity(got ? 1 : 0.4)
                        }
                        .buttonStyle(.plain).disabled(!got)
                    }
                }
                Button { phase = .home } label: {
                    Text("返回").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldInk)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Capsule().fill(Color.white.opacity(0.92)).overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)))
                }.buttonStyle(.plain).padding(.top, 8)
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 30)
        }
        .id(dexVersion)
    }

    private func dexModal(_ x: RareChar) -> some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea().onTapGesture { dexSel = nil }
            VStack(spacing: 10) {
                Text(x.c).font(.custom("Kaiti SC", size: 92)).foregroundStyle(AppTheme.fieldInk)
                Text(x.py).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(accent)
                Text(x.mean).font(.system(size: 14, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk).multilineTextAlignment(.center)
                if !x.near.isEmpty {
                    Text("形近提醒：不要和 \(x.near.joined(separator: "、")) 混哦")
                        .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldOliveDeep)
                }
                HStack(spacing: 12) {
                    Button { PoemSpeechService.shared.speak(text: x.say) } label: {
                        Text("🔊 听读音").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldInk)
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .background(Capsule().fill(Color.white.opacity(0.92)).overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)))
                    }.buttonStyle(.plain)
                    Button { dexSel = nil } label: {
                        Text("知道了").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 48).background(Capsule().fill(accent))
                    }.buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(24).frame(maxWidth: 340)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white))
        }
    }

    // MARK: 结算

    private var resultOverlay: some View {
        let total = list.count
        let acc = total > 0 ? Int((Double(correct) / Double(total) * 100).rounded()) : 0
        let s = acc >= 90 ? 3 : (acc >= 70 ? 2 : (acc >= 50 ? 1 : 0))
        return ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 12) {
                Text(s > 0 ? String(repeating: "★", count: s) + String(repeating: "☆", count: 3 - s) : "☆☆☆")
                    .font(.system(size: 30)).foregroundStyle(AppTheme.fieldGold)
                Text(s >= 2 ? "太棒了！" : (s == 1 ? "过关！" : "再接再厉"))
                    .font(.system(size: 20, weight: .black, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                Text("答对 \(correct) / \(total)").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
                HStack(spacing: 12) {
                    Button { showResult = false; phase = .home; dexVersion += 1 } label: {
                        Text("返回").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(AppTheme.fieldInk)
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .background(Capsule().fill(Color.white.opacity(0.92)).overlay(Capsule().strokeBorder(AppTheme.fieldOlive.opacity(0.3), lineWidth: 2)))
                    }.buttonStyle(.plain)
                    Button { showResult = false; isBrawl ? startBrawl() : startLevel(level) } label: {
                        Text("再来一局").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .background(Capsule().fill(LinearGradient(colors: [Color(red: 0.61, green: 0.55, blue: 0.82), accent], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    }.buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(24).frame(maxWidth: 340)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white))
        }
    }

    // MARK: 流程

    private func startLevel(_ lv: Int) {
        level = lv; isBrawl = false
        list = buildList(tier: tierOf(lv), count: 10)
        begin()
    }
    private func startBrawl() {
        isBrawl = true
        list = (0..<12).map { _ in makeQuestion(tier: Int.random(in: 1...3)) }
        begin()
    }
    private func begin() {
        qi = 0; correct = 0; wrongN = 0; answered = false; picked = ""; fbText = ""; fbOK = false; nextVisible = false
        startDate = Date()
        showResult = false
        phase = .play
        prepareAssemble()
    }
    private func next() {
        PoemSpeechService.shared.stop()
        qi += 1
        if qi >= list.count { finish(); return }
        answered = false; picked = ""; fbText = ""; fbOK = false; nextVisible = false
        prepareAssemble()
    }
    private func prepareAssemble() {
        asmSlot = []; asmUsed = []
        guard list.indices.contains(qi) else { asmTiles = []; return }
        let q = list[qi]
        if q.kind == .assemble {
            let decoys = kDecoyParts.filter { !q.base.parts.contains($0) }.shuffled().prefix(2)
            asmTiles = (q.base.parts + decoys).shuffled()
        } else { asmTiles = [] }
    }

    private func tierOf(_ lv: Int) -> Int { lv <= 3 ? 1 : (lv <= 7 ? 2 : 3) }

    private func buildList(tier: Int, count: Int) -> [RareQuestion] {
        (0..<count).map { _ in makeQuestion(tier: tier) }
    }

    private func makeQuestion(tier: Int) -> RareQuestion {
        let pool = kRareChars.filter { $0.tier == tier }
        let wq = RareStore.wrongs()
        let wcands = pool.filter { wq.contains($0.c) }
        let base: RareChar
        if !wcands.isEmpty && Double.random(in: 0...1) < 0.6 { base = wcands.randomElement()! }
        else { base = pool.randomElement()! }

        var kinds: [RareQKind] = [.read, .meaning]
        if tier >= 2 { kinds.append(.listen) }
        if base.parts.count >= 2 && (tier >= 3 || Double.random(in: 0...1) < 0.35) { kinds.append(.assemble) }
        return RareQuestion(kind: kinds.randomElement()!, base: base)
    }

    private func answer(_ o: String, _ ans: String, _ exp: String) {
        guard !answered else { return }
        answered = true; picked = o
        if o == ans {
            correct += 1; fbText = "✓ 答对了！"; fbOK = true
            if let b = list[safe: qi]?.base { RareStore.addDex(b.c); RareStore.removeWrong(b.c); PoemSpeechService.shared.speak(text: b.say) }
        } else {
            wrongN += 1; fbText = "✗ 正确答案：\(ans) · \(exp)"; fbOK = false
            if let b = list[safe: qi]?.base { RareStore.addWrong(b.c) }
        }
        nextVisible = true
    }

    private func asmTap(_ i: Int, _ p: String, _ q: RareQuestion) {
        guard !answered, !asmUsed.contains(i), asmSlot.count < q.base.parts.count else { return }
        asmUsed.insert(i); asmSlot.append(p)
        if asmSlot.count == q.base.parts.count {
            answered = true
            if asmSlot == q.base.parts {
                correct += 1; fbText = "✓ 拼对啦！\(q.base.c) = \(q.base.parts.joined(separator: " + ")) · \(q.base.py)"; fbOK = true
                RareStore.addDex(q.base.c); RareStore.removeWrong(q.base.c); PoemSpeechService.shared.speak(text: q.base.say)
            } else {
                wrongN += 1; fbText = "✗ 应该是 \(q.base.parts.joined(separator: " + ")) = \(q.base.c)"; fbOK = false
                RareStore.addWrong(q.base.c)
            }
            nextVisible = true
        }
    }

    private func finish() {
        let total = list.count
        let acc = total > 0 ? Int((Double(correct) / Double(total) * 100).rounded()) : 0
        let s = acc >= 90 ? 3 : (acc >= 70 ? 2 : (acc >= 50 ? 1 : 0))
        if !isBrawl { RareStore.setStar(level, s) }
        dexVersion += 1
        showResult = true
    }

    // MARK: 背景

    private var decorations: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Circle().fill(RadialGradient(colors: [Color(red: 1, green: 0.92, blue: 0.55), Color(red: 1, green: 0.78, blue: 0.30)], center: .center, startRadius: 0, endRadius: 32))
                    .frame(width: 62, height: 62).opacity(0.5).position(x: w * 0.85, y: h * 0.08)
                cloud.opacity(0.55).position(x: w * 0.16, y: h * 0.09)
                cloud.opacity(0.4).scaleEffect(0.7).position(x: w * 0.62, y: h * 0.04)
                ForEach(0..<10, id: \.self) { i in
                    Text(["✨", "🀄", "📖", "🖌️"][i % 4]).font(.system(size: i % 3 == 0 ? 15 : 12)).opacity(0.22)
                        .position(x: w * Double((i * 67) % 100) / 100, y: h * Double((i * 43) % 90) / 100)
                }
            }
            .allowsHitTesting(false)
        }
    }
    private var cloud: some View {
        HStack(spacing: -6) {
            Circle().fill(Color.white.opacity(0.65)).frame(width: 28, height: 28)
            Circle().fill(Color.white.opacity(0.55)).frame(width: 36, height: 36)
            Circle().fill(Color.white.opacity(0.5)).frame(width: 24, height: 24)
        }
    }

    // MARK: 玩法弹窗

    private var helpSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Text("?").font(.system(size: 24, weight: .black)).foregroundStyle(accent)
                        .frame(width: 46, height: 46).background(Circle().fill(accentSoft))
                    Text("生僻字大闯关怎么玩").font(.system(size: 21, weight: .black, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                }
                VStack(alignment: .leading, spacing: 10) {
                    helpLine("不要求默写", "只认读音、辨字形。")
                    helpLine("🔊 听音找字", "点喇叭听读音，找出对应汉字。")
                    helpLine("🧩 拆字拼装", "把生僻字拆成部件，从字盘拼回来。")
                    helpLine("👀 读音单选 / 字义猜字", "看字选音、看义选字。")
                    helpLine("错题回流", "答错的字下次优先再考。")
                    helpLine("字卡图鉴", "答对解锁字卡，集齐全部。")
                }
                Button { showHelp = false } label: {
                    Text("知道了").font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50).background(Capsule().fill(accent))
                }.buttonStyle(.plain).padding(.top, 6)
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
    }

    private func helpLine(_ t: String, _ d: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(accent).frame(width: 6, height: 6).padding(.top, 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(t).font(.system(size: 14.5, weight: .heavy, design: .serif)).foregroundStyle(AppTheme.fieldInk)
                Text(d).font(.system(size: 12.5, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.fieldMoss)
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
