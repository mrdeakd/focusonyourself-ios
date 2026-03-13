import SwiftUI

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

extension Color {
    static let foyBackground          = Color(hex: "FAF8F5")
    static let foyNavy                = Color(hex: "1E3A5F")
    static let foyNavyTint            = Color(hex: "1E3A5F").opacity(0.08)
    static let foyForeground          = Color(hex: "1C1C1C")
    static let foyForegroundSecondary = Color(hex: "6B6B6B")
    static let foyPlaceholder         = Color(hex: "9A9A9A")
    static let foyBorder              = Color(hex: "E8E5E0")
    static let foyButtonDisabled      = Color(hex: "D4D0C8")
    static let foyCard            = Color.white
    static let foyOrange          = Color(hex: "FF6B2B")
    static let foyOrangeTint      = Color(hex: "FF6B2B").opacity(0.12)
    static let foyMoodBackground  = Color(hex: "F5F3F0")
}
