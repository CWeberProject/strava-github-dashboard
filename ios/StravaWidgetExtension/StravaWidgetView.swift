import SwiftUI
import WidgetKit

struct StravaWidgetView: View {
    let entry: StravaWidgetEntry

    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        ZStack {
            Color(hex: Constants.widgetBackgroundColor)

            if entry.isLoggedIn {
                HeatmapGridView(
                    gridDates: entry.gridDates,
                    activityLevels: entry.activityLevels
                )
                .padding(widgetFamily == .systemSmall ? 6 : 12)
            } else {
                notLoggedInView
            }
        }
        .widgetURL(URL(string: entry.isLoggedIn ? "strava://" : "stravawidget://auth"))
    }

    private var notLoggedInView: some View {
        VStack(spacing: 4) {
            Image(systemName: "figure.run")
                .font(.title2)
                .foregroundColor(.orange)
            Text("Tap to connect")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

#Preview(as: .systemSmall) {
    StravaActivityWidget()
} timeline: {
    StravaWidgetEntry.preview
}

#Preview(as: .systemMedium) {
    StravaActivityWidget()
} timeline: {
    StravaWidgetEntry.preview
}
