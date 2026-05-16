import AVFoundation

@MainActor
final class MeditationAudioService: NSObject {
    private let networkClient: NetworkClientProtocol
    private var narrationMap: [String: String] = [:]
    private var narrationPlayer: AVAudioPlayer?
    private var onNarrationComplete: (() -> Void)?
    private var speakTask: Task<Void, Never>?
    private var bellEngine: AVAudioEngine?
    private var audioPlayer: AVAudioPlayer?

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
        super.init()
        configureAudioSession()
        Task { await fetchNarrationMap() }
    }

    private func fetchNarrationMap() async {
        do {
            narrationMap = try await networkClient.get("/api/narration-map")
            print("🗺️ [Audio] Narration map loaded: \(narrationMap.count) entries")
        } catch {
            print("❌ [Audio] Failed to load narration map: \(error)")
        }
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

        guard let audioUrl = narrationMap[text] else {
            // No map entry — silent, user reads the instruction and advances manually
            return
        }

        onNarrationComplete = onComplete
        speakTask = Task {
            guard !Task.isCancelled else { return }
            if let localURL = await cachedAudio(for: audioUrl) {
                guard !Task.isCancelled else { return }
                if let player = try? AVAudioPlayer(contentsOf: localURL) {
                    narrationPlayer = player
                    narrationPlayer?.delegate = self
                    narrationPlayer?.play()
                }
            }
            // Download failed — silent, user reads the instruction and advances manually
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
            print("🎵 [Audio] Cache hit: \(filename)")
            return localURL
        }

        print("⬇️ [Audio] Downloading: \(urlString)")
        do {
            let (data, response) = try await URLSession.shared.data(from: remoteURL)
            if let http = response as? HTTPURLResponse {
                print("⬇️ [Audio] Response \(http.statusCode) for \(filename) (\(data.count) bytes)")
            }
            try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            try data.write(to: localURL)
            print("✅ [Audio] Cached: \(filename)")
            return localURL
        } catch {
            print("❌ [Audio] Failed for \(filename): \(error)")
            return nil
        }
    }

    func stopSpeaking() {
        speakTask?.cancel()
        speakTask = nil
        onNarrationComplete = nil
        narrationPlayer?.stop()
        narrationPlayer = nil
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
