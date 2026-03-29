import Foundation
import WidgetKit

class SettingsManager: ObservableObject {

    @Published var defaultReminderDays: Int {
        didSet { UserDefaults.standard.set(defaultReminderDays, forKey: "defaultReminderDays") }
    }

    @Published var upcomingDaysToShow: Int {
        didSet {
            SharedStore.sharedDefaults.set(upcomingDaysToShow, forKey: SharedStore.upcomingDaysKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    init() {
        self.defaultReminderDays = UserDefaults.standard.object(forKey: "defaultReminderDays") as? Int ?? 7
        self.upcomingDaysToShow  = SharedStore.sharedDefaults.object(forKey: SharedStore.upcomingDaysKey) as? Int ?? 30
    }
}
