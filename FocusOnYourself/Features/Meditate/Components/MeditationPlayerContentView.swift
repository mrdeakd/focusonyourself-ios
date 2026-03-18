import SwiftUI

struct MeditationPlayerContentView: View {
    let session: MeditationSession
    let viewModel: MeditationPlayerViewModel

    var body: some View {
        VStack(spacing: 0) {
            Text(session.title)
                .font(.foyCaption)
                .foregroundStyle(Color.foyOnPrimary.opacity(0.5))
                .padding(.top, Spacing.xl)

            Spacer()

            if viewModel.phase == .narrating, let instruction = viewModel.currentStep.instruction {
                Text(instruction)
                    .font(.foyBody)
                    .foregroundStyle(Color.foyOnPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(Spacing.xs)
                    .padding(.horizontal, Spacing.xl)
            } else if viewModel.phase == .processingBreak {
                MeditationProcessingBreakView(timerDisplay: viewModel.timerDisplay)
            } else if viewModel.phase == .timerRunning || viewModel.phase == .timerPaused {
                MeditationTimerView(
                    timerDisplay: viewModel.timerDisplay,
                    phase: viewModel.phase,
                    onPause: { viewModel.pauseTimer() },
                    onResume: { viewModel.resumeTimer() }
                )
            }

            Spacer()

            MeditationProgressBarView(
                stepCount: viewModel.stepCount,
                currentStepIndex: viewModel.currentStepIndex
            )
            .padding(.horizontal, Spacing.screenHorizontal)

            Text("Step \(viewModel.currentStepIndex + 1) of \(viewModel.stepCount)")
                .font(.foyHint)
                .foregroundStyle(Color.foyOnPrimary.opacity(0.5))
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.lg)

            HStack(spacing: Spacing.md) {
                Button {
                    withAnimation {
                        viewModel.previousStep()
                    }
                } label: {
                    Text("Back")
                        .font(.foyButtonLabel)
                        .foregroundStyle(Color.foyOnPrimary.opacity(viewModel.isFirstStep ? 0.3 : 1))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.buttonVertical)
                        .background(Color.foyOnPrimary.opacity(viewModel.isFirstStep ? 0 : 0.12))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.pill)
                                .stroke(Color.foyOnPrimary.opacity(viewModel.isFirstStep ? 0.2 : 0.4), lineWidth: 1)
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
                        .background(Color.foyOnPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
        }
    }
}
