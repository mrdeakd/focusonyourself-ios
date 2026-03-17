import SwiftUI

struct IconBox: View {
    let systemName: String
    let tintColor: Color
    let iconColor: Color
    var size: CGFloat = 44
    var iconSize: CGFloat = 20

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(tintColor)
                .frame(width: size, height: size)
            Image(systemName: systemName)
                .font(.system(size: iconSize))
                .foregroundStyle(iconColor)
        }
    }
}
