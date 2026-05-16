import AppIntents
import WidgetKit

struct LogMoodIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Mood"
    static let openAppWhenRun = false
    static let isDiscoverable = false

    @Parameter(title: "Mood") var moodRawValue: String

    init() { moodRawValue = "" }
    init(moodRawValue: String) { self.moodRawValue = moodRawValue }

    func perform() async throws -> some IntentResult {
        WidgetDataProvider.logMood(moodRawValue)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct OpenOnboardingIntent: AppIntent {
    static let title: LocalizedStringResource = "Open FocusOnYourself"
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
