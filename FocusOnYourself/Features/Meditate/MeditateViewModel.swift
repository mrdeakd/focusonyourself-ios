import Factory
import Foundation
import Observation

@Observable @MainActor
final class MeditateViewModel {
    var selectedCategory: MeditationCategory?

    @ObservationIgnored @Injected(\.meditationService) private var meditationService
    @ObservationIgnored @Injected(\.purchaseService) private var purchaseService

    var isPro: Bool { purchaseService.isPro }

    func localizedTitle(for session: MeditationSession) -> String {
        meditationService.localizedTitle(for: session)
    }

    var filteredSessions: [MeditationSession] {
        let categoryOrder = MeditationCategory.allCases
        return meditationService.sessions(for: selectedCategory)
            .sorted {
                let catA = categoryOrder.firstIndex(of: $0.category) ?? 0
                let catB = categoryOrder.firstIndex(of: $1.category) ?? 0
                if catA != catB { return catA < catB }
                return !$0.isPro && $1.isPro
            }
    }
}
