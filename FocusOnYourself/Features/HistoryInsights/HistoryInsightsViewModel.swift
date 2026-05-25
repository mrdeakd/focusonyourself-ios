import Factory
import Foundation
import Observation

@Observable @MainActor
final class HistoryInsightsViewModel {
    var selectedSegment: Segment = .history

    enum Segment: String, CaseIterable {
        case history = "History"
        case insights = "Insights"
    }
}
