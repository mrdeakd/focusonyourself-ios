import SwiftUI

private let cardCornerRadius: CGFloat = 18

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

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.foyNavy.opacity(0.08))
                                        .frame(maxWidth: .infinity)

                                    let fillWidth = maxCount > 0
                                        ? geo.size.width * CGFloat(item.count) / CGFloat(maxCount)
                                        : 0
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.foyNavy)
                                        // swiftlint:disable:next empty_count
                                        .frame(width: max(fillWidth, item.count > 0 ? 4 : 0))
                                }
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
}
