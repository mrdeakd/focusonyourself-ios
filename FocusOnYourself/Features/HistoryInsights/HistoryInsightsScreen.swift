import SwiftUI

struct HistoryInsightsScreen: View {
    private enum Segment: String, CaseIterable {
        case history = "History"
        case insights = "Insights"
    }

    @State private var selectedSegment: Segment = .history

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Progress")
                        .font(.foyNavTitle)
                        .foregroundStyle(Color.foyForeground)
                    Spacer()
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)

                Picker("", selection: $selectedSegment) {
                    ForEach(Segment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.sm)

                switch selectedSegment {
                case .history:
                    HistoryScreen(showsHeader: false)
                case .insights:
                    InsightsScreen(showsHeader: false)
                }
            }
        }
    }
}
