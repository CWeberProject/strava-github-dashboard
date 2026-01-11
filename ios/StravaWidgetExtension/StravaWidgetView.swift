import SwiftUI
import WidgetKit

struct StravaWidgetView: View {
    let entry: StravaWidgetEntry

    var body: some View {
        ZStack {
            Color(hex: Constants.widgetBackgroundColor)

            if entry.isLoggedIn {
                HeatmapGridView(activityLevels: entry.activityLevels)
                    .padding(4)
            } else {
                notLoggedInView
            }
        }
        .widgetURL(URL(string: "stravawidget://open-strava"))
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
