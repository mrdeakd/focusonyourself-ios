import Factory
import Foundation
import Observation

@Observable @MainActor
final class HistoryInsightsViewModel {
    enum Segment: String, CaseIterable {
        case history = "History"
        case insights = "Insights"
    }

    var selectedSegment: Segment = .history
}
