import Foundation

enum Constants {
    static let appGroupID = "group.com.stravawidget"
    static let keychainService = "com.stravawidget.tokens"
    static let keychainAccessGroup = "com.stravawidget.shared"

    static let weeksToShow = 13
    static let daysPerWeek = 7
    static let totalDays = weeksToShow * daysPerWeek

    static let cellSize: CGFloat = 11.2
    static let cellSpacing: CGFloat = 2.8

    static let widgetBackgroundColor = "#1E1E1E"
    static let stravaOrange = "#FC4C02"
}
