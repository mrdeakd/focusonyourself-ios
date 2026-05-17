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

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -0.3

    func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .clear,               location: max(0, min(1, phase - 0.3))),
                        .init(color: .white.opacity(0.45), location: max(0, min(1, phase))),
                        .init(color: .clear,               location: max(0, min(1, phase + 0.3))),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}
