import SwiftUI

private let calendarCardRadius: CGFloat = 18

struct HistoryScreen: View {
    @State private var viewModel: HistoryViewModel
    @State private var selectedCheckIn: CheckIn?

    init() {
        _viewModel = State(initialValue: HistoryViewModel())
    }

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("History")
                        .font(.foyNavTitle)
                        .foregroundStyle(Color.foyForeground)
                    Spacer()
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)

                HStack(spacing: Spacing.sm) {
                    StreakStatCard(label: "Current Streak", value: viewModel.streakStats.current)
                    StreakStatCard(label: "Longest Streak", value: viewModel.streakStats.longest)
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.xxxs)

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        ForEach(viewModel.calendarMonths, id: \.self) { monthDate in
                            CalendarMonthView(
                                month: monthDate,
                                checkInDates: viewModel.checkInDateStrings,
                                onDayTapped: { dateString in
                                    selectedCheckIn = viewModel.checkIn(for: dateString)
                                }
                            )
                            .padding(Spacing.lg)
                            .background(Color.foyCard)
                            .clipShape(RoundedRectangle(cornerRadius: calendarCardRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: calendarCardRadius)
                                    .stroke(Color.foyNavy, lineWidth: 1)
                            )
                            .padding(.horizontal, Spacing.screenHorizontal)
                            .padding(.top, Spacing.md)
                        }
                    }
                }
                .padding(.top, Spacing.lg)
            }
        }
        .sheet(item: $selectedCheckIn) { checkIn in
            DayDetailSheet(checkIn: checkIn)
        }
    }
}
