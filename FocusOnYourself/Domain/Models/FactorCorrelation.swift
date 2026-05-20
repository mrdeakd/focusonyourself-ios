import Foundation

struct FactorCorrelation: Identifiable {
    let id: String
    let factor: String
    let pearsonR: Double
    var directionLabel: String { pearsonR >= 0 ? "↑ mood" : "↓ mood" }
}
