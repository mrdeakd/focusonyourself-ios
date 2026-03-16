import SwiftUI

struct MoodButtonView: View {
    let mood: Mood
    let isSelected: Bool
    let onTap: () -> Void

    private let emojiFontSize: CGFloat = 20
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xxxs) {
                Text(mood.emoji)
                    .font(.custom("Inter", size: emojiFontSize))
                Text(mood.displayName)
                    .font(isSelected ? .foyMicroMedium : .foyMicro)
                    .foregroundStyle(isSelected ? Color.foyNavy : Color.foyPlaceholder)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.xxs)
            .background(isSelected ? Color.foyNavyTint : Color.foyMoodBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.foyNavy, lineWidth: isSelected ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
    }
}
