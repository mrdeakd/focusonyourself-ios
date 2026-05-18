import Factory
import Foundation

final class MeditationPlayerUseCase: MeditationPlayerUseCaseProtocol {
    @Injected(\.meditationAudioService) private var meditationAudioService

    func speak(_ text: String, onComplete: @escaping () -> Void) {
        meditationAudioService.speak(text, onComplete: onComplete)
    }

    func stopSpeaking() {
        meditationAudioService.stopSpeaking()
    }

    func playBell() {
        meditationAudioService.playBell()
    }
}
