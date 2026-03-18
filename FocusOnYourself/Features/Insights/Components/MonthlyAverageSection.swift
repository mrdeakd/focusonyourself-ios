import Charts
import SwiftUI

private let cardCornerRadius: CGFloat = 18
private let chartHeight: CGFloat = 160

struct MonthlyAverageSection: View {
    var viewModel: InsightsViewModel

    var body: some View {
        ProFeatureOverlayView(isLocked: !viewModel.isPro) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionLabel("MONTHLY AVERAGE")

                let data = viewModel.monthlyAverages()

                if data.allSatisfy({ $0.avg == 0 }) {
                    emptyChartPlaceholder(message: "Check in regularly to see monthly trends")
                } else {
                    Chart(data, id: \.month) { item in
                        BarMark(
                            x: .value("Month", item.month),
                            y: .value("Avg", item.avg)
                        )
                        .foregroundStyle(viewModel.avgBarColor(for: item.avg))
                        .cornerRadius(CornerRadius.chartBar)
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
                    .frame(height: chartHeight)
                }
            }
            .padding(Spacing.lg)
            .foyCardStyle(borderColor: .foyNavy, cornerRadius: cardCornerRadius)
        }
    }

    private func emptyChartPlaceholder(message: String) -> some View {
        Text(message)
            .font(.foyCaption)
            .foregroundStyle(Color.foyPlaceholder)
            .frame(maxWidth: .infinity, minHeight: chartHeight)
            .multilineTextAlignment(.center)
    }
}
