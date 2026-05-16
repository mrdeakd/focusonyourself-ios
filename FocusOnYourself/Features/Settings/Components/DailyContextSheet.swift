import SwiftUI

struct DailyContextSheet: View {
    var viewModel: SettingsViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var sleep = true
    @State private var stress = true
    @State private var exercise = true
    @State private var social = true

    var body: some View {
        VStack(spacing: 0) {
            SheetDragHandle()
            SheetHeader(title: "Daily context") { dismiss() }
            content
            Spacer()
        }
        .background(Color.foyBackground)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.foyBackground)
        .onAppear {
            sleep    = viewModel.showSleepFactor
            stress   = viewModel.showStressFactor
            exercise = viewModel.showExerciseFactor
            social   = viewModel.showSocialFactor
        }
        .onChange(of: sleep) { viewModel.showSleepFactor = sleep }
        .onChange(of: stress) { viewModel.showStressFactor   = stress }
        .onChange(of: exercise) { viewModel.showExerciseFactor = exercise }
        .onChange(of: social) { viewModel.showSocialFactor   = social }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Choose which factors appear on your daily check-in.")
                .font(.foyCaption)
                .foregroundStyle(Color.foyForegroundSecondary)
                .lineSpacing(Spacing.xxs)

            VStack(spacing: 0) {
                toggleRow(label: "Sleep Quality", isOn: $sleep)
                Divider().background(Color.foyBorder).padding(.horizontal, Spacing.md)
                toggleRow(label: "Stress Level", isOn: $stress)
                Divider().background(Color.foyBorder).padding(.horizontal, Spacing.md)
                toggleRow(label: "Exercise", isOn: $exercise)
                Divider().background(Color.foyBorder).padding(.horizontal, Spacing.md)
                toggleRow(label: "Social Quality", isOn: $social)
            }
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
        .padding(.top, Spacing.lg)
        .padding(.horizontal, Spacing.screenHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.foyBody)
                .foregroundStyle(Color.foyForeground)
            Spacer()
            FOYToggle(isOn: isOn)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
    }
}
