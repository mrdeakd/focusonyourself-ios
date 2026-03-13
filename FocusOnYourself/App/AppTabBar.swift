import SwiftUI

enum AppTab: CaseIterable {
    case home, history, settings

    var label: String {
        switch self {
        case .home:     return "HOME"
        case .history:  return "HISTORY"
        case .settings: return "SETTINGS"
        }
    }

    var icon: String {
        switch self {
        case .home:     return "house.fill"
        case .history:  return "calendar"
        case .settings: return "gearshape"
        }
    }
}

struct AppTabBar: View {
    @Binding var selectedTab: AppTab

    private let pillHeight: CGFloat = 62
    private let pillCornerRadius: CGFloat = 36
    private let innerPadding: CGFloat = 4
    private let tabContainerPadding: CGFloat = 21
    private let tabContainerTop: CGFloat = 12

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabItemView(tab: tab, isSelected: selectedTab == tab) {
                    selectedTab = tab
                }
            }
        }
        .padding(innerPadding)
        .frame(height: pillHeight)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: pillCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: pillCornerRadius)
                .stroke(Color.foyBorder, lineWidth: 1)
        )
        .padding(.horizontal, tabContainerPadding)
        .padding(.top, tabContainerTop)
        .padding(.bottom, tabContainerPadding)
        .background(Color.foyBackground)
    }
}

private struct TabItemView: View {
    let tab: AppTab
    let isSelected: Bool
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
                    .font(.inter(10, weight: .medium))
                    .kerning(0.5)
            }
            .foregroundStyle(isSelected ? Color.white : Color.foyPlaceholder)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isSelected ? Color.foyNavy : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: activeCornerRadius))
        }
        .buttonStyle(.plain)
    }
}
