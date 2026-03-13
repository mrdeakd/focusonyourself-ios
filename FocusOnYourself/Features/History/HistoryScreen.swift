import SwiftUI

struct HistoryScreen: View {
    @State private var viewModel: HistoryViewModel

    init(appState: AppState) {
        _viewModel = State(initialValue: HistoryViewModel(appState: appState))
    }

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Fixed header
                HStack {
                    Text("History")
                        .font(.foyNavTitle)
                        .foregroundStyle(Color.foyForeground)
                    Spacer()
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)

                // Stat cards row
                HStack(spacing: Spacing.sm) {
                    StreakStatCard(label: "Current Streak", value: viewModel.streakStats.current)
                    StreakStatCard(label: "Longest Streak", value: viewModel.streakStats.longest)
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.xxxs)

                // Scrollable content
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        ForEach(viewModel.calendarMonths, id: \.self) { monthDate in
                            CalendarMonthView(
                                month: monthDate,
                                checkInDates: viewModel.checkInDateStrings
                            )
                            .padding(.horizontal, Spacing.screenHorizontal)
                        }
                    }
                }
                .padding(.vertical, Spacing.lg)
            }
        }
    }
}
