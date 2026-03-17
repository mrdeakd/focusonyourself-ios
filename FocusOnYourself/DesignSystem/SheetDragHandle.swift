import SwiftUI

struct SheetDragHandle: View {
    private let width: CGFloat = 36
    private let height: CGFloat = 4
    private let cornerRadius: CGFloat = 2

    var body: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.foyButtonDisabled)
                .frame(width: width, height: height)
            Spacer()
        }
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xxs)
    }
}
