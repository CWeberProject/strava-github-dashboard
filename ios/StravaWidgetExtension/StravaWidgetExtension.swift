import WidgetKit
import SwiftUI

struct StravaActivityWidget: Widget {
    let kind: String = "StravaActivityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StravaWidgetTimelineProvider()) { entry in
            StravaWidgetView(entry: entry)
                .containerBackground(Color(hex: Constants.widgetBackgroundColor), for: .widget)
        }
        .configurationDisplayName("Strava Heatmap")
        .description("Shows your workout activity as a GitHub-style heatmap")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct StravaWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        StravaActivityWidget()
    }
}
