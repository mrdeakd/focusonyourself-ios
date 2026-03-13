import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: AppTab = .home

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case .home:
                    HomeScreen(appState: appState)
                case .history:
                    HistoryScreen()
                case .settings:
                    SettingsScreen()
                }
            }
            .frame(maxHeight: .infinity)

            AppTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
