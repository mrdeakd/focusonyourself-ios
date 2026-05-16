import SwiftUI

struct FactorSlidersView: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        VStack(spacing: Spacing.md) {
            if viewModel.showSleepFactor {
                factorSliderRow(label: "Sleep Quality", value: $viewModel.sleepQuality)
            }
            if viewModel.showStressFactor {
                factorSliderRow(label: "Stress Level", value: $viewModel.stressLevel)
            }
            if viewModel.showExerciseFactor {
                exerciseRow
            }
            if viewModel.showSocialFactor {
                factorSliderRow(label: "Social Quality", value: $viewModel.socialQuality)
            }
        }
    }

    private func factorSliderRow(label: String, value: Binding<Int>) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Text(label)
                    .font(.foyHintMedium)
                    .foregroundStyle(Color.foyForeground)
                Spacer()
                Text("\(value.wrappedValue) / 5")
                    .font(.foyHint)
                    .foregroundStyle(Color.foyForegroundSecondary)
            }
            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0.rounded()) }
                ),
                in: 1...5,
                step: 1
            )
            .tint(Color.foyNavy)
            .accessibilityLabel(label)
            .accessibilityValue("\(value.wrappedValue) out of 5")
        }
    }

    private var exerciseRow: some View {
        HStack {
            Text("Exercise")
                .font(.foyHintMedium)
                .foregroundStyle(Color.foyForeground)
            Spacer()
            HStack(spacing: Spacing.xs) {
                chipButton(label: "Yes", isSelected: viewModel.exercised) {
                    viewModel.exercised = true
                }
                chipButton(label: "No", isSelected: !viewModel.exercised) {
                    viewModel.exercised = false
                }
            }
        }
    }

    private func chipButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.foyHintMedium)
                .foregroundStyle(isSelected ? Color.foyOnPrimary : Color.foyForegroundSecondary)
                .padding(.vertical, Spacing.xs)
                .padding(.horizontal, Spacing.md)
                .background(isSelected ? Color.foyNavy : Color.foyMoodBackground)
                .clipShape(Capsule())
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
