import SwiftUI

struct HistoryScreen: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Fixed header
                HStack {
                    Text("History")
                        .font(.inter(18, weight: .medium))
                        .foregroundStyle(Color.foyForeground)
                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Scrollable content
                ScrollView {
                    VStack(spacing: 20) {
                        // Stat cards row
                        HStack(spacing: 12) {
                            let stats = appState.streakStats()
                            StreakStatCard(label: "Current Streak", value: stats.current)
                            StreakStatCard(label: "Longest Streak", value: stats.longest)
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 4)

                        // Calendar months
                        VStack(spacing: 20) {
                            ForEach(calendarMonths, id: \.self) { monthDate in
                                CalendarMonthView(
                                    month: monthDate,
                                    checkInDates: checkInDateStrings
                                )
                                .padding(.horizontal, 28)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 0)
                }
            }
        }
    }

    private var checkInDateStrings: Set<String> {
        Set(appState.profile.checkIns.map { $0.dateString })
    }

    private var calendarMonths: [Date] {
        let cal = Calendar.current
        let today = Date()

        // Start from streak start month, or current month if no streak
        let startDate = appState.streakStartDate ?? today

        // Get start of month for startDate
        var comps = cal.dateComponents([.year, .month], from: startDate)
        comps.day = 1
        guard let startOfStartMonth = cal.date(from: comps) else { return [today] }

        // Get start of current month
        var todayComps = cal.dateComponents([.year, .month], from: today)
        todayComps.day = 1
        guard let startOfCurrentMonth = cal.date(from: todayComps) else { return [today] }

        // Enumerate months from startOfStartMonth through startOfCurrentMonth
        var months: [Date] = []
        var current = startOfStartMonth
        while current <= startOfCurrentMonth {
            months.append(current)
            guard let next = cal.date(byAdding: .month, value: 1, to: current) else { break }
            current = next
        }

        return months
    }
}
