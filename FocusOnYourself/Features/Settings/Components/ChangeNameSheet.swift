import SwiftUI

struct ChangeNameSheet: View {
    var viewModel: SettingsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var newName: String = ""

    private let handleWidth: CGFloat = 36
    private let handleHeight: CGFloat = 4

    var body: some View {
        VStack(spacing: 0) {
            handle

            header

            Rectangle()
                .fill(Color.foyBorder)
                .frame(height: 1)

            content
        }
        .background(Color.foyBackground)
    }

    private var handle: some View {
        RoundedRectangle(cornerRadius: handleHeight / 2)
            .fill(Color.foyBorder)
            .frame(width: handleWidth, height: handleHeight)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)
    }

    private var header: some View {
        HStack {
            Text("Change name")
                .font(.foyNavTitle)
                .foregroundStyle(Color.foyForeground)
            Spacer()
            Button("Cancel") {
                dismiss()
            }
            .font(.foyBodyMedium)
            .foregroundStyle(Color.foyNavy)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.md)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            currentNameSection
            newNameSection
            Text("This is the name shown in your daily greeting.")
                .font(.foyHint)
                .foregroundStyle(Color.foyPlaceholder)

            Spacer()

            saveButton
        }
        .padding(.top, Spacing.xl)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.lg)
    }

    private var currentNameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionLabel("CURRENT NAME")
            HStack {
                Text(viewModel.currentName.isEmpty ? "Your name" : viewModel.currentName)
                    .font(.foyBody)
                    .foregroundStyle(Color.foyPlaceholder)
                Spacer()
                Image(systemName: "lock")
                    .foregroundStyle(Color.foyPlaceholder)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }

    private var newNameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionLabel("NEW NAME")
            TextField("Enter new name", text: $newName)
                .font(.foyInputText)
                .foregroundStyle(Color.foyForeground)
                .padding(.horizontal, Spacing.md)
                .frame(height: Spacing.inputHeight)
                .background(Color.foyCard)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .stroke(Color.foyNavy, lineWidth: 1)
                )
        }
    }

    private var saveButton: some View {
        Button {
            viewModel.updateName(newName)
            dismiss()
        } label: {
            Text("Save Changes")
                .font(.foyButtonLabel)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.buttonVertical)
                .background(Color.foyNavy)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
        }
        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .foySectionLabelStyle()
            .foregroundStyle(Color.foyPlaceholder)
    }
}
