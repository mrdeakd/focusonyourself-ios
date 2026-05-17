import SwiftUI

struct CheckedInCardView: View {
    let mood: Mood?
    let streakCount: Int
    var viewModel: HomeViewModel

    private let iconSize: CGFloat = 18

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.md) {
                successRow
                moodSummaryRow
            }
            .padding(Spacing.lg)

            Rectangle()
                .fill(Color.foyBorder)
                .frame(height: 1)

            contextRow
                .padding(Spacing.md)
        }
        .foyCardStyle()
    }

    private var successRow: some View {
        HStack {
            Text("Check-in complete for today!")
                .font(.foyCaptionMedium)
                .foregroundStyle(Color.foyForeground)
            Spacer()
        }
    }

    private var moodSummaryRow: some View {
        HStack {
            Text("Your mood today")
                .font(.foyHint)
                .foregroundStyle(Color.foyPlaceholder)
            Spacer()
            if let mood {
                HStack(spacing: Spacing.xxs) {
                    Image(mood.imageName)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.primary)
                    Text(mood.displayName)
                        .font(.foyHintMedium)
                        .foregroundStyle(Color.foyNavy)
                }
                .padding(.vertical, Spacing.xxs)
                .padding(.horizontal, Spacing.sm)
                .background(Color.foyNavyTint)
                .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder private var contextRow: some View {
        if let factors = viewModel.todaysFactors {
            HStack {
                Text(factorSummary(factors))
                    .font(.foyHint)
                    .foregroundStyle(Color.foyForegroundSecondary)
                Spacer()
            }
        } else {
            Button {
                viewModel.showingContextSheet = true
            } label: {
                HStack {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "slider.horizontal.3")
                            .resizable()
                            .frame(width: iconSize, height: iconSize)
                            .foregroundStyle(Color.foyNavy)
                        Text("Log today's factors")
                            .font(.foyCaptionMedium)
                            .foregroundStyle(Color.foyNavy)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .foregroundStyle(Color.foyNavy)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func factorSummary(_ factors: CheckInFactors) -> String {
        let sleep    = "💤 \(factors.sleepQuality)"
        let stress   = "😮‍💨 \(factors.stressLevel)"
        let exercise = factors.exercised ? "🏃 Yes" : "🏃 No"
        let social   = "👥 \(factors.socialQuality)"
        return [sleep, stress, exercise, social].joined(separator: "  ·  ")
    }
}
