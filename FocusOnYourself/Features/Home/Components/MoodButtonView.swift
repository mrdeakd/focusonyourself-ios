import SwiftUI

struct MoodButtonView: View {
    let mood: Mood
    let isSelected: Bool
    let onTap: () -> Void

    private let emojiSize: CGFloat = 28
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xxxs) {
                Image(mood.imageName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: emojiSize, height: emojiSize)
                    .foregroundStyle(.primary)
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
