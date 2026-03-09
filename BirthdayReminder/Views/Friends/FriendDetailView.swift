import SwiftUI

struct FriendDetailView: View {
    @EnvironmentObject var friendsManager:  FriendsManager
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss

    // Keep a local copy that refreshes when edits are saved
    @State private var friend: Friend
    @State private var showingEdit        = false
    @State private var showingDeleteAlert = false

    init(friend: Friend) {
        _friend = State(initialValue: friend)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    heroHeader
                        .padding(.bottom, 32)

                    if !friend.phoneNumbers.isEmpty || !friend.emailAddresses.isEmpty {
                        contactSection
                            .padding(.horizontal, 16)
                    }

                    reminderSection
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    deleteButton
                        .padding(.horizontal, 16)
                        .padding(.top, 32)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showingEdit = true }
                    .foregroundColor(AppTheme.accent)
            }
        }
        .sheet(isPresented: $showingEdit, onDismiss: syncFriend) {
            FriendFormView(mode: .edit(friend))
        }
        .alert("Delete \(friend.fullName)?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                friendsManager.delete(friend)
                NotificationManager.scheduleAll(
                    friends: friendsManager.friends,
                    defaultDays: settingsManager.defaultReminderDays
                )
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: - Sub-views

    private var heroHeader: some View {
        VStack(spacing: 10) {
            AvatarView(friend: friend, size: 80)
                .padding(.top, 24)

            Text(friend.fullName)
                .font(.system(size: 26, weight: .light))
                .foregroundColor(AppTheme.primary)

            if let str = friend.birthdayString {
                HStack(spacing: 6) {
                    Image(systemName: "birthday.cake")
                        .font(.system(size: 12))
                    Text(str)
                    if let days = friend.daysUntilBirthday {
                        Text("·")
                        Text(days == 0 ? "Today!" : "in \(days) days")
                            .foregroundColor(days <= 7 ? AppTheme.accent : AppTheme.secondary)
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(AppTheme.secondary)
            }
        }
    }

    private var contactSection: some View {
        VStack(spacing: 1) {
            ForEach(friend.phoneNumbers) { phone in
                contactRow(
                    icon: "phone.fill",
                    label: phone.label,
                    value: phone.number
                ) { open("tel://\(phone.number.filter(\.isNumber))") }

                Divider().background(AppTheme.divider).padding(.leading, 52)
            }

            ForEach(Array(friend.emailAddresses.enumerated()), id: \.element.id) { idx, email in
                if idx > 0 || !friend.phoneNumbers.isEmpty {
                    Divider().background(AppTheme.divider).padding(.leading, 52)
                }
                contactRow(
                    icon: "envelope.fill",
                    label: email.label,
                    value: email.email
                ) { open("mailto:\(email.email)") }
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var reminderSection: some View {
        let isDefault = friend.reminderDays.isEmpty
        let days = isDefault
            ? [settingsManager.defaultReminderDays]
            : friend.reminderDays.sorted()

        return VStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, d in
                HStack {
                    Image(systemName: "bell")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 20)

                    Text("\(d) day\(d == 1 ? "" : "s") before")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.primary)

                    Spacer()

                    if isDefault {
                        Text("default")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.secondary)
                    }
                }
                .padding(16)

                if index < days.count - 1 {
                    Divider()
                        .background(AppTheme.divider)
                        .padding(.leading, 52)
                }
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var deleteButton: some View {
        Button {
            showingDeleteAlert = true
        } label: {
            Text("Delete Friend")
                .font(.system(size: 15))
                .foregroundColor(Color.red.opacity(0.75))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Helpers

    private func contactRow(icon: String, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.accent)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 1) {
                    if !label.isEmpty {
                        Text(label)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.secondary)
                    }
                    Text(value)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.divider)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func syncFriend() {
        if let updated = friendsManager.friends.first(where: { $0.id == friend.id }) {
            friend = updated
        }
    }

    private func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}
