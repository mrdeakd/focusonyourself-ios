import SwiftUI

struct InsightsStatsRow: View {
    let viewModel: InsightsViewModel

    var body: some View {
        HStack(spacing: Spacing.sm) {
            StatCard(label: "Avg Mood", value: viewModel.averageMoodText(days: 7))
            StatCard(label: "This Week", value: "\(viewModel.checkInCount(days: 7))")
        }
    }
}
