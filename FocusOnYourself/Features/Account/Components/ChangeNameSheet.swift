import SwiftUI

struct ChangeNameSheet: View {
    var viewModel: AccountViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var newName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            SheetDragHandle()

            SheetHeader(title: "Change name") { dismiss() }

            VStack(alignment: .leading, spacing: Spacing.lg) {
                ChangeNameCurrentSection(viewModel: viewModel)
                ChangeNameNewSection(name: $newName)
                Text("This is the name shown in your daily greeting.")
                    .font(.foyHint)
                    .foregroundStyle(Color.foyPlaceholder)

                Spacer()

                ChangeNameSaveButton(name: newName) {
                    viewModel.updateName(newName)
                    dismiss()
                }
            }
            .padding(.top, Spacing.xl)
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .background(Color.foyBackground)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.foyBackground)
    }
}

// MARK: - ChangeNameCurrentSection

struct ChangeNameCurrentSection: View {
    let viewModel: AccountViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel("CURRENT NAME")
            HStack {
                Text(viewModel.currentName.isEmpty ? "Your name" : viewModel.currentName)
                    .font(.foyBody)
                    .foregroundStyle(viewModel.currentName.isEmpty ? Color.foyPlaceholder : Color.foyForeground)
                Spacer()
                Image(systemName: "lock")
                    .foregroundStyle(Color.foyPlaceholder)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }
}

// MARK: - ChangeNameNewSection

struct ChangeNameNewSection: View {
    @Binding var name: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel("NEW NAME")
            TextField("Enter new name", text: $name)
                .font(.foyInputText)
                .foregroundStyle(Color.foyForeground)
                .padding(.horizontal, Spacing.md)
                .frame(height: Spacing.inputHeight)
                .background(Color.foyCard)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .stroke(Color.foyNavy, lineWidth: 1)
                }
        }
    }
}

// MARK: - ChangeNameSaveButton

struct ChangeNameSaveButton: View {
    let name: String
    let onSave: () -> Void

    var body: some View {
        Button("Save Changes") {
            onSave()
        }
        .buttonStyle(FoyPrimaryButtonStyle())
        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}
