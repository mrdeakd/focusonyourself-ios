import SwiftUI

private let cardCornerRadius: CGFloat = 18
private let barCornerRadius: CGFloat = 4

struct MoodBreakdownSection: View {
    var viewModel: InsightsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("MOOD BREAKDOWN")

            if viewModel.recentCheckIns(days: 30).isEmpty {
                Text("No check-ins in the last 30 days")
                    .font(.foyCaption)
                    .foregroundStyle(Color.foyPlaceholder)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .multilineTextAlignment(.center)
            } else {
                let distribution = viewModel.moodDistribution(days: 30)
                let maxCount = distribution.map(\.count).max() ?? 1

                VStack(spacing: Spacing.xs) {
                    ForEach(distribution, id: \.mood) { item in
                        HStack(spacing: Spacing.sm) {
                            Image(item.mood.imageName)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.primary)
                                .frame(width: 24, alignment: .center)

                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: barCornerRadius)
                                    .fill(Color.foyNavy.opacity(0.08))
                                RoundedRectangle(cornerRadius: barCornerRadius)
                                    .fill(Color.foyNavy)
                                    .scaleEffect(x: barScale(count: item.count, max: maxCount), anchor: .leading)
                            }
                            .frame(height: 10)

                            Text("\(item.count)")
                                .font(.foyHint)
                                .foregroundStyle(Color.foyForegroundSecondary)
                                .frame(width: 24, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .foyCardStyle(borderColor: .foyNavy, cornerRadius: cardCornerRadius)
    }

    private func barScale(count: Int, max maxCount: Int) -> CGFloat {
        guard maxCount > 0 else { return 0 }
        let ratio = CGFloat(count) / CGFloat(maxCount)
        // swiftlint:disable:next empty_count
        let minimumScale: CGFloat = count > 0 ? 0.02 : 0
        return Swift.max(ratio, minimumScale)
    }
}
