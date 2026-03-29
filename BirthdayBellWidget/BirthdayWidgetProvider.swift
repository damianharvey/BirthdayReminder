import WidgetKit

struct BirthdayWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BirthdayWidgetEntry {
        BirthdayWidgetEntry(date: Date(), upcomingFriends: [], upcomingDaysWindow: 30)
    }

    func getSnapshot(in context: Context, completion: @escaping (BirthdayWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BirthdayWidgetEntry>) -> Void) {
        let entry = makeEntry()
        let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func makeEntry() -> BirthdayWidgetEntry {
        BirthdayWidgetEntry(
            date: Date(),
            upcomingFriends: WidgetDataProvider.upcomingBirthdays(),
            upcomingDaysWindow: WidgetDataProvider.upcomingDaysWindow()
        )
    }
}
