import Foundation

enum WidgetDataProvider {
    static func upcomingBirthdays() -> [Friend] {
        let window = upcomingDaysWindow()
        guard
            let data = SharedStore.sharedDefaults.data(forKey: SharedStore.friendsKey),
            let friends = try? JSONDecoder().decode([Friend].self, from: data)
        else { return [] }
        return friends
            .filter { $0.birthday != nil }
            .filter { ($0.daysUntilBirthday ?? 999) <= window }
            .sorted { ($0.daysUntilBirthday ?? 999) < ($1.daysUntilBirthday ?? 999) }
    }

    static func upcomingDaysWindow() -> Int {
        let days = SharedStore.sharedDefaults.integer(forKey: SharedStore.upcomingDaysKey)
        return days > 0 ? days : 30
    }
}
