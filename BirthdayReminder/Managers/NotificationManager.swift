import Foundation
import UserNotifications

enum NotificationManager {

    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    /// Schedule (or reschedule) notifications for a single friend.
    /// Because notifications are grouped by fire-date, we do a full rebuild
    /// whenever any friend changes so the counts stay accurate.
    static func scheduleReminders(for friend: Friend, defaultDays: Int, allFriends: [Friend]) {
        scheduleAll(friends: allFriends, defaultDays: defaultDays)
    }

    /// Remove all birthday notifications then rebuild grouped summaries for
    /// every unique fire-date across all friends.
    ///
    /// Notifications are non-repeating and scheduled for both this year and
    /// next year so that the app doesn't need to be opened for a full year
    /// to keep reminders alive. iOS allows up to 64 pending notifications;
    /// we cap at 60 and prioritise the soonest dates.
    static func scheduleAll(friends: [Friend], defaultDays: Int) {
        let center = UNUserNotificationCenter.current()

        center.getPendingNotificationRequests { existing in
            // Remove all previously-scheduled birthday notifications
            let old = existing
                .filter { $0.identifier.hasPrefix("birthday_") }
                .map    { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: old)

            let calendar = Calendar.current
            let today    = calendar.startOfDay(for: Date())

            // Build a map of fireDate -> [Friend] covering two years
            var dateMap: [Date: [Friend]] = [:]

            for friend in friends {
                guard let birthday = friend.birthday else { continue }
                let reminderList = friend.reminderDays.isEmpty ? [defaultDays] : friend.reminderDays

                for d in reminderList {
                    for yearOffset in 0...1 {
                        var bdayComps      = calendar.dateComponents([.month, .day], from: birthday)
                        bdayComps.year     = calendar.component(.year, from: today) + yearOffset

                        guard
                            let bdayDate   = calendar.date(from: bdayComps),
                            let fireDate   = calendar.date(byAdding: .day, value: -d, to: bdayDate)
                        else { continue }

                        let fireDayStart = calendar.startOfDay(for: fireDate)
                        guard fireDayStart >= today else { continue }

                        dateMap[fireDayStart, default: []].append(friend)
                    }
                }
            }

            // De-duplicate friends on the same fire-date (a friend can appear
            // via multiple reminder values but should only count once per day)
            var deduped: [Date: [Friend]] = [:]
            for (date, friends) in dateMap {
                var seen  = Set<UUID>()
                var unique: [Friend] = []
                for f in friends where seen.insert(f.id).inserted {
                    unique.append(f)
                }
                deduped[date] = unique
            }

            // Keep only the 60 soonest fire-dates to stay under iOS's 64-notification cap
            let sortedDates = deduped.keys.sorted().prefix(60)

            DispatchQueue.main.async {
                for date in sortedDates {
                    guard let friends = deduped[date] else { continue }
                    schedule(friends: friends, on: date)
                }
            }
        }
    }

    static func removeReminders(for friend: Friend, completion: (() -> Void)? = nil) {
        // Removing individual friend notifications isn't meaningful in the
        // grouped model — callers should follow up with scheduleAll instead.
        DispatchQueue.main.async { completion?() }
    }

    // MARK: - Private

    private static func schedule(friends: [Friend], on date: Date) {
        let id      = "birthday_\(Int(date.timeIntervalSince1970))"
        let count   = friends.count
        let content = UNMutableNotificationContent()
        content.sound = .default

        if count == 1, let friend = friends.first {
            content.title = "\(friend.fullName)'s birthday is coming up"
            content.body  = reminderBody(for: friend, on: date)
        } else {
            content.title = "You have \(count) birthday reminders today"
            let names = friends
                .sorted { $0.daysUntilBirthday ?? 999 < $1.daysUntilBirthday ?? 999 }
                .prefix(3)
                .map { $0.firstName }
                .joined(separator: ", ")
            content.body = count > 3 ? "\(names) and \(count - 3) more" : names
        }

        let calendar    = Calendar.current
        var comps       = calendar.dateComponents([.year, .month, .day], from: date)
        comps.hour      = 9
        comps.minute    = 0

        // Non-repeating — we rebuild every app open and schedule two years ahead
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        )
    }

    private static func reminderBody(for friend: Friend, on fireDate: Date) -> String {
        guard let birthday = friend.birthday else { return "Don't forget to reach out!" }
        let calendar  = Calendar.current
        var bdayComps = calendar.dateComponents([.month, .day], from: birthday)
        bdayComps.year = calendar.component(.year, from: fireDate)
        guard
            let bdayThis = calendar.date(from: bdayComps),
            let days     = calendar.dateComponents([.day], from: fireDate, to: bdayThis).day
        else { return "Don't forget to reach out!" }

        switch days {
        case 0:  return "It's today — wish them a happy birthday!"
        case 1:  return "It's tomorrow — don't forget to reach out."
        default: return "Their birthday is in \(days) days."
        }
    }
}
