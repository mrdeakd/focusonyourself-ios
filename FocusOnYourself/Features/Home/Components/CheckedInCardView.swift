import SwiftUI

struct CheckedInCardView: View {
    let mood: Mood?
    let streakCount: Int
    var viewModel: HomeViewModel

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
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
        }
        .foyCardStyle()
    }

    private var successRow: some View {
        HStack(spacing: Spacing.xs) {
            Text("Check-in complete for today!")
                .font(.foyCaptionMedium)
                .foregroundStyle(Color.foyForeground)
            Spacer()
        }
    }

    private var moodSummaryRow: some View {
        HStack(spacing: Spacing.sm) {
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
        .alignmentGuide(.firstTextBaseline) { dims in dims[.firstTextBaseline] }
    }

    private var contextRow: some View {
        HStack {
            if let factors = viewModel.todaysFactors {
                Text(factorSummary(factors))
                    .font(.foyHint)
                    .foregroundStyle(Color.foyForegroundSecondary)
            } else {
                Button("Log today") {
                    viewModel.showingContextSheet = true
                }
                .font(.foyHintMedium)
                .foregroundStyle(Color.foyNavy)
            }
            Spacer()
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
