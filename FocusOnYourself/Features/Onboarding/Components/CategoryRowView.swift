import SwiftUI

struct CategoryRowView: View {
    let category: AffirmationCategory
    let isSelected: Bool
    let onTap: () -> Void

    private let iconSize: CGFloat = 20
    private let selectedBorderWidth: CGFloat = 1.5
    private let unselectedBorderWidth: CGFloat = 1

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(category.displayName)
                    .font(isSelected ? .inter(15, weight: .medium) : .foyBody)
                    .foregroundStyle(Color.foyForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(isSelected ? Color.foyNavy : Color.foyPlaceholder)
            }
            .padding(Spacing.md)
            .background(isSelected ? Color.foyNavyTint : .white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(
                        isSelected ? Color.foyNavy : Color.foyBorder,
                        lineWidth: isSelected ? selectedBorderWidth : unselectedBorderWidth
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
