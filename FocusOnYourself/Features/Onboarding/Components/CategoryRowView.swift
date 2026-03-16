import SwiftUI

struct CategoryRowView: View {
    let category: AffirmationCategory
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    private let iconSize: CGFloat = 20
    private let lockIconSize: CGFloat = 12
    private let selectedBorderWidth: CGFloat = 1.5
    private let unselectedBorderWidth: CGFloat = 1
    private let lockedOpacity: Double = 0.5
    private let proBadgeHorizontalPadding: CGFloat = 6
    private let proBadgeVerticalPadding: CGFloat = 3

    init(
        category: AffirmationCategory,
        isSelected: Bool,
        isLocked: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.category = category
        self.isSelected = isSelected
        self.isLocked = isLocked
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(category.displayName)
                    .font(isSelected && !isLocked ? .foyBodyMedium : .foyBody)
                    .foregroundStyle(Color.foyForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(isLocked ? lockedOpacity : 1)
                if isLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .resizable()
                            .frame(width: lockIconSize, height: lockIconSize)
                            .foregroundStyle(Color.foyOrange)
                        Text("Pro")
                            .font(.foyMicro)
                            .foregroundStyle(.white)
                            .padding(.horizontal, proBadgeHorizontalPadding)
                            .padding(.vertical, proBadgeVerticalPadding)
                            .background(Color.foyOrange)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.categoryTag))
                    }
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .frame(width: iconSize, height: iconSize)
                        .foregroundStyle(isSelected ? Color.foyNavy : Color.foyPlaceholder)
                }
            }
            .padding(Spacing.md)
            .background(isSelected && !isLocked ? Color.foyNavyTint : Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(
                        isSelected && !isLocked ? Color.foyNavy : Color.foyBorder,
                        lineWidth: isSelected && !isLocked ? selectedBorderWidth : unselectedBorderWidth
                    )
                    .opacity(isLocked ? lockedOpacity : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
