import WidgetKit

struct StravaWidgetEntry: TimelineEntry {
    let date: Date
    let activityLevels: [String: Int]
    let isLoggedIn: Bool

    static var placeholder: StravaWidgetEntry {
        StravaWidgetEntry(
            date: Date(),
            activityLevels: [:],
            isLoggedIn: false
        )
    }

    static var preview: StravaWidgetEntry {
        // Create sample data for preview (covering enough days for medium widget)
        var sampleLevels: [String: Int] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let calendar = Calendar.current
        for i in 0..<168 {  // 24 weeks * 7 days for medium widget
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let dateStr = formatter.string(from: date)
                sampleLevels[dateStr] = Int.random(in: 0...4)
            }
        }

        return StravaWidgetEntry(
            date: Date(),
            activityLevels: sampleLevels,
            isLoggedIn: true
        )
    }
}
