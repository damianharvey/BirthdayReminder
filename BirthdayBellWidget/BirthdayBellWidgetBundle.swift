import WidgetKit
import SwiftUI

@main
struct BirthdayBellWidgetBundle: WidgetBundle {
    var body: some Widget {
        BirthdayBellWidget()
    }
}

struct BirthdayBellWidget: Widget {
    let kind = "BirthdayBellWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BirthdayWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                BirthdayWidgetEntryView(entry: entry)
                    .containerBackground(for: ContainerBackgroundPlacement.widget) { Color.clear }
            } else {
                BirthdayWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Birthday Bell")
        .description("See upcoming birthdays at a glance.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}
