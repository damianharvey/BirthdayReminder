import WidgetKit
import Foundation

struct BirthdayWidgetEntry: TimelineEntry {
    let date: Date
    let upcomingFriends: [Friend]
    let upcomingDaysWindow: Int
}
