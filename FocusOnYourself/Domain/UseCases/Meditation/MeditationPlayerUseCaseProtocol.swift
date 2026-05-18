import Foundation

protocol MeditationPlayerUseCaseProtocol: AnyObject {
    func speak(_ text: String, onComplete: @escaping () -> Void)
    func stopSpeaking()
    func playBell()
}
