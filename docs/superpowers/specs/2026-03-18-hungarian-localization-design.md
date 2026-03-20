# Hungarian UI Localization — Design Spec

**Date:** 2026-03-18
**Status:** Draft

---

## Overview

Add Hungarian ("hu") as a second UI language to FocusOnYourself, alongside English ("en"). The app currently has ~60+ hardcoded English strings in SwiftUI views, enum display names in model files, and widget strings. `LOCALIZATION_PREFERS_STRING_CATALOGS = YES` is already set in the project, so the Xcode String Catalog infrastructure is already enabled.

Users select their language in the Settings tab. The selection is stored in `UserProfile` and persists across launches by overriding the iOS `AppleLanguages` key before any view renders. A restart is required to apply the change; the user is informed before this happens.

JSON content files (affirmations, articles, meditations) are **out of scope**.

---

## Files Changed

| File | Change |
|------|--------|
| `FocusOnYourself/Resources/Localizable.xcstrings` | **New** — main app String Catalog |
| `FocusOnYourselfWidgets/Localizable.xcstrings` | **New** — widget String Catalog |
| `FocusOnYourself/Models/UserProfile.swift` | Add `preferredLanguage: String?` |
| `FocusOnYourself/Models/Mood.swift` | `displayName` → `String(localized:)` |
| `FocusOnYourself/Models/Category.swift` | `displayName` → `String(localized:)` |
| `FocusOnYourself/Models/Article.swift` | `displayName` on `ArticleTopic` → `String(localized:)` |
| `FocusOnYourself/Models/MeditationSession.swift` | `displayName` on `MeditationCategory` → `String(localized:)` |
| `FocusOnYourself/FocusOnYourselfApp.swift` | Bootstrap language override on launch |
| `FocusOnYourself/Features/Settings/SettingsViewModel.swift` | Add `currentLanguage`, `changeLanguage(_:)` |
| `FocusOnYourself/Features/Settings/SettingsScreen.swift` | Add language section and confirmation alert |

---

## 1. String Catalogs

### 1.1 Main app — `Localizable.xcstrings`

Add the file to the `FocusOnYourself` target at `FocusOnYourself/Resources/Localizable.xcstrings`. Include English and Hungarian translations for every hardcoded UI string. The String Catalog format supports both languages in a single JSON-backed file managed by Xcode.

SwiftUI `Text("Some string")` literals are already typed as `LocalizedStringKey` and resolve against the catalog automatically — no call-site changes required for view strings.

### 1.2 Widget target — `FocusOnYourselfWidgets/Localizable.xcstrings`

A separate catalog is needed because the widget extension is a distinct bundle. Include translations for the four widget strings: `"today's mood"`, `"logged today ✓"`, `"not logged yet"`, `"day streak"`, `"keep it up! 💪"`, plus `.configurationDisplayName` and `.description` values for both widgets.

Widget strings are plain `String` (not `LocalizedStringKey`), so they require explicit `NSLocalizedString(...)` or `String(localized:)` calls at the use site within the widget view files.

### 1.3 Enum display names

The following computed `displayName` properties currently return plain `String` literals. Each must be converted to use `String(localized: "key")` so that lookups flow through the catalog.

| Type | Property | Keys to add |
|------|----------|-------------|
| `Mood` | `displayName` | `mood.rough`, `mood.low`, `mood.okay`, `mood.good`, `mood.great` |
| `AffirmationCategory` | `displayName` | `category.confidence`, `category.health`, `category.relationships`, `category.mindfulness`, `category.career`, `category.resilience` |
| `ArticleTopic` | `displayName` | `topic.sleep`, `topic.mentalHealth`, `topic.nutrition`, `topic.movement` |
| `MeditationCategory` | `displayName` | `meditation.morning`, `meditation.focus`, `meditation.anxiety`, `meditation.sleep` |

Example conversion:

```swift
// Before
var displayName: String { "Rough" }

// After
var displayName: String { String(localized: "mood.rough") }
```

`WidgetMood.displayName` in `WidgetDataProvider.swift` is a separate copy and must be updated independently. In the widget extension, `Bundle.main` refers to the widget bundle itself (not the main app bundle), so `String(localized: "mood.rough", bundle: .main)` will correctly resolve from `FocusOnYourselfWidgets/Localizable.xcstrings`.

---

## 2. Language Preference Storage

### 2.1 Model change — `UserProfile`

```swift
// UserProfile.swift
var preferredLanguage: String?   // nil = follow system; "en" or "hu"
```

Adding an optional field with a `nil` default is backward-compatible: existing JSON without the key decodes cleanly because `Codable` synthesises `nil` for missing optional keys.

### 2.2 Language bootstrap — `FocusOnYourselfApp.swift`

The `AppleLanguages` override must be applied **before** any view renders. Do this in `init()` of `FocusOnYourselfApp`:

```swift
@main
struct FocusOnYourselfApp: App {
    init() {
        applyStoredLanguageIfNeeded()
    }
    // ...

    private func applyStoredLanguageIfNeeded() {
        guard
            let data = UserDefaults(suiteName: AppGroup.suiteName)?.data(forKey: "userProfile")
                ?? UserDefaults.standard.data(forKey: "userProfile"),
            let profile = try? JSONDecoder().decode(UserProfile.self, from: data),
            let code = profile.preferredLanguage
        else { return }
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
    }
}
```

This reads the raw App Group UserDefaults JSON directly (bypassing `ProfileService`, which is not yet initialised) and applies the override before the first `WindowGroup` renders. No iCloud KVS call is needed here because the App Group copy is always written synchronously on save.

### 2.3 On language change

When the user picks a language in Settings:

1. Update `UserProfile.preferredLanguage` via `profileService.updateProfile(_:)` — this persists to both iCloud KVS and App Group UserDefaults.
2. Write `UserDefaults.standard.set([code], forKey: "AppleLanguages")`.
3. Call `exit(0)` to terminate the app. iOS restarts it; on relaunch the bootstrap (§2.2) applies the stored language before any view renders.

The `exit(0)` approach is the only reliable way to force a language change mid-session on iOS without rebuilding the entire view hierarchy. The App Store allows this pattern when triggered by an explicit user action.

---

## 3. Settings UI

### 3.1 SettingsViewModel additions

```swift
// Computed read
var currentLanguage: String {
    profileService.profile.preferredLanguage ?? Locale.current.language.languageCode?.identifier ?? "en"
}

// Write + restart
func changeLanguage(_ code: String) {
    var profile = profileService.profile
    profile.preferredLanguage = code
    profileService.updateProfile(profile)
    UserDefaults.standard.set([code], forKey: "AppleLanguages")
    exit(0)
}
```

`currentLanguage` falls back to the system locale's language code when `preferredLanguage` is nil, so the correct button appears selected for users who have never changed the setting.

### 3.2 SettingsScreen — language section

Insert `languageSection` in the `VStack` inside `SettingsScreen.body` between `appearanceSection` and the Apple Intelligence section. Confirm before calling `changeLanguage`:

```swift
@State private var showLanguageRestartAlert = false
@State private var pendingLanguageCode: String = ""
```

**Section view — same pill-button style as `appearanceSection`:**

`SectionLabel` takes a plain `String` (not `LocalizedStringKey`), so section label text must be wrapped explicitly:

```swift
private var languageSection: some View {
    VStack(alignment: .leading, spacing: Spacing.xs) {
        SectionLabel(String(localized: "settings.language"))
        HStack(spacing: Spacing.xs) {
            ForEach([("en", "English"), ("hu", "Magyar")], id: \.0) { code, label in
                let isSelected = viewModel.currentLanguage == code
                Button {
                    guard code != viewModel.currentLanguage else { return }
                    pendingLanguageCode = code
                    showLanguageRestartAlert = true
                } label: {
                    Text(label)
                        .font(.foyCaptionMedium)
                        .foregroundStyle(isSelected ? Color.foyOnPrimary : Color.foyPlaceholder)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(isSelected ? Color.foyNavy : Color.foyMoodBackground)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}
```

**Alert (attached to the root `ZStack` alongside other modifiers):**

```swift
.alert(String(localized: "settings.language.restartAlertTitle"), isPresented: $showLanguageRestartAlert) {
    Button(String(localized: "settings.language.ok")) { viewModel.changeLanguage(pendingLanguageCode) }
    Button(String(localized: "settings.language.cancel"), role: .cancel) { }
} message: {
    Text("settings.language.restartAlertMessage")
}
```

### 3.3 Section ordering in SettingsScreen

```
subscriptionSection   (if !isPro)
nameSection
categoriesSection
notificationsSection
appearanceSection
languageSection        ← insert here
appleIntelligenceSection (if available && isPro)
```

---

## 4. Widget Localization

Widgets run in a separate process and do not share the `AppleLanguages` override applied by the main app. iOS passes the device language to the widget extension based on the system locale. Because widgets cannot perform a restart-based override, they will always follow the **system language**.

This is acceptable for the initial implementation. Document it as a known limitation: if the user has set a different in-app language than the system language, widgets display in the system language.

The `WidgetMood.displayName` property in `WidgetDataProvider.swift` must still be converted to `String(localized:)` (with `bundle: .main` — which in the widget context refers to the widget bundle) so strings resolve correctly from `FocusOnYourselfWidgets/Localizable.xcstrings`.

Widget `.configurationDisplayName` and `.description` modifiers accept `LocalizedStringKey` — pass string literals so they auto-resolve from the widget catalog.

---

## 5. Hungarian Translations — Reference

The following tables record the canonical catalog key, English display value, and Hungarian translation for every string that must appear in the catalogs. This is the source of truth for translators.

Section §5.6 covers `SettingsScreen` in detail. The remaining screens (Home, Check-in, History, Insights, Meditate, Onboarding) also contain hardcoded strings that must be catalogued. Those strings are auto-resolved by SwiftUI because they are passed as `Text("literal")` — `LocalizedStringKey` — so no call-site changes are required for view body strings. The implementer must audit every `Text(...)` literal in the codebase and add matching entries to `Localizable.xcstrings`. Strings passed as plain `String` (e.g. `SectionLabel`, `navigationTitle` from a ViewModel, or interpolated strings) require explicit `String(localized:)` conversion.

### 5.1 Mood display names

| Key | English | Hungarian |
|-----|---------|-----------|
| `mood.rough` | Rough | Rossz |
| `mood.low` | Low | Levert |
| `mood.okay` | Okay | Oké |
| `mood.good` | Good | Jó |
| `mood.great` | Great | Nagyszerű |

### 5.2 Affirmation categories

| Key | English | Hungarian |
|-----|---------|-----------|
| `category.confidence` | Confidence & Self-Worth | Magabiztosság |
| `category.health` | Health & Body | Egészség & Test |
| `category.relationships` | Relationships & Love | Kapcsolatok & Szeretet |
| `category.mindfulness` | Mindfulness & Calm | Tudatosság & Nyugalom |
| `category.career` | Career & Success | Karrier & Siker |
| `category.resilience` | Resilience & Strength | Kitartás & Erő |

### 5.3 Article topics

| Key | English | Hungarian |
|-----|---------|-----------|
| `topic.sleep` | Sleep & Recovery | Alvás & Regeneráció |
| `topic.mentalHealth` | Mental Health | Mentális egészség |
| `topic.nutrition` | Nutrition & Gut Health | Táplálkozás & Bélflóra |
| `topic.movement` | Movement & Exercise | Mozgás & Edzés |

### 5.4 Meditation categories

| Key | English | Hungarian |
|-----|---------|-----------|
| `meditation.morning` | Morning & Energy | Reggel & Energia |
| `meditation.focus` | Focus & Productivity | Fókusz & Termelékenység |
| `meditation.anxiety` | Anxiety & Stress | Szorongás & Stressz |
| `meditation.sleep` | Sleep & Rest | Alvás & Pihenés |

### 5.5 Widget strings

| Key | English | Hungarian |
|-----|---------|-----------|
| `widget.mood.label` | today's mood | mai hangulat |
| `widget.mood.logged` | logged today ✓ | ma rögzítve ✓ |
| `widget.mood.notLogged` | not logged yet | még nincs rögzítve |
| `widget.streak.label` | day streak | napos sorozat |
| `widget.streak.motivation` | keep it up! 💪 | csak így tovább! 💪 |
| `widget.mood.displayName` | Mood | Hangulat |
| `widget.mood.description` | See today's logged mood at a glance. | Nézd meg a mai hangulatod egy pillantással. |
| `widget.streak.displayName` | Streak | Sorozat |
| `widget.streak.description` | See your current check-in streak at a glance. | Nézd meg az aktuális bejelentkezési sorozatod. |

### 5.6 Settings screen strings

| Key | English | Hungarian |
|-----|---------|-----------|
| `settings.title` | Settings | Beállítások |
| `settings.subscription` | SUBSCRIPTION | ELŐFIZETÉS |
| `settings.upgradeToPro` | Upgrade to Pro | Váltás Próra |
| `settings.unlockFeatures` | Unlock all categories & features | Összes kategória és funkció feloldása |
| `settings.yourName` | YOUR NAME | NEVED |
| `settings.yourNamePlaceholder` | Your name | Neved |
| `settings.changeName` | Change name | Név módosítása |
| `settings.affirmationCategories` | AFFIRMATION CATEGORIES | MEGERŐSÍTÉSI KATEGÓRIÁK |
| `settings.changeCategories` | Change categories | Kategóriák módosítása |
| `settings.notifications` | NOTIFICATIONS | ÉRTESÍTÉSEK |
| `settings.dailyReminder` | Daily 9am Reminder | Napi emlékeztető (9:00) |
| `settings.appearance` | APPEARANCE | MEGJELENÉS |
| `settings.appearance.system` | System | Rendszer |
| `settings.appearance.light` | Light | Világos |
| `settings.appearance.dark` | Dark | Sötét |
| `settings.language` | LANGUAGE | NYELV |
| `settings.appleIntelligence` | APPLE INTELLIGENCE | APPLE INTELLIGENCE |
| `settings.appleIntelligenceToggle` | Apple Intelligence | Apple Intelligence |
| `settings.appleIntelligenceHint` | After check-in, generate a personalized affirmation using on-device AI. Requires iPhone 15 Pro or newer. | Bejelentkezés után személyre szabott megerősítést generál az eszközön futó AI-jal. iPhone 15 Pro vagy újabb szükséges. |
| `settings.language.restartAlertTitle` | Language Change | Nyelv módosítása |
| `settings.language.restartAlertMessage` | The app will restart to apply the language change. | Az alkalmazás újraindul a nyelvváltás alkalmazásához. |
| `settings.language.ok` | OK | OK |
| `settings.language.cancel` | Cancel | Mégse |

> **Note:** The Appearance section's `"System"`, `"Light"`, `"Dark"` buttons are currently iterated from a raw `[String]` literal in `SettingsScreen`. These must be refactored to use localized keys rather than using the raw string both as identifier and label.

---

## 6. Implementation Notes

### SectionLabel takes a plain String — not LocalizedStringKey

`SectionLabel` is defined as `init(_ text: String)` and passes the text directly to `Text(text)` (not `Text(LocalizedStringKey(text))`). This means existing `SectionLabel("APPEARANCE")` calls do **not** automatically look up translations. Every `SectionLabel` call in `SettingsScreen` must be updated to pass `String(localized: "the.key")`:

```swift
SectionLabel(String(localized: "settings.appearance"))
SectionLabel(String(localized: "settings.notifications"))
// etc.
```

The translation table in §5.6 uses keys like `settings.appearance` whose English value is `"APPEARANCE"` — this is intentional. Alternatively, `SectionLabel` itself can be changed to accept `LocalizedStringKey`, but that would affect every call site across the entire app, not just Settings.

### Appearance button refactor

The current appearance section iterates `["System", "Light", "Dark"]` and uses the same string as both the comparison value and the button label. After localization, the comparison value must remain the English identifier while the label is localized:

```swift
// Replace the existing ForEach with:
ForEach([("System", String(localized: "settings.appearance.system")),
         ("Light",  String(localized: "settings.appearance.light")),
         ("Dark",   String(localized: "settings.appearance.dark"))], id: \.0) { id, label in
    let isSelected = selectedAppearanceOption == id
    Button { viewModel.appearanceOverride = id == "System" ? nil : id.lowercased() } label: {
        Text(label) ...
    }
}
```

### Backward compatibility

`UserProfile.preferredLanguage` is `String?` with no default value in the struct literal — it will be `nil` for all existing users. The language picker will show the button corresponding to the system language as selected (via the `Locale` fallback in `currentLanguage`). No migration is needed.

### iCloud KVS and language sync

`preferredLanguage` is stored in `UserProfile` and therefore syncs via iCloud KVS. If a user changes language on one device, the next launch on another device will pick up the stored code in `applyStoredLanguageIfNeeded` and apply it. This is the desired behaviour.

### SwiftLint

No new SwiftLint issues are expected from these changes. The `String(localized:)` calls and `exit(0)` call do not trigger any configured rules. The `exit(0)` call should be left without suppression — it is not matched by any opt-in rule in this project's configuration.

---

## 7. Out of Scope

- JSON content files: affirmations, articles, meditation scripts
- Any language beyond English ("en") and Hungarian ("hu")
- Plural rules, number formatters, or date formatters (none currently used in localizable UI)
- RTL layout support
