import Foundation
import WidgetKit

final class StravaRepository {
    static let shared = StravaRepository()

    private let tokenStorage = TokenStorage.shared
    private let activityCache = ActivityCache.shared
    private let client = StravaClient.shared

    private init() {}

    var isLoggedIn: Bool {
        tokenStorage.isLoggedIn
    }

    // MARK: - Token Management

    func saveTokens(from response: TokenResponse) {
        tokenStorage.saveTokens(from: response)
    }

    private func refreshTokenIfNeeded() async -> Bool {
        guard tokenStorage.isTokenExpired else { return true }
        guard let refreshToken = tokenStorage.refreshToken else { return false }

        do {
            let response = try await client.refreshToken(refreshToken)
            saveTokens(from: response)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Sync Activities

    @discardableResult
    func syncActivities() async throws -> [String: Int] {
        guard isLoggedIn else {
            throw RepositoryError.notLoggedIn
        }

        guard await refreshTokenIfNeeded() else {
            throw RepositoryError.tokenRefreshFailed
        }

        guard let accessToken = tokenStorage.accessToken else {
            throw RepositoryError.noAccessToken
        }

        let after = getStartOfPeriod()
        let activities = try await client.getActivities(accessToken: accessToken, after: after)
        let levels = calculateLevels(activities)

        activityCache.saveActivityLevels(levels)

        // Reload widget timelines
        WidgetCenter.shared.reloadTimelines(ofKind: "StravaActivityWidget")

        return levels
    }

    func getCachedActivityLevels() -> [String: Int] {
        activityCache.getActivityLevels()
    }

    // MARK: - Level Calculation

    private func getStartOfPeriod() -> TimeInterval {
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -Constants.totalDays, to: today)!
        return calendar.startOfDay(for: startDate).timeIntervalSince1970
    }

    private func calculateLevels(_ activities: [StravaActivity]) -> [String: Int] {
        var minutesByDate: [String: Int] = [:]

        for activity in activities {
            let date = String(activity.startDateLocal.prefix(10))
            let minutes = activity.movingTime / 60
            minutesByDate[date, default: 0] += minutes
        }

        return minutesByDate.mapValues { minutes in
            ActivityLevel.from(minutes: minutes).rawValue
        }
    }

    // MARK: - Grid Date Calculation

    static func getGridDates() -> [Date?] {
        let calendar = Calendar.current
        let today = Date()

        // Get current day of week (Sunday = 1 in Calendar)
        let currentDayOfWeek = calendar.component(.weekday, from: today) - 1

        // End date is Saturday of current week
        let endDate = calendar.date(byAdding: .day, value: 6 - currentDayOfWeek, to: today)!

        // Start date is Sunday 12 weeks before
        let startDate = calendar.date(byAdding: .day, value: -(Constants.totalDays - 1), to: endDate)!

        var dates: [Date?] = []

        // Build grid: 7 rows (days) x 13 columns (weeks)
        for dayOfWeek in 0..<Constants.daysPerWeek {
            for week in 0..<Constants.weeksToShow {
                let dayOffset = week * 7 + dayOfWeek
                let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!

                if date > today {
                    dates.append(nil)
                } else {
                    dates.append(date)
                }
            }
        }

        return dates
    }

    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Logout

    func logout() {
        tokenStorage.clear()
        activityCache.clear()
        WidgetCenter.shared.reloadTimelines(ofKind: "StravaActivityWidget")
    }
}

// MARK: - Errors

enum RepositoryError: Error, LocalizedError {
    case notLoggedIn
    case tokenRefreshFailed
    case noAccessToken

    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "Not logged in to Strava"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        case .noAccessToken:
            return "No access token available"
        }
    }
}
