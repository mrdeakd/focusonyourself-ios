import SwiftUI

struct MoodPickerView: View {
    let selectedMood: Mood?
    @Binding var feelingsDescription: String
    let onSelect: (Mood) -> Void
    let onCheckIn: () -> Void
    @FocusState private var isEditorFocused: Bool
    private let checkInHeight: CGFloat = 52

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("How are you feeling?")
                .font(.foyCaptionMedium)
                .foregroundStyle(Color.foyForeground)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Spacing.xs) {
                ForEach(Mood.allCases) { mood in
                    MoodButtonView(mood: mood, isSelected: selectedMood == mood) {
                        onSelect(mood)
                    }
                }
            }

            inputSection

            Button(action: onCheckIn) {
                Text("Complete Check-In")
                    .font(.foyBodyMedium)
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

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Tell me about your feelings")
                .font(.foyHintMedium)
                .foregroundStyle(Color.foyForegroundSecondary)

            ZStack(alignment: .topLeading) {
                if feelingsDescription.isEmpty {
                    Text("Express yourself freely…")
                        .font(.foySkipLabel)
                        .foregroundStyle(Color.foyPlaceholder)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $feelingsDescription)
                    .font(.foySkipLabel)
                    .foregroundStyle(Color.foyForeground)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
                    .focused($isEditorFocused)
            }
            .padding(Spacing.sm)
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.foyBorder, lineWidth: 1)
            )
        }
    }
}

private struct MoodButtonView: View {
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
