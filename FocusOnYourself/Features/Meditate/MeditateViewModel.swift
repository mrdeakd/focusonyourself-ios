import Factory
import Foundation
import Observation

@Observable @MainActor
final class MeditateViewModel {
    var selectedCategory: MeditationCategory?
    var sessions: [MeditationSession] = []
    var isLoading = false
    var selectedSession: MeditationSession?
    var showingPaywall = false
    var error: ErrorInfo?

    @ObservationIgnored @Injected(\.meditationService) private var meditationService
    @ObservationIgnored @Injected(\.purchaseUseCase) private var purchaseUseCase

    var isPro: Bool { purchaseUseCase.isPro }

    func handleSessionTap(_ session: MeditationSession) {
        if session.isPro && !isPro {
            showingPaywall = true
        } else {
            selectedSession = session
        }
    }

    func loadSessions() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched: [MeditationSession]
            if let selectedCategory {
                fetched = try await meditationService.sessions(in: selectedCategory)
            } else {
                fetched = try await meditationService.allSessions()
            }
            let categoryOrder = MeditationCategory.allCases
            sessions = fetched.sorted { lhs, rhs in
                let catA = categoryOrder.firstIndex(of: lhs.category) ?? 0
                let catB = categoryOrder.firstIndex(of: rhs.category) ?? 0
                if catA != catB {
                    return catA < catB
                }
                return !lhs.isPro && rhs.isPro
            }
        } catch {
            self.error = ErrorInfo(title: "Couldn't Load Meditations", description: error.localizedDescription)
        }
    }
}
