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
                    .foregroundStyle(Color.foyOnPrimary)
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

            TextField("Express yourself freely…", text: $feelingsDescription, axis: .vertical)
                .font(.foySkipLabel)
                .foregroundStyle(Color.foyForeground)
                .lineLimit(4...)
                .padding(Spacing.sm)
                .foyCardStyle(cornerRadius: CornerRadius.card)
                .focused($isEditorFocused)
        }
    }
}
