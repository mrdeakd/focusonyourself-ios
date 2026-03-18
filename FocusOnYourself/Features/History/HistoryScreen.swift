import SwiftUI

private let calendarCardRadius: CGFloat = 18

struct HistoryScreen: View {
    @State private var viewModel: HistoryViewModel
    @State private var selectedCheckIn: CheckIn?
    private let showsHeader: Bool

    init(showsHeader: Bool = true) {
        self.showsHeader = showsHeader
        _viewModel = State(initialValue: HistoryViewModel())
    }

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if showsHeader {
                    ScreenHeaderView(title: "History")
                }

                HStack(spacing: Spacing.sm) {
                    StatCard(label: "Current Streak", value: "\(viewModel.streakStats.current) days")
                    StatCard(label: "Longest Streak", value: "\(viewModel.streakStats.longest) days")
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
                            .foyCardStyle(borderColor: .foyNavy, cornerRadius: calendarCardRadius)
                            .padding(.horizontal, Spacing.screenHorizontal)
                            .padding(.top, Spacing.sm)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .padding(.top, Spacing.xxs)
            }
        }
        .sheet(item: $selectedCheckIn) { checkIn in
            DayDetailSheet(checkIn: checkIn)
        }
    }
}
