import SwiftUI

struct ChangeCategoriesSheet: View {
    var viewModel: SettingsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var draftCategories: Set<AffirmationCategory> = []
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            SheetDragHandle()

            SheetHeader(title: "Change categories") { dismiss() }

            ChangeCategoriesContent(
                viewModel: viewModel,
                draftCategories: $draftCategories,
                showPaywall: $showPaywall
            )

            Spacer()

            ChangeCategoriesSaveButton(isDisabled: draftCategories.isEmpty) {
                viewModel.updateCategories(draftCategories)
                dismiss()
            }
        }
        .background(Color.foyBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.foyBackground)
        .onAppear {
            draftCategories = viewModel.currentCategories
        }
        .sheet(isPresented: $showPaywall) {
            PaywallScreen()
        }
    }
}

// MARK: - ChangeCategoriesContent

struct ChangeCategoriesContent: View {
    let viewModel: SettingsViewModel
    @Binding var draftCategories: Set<AffirmationCategory>
    @Binding var showPaywall: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Select the topics you want to focus on.\nAt least one must be selected.")
                .font(.foyCaption)
                .foregroundStyle(Color.foyForegroundSecondary)
                .lineSpacing(Spacing.xxs)

            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.sortedCategories) { category in
                    let isLocked = !category.isFree && !viewModel.isPro
                    CategoryRowView(
                        category: category,
                        isSelected: draftCategories.contains(category),
                        isLocked: isLocked
                    ) {
                        if isLocked {
                            showPaywall = true
                        } else if draftCategories.contains(category) {
                            draftCategories.remove(category)
                        } else {
                            draftCategories.insert(category)
                        }
                    }
                }
            }
        }
        .padding(.top, Spacing.lg)
        .padding(.horizontal, Spacing.screenHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - ChangeCategoriesSaveButton

struct ChangeCategoriesSaveButton: View {
    let isDisabled: Bool
    let onSave: () -> Void

    var body: some View {
        Button("Save Changes") {
            onSave()
        }
        .buttonStyle(FoyPrimaryButtonStyle())
        .disabled(isDisabled)
        .padding(.top, Spacing.sm)
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.xxl)
    }
}
