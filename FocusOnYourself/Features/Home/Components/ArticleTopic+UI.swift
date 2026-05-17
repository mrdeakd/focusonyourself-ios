import SwiftUI

extension ArticleTopic {
    var color: Color {
        switch self {
        case .sleep:        return .foyNavy
        case .mentalHealth: return .foyOrange
        case .nutrition:    return .foyGreen
        case .movement:     return .foyOrangeAccent
        }
    }

    var tintColor: Color {
        switch self {
        case .sleep:        return .foyNavyTint
        case .mentalHealth: return .foyOrangeTint
        case .nutrition:    return .foyGreenTint
        case .movement:     return .foyOrangeTint
        }
    }
}
