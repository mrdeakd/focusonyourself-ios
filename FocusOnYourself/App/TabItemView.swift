import SwiftUI

struct TabItemView: View {
    let tab: AppTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void

    private let activeCornerRadius: CGFloat = 26

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xxxs) {
                Image(systemName: tab.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text(tab.label)
                    .font(.foySectionLabel)
                    .kerning(0.5)
            }
            .foregroundStyle(isSelected ? Color.white : Color.foyPlaceholder)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: activeCornerRadius)
                        .fill(Color.foyNavy)
                        .matchedGeometryEffect(id: "activeTab", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
