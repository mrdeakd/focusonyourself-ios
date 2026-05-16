import SwiftUI

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
        .overlay {
            RoundedRectangle(cornerRadius: pillCornerRadius)
                .stroke(Color.foyBorder, lineWidth: 1)
        }
        .padding(.horizontal, tabContainerPadding)
        .padding(.top, tabContainerTop)
        .padding(.bottom, tabContainerPadding)
        .background(Color.foyBackground)
    }
}
