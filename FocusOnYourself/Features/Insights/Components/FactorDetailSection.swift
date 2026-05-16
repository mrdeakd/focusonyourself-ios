import Charts
import SwiftUI

private let minimumGroupEntries = 3

struct FactorDetailSection: View {
    let factor: InsightsViewModel.FactorCorrelation
    let viewModel: InsightsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(factor.factor)
                    .font(.foyCaptionMedium)
                    .foregroundStyle(Color.foyForeground)
                Spacer()
                Text(factor.directionLabel)
                    .font(.foyHintMedium)
                    .foregroundStyle(factor.pearsonR >= 0 ? Color.foyOrange : Color.foyNavy)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background((factor.pearsonR >= 0 ? Color.foyOrange : Color.foyNavy).opacity(0.1))
                    .clipShape(Capsule())
            }

            if factor.id == "exercise" {
                binaryComparison
            } else {
                rangeComparison
            }
        }
        .padding(Spacing.md)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    private var binaryComparison: some View {
        let data = viewModel.averageMood(forBinaryFactor: \.exercised)
        return HStack(spacing: Spacing.sm) {
            averageMoodBar(label: "Exercised", average: data.with)
            averageMoodBar(label: "No exercise", average: data.without)
        }
    }

    private var rangeComparison: some View {
        let keyPath: KeyPath<CheckInFactors, Int>
        switch factor.id {
        case "sleep":   keyPath = \.sleepQuality
        case "stress":  keyPath = \.stressLevel
        default:        keyPath = \.socialQuality
        }
        let data = viewModel.averageMoodByRange(forFactor: keyPath)
        return HStack(spacing: Spacing.sm) {
            averageMoodBar(
                label: "Low (1–2)",
                average: data.low.count >= minimumGroupEntries ? data.low.average : nil,
                count: data.low.count
            )
            averageMoodBar(
                label: "Medium (3)",
                average: data.mid.count >= minimumGroupEntries ? data.mid.average : nil,
                count: data.mid.count
            )
            averageMoodBar(
                label: "High (4–5)",
                average: data.high.count >= minimumGroupEntries ? data.high.average : nil,
                count: data.high.count
            )
        }
    }

    private func averageMoodBar(label: String, average: Double?, count: Int = 0) -> some View {
        VStack(spacing: Spacing.xs) {
            if let avg = average {
                RoundedRectangle(cornerRadius: CornerRadius.chartBar)
                    .fill(Color.foyOrange)
                    .frame(height: max(4, CGFloat(avg / 5.0) * 80))
                Text(avg, format: .number.precision(.fractionLength(1)))
                    .font(.foyCaptionMedium)
                    .foregroundStyle(Color.foyForeground)
                // swiftlint:disable:next empty_count
                Text(count > 0 ? "\(count) days" : "")
                    .font(.foyHint)
                    .foregroundStyle(Color.foyForegroundSecondary)
            } else {
                RoundedRectangle(cornerRadius: CornerRadius.chartBar)
                    .fill(Color.foyBorder)
                    .frame(height: 4)
                Text("Not enough data")
                    .font(.foyHint)
                    .foregroundStyle(Color.foyPlaceholder)
                    .multilineTextAlignment(.center)
            }
            Text(label)
                .font(.foyHint)
                .foregroundStyle(Color.foyForegroundSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
