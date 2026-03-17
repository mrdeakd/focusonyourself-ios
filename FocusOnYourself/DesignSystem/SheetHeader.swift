import SwiftUI

struct SheetHeader: View {
    let title: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.foyNavTitle)
                    .foregroundStyle(Color.foyForeground)
                Spacer()
                Button("Cancel", action: onDismiss)
                    .font(.foyBodyMedium)
                    .foregroundStyle(Color.foyNavy)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.md)

            Rectangle()
                .fill(Color.foyBorder)
                .frame(height: 1)
        }
    }
}
