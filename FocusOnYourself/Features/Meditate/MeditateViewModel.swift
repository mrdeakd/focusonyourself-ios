import Factory
import Foundation
import Observation

@Observable @MainActor
final class MeditateViewModel {
    var selectedCategory: MeditationCategory? = nil

    @ObservationIgnored @Injected(\.meditationService) private var meditationService
    @ObservationIgnored @Injected(\.purchaseService) private var purchaseService

    var isPro: Bool { purchaseService.isPro }

    var filteredSessions: [MeditationSession] {
        meditationService.sessions(for: selectedCategory)
    }
}
