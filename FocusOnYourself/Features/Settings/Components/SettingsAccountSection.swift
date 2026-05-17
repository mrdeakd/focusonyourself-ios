import SwiftUI

// Pencil design: signed-out node tpdH3 · signed-in node XLOyV
struct SettingsAccountSection: View {
    var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel("ACCOUNT")
            if viewModel.isAuthenticated {
                signedInCard
            } else {
                signedOutCard
            }
        }
        .sheet(isPresented: Bindable(viewModel).showAuthFlow) {
            AuthFlow()
        }
    }

    private var signedOutCard: some View {
        Button {
            viewModel.showAuthFlow = true
        } label: {
            HStack {
                Text("Create account")
                    .font(.foyBody)
                    .foregroundStyle(Color.foyNavy)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.foyCaptionMedium)
                    .foregroundStyle(Color.foyNavy)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    private var signedInCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.accountEmail ?? "")
                    .font(.foyBody)
                    .foregroundStyle(Color.foyForeground)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)

            Rectangle()
                .fill(Color.foyBorder)
                .frame(height: 1)

            Button {
                Task { await viewModel.signOut() }
            } label: {
                HStack {
                    Text("Sign Out")
                        .font(.foyBody)
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
            }
        }
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}
