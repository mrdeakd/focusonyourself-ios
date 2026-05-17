import SwiftUI

// Pencil design: signed-out node zDSjd · signed-in node hEerR
struct SettingsAccountSection: View {
    var viewModel: SettingsViewModel

    private let cardRadius: CGFloat = 20

    var body: some View {
        Group {
            if viewModel.isAuthenticated {
                signedInCard
            } else {
                signedOutCard
            }
        }
        .fullScreenCover(isPresented: Bindable(viewModel).showAuthFlow) {
            AuthFlow()
        }
    }

    // MARK: - Signed out: navy CTA card

    private var signedOutCard: some View {
        Button {
            viewModel.showAuthFlow = true
        } label: {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.foyOnPrimary.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "person.fill")
                            .font(.foyHeadline)
                            .foregroundStyle(Color.foyOnPrimary)
                    }
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Sign in to FocusOnYourself")
                            .font(.foyBodyMedium)
                            .foregroundStyle(Color.foyOnPrimary)
                        Text("Sync your progress across all your devices.")
                            .font(.foyCaption)
                            .foregroundStyle(Color.foyOnPrimary.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text("Get Started")
                    .font(.foyBodyMedium)
                    .foregroundStyle(Color.foyOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.foyOnPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            }
            .padding(Spacing.lg)
            .background(Color.foyNavy)
            .clipShape(RoundedRectangle(cornerRadius: cardRadius))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Signed in: profile card

    private var signedInCard: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.foyNavy)
                    .frame(width: 52, height: 52)
                Text(avatarInitial)
                    .font(.foyHeadline)
                    .foregroundStyle(Color.foyOnPrimary)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(viewModel.currentName.isEmpty ? "Account" : viewModel.currentName)
                    .font(.foyBodySemibold)
                    .foregroundStyle(Color.foyForeground)
                Text(viewModel.accountEmail ?? "")
                    .font(.foyCaption)
                    .foregroundStyle(Color.foyForegroundSecondary)
            }

            Spacer()

            Text(viewModel.isPro ? "PRO" : "FREE")
                .font(.foySectionLabelSemibold)
                .foregroundStyle(viewModel.isPro ? Color.foyOrangeAccent : Color.foyNavy)
                .padding(.horizontal, Spacing.badgeHorizontal)
                .padding(.vertical, Spacing.xxxs)
                .background(viewModel.isPro ? Color.foyOrangeAccent.opacity(0.15) : Color.foyFreeBadgeBg)
                .clipShape(Capsule())
        }
        .padding(Spacing.md)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: cardRadius))
    }

    private var avatarInitial: String {
        if let name = viewModel.currentName.first.map(String.init), !viewModel.currentName.isEmpty {
            return name.uppercased()
        }
        return viewModel.accountEmail?.prefix(1).uppercased().description ?? "?"
    }
}
