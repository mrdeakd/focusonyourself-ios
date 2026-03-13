import SwiftUI

struct MoodPickerView: View {
    let selectedMood: Mood?
    let onSelect: (Mood) -> Void
    let onCheckIn: () -> Void

    private let checkInHeight: CGFloat = 52
    private let moodLabelFont = Font.custom("Inter", size: 13).weight(.medium)
    private let moodTitleFont = Font.custom("Inter", size: 15).weight(.medium)

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("How are you feeling?")
                .font(moodLabelFont)
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
                    .font(moodTitleFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: checkInHeight)
                    .background(selectedMood == nil ? Color.foyButtonDisabled : Color.foyNavy)
                    .clipShape(Capsule())
            }
            .disabled(selectedMood == nil)
        }
        .padding(Spacing.lg)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
    }
}

private struct MoodButtonView: View {
    let mood: Mood
    let isSelected: Bool
    let onTap: () -> Void

    private let emojiFontSize: CGFloat = 20
    private let moodSubLabelMedium = Font.custom("Inter", size: 10).weight(.medium)
    private let moodSubLabelRegular = Font.custom("Inter", size: 10).weight(.regular)
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xxxs) {
                Text(mood.emoji)
                    .font(.custom("Inter", size: emojiFontSize))
                Text(mood.displayName)
                    .font(isSelected ? moodSubLabelMedium : moodSubLabelRegular)
                    .foregroundStyle(isSelected ? Color.foyNavy : Color.foyPlaceholder)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.sm)
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
