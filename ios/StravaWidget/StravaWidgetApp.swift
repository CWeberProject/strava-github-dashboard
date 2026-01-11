import SwiftUI
import WidgetKit

@main
struct StravaWidgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleURL(url)
                }
        }
    }

    private func handleURL(_ url: URL) {
        if url.scheme == "stravawidget" && url.host == "auth" {
            // Auth flow will be triggered by ContentView
        }
    }
}
