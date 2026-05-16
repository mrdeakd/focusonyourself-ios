import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Entry

struct CheckInEntry: TimelineEntry {
    let date: Date
    let todaysMood: WidgetMood?
    let streak: Int
    let isOnboarded: Bool
    let todaysFactors: WidgetCheckInFactors?
}

// MARK: - Configuration

struct CheckInWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Check In"
    static var description = IntentDescription("Log your daily mood.")
}

// MARK: - Provider

struct CheckInProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CheckInEntry {
        CheckInEntry(date: .now, todaysMood: nil, streak: 7, isOnboarded: true, todaysFactors: nil)
    }

    func snapshot(for configuration: CheckInWidgetConfiguration, in context: Context) async -> CheckInEntry {
        makeEntry()
    }

    func timeline(for configuration: CheckInWidgetConfiguration, in context: Context) async -> Timeline<CheckInEntry> {
        let midnight = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: Date())
        ) ?? Date()
        return Timeline(entries: [makeEntry()], policy: .after(midnight))
    }

    private func makeEntry() -> CheckInEntry {
        CheckInEntry(
            date: .now,
            todaysMood: WidgetDataProvider.todaysMood,
            streak: WidgetDataProvider.streakStats().current,
            isOnboarded: WidgetDataProvider.isOnboarded,
            todaysFactors: WidgetDataProvider.todaysFactors
        )
    }
}

// MARK: - Root View

struct CheckInWidgetView: View {
    let entry: CheckInEntry

    var body: some View {
        if !entry.isOnboarded {
            NotOnboardedView()
        } else if let mood = entry.todaysMood {
            LoggedView(entry: entry, mood: mood)
        } else {
            UnloggedView(entry: entry)
        }
    }
}

// MARK: - Unlogged State

private struct UnloggedView: View {
    let entry: CheckInEntry

    private let orange = Color(red: 1.0, green: 0.420, blue: 0.169)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("How are you feeling?")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Label("\(entry.streak)", systemImage: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(orange)
                    .accessibilityLabel("Streak: \(entry.streak) days")
            }
            .invalidatableContent()

            Spacer(minLength: 10)

            HStack(spacing: 5) {
                ForEach([WidgetMood.rough, .low, .okay, .good, .great], id: \.rawValue) { mood in
                    Button(intent: LogMoodIntent(moodRawValue: mood.rawValue)) {
                        VStack(spacing: 5) {
                            Image(mood.imageName)
                                .renderingMode(.original)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                            Text(mood.displayName)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Log mood: \(mood.displayName)")
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Logged State

private struct LoggedView: View {
    let entry: CheckInEntry
    let mood: WidgetMood

    private let orange = Color(red: 1.0, green: 0.420, blue: 0.169)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Today")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Label("\(entry.streak)", systemImage: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(orange)
                    .contentTransition(.numericText())
                    .accessibilityLabel("Streak: \(entry.streak) days")
            }
            .invalidatableContent()

            Spacer()

            VStack(alignment: .center, spacing: 8) {
                HStack(alignment: .center, spacing: 14) {
                    Image(mood.imageName)
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 54, height: 54)
                    Text(mood.displayName)
                        .font(.system(size: 26, weight: .bold))
                }

                if let factors = entry.todaysFactors {
                    HStack(spacing: 0) {
                        FactorBadge(icon: "moon.fill", value: "\(factors.sleepQuality)", label: "Sleep")
                        FactorBadge(icon: "bolt.fill", value: "\(factors.stressLevel)", label: "Stress")
                        FactorBadge(icon: "figure.run", value: factors.exercised ? "Yes" : "No", label: "Exercise")
                        FactorBadge(icon: "person.2.fill", value: "\(factors.socialQuality)", label: "Social")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .invalidatableContent()
        }
        .padding(16)
    }
}

// MARK: - Not Onboarded State

private struct NotOnboardedView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Open FocusOnYourself to set up your profile.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(intent: OpenOnboardingIntent()) {
                Text("Get Started →")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }
}

// MARK: - Factor Badge

private struct FactorBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(value)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Widget

struct CheckInWidget: Widget {
    let kind = "CheckInWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CheckInWidgetConfiguration.self,
            provider: CheckInProvider()
        ) { entry in
            CheckInWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Check In")
        .description("Log your daily mood in one tap.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    CheckInWidget()
} timeline: {
    CheckInEntry(date: .now, todaysMood: nil, streak: 12, isOnboarded: true, todaysFactors: nil)
    CheckInEntry(date: .now, todaysMood: .good, streak: 13, isOnboarded: true, todaysFactors: nil)
    CheckInEntry(
        date: .now,
        todaysMood: .good,
        streak: 13,
        isOnboarded: true,
        todaysFactors: WidgetCheckInFactors(sleepQuality: 4, stressLevel: 2, exercised: true, socialQuality: 3)
    )
}
