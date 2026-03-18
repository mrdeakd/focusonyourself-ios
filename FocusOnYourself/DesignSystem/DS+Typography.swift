import SwiftUI

extension Font {
    private static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .light:    name = "Inter-Light"
        case .medium:   name = "Inter-Medium"
        case .semibold: name = "Inter-SemiBold"
        default:        name = "Inter-Regular"
        }
        return .custom(name, size: size)
    }

    static let foyDisplayTitle = Font.inter(32, weight: .light)
    static let foySectionTitle = Font.inter(28, weight: .light)
    static let foyNavTitle     = Font.inter(18, weight: .medium)
    static let foyBody         = Font.inter(15)
    static let foyButtonLabel  = Font.inter(16, weight: .medium)
    static let foyInputText    = Font.inter(16)
    static let foyHint         = Font.inter(12)
    static let foySkipLabel    = Font.inter(14)
    static let foySectionLabel = Font.inter(11, weight: .medium)

    static let foyCaption         = Font.inter(13)
    static let foyCaptionMedium   = Font.inter(13, weight: .medium)
    static let foyCaptionSemibold = Font.inter(13, weight: .semibold)
    static let foyBodyMedium      = Font.inter(15, weight: .medium)
    static let foyBodySemibold    = Font.inter(15, weight: .semibold)
    static let foyQuote           = Font.inter(18, weight: .light)
    static let foyMicro           = Font.inter(10)
    static let foyMicroMedium     = Font.inter(10, weight: .medium)
    static let foyHintMedium      = Font.inter(12, weight: .medium)
    static let foyStatValue       = Font.inter(24, weight: .medium)
    static let foyHeadline              = Font.inter(22, weight: .semibold)
    static let foySectionLabelSemibold  = Font.inter(11, weight: .semibold)

    static func foyMeditationTimer(size: CGFloat) -> Font {
        .system(size: size, weight: .thin, design: .rounded)
    }
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

    /// Inter 11px medium, kerning 0.8 (section label style)
    func foySectionLabelStyle() -> some View {
        self.font(.foySectionLabel).kerning(0.8)
    }
}
