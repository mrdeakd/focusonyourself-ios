import SwiftUI
import UIKit

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        // swiftlint:disable:next identifier_name
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }

    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

extension Color {
    static let foyBackground          = Color(light: Color(hex: "FAF8F5"), dark: Color(hex: "000000"))
    static let foyCard                = Color(light: Color(hex: "FFFFFF"), dark: Color(hex: "1C1C1E"))
    static let foyForeground          = Color(light: Color(hex: "1C1C1C"), dark: Color(hex: "F2F2F7"))
    static let foyForegroundSecondary = Color(light: Color(hex: "6B6B6B"), dark: Color(hex: "8E8E93"))
    static let foyPlaceholder         = Color(light: Color(hex: "9A9A9A"), dark: Color(hex: "636366"))
    static let foyBorder              = Color(light: Color(hex: "E8E5E0"), dark: Color(hex: "3A3A3C"))
    static let foyButtonDisabled      = Color(light: Color(hex: "D4D0C8"), dark: Color(hex: "48484A"))
    static let foyNavy                = Color(light: Color(hex: "1E3A5F"), dark: Color(hex: "5B8FCC"))
    static let foyNavyTint            = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(Color(hex: "3A6494")).withAlphaComponent(0.20)
            : UIColor(Color(hex: "1E3A5F")).withAlphaComponent(0.08)
    })
    static let foyOrange              = Color(hex: "FF6B2B")
    static let foyOrangeTint          = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(Color(hex: "FF6B2B")).withAlphaComponent(0.20)
            : UIColor(Color(hex: "FF6B2B")).withAlphaComponent(0.12)
    })
    static let foyOrangeAccent        = Color(hex: "F4845F")
    static let foyMoodBackground      = Color(light: Color(hex: "F5F3F0"), dark: Color(hex: "2C2C2E"))
    static let foyCalendarSkipped     = Color(light: Color(hex: "F5F3F0"), dark: Color(hex: "2C2C2E"))

    // Day Detail Sheet
    static let foyDetailPencil        = Color(light: Color(hex: "B8A88A"), dark: Color(hex: "8E8E93"))
    static let foyDetailDotFill       = Color(light: Color(hex: "E5E4E1"), dark: Color(hex: "3A3A3C"))
    static let foyDetailDotStroke     = Color(light: Color(hex: "C8C7C4"), dark: Color(hex: "48484A"))

    // Nutrition
    static let foyGreen     = Color(light: Color(hex: "2E7D5A"), dark: Color(hex: "4CAF82"))
    static let foyGreenTint = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(Color(hex: "4CAF82")).withAlphaComponent(0.20)
            : UIColor(Color(hex: "2E7D5A")).withAlphaComponent(0.10)
    })

    // Always-opaque white / overlay
    static let foyOnPrimary = Color.white
    static let foyScrim     = Color.black.opacity(0.4)

    // Upgrade / Pro
    static let foyUpgradeCardBg       = Color(light: Color(hex: "F5F8FF"), dark: Color(hex: "1C2C3E"))
    static let foyUpgradeCardBorder   = Color(light: Color(hex: "DDEAFF"), dark: Color(hex: "2C4A6E"))
    static let foyUpgradeIconBg       = Color(light: Color(hex: "FFF0EA"), dark: Color(hex: "2C1810"))
    static let foyFreeBadgeBg         = Color(light: Color(hex: "EEF3FF"), dark: Color(hex: "1C2A40"))
}
