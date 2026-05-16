import Factory
import Foundation
import Observation

@Observable @MainActor
final class MeditationPlayerViewModel {
    let session: MeditationSession
    @ObservationIgnored @Injected(\.meditationAudioService) private var audioService

    var currentStepIndex: Int = 0
    var isComplete = false
    var phase: MeditationPhase = .narrating
    var timerSecondsRemaining: Int = 0

    private var timerTask: Task<Void, Never>?

    private let processingBreakDuration = 15

    init(session: MeditationSession) {
        self.session = session
    }

    // MARK: - Computed

    var currentStep: MeditationStep { session.steps[currentStepIndex] }
    var stepCount: Int { session.steps.count }
    var progress: Double { guard stepCount > 1 else { return 1 }; return Double(currentStepIndex) / Double(stepCount - 1) }
    var isFirstStep: Bool { currentStepIndex == 0 }
    var isLastStep: Bool { currentStepIndex == stepCount - 1 }

    var timerDisplay: String {
        Duration.seconds(timerSecondsRemaining)
            .formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1)))
    }

    // MARK: - Lifecycle

    func onAppear() {
        startStep()
    }

    func onDisappear() {
        audioService.stopSpeaking()
        timerTask?.cancel()
    }

    // MARK: - Navigation

    func nextStep() {
        cancelTimer()
        audioService.stopSpeaking()
        if isLastStep {
            isComplete = true
        } else {
            currentStepIndex += 1
            startStep()
        }
    }

    func previousStep() {
        guard !isFirstStep else { return }
        cancelTimer()
        audioService.stopSpeaking()
        currentStepIndex -= 1
        startStep()
    }

    // MARK: - Timer Controls

    func pauseTimer() {
        guard phase == .timerRunning else { return }
        timerTask?.cancel()
        phase = .timerPaused
    }

    func resumeTimer() {
        guard phase == .timerPaused else { return }
        phase = .timerRunning
        runTimer()
    }

    // MARK: - Private

    private func startStep() {
        phase = .narrating
        if let instruction = currentStep.instruction {
            audioService.speak(instruction) { [weak self] in
                self?.onNarrationFinished()
            }
        } else {
            onNarrationFinished()
        }
    }

    private func advanceStep() {
        cancelTimer()
        if isLastStep {
            isComplete = true
        } else {
            currentStepIndex += 1
            startStep()
        }
    }

    private func onNarrationFinished() {
        if let duration = currentStep.silenceDurationSeconds {
            audioService.playBell()
            timerSecondsRemaining = duration
            phase = .timerRunning
            runTimer()
        } else if !isLastStep {
            let nextStep = session.steps[currentStepIndex + 1]
            if nextStep.silenceDurationSeconds != nil {
                advanceStep()
            } else {
                timerSecondsRemaining = processingBreakDuration
                phase = .processingBreak
                runProcessingBreak()
            }
        }
    }

    private func runCountdown(onTick: (() -> Void)? = nil, onComplete: @escaping () -> Void) {
        timerTask = Task {
            while timerSecondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                onTick?()
            }
            if !Task.isCancelled {
                onComplete()
            }
        }
    }

    private func runProcessingBreak() {
        runCountdown(
            onTick: { [weak self] in self?.timerSecondsRemaining -= 1 },
            onComplete: { [weak self] in self?.advanceStep() }
        )
    }

    private func runTimer() {
        runCountdown(
            onTick: { [weak self] in
                guard let self, phase == .timerRunning else { return }
                timerSecondsRemaining -= 1
            },
            onComplete: { [weak self] in self?.onTimerFinished() }
        )
    }

    private func onTimerFinished() {
        audioService.playBell()
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            nextStep()
        }
    }

    private func cancelTimer() {
        timerTask?.cancel()
        timerTask = nil
        phase = .narrating
        timerSecondsRemaining = 0
    }
}
