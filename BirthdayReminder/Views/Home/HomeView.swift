import SwiftUI

struct HomeView: View {
    @EnvironmentObject var friendsManager:  FriendsManager
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var selectedFriend: Friend?
    @State private var showingAction = false

    private var upcoming: [Friend] {
        friendsManager.upcomingBirthdays(within: settingsManager.upcomingDaysToShow)
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
                            VStack(spacing: 0) {
                                ForEach(Array(upcoming.enumerated()), id: \.element.id) { index, friend in
                                    BirthdayCard(friend: friend)
                                        .onTapGesture {
                                            selectedFriend = friend
                                            showingAction = true
                                        }

                                    if index < upcoming.count - 1 {
                                        Divider()
                                            .background(AppTheme.divider)
                                            .padding(.leading, 88)
                                    }
                                }
                            }
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .confirmationDialog(
                selectedFriend.map { $0.fullName } ?? "",
                isPresented: $showingAction,
                titleVisibility: .visible
            ) {
                contactActions
            }
        }
    }

    // MARK: - Sub-views

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

    @ViewBuilder
    private var contactActions: some View {
        if let friend = selectedFriend {
            if friend.phoneNumbers.isEmpty && friend.emailAddresses.isEmpty {
                Button("No contact information", action: {})
                    .disabled(true)
            } else {
                ForEach(friend.phoneNumbers) { phone in
                    Button("Call \(phone.number)") {
                        open("tel://\(phone.number.filter(\.isNumber))")
                    }
                    Button("Text \(phone.number)") {
                        open("sms:\(phone.number.filter(\.isNumber))")
                    }
                }
                ForEach(friend.emailAddresses) { email in
                    Button("Email \(email.email)") {
                        open("mailto:\(email.email)")
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
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

    private func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Birthday Card

struct BirthdayCard: View {
    let friend: Friend

    var body: some View {
        HStack(spacing: 16) {
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

            Spacer()

            daysLabel
        }
        .padding(.horizontal, 20)
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
