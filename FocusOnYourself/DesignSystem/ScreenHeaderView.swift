import SwiftUI

struct ScreenHeaderView<Trailing: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack {
            Text(title)
                .font(.foyNavTitle)
                .foregroundStyle(Color.foyForeground)
            Spacer()
            trailing()
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }
}

extension ScreenHeaderView where Trailing == EmptyView {
    init(title: LocalizedStringKey) {
        self.title = title
        self.trailing = { EmptyView() }
    }
}
