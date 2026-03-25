import SwiftUI

struct HomeView: View {
    @EnvironmentObject var friendsManager:  FriendsManager
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var selectedFriend: Friend?

    private var upcoming: [Friend] {
        friendsManager.upcomingBirthdays(within: settingsManager.upcomingDaysToShow)
    }

    private var todayFriends: [Friend] {
        upcoming.filter { $0.daysUntilBirthday == 0 }
    }

    private var futureFriends: [Friend] {
        upcoming.filter { ($0.daysUntilBirthday ?? 1) > 0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 28)

                        if upcoming.isEmpty {
                            emptyState
                        } else {
                            if !todayFriends.isEmpty {
                                sectionHeader("Message Today")
                                cardList(todayFriends, showDots: true)
                            }

                            if !futureFriends.isEmpty {
                                if !todayFriends.isEmpty {
                                    sectionHeader("Upcoming")
                                }
                                cardList(futureFriends, showDots: false)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedFriend) { friend in
                BirthdayMessageView(friend: friend)
            }
        }
    }

    // MARK: - Sub-views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(AppTheme.secondary)
            .textCase(.uppercase)
            .tracking(1.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    private func cardList(_ friends: [Friend], showDots: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                BirthdayCard(
                    friend: friend,
                    showDot: showDots && !friendsManager.hasBeenMessaged(friend)
                )
                .onTapGesture {
                    if friend.daysUntilBirthday == 0 {
                        friendsManager.markMessaged(friend)
                    }
                    selectedFriend = friend
                }

                if index < friends.count - 1 {
                    Divider()
                        .background(AppTheme.divider)
                        .padding(.leading, 98)
                }
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.secondary)
                .textCase(.uppercase)
                .tracking(1.5)

            Text("Upcoming")
                .font(.system(size: 34, weight: .light))
                .foregroundColor(AppTheme.primary)

            Text(todayLabel)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "birthday.cake")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundColor(AppTheme.secondary.opacity(0.4))

            Text("No upcoming birthdays")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(AppTheme.secondary)

            Text("within the next \(settingsManager.upcomingDaysToShow) days")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
    }

    // MARK: - Helpers

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default:     return "Good evening"
        }
    }

    private var todayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

}

// MARK: - Birthday Card

struct BirthdayCard: View {
    let friend: Friend
    var showDot: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Fixed-width dot column keeps all cards aligned
            ZStack {
                if showDot {
                    Circle()
                        .fill(Color(.systemBlue))
                        .frame(width: 10, height: 10)
                }
            }
            .frame(width: 20)

            AvatarView(friend: friend, size: 50)

            VStack(alignment: .leading, spacing: 3) {
                Text(friend.fullName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.primary)

                HStack(spacing: 4) {
                    if let str = friend.birthdayString {
                        Text(str)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.secondary)
                    }
                    if let age = friend.turningAge {
                        Text("· turns \(age)")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.secondary)
                    }
                }
            }
            .padding(.leading, 16)

            Spacer()

            daysLabel
        }
        .padding(.leading, 8)
        .padding(.trailing, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var daysLabel: some View {
        if let days = friend.daysUntilBirthday {
            if days == 0 {
                Text("Today!")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
            } else {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(days)")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(days <= 7 ? AppTheme.accent : AppTheme.primary)
                    Text("days")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.secondary)
                }
            }
        }
    }
}
