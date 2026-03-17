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
            .foyCardStyle(cornerRadius: CornerRadius.card)
        }
    }
}

