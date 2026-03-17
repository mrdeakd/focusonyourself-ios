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

            content

            Spacer()

            saveWrapper
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

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Select the topics you want to focus on.\nAt least one must be selected.")
                .font(.foyCaption)
                .foregroundStyle(Color.foyForegroundSecondary)
                .lineSpacing(Spacing.xxs)

            VStack(spacing: Spacing.sm) {
                ForEach(AffirmationCategory.allCases.sorted { $0.isFree && !$1.isFree }) { category in
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

    private var saveWrapper: some View {
        Button("Save Changes") {
            viewModel.updateCategories(draftCategories)
            dismiss()
        }
        .buttonStyle(FoyPrimaryButtonStyle())
        .disabled(draftCategories.isEmpty)
        .padding(.top, Spacing.sm)
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.xxl)
    }
}
