import SwiftUI

struct InlineErrorView: View {
    let error: ErrorInfo

    @State private var isVisible = false

    private let horizontalPadding: CGFloat = 18
    private let iconWrapCornerRadius: CGFloat = 8
    private let gradientEnd = Color(red: 1, green: 0.678, blue: 0.502)

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: iconWrapCornerRadius)
                    .fill(Color.white.opacity(0.15))
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.white)
            }
            .frame(width: 32, height: 32)
            if let description = error.description {
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(error.title)
                        .font(.foySkipLabelMedium)
                        .foregroundStyle(Color.white)
                    Text(description)
                        .font(.foyHint)
                        .foregroundStyle(Color.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
            } else {
                Text(error.title)
                    .font(.foySkipLabelMedium)
                    .foregroundStyle(Color.white)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.foyOrange, gradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -6)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isVisible = true
            }
        }
    }
}
