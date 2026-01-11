import WidgetKit

struct StravaWidgetTimelineProvider: TimelineProvider {
    typealias Entry = StravaWidgetEntry

    func placeholder(in context: Context) -> StravaWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (StravaWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.preview)
        } else {
            completion(makeEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StravaWidgetEntry>) -> Void) {
        Task {
            // Try to sync fresh data
            let repository = StravaRepository.shared
            if repository.isLoggedIn {
                _ = try? await repository.syncActivities()
            }

            let entry = makeEntry()

            // Refresh timeline in 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

            completion(timeline)
        }
    }

    private func makeEntry() -> StravaWidgetEntry {
        let repository = StravaRepository.shared
        return StravaWidgetEntry(
            date: Date(),
            activityLevels: repository.getCachedActivityLevels(),
            isLoggedIn: repository.isLoggedIn,
            gridDates: StravaRepository.getGridDates()
        )
    }
}
