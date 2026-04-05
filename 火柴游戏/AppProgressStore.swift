import Combine
import Foundation
import SwiftUI

struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String

    static let all: [Achievement] = [
        Achievement(id: "first_match", title: "初露锋芒", subtitle: "首次解对一道火柴题", systemImage: "flame.fill"),
        Achievement(id: "match_10", title: "炉火纯青", subtitle: "累计解对 10 道火柴题", systemImage: "10.circle.fill"),
        Achievement(id: "streak_3", title: "三日坚持", subtitle: "连续打卡满 3 天", systemImage: "calendar.badge.clock"),
        Achievement(id: "poem_10", title: "开卷有益", subtitle: "在诗库中读过 10 首不同的诗", systemImage: "book.pages.fill")
    ]
}

/// 轻量进度与成就（UserDefaults），驱动首页「今日」与个人页统计。
final class AppProgressStore: ObservableObject {
    static let shared = AppProgressStore()

    @Published var selectedTab: Int = 0

    @Published private(set) var streakDays: Int
    @Published private(set) var totalMatchstickSolves: Int
    @Published private(set) var openedPoemIds: Set<Int>
    @Published private(set) var unlockedAchievementIds: Set<String>
    @Published private(set) var dailyMatchstickCompletedDayOrdinal: Int?
    /// 自由模式书签：下次从该题继续（0-based）。
    @Published private(set) var matchstickBookmarkIndex: Int

    private let defaults = UserDefaults.standard

    private enum Key {
        static let streak = "progress.streakDays"
        static let lastActiveDay = "progress.lastActiveDayOrdinal"
        static let totalSolves = "progress.totalMatchstickSolves"
        static let openedPoems = "progress.openedPoemIds"
        static let achievements = "progress.unlockedAchievementIds"
        static let dailyMatchDone = "progress.dailyMatchstickDayOrdinal"
        static let matchstickBookmark = "progress.matchstickBookmarkIndex"
    }

    private init() {
        streakDays = defaults.integer(forKey: Key.streak)
        totalMatchstickSolves = defaults.integer(forKey: Key.totalSolves)
        if let data = defaults.data(forKey: Key.openedPoems),
           let ids = try? JSONDecoder().decode([Int].self, from: data) {
            openedPoemIds = Set(ids)
        } else {
            openedPoemIds = []
        }
        if let data = defaults.data(forKey: Key.achievements),
           let arr = try? JSONDecoder().decode([String].self, from: data) {
            unlockedAchievementIds = Set(arr)
        } else {
            unlockedAchievementIds = []
        }
        let v = defaults.integer(forKey: Key.dailyMatchDone)
        dailyMatchstickCompletedDayOrdinal = v > 0 ? v : nil
        matchstickBookmarkIndex = max(0, defaults.integer(forKey: Key.matchstickBookmark))
    }

    private var todayOrdinal: Int {
        let day = Calendar.current.startOfDay(for: Date())
        return Int(day.timeIntervalSince1970 / 86400)
    }

    /// 进入首页或完成学习动作时调用，更新连续打卡。
    func refreshStreakOnActivity() {
        let today = todayOrdinal
        let last = defaults.object(forKey: Key.lastActiveDay) as? Int

        if last == today { return }

        if let last, last == today - 1 {
            streakDays = max(1, streakDays + 1)
        } else if last == nil {
            streakDays = max(1, streakDays)
        } else {
            streakDays = 1
        }

        defaults.set(today, forKey: Key.lastActiveDay)
        defaults.set(streakDays, forKey: Key.streak)
        objectWillChange.send()
    }

    func recordMatchstickSuccess(isDailyChallenge: Bool) {
        refreshStreakOnActivity()
        totalMatchstickSolves += 1
        defaults.set(totalMatchstickSolves, forKey: Key.totalSolves)

        if isDailyChallenge {
            dailyMatchstickCompletedDayOrdinal = todayOrdinal
            defaults.set(todayOrdinal, forKey: Key.dailyMatchDone)
        }

        evaluateAchievements()
        objectWillChange.send()
    }

    func recordPoemOpened(id: Int) {
        refreshStreakOnActivity()
        if openedPoemIds.insert(id).inserted {
            persistPoems()
            evaluateAchievements()
            objectWillChange.send()
        }
    }

    func isDailyMatchstickCompletedToday() -> Bool {
        dailyMatchstickCompletedDayOrdinal == todayOrdinal
    }

    func dailyMatchstickProblemIndex(totalProblems: Int) -> Int {
        guard totalProblems > 0 else { return 0 }
        let n = todayOrdinal
        return abs(n) % totalProblems
    }

    /// 保存当前做到第几题（自由模式下次继续）。
    func saveMatchstickBookmark(index: Int, totalProblems: Int) {
        guard totalProblems > 0 else { return }
        let clamped = min(max(0, index), totalProblems - 1)
        matchstickBookmarkIndex = clamped
        defaults.set(clamped, forKey: Key.matchstickBookmark)
    }

    private func persistPoems() {
        let arr = Array(openedPoemIds).sorted()
        if let data = try? JSONEncoder().encode(arr) {
            defaults.set(data, forKey: Key.openedPoems)
        }
    }

    private func persistAchievements() {
        let arr = Array(unlockedAchievementIds).sorted()
        if let data = try? JSONEncoder().encode(arr) {
            defaults.set(data, forKey: Key.achievements)
        }
    }

    private func evaluateAchievements() {
        var changed = false
        func unlock(_ id: String) {
            if unlockedAchievementIds.insert(id).inserted { changed = true }
        }

        if totalMatchstickSolves >= 1 { unlock("first_match") }
        if totalMatchstickSolves >= 10 { unlock("match_10") }
        if streakDays >= 3 { unlock("streak_3") }
        if openedPoemIds.count >= 10 { unlock("poem_10") }

        if changed { persistAchievements() }
    }
}
