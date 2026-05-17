import SwiftUI

extension View {
    func foyCardStyle(
        borderColor: Color = .foyBorder,
        cornerRadius: CGFloat = CornerRadius.input
    ) -> some View {
        self
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}
