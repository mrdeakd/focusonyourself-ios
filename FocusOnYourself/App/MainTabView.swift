import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case .home:
                    HomeScreen()
                case .history:
                    HistoryScreen()
                case .settings:
                    SettingsScreen()
                }
            }
            .frame(maxHeight: .infinity)
            .animation(.none, value: selectedTab)

            AppTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
