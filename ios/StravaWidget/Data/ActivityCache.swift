import Foundation

final class ActivityCache {
    static let shared = ActivityCache()

    private let userDefaults: UserDefaults

    private let activityLevelsKey = "activity_levels"
    private let lastSyncKey = "last_sync"
    private let isLoggedInKey = "is_logged_in"

    private init() {
        userDefaults = UserDefaults(suiteName: Constants.appGroupID) ?? .standard
    }

    var isLoggedIn: Bool {
        get { userDefaults.bool(forKey: isLoggedInKey) }
        set { userDefaults.set(newValue, forKey: isLoggedInKey) }
    }

    func saveActivityLevels(_ levels: [String: Int]) {
        userDefaults.set(levels, forKey: activityLevelsKey)
        userDefaults.set(Date().timeIntervalSince1970, forKey: lastSyncKey)
    }

    func getActivityLevels() -> [String: Int] {
        userDefaults.dictionary(forKey: activityLevelsKey) as? [String: Int] ?? [:]
    }

    func getLastSyncTime() -> TimeInterval {
        userDefaults.double(forKey: lastSyncKey)
    }

    func clear() {
        userDefaults.removeObject(forKey: activityLevelsKey)
        userDefaults.removeObject(forKey: lastSyncKey)
        isLoggedIn = false
    }
}
