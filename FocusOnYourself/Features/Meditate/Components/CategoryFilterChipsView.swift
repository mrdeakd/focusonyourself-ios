import SwiftUI

struct CategoryFilterChipsView: View {
    @Bindable var viewModel: MeditateViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                categoryChip(label: "All", category: nil)
                ForEach(MeditationCategory.allCases, id: \.self) { category in
                    categoryChip(label: category.displayName, category: category)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }

    @ViewBuilder
    private func categoryChip(label: String, category: MeditationCategory?) -> some View {
        let isSelected = viewModel.selectedCategory == category
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                viewModel.selectedCategory = category
            }
        } label: {
            Text(label)
                .font(.foyCaptionMedium)
                .foregroundStyle(isSelected ? .white : Color.foyForeground)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(isSelected ? Color.foyNavy : Color.foyCard)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : Color.foyBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
