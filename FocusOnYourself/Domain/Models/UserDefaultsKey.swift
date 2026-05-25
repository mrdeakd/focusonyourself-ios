import Foundation

enum UserDefaultsKey: String {
    case userProfile          = "userProfile"
    case affirmationCache     = "affirmation.quote"
    case affirmationCacheDate = "affirmation.date"
    case isPro                = "com.focusonyourself.isPro"
    case showSleepFactor      = "factor.show.sleep"
    case showStressFactor     = "factor.show.stress"
    case showExerciseFactor   = "factor.show.exercise"
    case showSocialFactor     = "factor.show.social"
    case pendingWidgetCheckIn = "pendingWidgetCheckIn"
    case serverStreakStats    = "server-streak-stats"
}
