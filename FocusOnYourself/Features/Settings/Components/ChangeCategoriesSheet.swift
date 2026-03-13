import SwiftUI

struct ChangeCategoriesSheet: View {
    var viewModel: SettingsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var draftCategories: Set<AffirmationCategory> = []

    private let handleWidth: CGFloat = 36
    private let handleHeight: CGFloat = 4
    private let contentHorizontal: CGFloat = 20
    private let categorySpacing: CGFloat = 10

    var body: some View {
        VStack(spacing: 0) {
            handle

            header

            Rectangle()
                .fill(Color.foyBorder)
                .frame(height: 1)

            content

            Spacer()

            saveWrapper
        }
        .background(Color.foyBackground)
        .onAppear {
            draftCategories = viewModel.currentCategories
        }
    }

    private var handle: some View {
        RoundedRectangle(cornerRadius: handleHeight / 2)
            .fill(Color.foyButtonDisabled)
            .frame(width: handleWidth, height: handleHeight)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)
    }

    private var header: some View {
        HStack {
            Text("Change categories")
                .font(.foyNavTitle)
                .foregroundStyle(Color.foyForeground)
            Spacer()
            Button("Cancel") {
                dismiss()
            }
            .font(.foyBody)
            .foregroundStyle(Color.foyForegroundSecondary)
        }
        .padding(.horizontal, contentHorizontal)
        .padding(.bottom, Spacing.md)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Select the topics you want to focus on.\nAt least one must be selected.")
                .font(.foyCaption)
                .foregroundStyle(Color.foyForegroundSecondary)
                .lineSpacing(Spacing.xxs)

            VStack(spacing: categorySpacing) {
                ForEach(AffirmationCategory.allCases) { category in
                    CategoryRowView(
                        category: category,
                        isSelected: draftCategories.contains(category)
                    ) {
                        if draftCategories.contains(category) {
                            draftCategories.remove(category)
                        } else {
                            draftCategories.insert(category)
                        }
                    }
                }
            }
        }
        .padding(.top, Spacing.lg)
        .padding(.horizontal, contentHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var saveWrapper: some View {
        Button {
            viewModel.updateCategories(draftCategories)
            dismiss()
        } label: {
            Text("Save Changes")
                .font(.foyButtonLabel)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.buttonVertical)
                .background(draftCategories.isEmpty ? Color.foyButtonDisabled : Color.foyNavy)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
        }
        .disabled(draftCategories.isEmpty)
        .padding(.top, Spacing.sm)
        .padding(.horizontal, contentHorizontal)
        .padding(.bottom, Spacing.xxl)
    }
}
