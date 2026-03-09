import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var friendsManager:  FriendsManager

    @State private var showingRescheduleConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                Form {
                    // Notifications
                    Section {
                        HStack {
                            Label("Default reminder", systemImage: "bell")
                                .foregroundColor(AppTheme.primary)
                            Spacer()
                            Stepper(
                                "\(settingsManager.defaultReminderDays) day\(settingsManager.defaultReminderDays == 1 ? "" : "s")",
                                value: $settingsManager.defaultReminderDays,
                                in: 1...365
                            )
                            .fixedSize()
                            .foregroundColor(AppTheme.secondary)
                        }
                    } header: {
                        SectionHeader(title: "Notifications")
                    } footer: {
                        Text("How many days before a birthday to receive a reminder. Friends with a custom reminder override this setting.")
                            .foregroundColor(AppTheme.secondary)
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.divider)

                    // Home screen
                    Section {
                        HStack {
                            Label("Show upcoming", systemImage: "calendar")
                                .foregroundColor(AppTheme.primary)
                            Spacer()
                            Stepper(
                                "\(settingsManager.upcomingDaysToShow) days",
                                value: $settingsManager.upcomingDaysToShow,
                                in: 7...180,
                                step: 7
                            )
                            .fixedSize()
                            .foregroundColor(AppTheme.secondary)
                        }
                    } header: {
                        SectionHeader(title: "Home Screen")
                    } footer: {
                        Text("How far ahead to display upcoming birthdays on the home screen.")
                            .foregroundColor(AppTheme.secondary)
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.divider)

                    // Actions
                    Section {
                        Button {
                            showingRescheduleConfirm = true
                        } label: {
                            Label("Reschedule all reminders", systemImage: "arrow.clockwise")
                                .foregroundColor(AppTheme.accent)
                        }
                    } header: {
                        SectionHeader(title: "Actions")
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.divider)

                    // Stats
                    Section {
                        statRow("Total friends",    "\(friendsManager.friends.count)")
                        statRow("With birthday",    "\(friendsManager.friendsWithBirthday.count)")
                        statRow("Without birthday", "\(friendsManager.friendsWithoutBirthday.count)")
                    } header: {
                        SectionHeader(title: "Statistics")
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.divider)
                }
                .scrollContentBackground(.hidden)
                .background(AppTheme.background)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reschedule Reminders?", isPresented: $showingRescheduleConfirm) {
                Button("Reschedule") {
                    NotificationManager.scheduleAll(
                        friends:     friendsManager.friends,
                        defaultDays: settingsManager.defaultReminderDays
                    )
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All existing birthday reminders will be cancelled and rescheduled using the current default.")
            }
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(AppTheme.primary)
            Spacer()
            Text(value)
                .foregroundColor(AppTheme.secondary)
        }
    }
}
