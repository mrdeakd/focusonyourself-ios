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
                completionView
            } else {
                playerView
            }
        }
        .preferredColorScheme(.dark)
    }

    private var playerView: some View {
        VStack(spacing: 0) {
            // Title
            Text(session.title)
                .font(.foyCaption)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, Spacing.xl)

            Spacer()

            // Instruction
            Text(viewModel.currentStep.instruction)
                .font(.foyBody)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, Spacing.xl)

            Spacer()

            // Progress bar
            progressBar
                .padding(.horizontal, Spacing.screenHorizontal)

            Text("Step \(viewModel.currentStepIndex + 1) of \(viewModel.stepCount)")
                .font(.foyHint)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.lg)

            // Navigation buttons
            HStack(spacing: Spacing.md) {
                Button {
                    withAnimation {
                        viewModel.previousStep()
                    }
                } label: {
                    Text("Back")
                        .font(.foyButtonLabel)
                        .foregroundStyle(.white.opacity(viewModel.isFirstStep ? 0.3 : 1))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.buttonVertical)
                        .background(Color.white.opacity(viewModel.isFirstStep ? 0 : 0.12))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.pill)
                                .stroke(Color.white.opacity(viewModel.isFirstStep ? 0.2 : 0.4), lineWidth: 1)
                        )
                }
                .disabled(viewModel.isFirstStep)

                Button {
                    withAnimation {
                        viewModel.nextStep()
                    }
                } label: {
                    Text(viewModel.isLastStep ? "Finish" : "Next")
                        .font(.foyButtonLabel)
                        .foregroundStyle(Color.foyNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.buttonVertical)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
        }
    }

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<viewModel.stepCount, id: \.self) { index in
                Capsule()
                    .fill(index <= viewModel.currentStepIndex ? Color.white : Color.white.opacity(0.25))
                    .frame(height: 4)
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white)

            VStack(spacing: Spacing.xs) {
                Text("Session Complete")
                    .font(.foyNavTitle)
                    .foregroundStyle(.white)

                Text(session.title)
                    .font(.foyCaption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.foyButtonLabel)
                    .foregroundStyle(Color.foyNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.buttonVertical)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
        }
    }
}
