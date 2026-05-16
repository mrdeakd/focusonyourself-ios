import SwiftUI

struct HistoryInsightsScreen: View {
    @State private var viewModel = HistoryInsightsViewModel()

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeaderView(title: "Progress")

                Picker("View", selection: Bindable(viewModel).selectedSegment) {
                    ForEach(HistoryInsightsViewModel.Segment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.sm)

                switch viewModel.selectedSegment {
                case .history:
                    HistoryScreen(showsHeader: false)
                case .insights:
                    InsightsScreen(showsHeader: false)
                }
            }
        }
    }
}
