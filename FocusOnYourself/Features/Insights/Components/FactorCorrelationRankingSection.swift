import Charts
import SwiftUI

struct FactorCorrelationRankingSection: View {
    let viewModel: InsightsViewModel
    @Binding var selectedFactor: FactorCorrelation?

    var body: some View {
        let correlations = viewModel.factorCorrelations()
        if correlations.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if let top = viewModel.topMoodBooster() {
                    topBoosterCard(top)
                }
                rankingChart(correlations)
            }
        }
    }

    private var emptyState: some View {
        Text("Keep logging to see what affects your mood.")
            .font(.foyBody)
            .foregroundStyle(Color.foyForegroundSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    private func topBoosterCard(_ top: FactorCorrelation) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.foyOrange)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text("Your top mood booster")
                    .font(.foyHint)
                    .foregroundStyle(Color.foyForegroundSecondary)
                Text("\(top.factor) \(top.directionLabel)")
                    .font(.foyCaptionMedium)
                    .foregroundStyle(Color.foyNavy)
            }
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.foyUpgradeCardBg)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .strokeBorder(Color.foyUpgradeCardBorder, lineWidth: 1)
        }
    }

    private func rankingChart(_ correlations: [FactorCorrelation]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("What affects your mood")
                .font(.foyCaptionMedium)
                .foregroundStyle(Color.foyForeground)

            Chart(correlations) { item in
                BarMark(
                    x: .value("Correlation", item.pearsonR),
                    y: .value("Factor", item.factor)
                )
                .foregroundStyle(item.pearsonR >= 0 ? Color.foyOrange : Color.foyNavy)
                .cornerRadius(CornerRadius.chartBar)
                .annotation(position: item.pearsonR >= 0 ? .trailing : .leading) {
                    Text(item.pearsonR, format: .number.precision(.fractionLength(2)))
                        .font(.foyHint)
                        .foregroundStyle(Color.foyForegroundSecondary)
                }
            }
            .chartXScale(domain: -1...1)
            .chartXAxis {
                AxisMarks(values: [-1, -0.5, 0, 0.5, 1]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let axisValue = value.as(Double.self), axisValue == 0 {
                            Text("0").font(.foyHint).foregroundStyle(Color.foyForegroundSecondary)
                        }
                    }
                }
            }
            .frame(height: 160)
            .chartOverlay { proxy in
                GeometryReader { _ in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            guard let yVal: String = proxy.value(atY: location.y) else { return }
                            selectedFactor = correlations.first { $0.factor == yVal }
                        }
                        .accessibilityAddTraits(.isButton)
                }
            }
            .accessibilityLabel("Factor correlation chart")
        }
        .padding(Spacing.md)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}
