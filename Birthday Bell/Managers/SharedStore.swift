import Foundation

enum SharedStore {
    static let suiteName      = "group.com.damianharvey.birthdaybell"
    static let friendsKey     = "friends_data"
    static let upcomingDaysKey = "upcomingDaysToShow"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: suiteName)!
    }
}
