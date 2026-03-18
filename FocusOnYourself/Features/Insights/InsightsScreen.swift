import Charts
import SwiftUI

private let cardCornerRadius: CGFloat = 18

struct InsightsScreen: View {
    @State private var viewModel = InsightsViewModel()
    @State private var showingPaywall = false
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

                statsRow
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xxxs)

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        MoodThisWeekSection(viewModel: viewModel)
                            .padding(.horizontal, Spacing.screenHorizontal)
                            .padding(.top, Spacing.sm)

                        MoodBreakdownSection(viewModel: viewModel)
                            .padding(.horizontal, Spacing.screenHorizontal)

                        WeeklyAverageSection(viewModel: viewModel)
                            .padding(.horizontal, Spacing.screenHorizontal)

                        MonthlyAverageSection(viewModel: viewModel)
                            .padding(.horizontal, Spacing.screenHorizontal)

                        if !viewModel.isPro {
                            proUpsellCard
                                .padding(.horizontal, Spacing.screenHorizontal)
                        }
                    }
                    .padding(.bottom, Spacing.screenBottom)
                }
                .scrollIndicators(.hidden)
                .padding(.top, Spacing.xxs)
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallScreen()
        }
    }

    private var statsRow: some View {
        HStack(spacing: Spacing.sm) {
            StatCard(label: "Avg Mood", value: viewModel.averageMoodText(days: 7))
            StatCard(label: "This Week", value: "\(viewModel.checkInCount(days: 7))")
        }
    }

    private var proUpsellCard: some View {
        Button {
            showingPaywall = true
        } label: {
            HStack(spacing: Spacing.md) {
                IconBox(
                    systemName: "chart.line.uptrend.xyaxis",
                    tintColor: Color.foyUpgradeIconBg,
                    iconColor: Color.foyOrange
                )
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text("Unlock Full History")
                        .font(.foyBodyMedium)
                        .foregroundStyle(Color.foyForeground)
                    Text("30-day trends, best day & more")
                        .font(.foyCaption)
                        .foregroundStyle(Color.foyForegroundSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.foyCaptionMedium)
                    .foregroundStyle(Color.foyPlaceholder)
            }
            .padding(Spacing.md)
            .background(Color.foyUpgradeCardBg)
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .stroke(Color.foyUpgradeCardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
