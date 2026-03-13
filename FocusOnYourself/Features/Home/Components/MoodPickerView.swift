import SwiftUI

struct MoodPickerView: View {
    let selectedMood: Mood?
    let onSelect: (Mood) -> Void
    let onCheckIn: () -> Void

    private let moodCardPadding: CGFloat = 20
    private let checkInHeight: CGFloat = 52

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("How are you feeling?")
                .font(.inter(13, weight: .medium))
                .foregroundStyle(Color.foyForeground)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Spacing.xs) {
                ForEach(Mood.allCases) { mood in
                    MoodButtonView(mood: mood, isSelected: selectedMood == mood) {
                        onSelect(mood)
                    }
                }
            }

            Button(action: onCheckIn) {
                Text("Complete Check-In")
                    .font(.inter(15, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: checkInHeight)
                    .background(selectedMood == nil ? Color.foyButtonDisabled : Color.foyNavy)
                    .clipShape(Capsule())
            }
            .disabled(selectedMood == nil)
        }
        .padding(moodCardPadding)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
    }
}

private struct MoodButtonView: View {
    let mood: Mood
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xxxs) {
                Text(mood.emoji)
                    .font(.system(size: 20))
                Text(mood.displayName)
                    .font(.inter(10, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? Color.foyNavy : Color.foyPlaceholder)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, 10)
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
