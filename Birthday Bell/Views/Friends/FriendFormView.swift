import SwiftUI

enum FriendFormMode {
    case add
    case edit(Friend)
}

// Wrapper so each reminder row has a stable identity in ForEach
private struct ReminderEntry: Identifiable {
    let id   = UUID()
    var days: Int
}

struct FriendFormView: View {
    @EnvironmentObject var friendsManager:  FriendsManager
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss

    let mode: FriendFormMode

    @State private var firstName:       String          = ""
    @State private var lastName:        String          = ""
    @State private var hasBirthday:     Bool            = false
    @State private var birthday:        Date            = Calendar.current.date(
                                                          byAdding: .year,
                                                          value: -30,
                                                          to: Date()
                                                         ) ?? Date()
    @State private var phoneNumbers:    [PhoneNumber]   = []
    @State private var emailAddresses:  [EmailAddress]  = []
    @State private var reminders:       [ReminderEntry] = []

    private var title: String {
        if case .edit = mode { return "Edit Friend" }
        return "New Friend"
    }

    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty ||
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                Form {
                    // Name
                    Section {
                        TextField("First name", text: $firstName)
                            .foregroundColor(AppTheme.primary)
                        TextField("Last name", text: $lastName)
                            .foregroundColor(AppTheme.primary)
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.divider)

                    // Birthday
                    Section {
                        Toggle(isOn: $hasBirthday.animation()) {
                            Label("Birthday", systemImage: "birthday.cake")
                                .foregroundColor(AppTheme.primary)
                        }
                        .tint(AppTheme.accent)

                        if hasBirthday {
                            DatePicker("Date",
                                       selection: $birthday,
                                       displayedComponents: .date)
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.divider)

                    // Phone numbers
                    Section {
                        ForEach($phoneNumbers) { $phone in
                            HStack(spacing: 10) {
                                Image(systemName: "phone")
                                    .foregroundColor(AppTheme.secondary)
                                    .frame(width: 18)
                                TextField("Number", text: $phone.number)
                                    .keyboardType(.phonePad)
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                        .onDelete { phoneNumbers.remove(atOffsets: $0) }

                        Button {
                            phoneNumbers.append(PhoneNumber(label: "mobile", number: ""))
                        } label: {
                            Label("Add Phone", systemImage: "plus")
                                .foregroundColor(AppTheme.accent)
                                .font(.system(size: 15))
                        }
                    } header: {
                        SectionHeader(title: "Phone Numbers")
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.divider)

                    // Email addresses
                    Section {
                        ForEach($emailAddresses) { $email in
                            HStack(spacing: 10) {
                                Image(systemName: "envelope")
                                    .foregroundColor(AppTheme.secondary)
                                    .frame(width: 18)
                                TextField("Email", text: $email.email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                        .onDelete { emailAddresses.remove(atOffsets: $0) }

                        Button {
                            emailAddresses.append(EmailAddress(label: "home", email: ""))
                        } label: {
                            Label("Add Email", systemImage: "plus")
                                .foregroundColor(AppTheme.accent)
                                .font(.system(size: 15))
                        }
                    } header: {
                        SectionHeader(title: "Email Addresses")
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.divider)

                    // Reminders
                    Section {
                        ForEach($reminders) { $entry in
                            HStack {
                                Image(systemName: "bell")
                                    .foregroundColor(AppTheme.accent)
                                    .frame(width: 20)
                                Stepper(
                                    "\(entry.days) day\(entry.days == 1 ? "" : "s") before",
                                    value: $entry.days,
                                    in: 1...365
                                )
                                .foregroundColor(AppTheme.primary)
                            }
                        }
                        .onDelete { reminders.remove(atOffsets: $0) }

                        Button {
                            // Default new reminder to the global default, avoid duplicates
                            let existing = Set(reminders.map { $0.days })
                            var candidate = settingsManager.defaultReminderDays
                            // Pick a different value if already present
                            let suggestions = [1, 3, 7, 14, 30, 60]
                            for s in suggestions where !existing.contains(s) {
                                candidate = s
                                break
                            }
                            reminders.append(ReminderEntry(days: candidate))
                        } label: {
                            Label("Add Reminder", systemImage: "plus")
                                .foregroundColor(AppTheme.accent)
                                .font(.system(size: 15))
                        }
                    } header: {
                        SectionHeader(title: "Reminders")
                    } footer: {
                        if reminders.isEmpty {
                            Text("Using default: \(settingsManager.defaultReminderDays) days before. Add reminders to set custom ones.")
                                .foregroundColor(AppTheme.secondary)
                        } else {
                            Text("Swipe left on a reminder to delete it.")
                                .foregroundColor(AppTheme.secondary)
                        }
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.divider)
                }
                .scrollContentBackground(.hidden)
                .background(AppTheme.background)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .foregroundColor(AppTheme.accent)
                        .fontWeight(.medium)
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: populate)
        }
    }

    // MARK: - Logic

    private func populate() {
        guard case .edit(let existing) = mode else { return }
        firstName      = existing.firstName
        lastName       = existing.lastName
        phoneNumbers   = existing.phoneNumbers
        emailAddresses = existing.emailAddresses
        reminders      = existing.reminderDays.map { ReminderEntry(days: $0) }

        if let bday = existing.birthday {
            hasBirthday = true
            birthday    = bday
        }
    }

    private func save() {
        let phones  = phoneNumbers.filter  { !$0.number.isEmpty }
        let emails  = emailAddresses.filter { !$0.email.isEmpty }
        // Deduplicate and sort reminder days
        let days    = Array(Set(reminders.map { $0.days })).sorted()

        switch mode {
        case .add:
            let friend = Friend(
                firstName:      firstName.trimmed,
                lastName:       lastName.trimmed,
                birthday:       hasBirthday ? birthday : nil,
                phoneNumbers:   phones,
                emailAddresses: emails,
                reminderDays:   days
            )
            friendsManager.add(friend)
            NotificationManager.scheduleReminders(for: friend, defaultDays: settingsManager.defaultReminderDays, allFriends: friendsManager.friends)

        case .edit(var existing):
            existing.firstName      = firstName.trimmed
            existing.lastName       = lastName.trimmed
            existing.birthday       = hasBirthday ? birthday : nil
            existing.phoneNumbers   = phones
            existing.emailAddresses = emails
            existing.reminderDays   = days
            friendsManager.update(existing)
            NotificationManager.scheduleReminders(for: existing, defaultDays: settingsManager.defaultReminderDays, allFriends: friendsManager.friends)
        }

        dismiss()
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespaces) }
}
