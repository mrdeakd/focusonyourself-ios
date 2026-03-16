import WidgetKit
import SwiftUI

struct StreakEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let longestStreak: Int
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), currentStreak: 7, longestStreak: 14)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let stats = WidgetDataProvider.streakStats()
        completion(StreakEntry(date: Date(), currentStreak: stats.current, longestStreak: stats.longest))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let stats = WidgetDataProvider.streakStats()
        let entry = StreakEntry(date: Date(), currentStreak: stats.current, longestStreak: stats.longest)
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

struct StreakWidgetView: View {
    let entry: StreakEntry
    @Environment(\.colorScheme) var colorScheme

    private var navy: Color { Color(red: 0.118, green: 0.227, blue: 0.373) }
    private var iconBg: Color {
        colorScheme == .dark
            ? Color(red: 0.227, green: 0.392, blue: 0.580)
            : Color(red: 0.118, green: 0.227, blue: 0.373).opacity(0.10)
    }
    private var iconTint: Color {
        colorScheme == .dark ? Color(red: 0.420, green: 0.620, blue: 0.831) : navy
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
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconBg)
                    .frame(width: 44, height: 44)
                Image(systemName: "flame.fill")
                    .foregroundStyle(iconTint)
                    .font(.system(size: 22, weight: .medium))
            }

            Text("\(entry.currentStreak)")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(primaryText)
                .kerning(-1)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("day streak")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(labelTint)

            Text("keep it up! 💪")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Streak")
        .description("See your current check-in streak at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakEntry(date: .now, currentStreak: 7, longestStreak: 14)
    StreakEntry(date: .now, currentStreak: 0, longestStreak: 14)
}
