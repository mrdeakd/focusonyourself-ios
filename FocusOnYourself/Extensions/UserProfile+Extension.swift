import FoundationModels

extension UserProfile {
    var isAppleIntelligenceActive: Bool {
        appleIntelligenceEnabled && SystemLanguageModel.default.isAvailable
    }
}
