import SwiftUI

extension Font {
    static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Inter", size: size).weight(weight)
    }

    static let foyDisplayTitle = Font.inter(32, weight: .light)
    static let foySectionTitle = Font.inter(28, weight: .light)
    static let foyBody         = Font.inter(15)
    static let foyButtonLabel  = Font.inter(16, weight: .medium)
    static let foyInputText    = Font.inter(16)
    static let foyHint         = Font.inter(12)
    static let foySkipLabel    = Font.inter(14)
}

extension View {
    /// Inter 32px light, kerning −0.5, lineSpacing 1.6pt (lineHeight 1.05)
    func foyDisplayTitleStyle() -> some View {
        self.font(.foyDisplayTitle).kerning(-0.5).lineSpacing(1.6)
    }

    /// Inter 28px light, kerning −0.5, lineSpacing 1.4pt (lineHeight 1.05)
    func foySectionTitleStyle() -> some View {
        self.font(.foySectionTitle).kerning(-0.5).lineSpacing(1.4)
    }

    /// Inter 15px, lineSpacing 9pt (lineHeight 1.6)
    func foyBodyStyle() -> some View {
        self.font(.foyBody).lineSpacing(9)
    }
}
