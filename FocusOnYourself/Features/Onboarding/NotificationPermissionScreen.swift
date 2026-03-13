import SwiftUI

struct NotificationPermissionScreen: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: Spacing.xxl) {
                    ZStack {
                        Circle()
                            .fill(Color.foyNavyTint)
                            .frame(width: Spacing.iconCircle, height: Spacing.iconCircle)
                        Image(systemName: "bell")
                            .resizable()
                            .scaledToFit()
                            .frame(width: Spacing.iconImage, height: Spacing.iconImage)
                            .foregroundStyle(Color.foyNavy)
                    }
                    VStack(spacing: Spacing.sm) {
                        Text("Stay on track")
                            .foySectionTitleStyle()
                            .foregroundStyle(Color.foyForeground)
                            .multilineTextAlignment(.center)
                        Text("We'll send you a gentle reminder at 9:00 AM each morning so you never miss a day.")
                            .foyBodyStyle()
                            .foregroundStyle(Color.foyForegroundSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }

                Spacer()

                VStack(spacing: Spacing.md) {
                    Button {
                        Task { await viewModel.enableNotifications() }
                    } label: {
                        Text("Enable Notifications")
                            .font(.foyButtonLabel)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.buttonVertical)
                            .background(Color.foyNavy)
                            .clipShape(Capsule())
                    }
                    Button { viewModel.skipNotifications() } label: {
                        Text("Skip for now")
                            .font(.foySkipLabel)
                            .foregroundStyle(Color.foyPlaceholder)
                            .padding(.vertical, Spacing.sm)
                    }
                }
            }
            .padding(.top, Spacing.screenTop)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.screenBottom)
        }
    }
}

#Preview { NotificationPermissionScreen(viewModel: OnboardingViewModel()) }
