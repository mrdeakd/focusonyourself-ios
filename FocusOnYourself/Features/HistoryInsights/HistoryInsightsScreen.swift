import SwiftUI

struct HistoryInsightsScreen: View {
    private enum Segment: CaseIterable {
        case history
        case insights

        var displayName: String {
            switch self {
            case .history:  return String(localized: "history.title")
            case .insights: return String(localized: "insights.title")
            }
        }
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
                        Text(segment.displayName).tag(segment)
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
