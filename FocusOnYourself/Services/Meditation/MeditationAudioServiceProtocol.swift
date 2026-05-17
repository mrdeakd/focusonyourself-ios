protocol MeditationAudioServiceProtocol {
    func speak(_ text: String, onComplete: @escaping () -> Void)
    func stopSpeaking()
    func playBell()
}
