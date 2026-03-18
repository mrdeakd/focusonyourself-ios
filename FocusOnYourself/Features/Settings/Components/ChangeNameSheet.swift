import SwiftUI

struct ChangeNameSheet: View {
    var viewModel: SettingsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var newName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            SheetDragHandle()

            SheetHeader(title: String(localized: "settings.changeName")) { dismiss() }

            content
        }
        .background(Color.foyBackground)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.foyBackground)
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
            SectionLabel(String(localized: "changeName.currentName"))
            HStack {
                Text(viewModel.currentName.isEmpty
                     ? String(localized: "settings.yourNamePlaceholder")
                     : viewModel.currentName)
                    .font(.foyBody)
                    .foregroundStyle(viewModel.currentName.isEmpty ? Color.foyPlaceholder : Color.foyForeground)
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
            SectionLabel(String(localized: "changeName.newName"))
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
        Button("Save Changes") {
            viewModel.updateName(newName)
            dismiss()
        }
        .buttonStyle(FoyPrimaryButtonStyle())
        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}
