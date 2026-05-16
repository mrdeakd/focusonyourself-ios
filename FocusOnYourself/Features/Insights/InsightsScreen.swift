import Charts
import SwiftUI

struct InsightsScreen: View {
    @State private var viewModel = InsightsViewModel()
    private let showsHeader: Bool

    init(showsHeader: Bool = true) {
        self.showsHeader = showsHeader
    }

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if showsHeader {
                    ScreenHeaderView(title: "Insights")
                }

                InsightsStatsRow(viewModel: viewModel)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xxxs)

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        FactorCorrelationRankingSection(viewModel: viewModel, selectedFactor: Bindable(viewModel).selectedFactor)
                            .padding(.top, Spacing.sm)

                        if let factor = viewModel.selectedFactor {
                            FactorDetailSection(factor: factor, viewModel: viewModel)
                        }

                        MoodThisWeekSection(viewModel: viewModel)

                        MoodBreakdownSection(viewModel: viewModel)

                        WeeklyAverageSection(viewModel: viewModel)

                        MonthlyAverageSection(viewModel: viewModel)

                        if !viewModel.isPro {
                            InsightsProUpsellCard(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.screenBottom)
                }
                .scrollIndicators(.hidden)
                .padding(.top, Spacing.xxs)
            }
        }
        .sheet(isPresented: Bindable(viewModel).showingPaywall) {
            PaywallScreen()
        }
    }
}
