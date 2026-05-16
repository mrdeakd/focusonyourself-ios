import SwiftUI

struct HomeHeaderRow: View {
    let greeting: String
    let date: String
    let streakCount: Int

    private let iconSize: CGFloat = 14

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(greeting)
                    .font(.foyNavTitle)
                    .foregroundStyle(Color.foyForeground)
                Text(date)
                    .font(.foyCaption)
                    .foregroundStyle(Color.foyForegroundSecondary)
            }
            Spacer()
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "flame.fill")
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(Color.foyOrange)
                    .accessibilityHidden(true)
                Text("\(streakCount) days")
                    .font(.foyCaptionSemibold)
                    .foregroundStyle(Color.foyOrange)
            }
            .padding(.vertical, Spacing.xxs)
            .padding(.horizontal, Spacing.sm)
            .background(Color.foyOrangeTint)
            .clipShape(Capsule())
            .accessibilityLabel("\(streakCount)-day streak")
        }
    }
}
