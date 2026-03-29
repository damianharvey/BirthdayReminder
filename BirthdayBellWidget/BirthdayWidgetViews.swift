import SwiftUI
import WidgetKit

struct BirthdayWidgetEntryView: View {
    var entry: BirthdayWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryInline:      InlineWidgetView(entry: entry)
        case .accessoryCircular:    CircularWidgetView(entry: entry)
        case .accessoryRectangular: RectangularWidgetView(entry: entry)
        default:                    RectangularWidgetView(entry: entry)
        }
    }
}

// MARK: - accessoryInline

struct InlineWidgetView: View {
    let entry: BirthdayWidgetEntry

    var body: some View {
        if let friend = entry.upcomingFriends.first {
            Label("\(friend.firstName) · \(daysLabel(friend))", systemImage: "birthday.cake")
        } else {
            Label("No upcoming birthdays", systemImage: "birthday.cake")
        }
    }

    private func daysLabel(_ friend: Friend) -> String {
        switch friend.daysUntilBirthday {
        case 0:       return "Today!"
        case 1:       return "Tomorrow"
        case let d?:  return "\(d)d"
        default:      return ""
        }
    }
}

// MARK: - accessoryCircular

struct CircularWidgetView: View {
    let entry: BirthdayWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if entry.upcomingFriends.isEmpty {
                Image(systemName: "birthday.cake")
                    .font(.system(size: 20))
            } else {
                VStack(spacing: 1) {
                    Text("\(entry.upcomingFriends.count)")
                        .font(.system(size: 24, weight: .semibold))
                    Text("upcoming")
                        .font(.system(size: 9))
                }
            }
        }
    }
}

// MARK: - accessoryRectangular

struct RectangularWidgetView: View {
    let entry: BirthdayWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if entry.upcomingFriends.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "birthday.cake")
                    Text("No upcoming birthdays")
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)
            } else {
                ForEach(entry.upcomingFriends.prefix(3)) { friend in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.avatar(friend.avatarColor))
                            .frame(width: 18, height: 18)
                            .overlay(
                                Text(friend.initials)
                                    .font(.system(size: 6, weight: .medium))
                                    .foregroundColor(.white)
                            )
                        Text(friend.firstName)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        Spacer()
                        Text(daysLabel(friend))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private func daysLabel(_ friend: Friend) -> String {
        switch friend.daysUntilBirthday {
        case 0:       return "Today!"
        case 1:       return "1d"
        case let d?:  return "\(d)d"
        default:      return ""
        }
    }
}
