import SwiftUI

struct MeditationPlayerView: View {
    let session: MeditationSession
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MeditationPlayerViewModel

    init(session: MeditationSession) {
        self.session = session
        _viewModel = State(initialValue: MeditationPlayerViewModel(session: session))
    }

    var body: some View {
        ZStack {
            Color.foyNavy.ignoresSafeArea()

            if viewModel.isComplete {
                MeditationCompletionView(sessionTitle: viewModel.localizedTitle, onDone: { dismiss() })
            } else {
                MeditationPlayerContentView(viewModel: viewModel)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}
