import SwiftUI

struct CategoryPickerScreen: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("What matters\nto you?")
                        .foySectionTitleStyle()
                        .foregroundStyle(Color.foyForeground)
                    Text("Choose topics for your daily affirmations.\nSelect at least one.")
                        .foyBodyStyle()
                        .foregroundStyle(Color.foyForegroundSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: Spacing.sm) {
                    ForEach(AffirmationCategory.allCases) { category in
                        CategoryRowView(
                            category: category,
                            isSelected: viewModel.selectedCategories.contains(category),
                            onTap: { viewModel.toggleCategory(category) }
                        )
                    }
                }
                .frame(maxWidth: .infinity)

                Spacer()

                Button { viewModel.advance() } label: {
                    Text("Continue")
                        .font(.foyButtonLabel)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.buttonVertical)
                        .background(viewModel.selectedCategories.isEmpty ? Color.foyButtonDisabled : Color.foyNavy)
                        .clipShape(Capsule())
                }
                .disabled(viewModel.selectedCategories.isEmpty)
            }
            .padding(.top, Spacing.screenTop)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.screenBottom)
        }
    }
}

#Preview {
    CategoryPickerScreen(viewModel: {
        let vm = OnboardingViewModel()
        vm.selectedCategories = [.confidence, .relationships]
        return vm
    }())
}
