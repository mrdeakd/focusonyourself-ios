import SwiftUI

enum AppTab: CaseIterable {
    case checkin, meditate, historyInsights, settings

    var label: String {
        switch self {
        case .checkin:         return String(localized: "tab.checkin")
        case .meditate:        return String(localized: "tab.meditate")
        case .historyInsights: return String(localized: "tab.progress")
        case .settings:        return String(localized: "tab.settings")
        }
    }

    var icon: String {
        switch self {
        case .checkin:         return "heart.fill"
        case .meditate:        return "figure.mind.and.body"
        case .historyInsights: return "chart.bar.fill"
        case .settings:        return "gearshape"
        }
    }
}

struct AppTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var tabNamespace

    private let pillHeight: CGFloat = 62
    private let pillCornerRadius: CGFloat = 36
    private let innerPadding: CGFloat = 4
    private let tabContainerPadding: CGFloat = 21
    private let tabContainerTop: CGFloat = 12

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabItemView(tab: tab, isSelected: selectedTab == tab, namespace: tabNamespace) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(innerPadding)
        .frame(height: pillHeight)
        .background(Color.foyCard)
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
