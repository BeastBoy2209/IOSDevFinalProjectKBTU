import Foundation
import UIKit

final class UserManager {
    static let shared = UserManager()

    // MARK: - Notifications

    enum NotificationKey {
        static let balance = "balance"
        static let theme = "theme"
        static let bannerClaimed = "bannerClaimed"
    }

    static let didUpdateNotification = Notification.Name("UserManager.didUpdate")

    // MARK: - Types

    enum Theme: String, CaseIterable {
        case system
        case light
        case dark

        var interfaceStyle: UIUserInterfaceStyle {
            switch self {
            case .system: return .unspecified
            case .light: return .light
            case .dark: return .dark
            }
        }

        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }

    struct Transaction: Codable, Equatable {
        let date: Date
        let amount: Int
        let gameName: String

        var isCredit: Bool { amount >= 0 }
    }

    struct Achievement: Codable, Equatable {
        let id: String
        let title: String
        let detail: String
        var isUnlocked: Bool
    }

    struct Stats: Codable, Equatable {
        var gamesPlayed: Int
        var wins: Int

        var winRate: Double {
            guard gamesPlayed > 0 else { return 0 }
            return (Double(wins) / Double(gamesPlayed)) * 100
        }
    }

    // MARK: - Stored State

    private(set) var balance: Int {
        didSet { persist() }
    }

    private(set) var userName: String {
        didSet { persist() }
    }

    private(set) var level: Int {
        didSet { persist() }
    }

    private(set) var stats: Stats {
        didSet { persist() }
    }

    private(set) var transactions: [Transaction] {
        didSet { persist() }
    }

    private(set) var achievements: [Achievement] {
        didSet { persist() }
    }

    private(set) var currentTheme: Theme {
        didSet { persist() }
    }

    private(set) var isHomeBannerClaimed: Bool {
        didSet { persist() }
    }

    // MARK: - Persistence

    private enum DefaultsKey {
        static let payload = "UserManager.payload.v1"
    }

    private struct Payload: Codable {
        var balance: Int
        var userName: String
        var level: Int
        var stats: Stats
        var transactions: [Transaction]
        var achievements: [Achievement]
        var currentThemeRaw: String
        var isHomeBannerClaimed: Bool
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: DefaultsKey.payload),
           let payload = try? JSONDecoder().decode(Payload.self, from: data),
           let theme = Theme(rawValue: payload.currentThemeRaw) {
            self.balance = payload.balance
            self.userName = payload.userName
            self.level = payload.level
            self.stats = payload.stats
            self.transactions = payload.transactions
            self.achievements = payload.achievements
            self.currentTheme = theme
            self.isHomeBannerClaimed = payload.isHomeBannerClaimed
        } else {
            // Seed defaults for first launch.
            self.balance = 15_000
            self.userName = "Player"
            self.level = 1
            self.stats = Stats(gamesPlayed: 0, wins: 0)
            self.transactions = []
            self.achievements = [
                Achievement(id: "first_win", title: "First Win", detail: "Win your first game.", isUnlocked: false),
                Achievement(id: "high_roller", title: "High Roller", detail: "Reach a balance of 100,000.", isUnlocked: false),
                Achievement(id: "ten_games", title: "Getting Started", detail: "Play 10 games.", isUnlocked: false)
            ]
            self.currentTheme = .system
            self.isHomeBannerClaimed = false
            persist()
        }
    }

    private func persist() {
        let payload = Payload(
            balance: balance,
            userName: userName,
            level: level,
            stats: stats,
            transactions: transactions,
            achievements: achievements,
            currentThemeRaw: currentTheme.rawValue,
            isHomeBannerClaimed: isHomeBannerClaimed
        )
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: DefaultsKey.payload)
    }

    // MARK: - Public API

    func addCredits(amount: Int, source: String = "Deposit") {
        guard amount != 0 else { return }

        balance += amount
        transactions.insert(Transaction(date: Date(), amount: amount, gameName: source), at: 0)
        evaluateAchievements()
        notifyChange(balanceChanged: true, themeChanged: false)
    }

    func recordGameResult(gameName: String, didWin: Bool, delta: Int) {
        stats.gamesPlayed += 1
        if didWin { stats.wins += 1 }

        if delta != 0 {
            balance += delta
            transactions.insert(Transaction(date: Date(), amount: delta, gameName: gameName), at: 0)
        }

        evaluateAchievements()
        notifyChange(balanceChanged: delta != 0, themeChanged: false)
    }

    func updateTheme(_ theme: Theme) {
        guard currentTheme != theme else { return }
        currentTheme = theme
        notifyChange(balanceChanged: false, themeChanged: true)
    }

    func updateProfile(name: String? = nil, level: Int? = nil) {
        if let name, !name.isEmpty { userName = name }
        if let level, level > 0 { self.level = level }
        notifyChange(balanceChanged: false, themeChanged: false)
    }

    /// Claims the Home banner bonus once.
    /// - Returns: `true` if claimed now, `false` if it was already claimed before.
    @discardableResult
    func claimHomeBannerBonus(amount: Int = 15_000) -> Bool {
        guard !isHomeBannerClaimed else { return false }
        isHomeBannerClaimed = true
        addCredits(amount: amount, source: "Claim Bonus")
        notifyChange(balanceChanged: true, themeChanged: false, bannerClaimedChanged: true)
        return true
    }

    // MARK: - Helpers

    private func evaluateAchievements() {
        for idx in achievements.indices {
            switch achievements[idx].id {
            case "first_win":
                if stats.wins >= 1 { achievements[idx].isUnlocked = true }
            case "high_roller":
                if balance >= 100_000 { achievements[idx].isUnlocked = true }
            case "ten_games":
                if stats.gamesPlayed >= 10 { achievements[idx].isUnlocked = true }
            default:
                break
            }
        }
    }

    private func notifyChange(balanceChanged: Bool, themeChanged: Bool) {
        notifyChange(balanceChanged: balanceChanged, themeChanged: themeChanged, bannerClaimedChanged: false)
    }

    private func notifyChange(balanceChanged: Bool, themeChanged: Bool, bannerClaimedChanged: Bool) {
        var userInfo: [AnyHashable: Any] = [:]
        if balanceChanged { userInfo[NotificationKey.balance] = balance }
        if themeChanged { userInfo[NotificationKey.theme] = currentTheme.rawValue }
        if bannerClaimedChanged { userInfo[NotificationKey.bannerClaimed] = isHomeBannerClaimed }

        NotificationCenter.default.post(
            name: UserManager.didUpdateNotification,
            object: self,
            userInfo: userInfo
        )
    }
}
