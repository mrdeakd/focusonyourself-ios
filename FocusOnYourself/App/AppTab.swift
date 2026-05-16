import Foundation

enum AppTab: CaseIterable {
    case checkin, meditate, historyInsights, settings

    var label: String {
        switch self {
        case .checkin:         return "CHECK-IN"
        case .meditate:        return "MEDITATE"
        case .historyInsights: return "PROGRESS"
        case .settings:        return "SETTINGS"
        }
    }

    var icon: String {
        switch self {
        case .checkin:         return "heart.fill"
        case .meditate:        return "figure.mind.and.body"
        case .historyInsights: return "chart.bar.fill"
        case .settings:        return "gearshape"
        }
    }
}
