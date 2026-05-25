import AVFoundation
import Factory
import Foundation
import Observation

@Observable @MainActor
final class MeditationPlayerViewModel: NSObject {
    @ObservationIgnored @Injected(\.meditationService) private var meditationService

    let session: MeditationSession

    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var narrationMap: [String: String] = [:]
    @ObservationIgnored private var narrationPlayer: AVAudioPlayer?
    @ObservationIgnored private var onNarrationComplete: (() -> Void)?
    @ObservationIgnored private var speakTask: Task<Void, Never>?
    @ObservationIgnored private var bellEngine: AVAudioEngine?
    @ObservationIgnored private var audioPlayer: AVAudioPlayer?

    private let processingBreakDuration = 15

    // MARK: - State

    var currentStepIndex: Int = 0
    var isComplete = false
    var phase: MeditationPhase = .narrating
    var timerSecondsRemaining: Int = 0

    init(session: MeditationSession) {
        self.session = session
        super.init()
        configureAudioSession()
        Task { await fetchNarrationMap() }
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

    // MARK: - Public methods

    func onAppear() {
        startStep()
    }

    func onDisappear() {
        stopSpeaking()
        timerTask?.cancel()
    }

    func nextStep() {
        cancelTimer()
        stopSpeaking()
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
        stopSpeaking()
        currentStepIndex -= 1
        startStep()
    }

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

    // MARK: - Private methods

    private func configureAudioSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    private func activateAudioSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    private func fetchNarrationMap() async {
        // Narration is a non-fatal enhancement: if the map fails to load, speak() silently no-ops
        // and the player still progresses through steps.
        narrationMap = (try? await meditationService.narrationMap()) ?? [:]
    }

    private func speak(_ text: String, onComplete: @escaping () -> Void) {
        activateAudioSession()
        stopSpeaking()

        guard let audioUrl = narrationMap[text] else { return }

        onNarrationComplete = onComplete
        speakTask = Task { [weak self] in
            guard let self else { return }
            guard !Task.isCancelled else { return }
            if let localURL = await self.cachedAudio(for: audioUrl) {
                guard !Task.isCancelled else { return }
                if let player = try? AVAudioPlayer(contentsOf: localURL) {
                    self.narrationPlayer = player
                    self.narrationPlayer?.delegate = self
                    self.narrationPlayer?.play()
                }
            }
        }
    }

    private func cachedAudio(for urlString: String) async -> URL? {
        guard let remoteURL = URL(string: urlString) else { return nil }
        let filename = remoteURL.lastPathComponent
        let cacheDir = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("narrations")
        let localURL = cacheDir.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            try data.write(to: localURL)
            return localURL
        } catch {
            return nil
        }
    }

    private func stopSpeaking() {
        speakTask?.cancel()
        speakTask = nil
        onNarrationComplete = nil
        narrationPlayer?.stop()
        narrationPlayer = nil
    }

    private func playBell() {
        activateAudioSession()
        bellEngine?.stop()
        bellEngine = nil
        if let url = Bundle.main.url(forResource: "meditation-bell", withExtension: "aiff") {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } else {
            playGeneratedBell()
        }
    }

    private func playGeneratedBell() {
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * 2.5)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let ptr = buffer.floatChannelData![0]
        for index in 0..<Int(frameCount) {
            // swiftlint:disable:next identifier_name
            let t = Double(index) / sampleRate
            ptr[index] = Float(sin(2 * .pi * 528 * t) * exp(-t * 1.8) * 0.6)
        }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
        } catch {
            assertionFailure("AVAudioEngine failed to start: \(error)")
            return
        }
        bellEngine = engine
        player.scheduleBuffer(buffer, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor in
                self?.bellEngine = nil
            }
        }
        player.play()
    }

    private func startStep() {
        phase = .narrating
        if let instruction = currentStep.instruction {
            speak(instruction) { [weak self] in
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
            playBell()
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
        playBell()
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

extension MeditationPlayerViewModel: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            guard player === self.narrationPlayer else { return }
            self.narrationPlayer = nil
            self.onNarrationComplete?()
            self.onNarrationComplete = nil
        }
    }
}
