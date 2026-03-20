import Foundation

class SettingsManager: ObservableObject {

    @Published var defaultReminderDays: Int {
        didSet { UserDefaults.standard.set(defaultReminderDays, forKey: "defaultReminderDays") }
    }

    @Published var upcomingDaysToShow: Int {
        didSet { UserDefaults.standard.set(upcomingDaysToShow, forKey: "upcomingDaysToShow") }
    }

    init() {
        self.defaultReminderDays = UserDefaults.standard.object(forKey: "defaultReminderDays") as? Int ?? 7
        self.upcomingDaysToShow  = UserDefaults.standard.object(forKey: "upcomingDaysToShow")  as? Int ?? 30
    }
}
