import Foundation
import Observation

@Observable @MainActor
final class MeditationPlayerViewModel {
    let session: MeditationSession
    var currentStepIndex: Int = 0
    var isComplete: Bool = false

    init(session: MeditationSession) {
        self.session = session
    }

    var currentStep: MeditationStep {
        session.steps[currentStepIndex]
    }

    var stepCount: Int {
        session.steps.count
    }

    var progress: Double {
        guard stepCount > 1 else { return 1 }
        return Double(currentStepIndex) / Double(stepCount - 1)
    }

    var isFirstStep: Bool {
        currentStepIndex == 0
    }

    var isLastStep: Bool {
        currentStepIndex == stepCount - 1
    }

    func nextStep() {
        if isLastStep {
            isComplete = true
        } else {
            currentStepIndex += 1
        }
    }

    func previousStep() {
        guard !isFirstStep else { return }
        currentStepIndex -= 1
    }
}
