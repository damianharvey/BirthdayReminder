import SwiftUI

@main
struct BirthdayBellApp: App {
    @StateObject private var friendsManager  = FriendsManager()
    @StateObject private var settingsManager = SettingsManager()

    init() {
        NotificationManager.requestPermission()
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(friendsManager)
                .environmentObject(settingsManager)
                .onAppear {
                    NotificationManager.scheduleAll(
                        friends:     friendsManager.friends,
                        defaultDays: settingsManager.defaultReminderDays
                    )
                }
        }
    }

    private func configureAppearance() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .light),
            .foregroundColor: UIColor(AppTheme.primary)
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.primary)
        ]
    }
}
