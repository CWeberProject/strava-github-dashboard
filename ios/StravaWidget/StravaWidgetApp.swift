import SwiftUI
import WidgetKit

@main
struct StravaWidgetApp: App {
    @Environment(\.openURL) private var openURL

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleURL(url)
                }
        }
    }

    private func handleURL(_ url: URL) {
        if url.scheme == "stravawidget" {
            if url.host == "open-strava" {
                if let stravaURL = URL(string: "strava://") {
                    openURL(stravaURL)
                }
            }
        }
    }
}
