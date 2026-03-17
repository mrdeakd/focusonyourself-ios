import SwiftUI

struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .foySectionLabelStyle()
            .foregroundStyle(Color.foyPlaceholder)
    }
}
