import SwiftUI

struct PaywallCtaSection: View {
    var viewModel: PaywallViewModel

    var body: some View {
        VStack(spacing: Spacing.md) {
            Button {
                viewModel.purchase()
            } label: {
                Text(viewModel.ctaLabel)
                    .font(.foyButtonLabel)
                    .foregroundStyle(Color.foyOnPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: Spacing.inputHeight)
                    .background(viewModel.ctaDisabled ? Color.foyButtonDisabled : Color.foyNavy)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
            }
            .disabled(viewModel.ctaDisabled)

            Button {
                viewModel.restore()
            } label: {
                Text("Restore Purchase")
                    .font(.foyCaption)
                    .foregroundStyle(Color.foyPlaceholder)
            }
            .disabled(viewModel.isLoading)

            if let error = viewModel.error {
                InlineErrorView(error: error)
            }

            PaywallLegalFooterView()
        }
    }
}
