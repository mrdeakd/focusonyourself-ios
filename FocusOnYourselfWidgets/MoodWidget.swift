import WidgetKit
import SwiftUI

struct MoodEntry: TimelineEntry {
    let date: Date
    let mood: WidgetMood?
    let hasCheckedInToday: Bool
}

struct MoodProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoodEntry {
        MoodEntry(date: Date(), mood: .good, hasCheckedInToday: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (MoodEntry) -> Void) {
        completion(MoodEntry(
            date: Date(),
            mood: WidgetDataProvider.todaysMood,
            hasCheckedInToday: WidgetDataProvider.hasCheckedInToday
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoodEntry>) -> Void) {
        let entry = MoodEntry(
            date: Date(),
            mood: WidgetDataProvider.todaysMood,
            hasCheckedInToday: WidgetDataProvider.hasCheckedInToday
        )
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

struct MoodWidgetView: View {
    let entry: MoodEntry
    @Environment(\.colorScheme) var colorScheme

    private var navy: Color { Color(red: 0.118, green: 0.227, blue: 0.373) }
    private var iconBg: Color {
        colorScheme == .dark
            ? Color(red: 0.227, green: 0.392, blue: 0.580)
            : Color(red: 0.118, green: 0.227, blue: 0.373).opacity(0.10)
    }
    private var primaryText: Color {
        colorScheme == .dark ? Color(red: 0.949, green: 0.949, blue: 0.969) : Color(red: 0.110, green: 0.110, blue: 0.110)
    }
    private var labelTint: Color {
        colorScheme == .dark ? Color(red: 0.420, green: 0.620, blue: 0.831) : navy
    }
    private var secondaryText: Color {
        colorScheme == .dark ? Color(red: 0.388, green: 0.388, blue: 0.400) : Color(red: 0.678, green: 0.678, blue: 0.678)
    }
    private var moodEmoji: String {
        entry.mood?.emoji ?? "—"
    }

    private var moodWord: String {
        entry.mood?.displayName ?? "—"
    }

    private var statusText: String {
        entry.hasCheckedInToday ? "logged today ✓" : "not logged yet"
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconBg)
                    .frame(width: 44, height: 44)
                Text(moodEmoji)
                    .font(.system(size: 22))
            }

            Text(moodWord)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(primaryText)
                .kerning(-0.5)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("today's mood")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(labelTint)

            Text(statusText)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MoodWidget: Widget {
    let kind: String = "MoodWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoodProvider()) { entry in
            MoodWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Mood")
        .description("See today's logged mood at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    MoodWidget()
} timeline: {
    MoodEntry(date: .now, mood: .good, hasCheckedInToday: true)
    MoodEntry(date: .now, mood: nil, hasCheckedInToday: false)
}
