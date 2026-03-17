import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .checkin

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case .checkin:
                    HomeScreen()
                case .meditate:
                    MeditateScreen()
                case .historyInsights:
                    HistoryInsightsScreen()
                case .settings:
                    SettingsScreen()
                }
            }
            .frame(maxHeight: .infinity)
            .animation(.none, value: selectedTab)

            AppTabBar(selectedTab: $selectedTab)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
