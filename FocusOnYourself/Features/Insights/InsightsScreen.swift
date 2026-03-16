import SwiftUI
import Charts

private let cardCornerRadius: CGFloat = 18
private let chartHeight: CGFloat = 160
private let statCardCornerRadius: CGFloat = 16

struct InsightsScreen: View {
    @State private var viewModel = InsightsViewModel()
    @State private var showingPaywall = false

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        statsRow
                            .padding(.horizontal, Spacing.screenHorizontal)

                        moodThisWeekSection
                            .padding(.horizontal, Spacing.screenHorizontal)

                        weeklyAverageSection
                            .padding(.horizontal, Spacing.screenHorizontal)

                        if !viewModel.isPro {
                            proUpsellCard
                                .padding(.horizontal, Spacing.screenHorizontal)
                        }
                    }
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.screenBottom)
                }
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
            InsightStatCard(label: "Avg Mood", value: viewModel.averageMoodEmoji(days: 7))
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
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.foyBorder)
                        AxisValueLabel {
                            if let intVal = value.as(Int.self),
                               let mood = Mood.allCases.first(where: { $0.numericValue == intVal }) {
                                Text(mood.emoji).font(.foyMicro)
                            }
                        }
                    }
                }
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
                .stroke(Color.foyBorder, lineWidth: 1)
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
                        .foregroundStyle(item.avg >= 3.5 ? Color.foyOrange : Color.foyNavyTint)
                        .cornerRadius(6)
                    }
                    .chartYScale(domain: 0...5)
                    .chartYAxis {
                        AxisMarks(values: [1, 2, 3, 4, 5]) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.foyBorder)
                            AxisValueLabel()
                                .foregroundStyle(Color.foyForegroundSecondary)
                                .font(.foyHint)
                        }
                    }
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
                    .stroke(Color.foyBorder, lineWidth: 1)
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
            Text("Unlock weekly trends with Pro")
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

    private func barColor(for mood: Mood?) -> Color {
        guard let mood else { return Color.foyBorder }
        switch mood {
        case .good, .great: return Color.foyOrange
        case .okay:         return Color.foyNavy.opacity(0.5)
        case .low, .rough:  return Color.foyNavyTint
        }
    }
}
