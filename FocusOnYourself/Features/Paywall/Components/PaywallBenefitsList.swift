import SwiftUI

struct PaywallBenefitsList: View {
    let benefits: [(symbol: String, title: String, subtitle: String)]

    var body: some View {
        VStack(spacing: Spacing.xxxs) {
            ForEach(benefits, id: \.symbol) { benefit in
                BenefitRow(symbol: benefit.symbol, title: benefit.title, subtitle: benefit.subtitle)
            }
        }
    }
}
