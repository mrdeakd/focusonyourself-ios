import AVFoundation

@MainActor
final class MeditationAudioService: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?       // bell
    private var narrationPlayer: AVAudioPlayer?   // bundled MP3 narrations
    private var narrationMap: [String: String] = [:]
    private var onNarrationComplete: (() -> Void)?
    private var currentUtterance: AVSpeechUtterance?
    private var bellEngine: AVAudioEngine?

    override init() {
        super.init()
        synthesizer.delegate = self
        loadNarrationMap()
        configureAudioSession()
    }

    private func loadNarrationMap() {
        guard let url = Bundle.main.url(forResource: "narration_map", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let map = try? JSONDecoder().decode([String: String].self, from: data) else {
            return
        }
        narrationMap = map
    }

    private func configureAudioSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    func speak(_ text: String, onComplete: @escaping () -> Void) {
        activateAudioSession()
        stopSpeaking()

        if let filename = narrationMap[text],
           let url = Bundle.main.url(forResource: filename, withExtension: "mp3"),
           let player = try? AVAudioPlayer(contentsOf: url) {
            onNarrationComplete = onComplete
            narrationPlayer = player
            narrationPlayer?.delegate = self
            narrationPlayer?.play()
            return
        }

        // Fallback: AVSpeechSynthesizer
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.0
        utterance.voice = Self.bestEnglishVoice
        currentUtterance = utterance
        onNarrationComplete = onComplete
        synthesizer.speak(utterance)
    }

    private static let bestEnglishVoice: AVSpeechSynthesisVoice? = {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
            .first
    }()

    func stopSpeaking() {
        onNarrationComplete = nil
        currentUtterance = nil
        narrationPlayer?.stop()
        narrationPlayer = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    func playBell() {
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

    private func fireAndClearNarrationCallback() {
        onNarrationComplete?()
        onNarrationComplete = nil
    }

    private func activateAudioSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    private func playGeneratedBell() {
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * 2.5)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let ptr = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            ptr[i] = Float(sin(2 * .pi * 528 * t) * exp(-t * 1.8) * 0.6)
        }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        guard (try? engine.start()) != nil else { return }

        bellEngine = engine
        player.scheduleBuffer(buffer, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor in
                self?.bellEngine = nil
            }
        }
        player.play()
    }
}

extension MeditationAudioService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard utterance === self.currentUtterance else { return }
            self.currentUtterance = nil
            self.fireAndClearNarrationCallback()
        }
    }
}

extension MeditationAudioService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            guard player === self.narrationPlayer else { return }
            self.narrationPlayer = nil
            self.fireAndClearNarrationCallback()
        }
    }
}
