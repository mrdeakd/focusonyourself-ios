import SwiftUI
import Charts

private let cardCornerRadius: CGFloat = 18
private let chartHeight: CGFloat = 160
private let moodChartHeight: CGFloat = 140
private let statCardCornerRadius: CGFloat = 16

struct InsightsScreen: View {
    @State private var viewModel = InsightsViewModel()
    @State private var showingPaywall = false

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                statsRow
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xxxs)

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        moodThisWeekSection
                            .padding(.horizontal, Spacing.screenHorizontal)
                            .padding(.top, Spacing.lg)

                        moodBreakdownSection
                            .padding(.horizontal, Spacing.screenHorizontal)

                        weeklyAverageSection
                            .padding(.horizontal, Spacing.screenHorizontal)

                        monthlyAverageSection
                            .padding(.horizontal, Spacing.screenHorizontal)

                        if !viewModel.isPro {
                            proUpsellCard
                                .padding(.horizontal, Spacing.screenHorizontal)
                        }
                    }
                    .padding(.bottom, Spacing.screenBottom)
                }
                .scrollIndicators(.hidden)
                .padding(.top, Spacing.md)
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallScreen()
        }
    }

    private var header: some View {
        HStack {
            Text("Insights")
                .font(.foyNavTitle)
                .foregroundStyle(Color.foyForeground)
            Spacer()
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }

    private var statsRow: some View {
        HStack(spacing: Spacing.sm) {
            InsightStatCard(label: "Avg Mood", value: viewModel.averageMoodText(days: 7))
            InsightStatCard(label: "This Week", value: "\(viewModel.checkInCount(days: 7))")
        }
    }

    private var moodThisWeekSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("MOOD THIS WEEK")
                .foySectionLabelStyle()
                .foregroundStyle(Color.foyPlaceholder)

            let data = viewModel.dailyMoodData(days: 7)

            if data.allSatisfy({ $0.checkIn == nil }) {
                emptyChartPlaceholder(message: "No check-ins yet this week")
            } else {
                Chart(data, id: \.label) { item in
                    BarMark(
                        x: .value("Day", item.label),
                        y: .value("Mood", item.checkIn?.mood.numericValue ?? 0)
                    )
                    .foregroundStyle(barColor(for: item.checkIn?.mood))
                    .cornerRadius(6)
                }
                .chartYScale(domain: 0...5)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.foyForegroundSecondary)
                            .font(.foyHint)
                    }
                }
                .frame(height: moodChartHeight)
            }
        }
        .padding(Spacing.md)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(Color.foyNavy, lineWidth: 1)
        )
    }

    private var moodBreakdownSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("MOOD BREAKDOWN")
                .foySectionLabelStyle()
                .foregroundStyle(Color.foyPlaceholder)

            if viewModel.recentCheckIns(days: 30).isEmpty {
                Text("No check-ins in the last 30 days")
                    .font(.foyCaption)
                    .foregroundStyle(Color.foyPlaceholder)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .multilineTextAlignment(.center)
            } else {
                let distribution = viewModel.moodDistribution(days: 30)
                let maxCount = distribution.map(\.count).max() ?? 1

                VStack(spacing: Spacing.xs) {
                    ForEach(distribution, id: \.mood) { item in
                        HStack(spacing: Spacing.sm) {
                            Image(item.mood.imageName)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.primary)
                                .frame(width: 24, alignment: .center)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.foyNavy.opacity(0.08))
                                        .frame(maxWidth: .infinity)

                                    let fillWidth = maxCount > 0
                                        ? geo.size.width * CGFloat(item.count) / CGFloat(maxCount)
                                        : 0
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.foyNavy)
                                        .frame(width: max(fillWidth, item.count > 0 ? 4 : 0))
                                }
                            }
                            .frame(height: 10)

                            Text("\(item.count)")
                                .font(.foyHint)
                                .foregroundStyle(Color.foyForegroundSecondary)
                                .frame(width: 24, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(Color.foyNavy, lineWidth: 1)
        )
    }

    private var weeklyAverageSection: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("WEEKLY AVERAGE")
                    .foySectionLabelStyle()
                    .foregroundStyle(Color.foyPlaceholder)

                let data = viewModel.weeklyAverages()

                if data.allSatisfy({ $0.avg == 0 }) {
                    emptyChartPlaceholder(message: "Check in daily to see weekly trends")
                } else {
                    Chart(data, id: \.week) { item in
                        BarMark(
                            x: .value("Week", item.week),
                            y: .value("Avg", item.avg)
                        )
                        .foregroundStyle(avgBarColor(for: item.avg))
                        .cornerRadius(6)
                    }
                    .chartYScale(domain: 0...5)
                    .chartYAxis(.hidden)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(Color.foyForegroundSecondary)
                                .font(.foyHint)
                        }
                    }
                    .frame(height: chartHeight)
                }
            }
            .padding(Spacing.lg)
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .stroke(Color.foyNavy, lineWidth: 1)
            )
            .blur(radius: viewModel.isPro ? 0 : 6)
            .allowsHitTesting(viewModel.isPro)

            if !viewModel.isPro {
                proChartOverlay
            }
        }
    }

    private var monthlyAverageSection: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("MONTHLY AVERAGE")
                    .foySectionLabelStyle()
                    .foregroundStyle(Color.foyPlaceholder)

                let data = viewModel.monthlyAverages()

                if data.allSatisfy({ $0.avg == 0 }) {
                    emptyChartPlaceholder(message: "Check in regularly to see monthly trends")
                } else {
                    Chart(data, id: \.month) { item in
                        BarMark(
                            x: .value("Month", item.month),
                            y: .value("Avg", item.avg)
                        )
                        .foregroundStyle(avgBarColor(for: item.avg))
                        .cornerRadius(6)
                    }
                    .chartYScale(domain: 0...5)
                    .chartYAxis(.hidden)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(Color.foyForegroundSecondary)
                                .font(.foyHint)
                        }
                    }
                    .frame(height: chartHeight)
                }
            }
            .padding(Spacing.lg)
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .stroke(Color.foyNavy, lineWidth: 1)
            )
            .blur(radius: viewModel.isPro ? 0 : 6)
            .allowsHitTesting(viewModel.isPro)

            if !viewModel.isPro {
                proChartOverlay
            }
        }
    }

    private var proChartOverlay: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: "lock.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.foyNavy)
            Text("Unlock trends with Pro")
                .font(.foyBodyMedium)
                .foregroundStyle(Color.foyForeground)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
    }

    private var proUpsellCard: some View {
        Button {
            showingPaywall = true
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .fill(Color.foyUpgradeIconBg)
                        .frame(width: 44, height: 44)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.foyOrange)
                }
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
                    .font(.system(size: 13, weight: .medium))
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

    private func emptyChartPlaceholder(message: String) -> some View {
        Text(message)
            .font(.foyCaption)
            .foregroundStyle(Color.foyPlaceholder)
            .frame(maxWidth: .infinity, minHeight: chartHeight)
            .multilineTextAlignment(.center)
    }

    private func avgBarColor(for avg: Double) -> Color {
        switch Int(avg.rounded()) {
        case 5: return Color.foyOrange
        case 4: return Color.foyOrangeAccent
        case 3: return Color.foyForegroundSecondary
        case 2: return Color.foyPlaceholder
        default: return Color.foyBorder
        }
    }

    private func barColor(for mood: Mood?) -> Color {
        guard let mood else { return Color.foyBorder }
        switch mood {
        case .great: return Color.foyOrange
        case .good:  return Color.foyOrangeAccent
        case .okay:  return Color.foyForegroundSecondary
        case .low:   return Color.foyPlaceholder
        case .rough: return Color.foyBorder
        }
    }
}
