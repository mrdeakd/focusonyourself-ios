import SwiftUI
import Charts

private let cardCornerRadius: CGFloat = 18
private let moodChartHeight: CGFloat = 140

struct MoodThisWeekSection: View {
    var viewModel: InsightsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("MOOD THIS WEEK")

            let data = viewModel.dailyMoodData(days: 7)

            if data.allSatisfy({ $0.checkIn == nil }) {
                emptyChartPlaceholder(message: "No check-ins yet this week")
            } else {
                Chart(data, id: \.label) { item in
                    BarMark(
                        x: .value("Day", item.label),
                        y: .value("Mood", item.checkIn?.mood.numericValue ?? 0)
                    )
                    .foregroundStyle(viewModel.barColor(for: item.checkIn?.mood))
                    .cornerRadius(6)
                }
                .chartYScale(domain: 0...5)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.foyForegroundSecondary)
                            .font(.foyHint)
                    }
                }
                .frame(height: moodChartHeight)
            }
        }
        .padding(Spacing.md)
        .foyCardStyle(borderColor: .foyNavy, cornerRadius: cardCornerRadius)
    }

    private func emptyChartPlaceholder(message: String) -> some View {
        Text(message)
            .font(.foyCaption)
            .foregroundStyle(Color.foyPlaceholder)
            .frame(maxWidth: .infinity, minHeight: moodChartHeight)
            .multilineTextAlignment(.center)
    }
}
