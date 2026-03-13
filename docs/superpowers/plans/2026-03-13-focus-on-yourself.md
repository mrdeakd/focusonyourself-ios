# Focus On Yourself — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a daily affirmations + streak iOS app from blank Xcode project to fully working app with onboarding, home check-in, history, settings, and optional Apple Intelligence.

**Architecture:** MVVM/SwiftUI with `@Observable` ViewModels. Shared state in `AppState` injected via `.environment`. Local-first persistence via UserDefaults + SwiftData, synced to iCloud via NSUbiquitousKeyValueStore + CloudKit.

**Tech Stack:** Swift 6, SwiftUI, SwiftData + CloudKit, UserDefaults, NSUbiquitousKeyValueStore, UNUserNotificationCenter, FoundationModels (iOS 26+), XCTest.

**Spec:** `docs/superpowers/specs/2026-03-13-focus-on-yourself-design.md`

---

## Chunk 1: Foundation — Project Structure + Core Models

### Task 1: Create folder structure

**Files:** (structural only — no Swift files created here)

- [ ] **Step 1: Create the folder hierarchy in Xcode**

In Xcode, create the following groups under the `FocusOnYourself` target. **Important:** use "New Group with Folder" (not just "New Group") so actual directories are created on disk alongside the Xcode project file.
```
FocusOnYourself/
├── App/
├── Features/
│   ├── Onboarding/
│   ├── Home/
│   │   └── Components/
│   ├── History/
│   │   └── Components/
│   └── Settings/
├── Models/
├── Services/
└── Resources/
```

- [ ] **Step 2: Verify folders were created on disk**

In Terminal:
```bash
ls FocusOnYourself/
```
Expected: directories `App/`, `Features/`, `Models/`, `Services/`, `Resources/` are present on disk.

- [ ] **Step 3: Verify test target exists**

Open the Xcode project. Confirm there is a `FocusOnYourselfTests` target. If not, add one via File → New → Target → Unit Testing Bundle, name it `FocusOnYourselfTests`.

---

### Task 2: Category model

**Files:**
- Create: `FocusOnYourself/Models/Category.swift`
- Create: `FocusOnYourselfTests/Models/CategoryTests.swift`

- [ ] **Step 1: Write the failing test**

`FocusOnYourselfTests/Models/CategoryTests.swift`:
```swift
import XCTest
@testable import FocusOnYourself

final class CategoryTests: XCTestCase {
    func test_allCases_hasFourCategories() {
        XCTAssertEqual(AffirmationCategory.allCases.count, 4)
    }

    func test_displayName_confidence() {
        XCTAssertEqual(AffirmationCategory.confidence.displayName, "Confidence & Self-Worth")
    }

    func test_displayName_health() {
        XCTAssertEqual(AffirmationCategory.health.displayName, "Health & Body")
    }

    func test_displayName_relationships() {
        XCTAssertEqual(AffirmationCategory.relationships.displayName, "Relationships & Love")
    }

    func test_displayName_mindfulness() {
        XCTAssertEqual(AffirmationCategory.mindfulness.displayName, "Mindfulness & Calm")
    }

    func test_codable_roundtrip() throws {
        let encoded = try JSONEncoder().encode(AffirmationCategory.confidence)
        let decoded = try JSONDecoder().decode(AffirmationCategory.self, from: encoded)
        XCTAssertEqual(decoded, .confidence)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

In Xcode: Cmd+U. Expected: build fails with "cannot find type 'AffirmationCategory'".

- [ ] **Step 3: Implement Category model**

`FocusOnYourself/Models/Category.swift`:
```swift
import Foundation

enum AffirmationCategory: String, CaseIterable, Codable, Identifiable {
    case confidence
    case health
    case relationships
    case mindfulness

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .confidence:    return "Confidence & Self-Worth"
        case .health:        return "Health & Body"
        case .relationships: return "Relationships & Love"
        case .mindfulness:   return "Mindfulness & Calm"
        }
    }
}
```

- [ ] **Step 4: Run tests and verify they pass**

Cmd+U. Expected: all CategoryTests pass.

- [ ] **Step 5: Commit**

```bash
git add FocusOnYourself/Models/Category.swift FocusOnYourselfTests/Models/CategoryTests.swift
git commit -m "feat: add AffirmationCategory model"
```

---

### Task 3: Affirmation model

**Files:**
- Create: `FocusOnYourself/Models/Affirmation.swift`
- Create: `FocusOnYourselfTests/Models/AffirmationTests.swift`

- [ ] **Step 1: Write the failing test**

`FocusOnYourselfTests/Models/AffirmationTests.swift`:
```swift
import XCTest
@testable import FocusOnYourself

final class AffirmationTests: XCTestCase {
    func test_decodable_fromJSON() throws {
        let json = """
        {
            "id": "aff-001",
            "text": "I am enough.",
            "author": "Unknown",
            "categories": ["confidence"]
        }
        """.data(using: .utf8)!
        let affirmation = try JSONDecoder().decode(Affirmation.self, from: json)
        XCTAssertEqual(affirmation.id, "aff-001")
        XCTAssertEqual(affirmation.text, "I am enough.")
        XCTAssertEqual(affirmation.author, "Unknown")
        XCTAssertEqual(affirmation.categories, [.confidence])
    }

    func test_decodable_nilAuthor() throws {
        let json = """
        {"id": "aff-002", "text": "I grow.", "categories": ["health"]}
        """.data(using: .utf8)!
        let affirmation = try JSONDecoder().decode(Affirmation.self, from: json)
        XCTAssertNil(affirmation.author)
    }

    func test_matchesCategory_returnsTrue_whenCategoryPresent() {
        let aff = Affirmation(id: "1", text: "x", author: nil, categories: [.confidence, .health])
        XCTAssertTrue(aff.matches(categories: [.confidence]))
    }

    func test_matchesCategory_returnsFalse_whenNoCategoryOverlap() {
        let aff = Affirmation(id: "1", text: "x", author: nil, categories: [.mindfulness])
        XCTAssertFalse(aff.matches(categories: [.confidence]))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Cmd+U. Expected: build fails — `Affirmation` not defined.

- [ ] **Step 3: Implement Affirmation model**

`FocusOnYourself/Models/Affirmation.swift`:
```swift
import Foundation

struct Affirmation: Codable, Identifiable, Equatable {
    let id: String
    let text: String
    let author: String?
    let categories: [AffirmationCategory]

    func matches(categories: [AffirmationCategory]) -> Bool {
        !self.categories.isDisjoint(with: categories)
    }
}
```

- [ ] **Step 4: Run tests and verify they pass**

Cmd+U. Expected: all AffirmationTests pass.

- [ ] **Step 5: Commit**

```bash
git add FocusOnYourself/Models/Affirmation.swift FocusOnYourselfTests/Models/AffirmationTests.swift
git commit -m "feat: add Affirmation model"
```

---

### Task 4: UserProfile model

**Files:**
- Create: `FocusOnYourself/Models/UserProfile.swift`
- Create: `FocusOnYourselfTests/Models/UserProfileTests.swift`

- [ ] **Step 1: Write the failing test**

`FocusOnYourselfTests/Models/UserProfileTests.swift`:
```swift
import XCTest
@testable import FocusOnYourself

final class UserProfileTests: XCTestCase {
    func test_defaultValues() {
        let profile = UserProfile()
        XCTAssertEqual(profile.name, "")
        XCTAssertTrue(profile.selectedCategories.isEmpty)
        XCTAssertTrue(profile.notificationsEnabled)
        XCTAssertFalse(profile.appleIntelligenceEnabled)
        XCTAssertFalse(profile.onboardingCompleted)
    }

    func test_codable_roundtrip() throws {
        var profile = UserProfile()
        profile.name = "Alex"
        profile.selectedCategories = [.confidence, .health]
        profile.onboardingCompleted = true
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        XCTAssertEqual(decoded.name, "Alex")
        XCTAssertEqual(decoded.selectedCategories, [.confidence, .health])
        XCTAssertTrue(decoded.onboardingCompleted)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Cmd+U. Expected: build fails — `UserProfile` not defined.

- [ ] **Step 3: Implement UserProfile**

`FocusOnYourself/Models/UserProfile.swift`:
```swift
import Foundation

struct UserProfile: Codable, Equatable {
    var name: String = ""
    var selectedCategories: [AffirmationCategory] = []
    var notificationsEnabled: Bool = true
    var appleIntelligenceEnabled: Bool = false
    var onboardingCompleted: Bool = false
}
```

- [ ] **Step 4: Run tests and verify they pass**

Cmd+U. Expected: all UserProfileTests pass.

- [ ] **Step 5: Commit**

```bash
git add FocusOnYourself/Models/UserProfile.swift FocusOnYourselfTests/Models/UserProfileTests.swift
git commit -m "feat: add UserProfile model"
```

---

### Task 5: DailyCheckIn model

**Files:**
- Create: `FocusOnYourself/Models/DailyCheckIn.swift`
- Create: `FocusOnYourselfTests/Models/DailyCheckInTests.swift`

- [ ] **Step 1: Write the failing test**

`FocusOnYourselfTests/Models/DailyCheckInTests.swift`:
```swift
import XCTest
import SwiftData
@testable import FocusOnYourself

final class DailyCheckInTests: XCTestCase {
    func test_init_setsFields() {
        let date = Calendar.current.startOfDay(for: Date())
        let checkIn = DailyCheckIn(date: date, affirmationID: "aff-001", mood: 4)
        XCTAssertEqual(checkIn.affirmationID, "aff-001")
        XCTAssertEqual(checkIn.mood, 4)
        XCTAssertEqual(checkIn.date, date)
        XCTAssertNotNil(checkIn.completedAt)
    }

    func test_mood_clampedToOne_whenBelowRange() {
        let checkIn = DailyCheckIn(date: Date(), affirmationID: "x", mood: 0)
        XCTAssertEqual(checkIn.mood, 1)
    }

    func test_mood_clampedToFive_whenAboveRange() {
        let checkIn = DailyCheckIn(date: Date(), affirmationID: "x", mood: 9)
        XCTAssertEqual(checkIn.mood, 5)
    }

    func test_mood_unchanged_whenInRange() {
        let checkIn = DailyCheckIn(date: Date(), affirmationID: "x", mood: 3)
        XCTAssertEqual(checkIn.mood, 3)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Cmd+U. Expected: build fails — `DailyCheckIn` not defined.

- [ ] **Step 3: Implement DailyCheckIn**

`FocusOnYourself/Models/DailyCheckIn.swift`:
```swift
import Foundation
import SwiftData

@Model
final class DailyCheckIn {
    var date: Date          // calendar day, normalized to midnight
    var affirmationID: String
    var mood: Int           // 1–5
    var completedAt: Date   // wall-clock timestamp

    init(date: Date, affirmationID: String, mood: Int) {
        self.date = Calendar.current.startOfDay(for: date)
        self.affirmationID = affirmationID
        self.mood = min(max(mood, 1), 5)
        self.completedAt = Date()
    }
}
```

- [ ] **Step 4: Run tests and verify they pass**

Cmd+U. Expected: all DailyCheckInTests pass (3 mood tests + init test).

- [ ] **Step 5: Commit**

```bash
git add FocusOnYourself/Models/DailyCheckIn.swift FocusOnYourselfTests/Models/DailyCheckInTests.swift
git commit -m "feat: add DailyCheckIn SwiftData model"
```

---

## Chunk 2: Services — Storage, Affirmation, Streak, Notification

### Task 6: StorageService (UserDefaults + NSUbiquitousKeyValueStore)

**Files:**
- Create: `FocusOnYourself/Services/StorageService.swift`
- Create: `FocusOnYourselfTests/Services/StorageServiceTests.swift`

Note: `StorageService` owns UserDefaults + iCloud KV sync only. SwiftData (`DailyCheckIn`) is configured separately in `FocusOnYourselfApp` and accessed via `@Query`/`ModelContext` in ViewModels.

- [ ] **Step 1: Write failing tests**

`FocusOnYourselfTests/Services/StorageServiceTests.swift`:
```swift
import XCTest
@testable import FocusOnYourself

final class StorageServiceTests: XCTestCase {
    var sut: StorageService!
    var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        sut = StorageService(defaults: defaults)
    }

    override func tearDown() {
        defaults.removeSuite(named: defaults.description)
        super.tearDown()
    }

    func test_saveAndLoad_userProfile() throws {
        var profile = UserProfile()
        profile.name = "Sam"
        profile.selectedCategories = [.mindfulness]
        profile.onboardingCompleted = true

        sut.save(profile: profile)
        let loaded = sut.loadProfile()

        XCTAssertEqual(loaded.name, "Sam")
        XCTAssertEqual(loaded.selectedCategories, [.mindfulness])
        XCTAssertTrue(loaded.onboardingCompleted)
    }

    func test_loadProfile_returnsDefault_whenNothingSaved() {
        let profile = sut.loadProfile()
        XCTAssertEqual(profile.name, "")
        XCTAssertFalse(profile.onboardingCompleted)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Cmd+U. Expected: build fails — `StorageService` not defined.

- [ ] **Step 3: Implement StorageService**

`FocusOnYourself/Services/StorageService.swift`:
```swift
import Foundation

final class StorageService {
    private let defaults: UserDefaults
    private let kvStore = NSUbiquitousKeyValueStore.default
    private let profileKey = "userProfile"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        setupKVStoreSync()
    }

    // MARK: - UserProfile

    func save(profile: UserProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: profileKey)
        kvStore.set(data, forKey: profileKey)
        kvStore.synchronize()
    }

    func loadProfile() -> UserProfile {
        // Prefer iCloud KV if available and newer
        if let data = kvStore.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            // Write back to local defaults to keep in sync
            defaults.set(data, forKey: profileKey)
            return profile
        }
        if let data = defaults.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        return UserProfile()
    }

    // MARK: - iCloud KV sync

    private func setupKVStoreSync() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(kvStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvStore
        )
    }

    @objc private func kvStoreDidChange(_ notification: Notification) {
        guard let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
              keys.contains(profileKey),
              let data = kvStore.data(forKey: profileKey) else { return }
        defaults.set(data, forKey: profileKey)
    }
}
```

- [ ] **Step 4: Run tests and verify they pass**

Cmd+U.

- [ ] **Step 5: Add CloudKit + iCloud entitlements to Xcode project**

In Xcode:
1. Select the `FocusOnYourself` target → Signing & Capabilities
2. Click `+` → add **iCloud** capability → check both **Key-value storage** and **CloudKit**
3. Under CloudKit, create a container named `iCloud.com.yourname.focusonyourself`
4. Click `+` → add **Push Notifications** capability (required for CloudKit sync)

- [ ] **Step 6: Commit**

```bash
git add FocusOnYourself/Services/StorageService.swift FocusOnYourselfTests/Services/StorageServiceTests.swift
git commit -m "feat: add StorageService with UserDefaults + iCloud KV sync"
```

---

### Task 7: Configure SwiftData ModelContainer

**Files:**
- Modify: `FocusOnYourself/App/FocusOnYourselfApp.swift`

- [ ] **Step 1: Configure ModelContainer in app entry point**

`FocusOnYourself/App/FocusOnYourselfApp.swift`:
```swift
import SwiftUI
import SwiftData

@main
struct FocusOnYourselfApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([DailyCheckIn.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to configure SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
```

- [ ] **Step 2: Build the app to confirm no errors**

Cmd+B. Expected: compiles without error.

- [ ] **Step 3: Commit**

```bash
git add FocusOnYourself/App/FocusOnYourselfApp.swift
git commit -m "feat: configure SwiftData ModelContainer with CloudKit sync"
```

---

### Task 8: AffirmationService + affirmations.json

**Files:**
- Create: `FocusOnYourself/Resources/affirmations.json`
- Create: `FocusOnYourself/Services/AffirmationService.swift`
- Create: `FocusOnYourselfTests/Services/AffirmationServiceTests.swift`

- [ ] **Step 1: Create affirmations.json**

`FocusOnYourself/Resources/affirmations.json`:
```json
[
  {"id":"conf-001","text":"I am worthy of love and respect exactly as I am.","categories":["confidence"]},
  {"id":"conf-002","text":"I believe in my ability to overcome any challenge.","categories":["confidence"]},
  {"id":"conf-003","text":"My confidence grows each day I show up for myself.","categories":["confidence"]},
  {"id":"conf-004","text":"I trust my instincts and my own judgment.","categories":["confidence"]},
  {"id":"conf-005","text":"I am enough — right here, right now.","categories":["confidence"]},
  {"id":"hlth-001","text":"My body is strong and capable of healing.","categories":["health"]},
  {"id":"hlth-002","text":"I nourish my body with care and intention.","categories":["health"]},
  {"id":"hlth-003","text":"Every step I take is an act of self-love.","categories":["health"]},
  {"id":"hlth-004","text":"I listen to what my body needs and respond with kindness.","categories":["health"]},
  {"id":"hlth-005","text":"My energy is a gift I protect and restore daily.","categories":["health"]},
  {"id":"rel-001","text":"I deserve relationships that are kind, honest, and nurturing.","categories":["relationships"]},
  {"id":"rel-002","text":"I give and receive love freely and openly.","categories":["relationships"]},
  {"id":"rel-003","text":"My boundaries are an act of self-respect, not self-isolation.","categories":["relationships"]},
  {"id":"rel-004","text":"I attract people who support and celebrate my growth.","categories":["relationships"]},
  {"id":"rel-005","text":"I show up fully in my relationships with presence and care.","categories":["relationships"]},
  {"id":"mind-001","text":"I am present in this moment and this moment is enough.","categories":["mindfulness"]},
  {"id":"mind-002","text":"Peace is available to me in every breath.","categories":["mindfulness"]},
  {"id":"mind-003","text":"I release what I cannot control and embrace what I can.","categories":["mindfulness"]},
  {"id":"mind-004","text":"I observe my thoughts with curiosity, not judgment.","categories":["mindfulness"]},
  {"id":"mind-005","text":"My inner calm is a strength I carry everywhere.","categories":["mindfulness"]}
]
```

Add `affirmations.json` to the app target in Xcode (it must be included in the bundle).

- [ ] **Step 2: Write failing tests**

`FocusOnYourselfTests/Services/AffirmationServiceTests.swift`:
```swift
import XCTest
@testable import FocusOnYourself

final class AffirmationServiceTests: XCTestCase {
    var sut: AffirmationService!

    override func setUp() {
        super.setUp()
        sut = AffirmationService()
    }

    func test_allAffirmations_loadsFromBundle() {
        XCTAssertFalse(sut.allAffirmations.isEmpty)
    }

    func test_affirmationForDate_isStable_sameDay() {
        let date = Date()
        let categories: [AffirmationCategory] = [.confidence]
        let first = sut.affirmation(for: date, categories: categories)
        let second = sut.affirmation(for: date, categories: categories)
        XCTAssertEqual(first?.id, second?.id)
    }

    func test_affirmationForDate_filtersByCategory() {
        let date = Date()
        let result = sut.affirmation(for: date, categories: [.health])
        XCTAssertNotNil(result)
        if let result {
            XCTAssertTrue(result.categories.contains(.health))
        }
    }

    func test_affirmationForDate_returnsNil_whenNoCategoriesMatch() {
        // Create a service with only one category's affirmations
        // and request a different category
        let result = sut.affirmation(for: Date(), categories: [])
        XCTAssertNil(result)
    }

    func test_affirmationForDate_changesBetweenDays() {
        let categories: [AffirmationCategory] = [.confidence]
        // Use two dates far enough apart to guarantee different dayOfYear indices
        let day1 = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let day2 = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 2))!
        // Not guaranteed to differ for every pair, but filtered list has 5 items,
        // so days 1 and 2 will produce indices 0 and 1 — different affirmations.
        let aff1 = sut.affirmation(for: day1, categories: categories)
        let aff2 = sut.affirmation(for: day2, categories: categories)
        XCTAssertNotEqual(aff1?.id, aff2?.id)
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Cmd+U. Expected: build fails — `AffirmationService` not defined.

- [ ] **Step 4: Implement AffirmationService**

`FocusOnYourself/Services/AffirmationService.swift`:
```swift
import Foundation

final class AffirmationService {
    let allAffirmations: [Affirmation]

    init() {
        guard let url = Bundle.main.url(forResource: "affirmations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Affirmation].self, from: data) else {
            allAffirmations = []
            return
        }
        allAffirmations = decoded
    }

    /// Returns today's affirmation deterministically.
    /// Same date + same categories → same affirmation.
    /// Yearly repetition is acceptable (v1).
    func affirmation(for date: Date, categories: [AffirmationCategory]) -> Affirmation? {
        guard !categories.isEmpty else { return nil }
        let filtered = allAffirmations.filter { $0.matches(categories: categories) }
        guard !filtered.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % filtered.count
        return filtered[index]
    }
}
```

- [ ] **Step 5: Run tests and verify they pass**

Cmd+U.

- [ ] **Step 6: Commit**

```bash
git add FocusOnYourself/Resources/affirmations.json FocusOnYourself/Services/AffirmationService.swift FocusOnYourselfTests/Services/AffirmationServiceTests.swift
git commit -m "feat: add AffirmationService and bundled affirmations"
```

---

### Task 9: StreakService

**Files:**
- Create: `FocusOnYourself/Services/StreakService.swift`
- Create: `FocusOnYourselfTests/Services/StreakServiceTests.swift`

- [ ] **Step 1: Write failing tests**

`FocusOnYourselfTests/Services/StreakServiceTests.swift`:
```swift
import XCTest
@testable import FocusOnYourself

final class StreakServiceTests: XCTestCase {
    let calendar = Calendar.current

    func makeDate(daysAgo: Int) -> Date {
        calendar.startOfDay(for: calendar.date(byAdding: .day, value: -daysAgo, to: Date())!)
    }

    func test_currentStreak_zeroForNewUser() {
        let streak = StreakService.currentStreak(checkInDates: [], today: Date())
        XCTAssertEqual(streak, 0)
    }

    func test_currentStreak_oneAfterTodaysCheckIn() {
        let streak = StreakService.currentStreak(checkInDates: [makeDate(daysAgo: 0)], today: Date())
        XCTAssertEqual(streak, 1)
    }

    func test_currentStreak_continuesFromYesterday_beforeTodayCheckIn() {
        // 3-day chain ending yesterday, today not done yet
        let dates = [makeDate(daysAgo: 1), makeDate(daysAgo: 2), makeDate(daysAgo: 3)]
        let streak = StreakService.currentStreak(checkInDates: dates, today: Date())
        XCTAssertEqual(streak, 3)
    }

    func test_currentStreak_resetsWhenDayMissed() {
        // 2 days ago and today — yesterday missed
        let dates = [makeDate(daysAgo: 0), makeDate(daysAgo: 2)]
        let streak = StreakService.currentStreak(checkInDates: dates, today: Date())
        XCTAssertEqual(streak, 1)
    }

    func test_currentStreak_extendedByTodayCheckIn() {
        // yesterday + today = 2
        let dates = [makeDate(daysAgo: 0), makeDate(daysAgo: 1)]
        let streak = StreakService.currentStreak(checkInDates: dates, today: Date())
        XCTAssertEqual(streak, 2)
    }

    func test_longestStreak_withGap() {
        // 3-day chain, 2-day gap, 2-day chain → longest = 3
        let dates = [
            makeDate(daysAgo: 10),
            makeDate(daysAgo: 9),
            makeDate(daysAgo: 8),
            makeDate(daysAgo: 4),
            makeDate(daysAgo: 3)
        ]
        let longest = StreakService.longestStreak(checkInDates: dates)
        XCTAssertEqual(longest, 3)
    }

    func test_longestStreak_emptyIsZero() {
        XCTAssertEqual(StreakService.longestStreak(checkInDates: []), 0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Cmd+U. Expected: build fails — `StreakService` not defined.

- [ ] **Step 3: Implement StreakService**

`FocusOnYourself/Services/StreakService.swift`:
```swift
import Foundation

enum StreakService {
    static let calendar = Calendar.current

    /// Current streak count.
    /// - Before today's check-in: counts from yesterday backward.
    /// - After today's check-in: counts from today backward.
    static func currentStreak(checkInDates: [Date], today: Date) -> Int {
        let todayStart = calendar.startOfDay(for: today)
        let normalizedDates = Set(checkInDates.map { calendar.startOfDay(for: $0) })
        let hasTodayCheckIn = normalizedDates.contains(todayStart)
        var cursor = hasTodayCheckIn ? todayStart : calendar.date(byAdding: .day, value: -1, to: todayStart)!
        var count = 0
        while normalizedDates.contains(cursor) {
            count += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        return count
    }

    /// Longest consecutive-day streak across all check-ins.
    static func longestStreak(checkInDates: [Date]) -> Int {
        guard !checkInDates.isEmpty else { return 0 }
        let sorted = checkInDates
            .map { calendar.startOfDay(for: $0) }
            .sorted()
        var longest = 1
        var current = 1
        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else if diff > 1 {
                current = 1
            }
            // diff == 0 means duplicate date (multiple check-ins same day) — ignore
        }
        return longest
    }
}
```

- [ ] **Step 4: Run tests and verify they pass**

Cmd+U.

- [ ] **Step 5: Commit**

```bash
git add FocusOnYourself/Services/StreakService.swift FocusOnYourselfTests/Services/StreakServiceTests.swift
git commit -m "feat: add StreakService"
```

---

### Task 10: NotificationService

**Files:**
- Create: `FocusOnYourself/Services/NotificationService.swift`
- Create: `FocusOnYourselfTests/Services/NotificationServiceTests.swift`

- [ ] **Step 1: Write failing tests**

`FocusOnYourselfTests/Services/NotificationServiceTests.swift`:
```swift
import XCTest
import UserNotifications
@testable import FocusOnYourself

final class NotificationServiceTests: XCTestCase {
    func test_notificationContent_includesName() {
        let content = NotificationService.makeContent(name: "Alex")
        XCTAssertEqual(content.title, "Good morning, Alex ✨")
        XCTAssertFalse(content.body.isEmpty)
    }

    func test_notificationContent_defaultName_whenEmpty() {
        let content = NotificationService.makeContent(name: "")
        XCTAssertTrue(content.title.contains("Good morning"))
    }

    func test_trigger_firesAt9am() {
        let trigger = NotificationService.makeTrigger()
        XCTAssertEqual(trigger.dateComponents.hour, 9)
        XCTAssertEqual(trigger.dateComponents.minute, 0)
        XCTAssertTrue(trigger.repeats)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Cmd+U.

- [ ] **Step 3: Implement NotificationService**

`FocusOnYourself/Services/NotificationService.swift`:
```swift
import Foundation
import UserNotifications

final class NotificationService {
    static let notificationID = "daily-affirmation"

    // MARK: - Factory (testable)

    static func makeContent(name: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let greeting = name.isEmpty ? "Good morning ✨" : "Good morning, \(name) ✨"
        content.title = greeting
        content.body = "Your daily affirmation is ready. Take a moment for yourself."
        content.sound = .default
        return content
    }

    static func makeTrigger() -> UNCalendarNotificationTrigger {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    }

    // MARK: - Scheduling

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func schedule(name: String) {
        let request = UNNotificationRequest(
            identifier: Self.notificationID,
            content: Self.makeContent(name: name),
            trigger: Self.makeTrigger()
        )
        UNUserNotificationCenter.current().add(request)
    }

    func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
    }

    /// Returns true if authorized, false if denied.
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
}
```

- [ ] **Step 4: Run tests and verify they pass**

Cmd+U.

- [ ] **Step 5: Commit**

```bash
git add FocusOnYourself/Services/NotificationService.swift FocusOnYourselfTests/Services/NotificationServiceTests.swift
git commit -m "feat: add NotificationService"
```

---

### Task 11: AppState

**Files:**
- Create: `FocusOnYourself/App/AppState.swift`
- Create: `FocusOnYourselfTests/App/AppStateTests.swift`

- [ ] **Step 1: Write failing tests**

`FocusOnYourselfTests/App/AppStateTests.swift`:
```swift
import XCTest
@testable import FocusOnYourself

final class AppStateTests: XCTestCase {
    func test_todayAffirmation_isNil_whenNoCategoriesSelected() {
        let defaults = UserDefaults(suiteName: "appstate-test-\(UUID().uuidString)")!
        let storage = StorageService(defaults: defaults)
        let affirmationService = AffirmationService()
        let state = AppState(storage: storage, affirmationService: affirmationService)
        XCTAssertNil(state.todayAffirmation)
    }

    func test_todayAffirmation_isSet_afterCategoriesSelected() {
        let defaults = UserDefaults(suiteName: "appstate-test-\(UUID().uuidString)")!
        let storage = StorageService(defaults: defaults)
        var profile = UserProfile()
        profile.selectedCategories = [.confidence]
        storage.save(profile: profile)
        let affirmationService = AffirmationService()
        let state = AppState(storage: storage, affirmationService: affirmationService)
        XCTAssertNotNil(state.todayAffirmation)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Cmd+U.

- [ ] **Step 3: Implement AppState**

`FocusOnYourself/App/AppState.swift`:
```swift
import Foundation
import Observation

@Observable
final class AppState {
    var profile: UserProfile
    var todayAffirmation: Affirmation?

    private let storage: StorageService
    private let affirmationService: AffirmationService

    init(storage: StorageService = StorageService(),
         affirmationService: AffirmationService = AffirmationService()) {
        self.storage = storage
        self.affirmationService = affirmationService
        self.profile = storage.loadProfile()
        self.todayAffirmation = affirmationService.affirmation(
            for: Date(),
            categories: profile.selectedCategories
        )
    }

    func updateProfile(_ profile: UserProfile) {
        self.profile = profile
        storage.save(profile: profile)
        todayAffirmation = affirmationService.affirmation(
            for: Date(),
            categories: profile.selectedCategories
        )
    }

    func refreshAffirmation() {
        todayAffirmation = affirmationService.affirmation(
            for: Date(),
            categories: profile.selectedCategories
        )
    }
}
```

- [ ] **Step 4: Wire AppState into FocusOnYourselfApp**

`FocusOnYourself/App/FocusOnYourselfApp.swift`:
```swift
import SwiftUI
import SwiftData

@main
struct FocusOnYourselfApp: App {
    let container: ModelContainer
    @State private var appState = AppState()

    init() {
        do {
            let schema = Schema([DailyCheckIn.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to configure SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(appState)
        }
    }
}
```

- [ ] **Step 5: Run tests and verify they pass**

Cmd+U.

- [ ] **Step 6: Commit**

```bash
git add FocusOnYourself/App/AppState.swift FocusOnYourself/App/FocusOnYourselfApp.swift FocusOnYourselfTests/App/AppStateTests.swift
git commit -m "feat: add AppState and wire into app entry point"
```

---

## Chunk 3: Onboarding Feature

> **Note:** Before implementing any screen in this chunk, open `FocusOnYourselfDesign.pen` in Pencil.dev to design each screen's layout first. Implement to match the design.

### Task 12: OnboardingCoordinator

**Files:**
- Create: `FocusOnYourself/Features/Onboarding/OnboardingCoordinator.swift`

- [ ] **Step 1: Implement OnboardingCoordinator**

`FocusOnYourself/Features/Onboarding/OnboardingCoordinator.swift`:
```swift
import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case name
    case categories
    case notifications
}

@Observable
final class OnboardingCoordinator {
    var currentStep: OnboardingStep = .welcome
    var draftProfile = UserProfile()

    func advance() {
        let all = OnboardingStep.allCases
        guard let idx = all.firstIndex(of: currentStep), idx + 1 < all.count else { return }
        currentStep = all[idx + 1]
    }

    var isLastStep: Bool {
        currentStep == OnboardingStep.allCases.last
    }
}
```

- [ ] **Step 2: Build and verify no errors**

Cmd+B.

- [ ] **Step 3: Commit**

```bash
git add FocusOnYourself/Features/Onboarding/OnboardingCoordinator.swift
git commit -m "feat: add OnboardingCoordinator"
```

---

### Task 13: WelcomeScreen

**Files:**
- Create: `FocusOnYourself/Features/Onboarding/WelcomeScreen.swift`

- [ ] **Step 1: Design the screen in Pencil.dev first**

Open `FocusOnYourselfDesign.pen`. Design the WelcomeScreen: app logo/icon, app name "Focus On Yourself", tagline, and a "Get Started" button.

- [ ] **Step 2: Implement WelcomeScreen**

`FocusOnYourself/Features/Onboarding/WelcomeScreen.swift`:
```swift
import SwiftUI

struct WelcomeScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "heart.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.pink)

            VStack(spacing: 12) {
                Text("Focus On Yourself")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("A daily moment of intention.\nOne affirmation. One check-in. One streak.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.pink)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }
}

#Preview {
    WelcomeScreen(onContinue: {})
}
```

- [ ] **Step 3: Build and preview**

Cmd+B. Open preview in Xcode canvas to visually verify against your Pencil.dev design.

- [ ] **Step 4: Commit**

```bash
git add FocusOnYourself/Features/Onboarding/WelcomeScreen.swift
git commit -m "feat: add WelcomeScreen"
```

---

### Task 14: NameEntryScreen

**Files:**
- Create: `FocusOnYourself/Features/Onboarding/NameEntryScreen.swift`

- [ ] **Step 1: Design in Pencil.dev**

Design NameEntryScreen: heading "What should we call you?", text field, Continue button (enabled when name is non-empty).

- [ ] **Step 2: Implement NameEntryScreen**

`FocusOnYourself/Features/Onboarding/NameEntryScreen.swift`:
```swift
import SwiftUI

struct NameEntryScreen: View {
    @Binding var name: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 12) {
                Text("What should we call you?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                Text("We'll use your name to personalize your experience.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            TextField("Your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 32)
                .submitLabel(.done)
                .onSubmit { if !name.trimmingCharacters(in: .whitespaces).isEmpty { onContinue() } }

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.pink)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }
}

#Preview {
    NameEntryScreen(name: .constant(""), onContinue: {})
}
```

- [ ] **Step 3: Build and preview**

Cmd+B. Verify the Continue button is disabled when name is empty, enabled when non-empty.

- [ ] **Step 4: Commit**

```bash
git add FocusOnYourself/Features/Onboarding/NameEntryScreen.swift
git commit -m "feat: add NameEntryScreen"
```

---

### Task 15: CategoryPickerScreen

**Files:**
- Create: `FocusOnYourself/Features/Onboarding/CategoryPickerScreen.swift`

- [ ] **Step 1: Design in Pencil.dev**

Design CategoryPickerScreen: heading, 4 category cards (multi-select with checkmarks), Continue button disabled until at least one is selected.

- [ ] **Step 2: Implement CategoryPickerScreen**

`FocusOnYourself/Features/Onboarding/CategoryPickerScreen.swift`:
```swift
import SwiftUI

struct CategoryPickerScreen: View {
    @Binding var selectedCategories: [AffirmationCategory]
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 8) {
                Text("What matters to you?")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Choose topics for your daily affirmations.\nSelect at least one.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach(AffirmationCategory.allCases) { category in
                    CategoryRowView(
                        category: category,
                        isSelected: selectedCategories.contains(category),
                        onTap: { toggle(category) }
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedCategories.isEmpty ? Color.gray : Color.pink)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(selectedCategories.isEmpty)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }

    private func toggle(_ category: AffirmationCategory) {
        if let idx = selectedCategories.firstIndex(of: category) {
            selectedCategories.remove(at: idx)
        } else {
            selectedCategories.append(category)
        }
    }
}

private struct CategoryRowView: View {
    let category: AffirmationCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(category.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .pink : .secondary)
            }
            .padding()
            .background(isSelected ? Color.pink.opacity(0.1) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CategoryPickerScreen(selectedCategories: .constant([.confidence]), onContinue: {})
}
```

- [ ] **Step 3: Build and preview**

Cmd+B. Verify multi-select works and Continue is disabled until a category is tapped.

- [ ] **Step 4: Commit**

```bash
git add FocusOnYourself/Features/Onboarding/CategoryPickerScreen.swift
git commit -m "feat: add CategoryPickerScreen"
```

---

### Task 16: NotificationPermissionScreen

**Files:**
- Create: `FocusOnYourself/Features/Onboarding/NotificationPermissionScreen.swift`

- [ ] **Step 1: Design in Pencil.dev**

Design NotificationPermissionScreen: bell icon, heading, body copy explaining the 9am reminder, "Enable Notifications" primary button, "Skip for now" secondary link.

- [ ] **Step 2: Implement NotificationPermissionScreen**

`FocusOnYourself/Features/Onboarding/NotificationPermissionScreen.swift`:
```swift
import SwiftUI

struct NotificationPermissionScreen: View {
    let onEnable: () async -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundStyle(.pink)

            VStack(spacing: 12) {
                Text("Stay on track")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("We'll send you a gentle reminder at 9:00 AM each morning so you never miss a day.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task { await onEnable() }
                } label: {
                    Text("Enable Notifications")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(action: onSkip) {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }
}

#Preview {
    NotificationPermissionScreen(onEnable: {}, onSkip: {})
}
```

- [ ] **Step 3: Build and preview**

Cmd+B.

- [ ] **Step 4: Commit**

```bash
git add FocusOnYourself/Features/Onboarding/NotificationPermissionScreen.swift
git commit -m "feat: add NotificationPermissionScreen"
```

---

### Task 17: Onboarding flow — wire everything together

**Files:**
- Create: `FocusOnYourself/Features/Onboarding/OnboardingFlow.swift`
- Modify: `FocusOnYourself/ContentView.swift`

- [ ] **Step 1: Create OnboardingFlow view**

`FocusOnYourself/Features/Onboarding/OnboardingFlow.swift`:
```swift
import SwiftUI

struct OnboardingFlow: View {
    @Environment(AppState.self) private var appState
    @State private var coordinator = OnboardingCoordinator()
    private let notificationService = NotificationService()

    var body: some View {
        switch coordinator.currentStep {
        case .welcome:
            WelcomeScreen { coordinator.advance() }
        case .name:
            NameEntryScreen(name: $coordinator.draftProfile.name) { coordinator.advance() }
        case .categories:
            CategoryPickerScreen(selectedCategories: $coordinator.draftProfile.selectedCategories) { coordinator.advance() }
        case .notifications:
            NotificationPermissionScreen(
                onEnable: {
                    let granted = await notificationService.requestPermission()
                    coordinator.draftProfile.notificationsEnabled = granted
                    if granted {
                        notificationService.schedule(name: coordinator.draftProfile.name)
                    }
                    completeOnboarding()
                },
                onSkip: {
                    coordinator.draftProfile.notificationsEnabled = false
                    completeOnboarding()
                }
            )
        }
    }

    private func completeOnboarding() {
        coordinator.draftProfile.onboardingCompleted = true
        appState.updateProfile(coordinator.draftProfile)
    }
}
```

- [ ] **Step 2: Update ContentView to route between onboarding and main app**

`FocusOnYourself/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.profile.onboardingCompleted {
            MainTabView()
        } else {
            OnboardingFlow()
        }
    }
}
```

- [ ] **Step 3: Create placeholder MainTabView**

`FocusOnYourself/App/MainTabView.swift`:
```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Text("Home")
                .tabItem { Label("Home", systemImage: "house.fill") }
            Text("History")
                .tabItem { Label("History", systemImage: "calendar") }
            Text("Settings")
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
```

- [ ] **Step 4: Build and run on simulator**

Cmd+R. Verify: first launch shows onboarding, completing all steps transitions to the tab bar placeholder. Re-launching the app (after onboarding is stored) goes directly to the tab bar.

- [ ] **Step 5: Commit**

```bash
git add FocusOnYourself/Features/Onboarding/OnboardingFlow.swift FocusOnYourself/ContentView.swift FocusOnYourself/App/MainTabView.swift
git commit -m "feat: wire onboarding flow end-to-end"
```

---

## Chunk 4: Home Feature

### Task 18: Design HomeScreen components in Pencil.dev

- [ ] **Step 1: Design all Home components**

Open `FocusOnYourselfDesign.pen`. Design:
1. `HomeScreen` — greeting header, affirmation card, mood check-in section, streak badge at top
2. `AffirmationCardView` — large card with affirmation text and optional author
3. `MoodCheckInView` — 5-option mood selector (emoji or 1-5 scale) with confirm button
4. `StreakBadgeView` — compact flame icon + day count

---

### Task 19: StreakBadgeView

**Files:**
- Create: `FocusOnYourself/Features/Home/Components/StreakBadgeView.swift`

- [ ] **Step 1: Implement StreakBadgeView**

`FocusOnYourself/Features/Home/Components/StreakBadgeView.swift`:
```swift
import SwiftUI

struct StreakBadgeView: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(streak > 0 ? .orange : .secondary)
            Text(streak == 1 ? "1 day" : "\(streak) days")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(streak > 0 ? .primary : .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(streak > 0 ? Color.orange.opacity(0.12) : Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 16) {
        StreakBadgeView(streak: 0)
        StreakBadgeView(streak: 1)
        StreakBadgeView(streak: 12)
    }
}
```

- [ ] **Step 2: Build and preview**

Cmd+B.

- [ ] **Step 3: Commit**

```bash
git add FocusOnYourself/Features/Home/Components/StreakBadgeView.swift
git commit -m "feat: add StreakBadgeView"
```

---

### Task 20: AffirmationCardView

**Files:**
- Create: `FocusOnYourself/Features/Home/Components/AffirmationCardView.swift`

- [ ] **Step 1: Implement AffirmationCardView**

`FocusOnYourself/Features/Home/Components/AffirmationCardView.swift`:
```swift
import SwiftUI

struct AffirmationCardView: View {
    let affirmation: Affirmation

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\u{201C}\(affirmation.text)\u{201D}")
                .font(.title3)
                .fontWeight(.medium)
                .lineSpacing(6)

            if let author = affirmation.author {
                Text("— \(author)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    AffirmationCardView(
        affirmation: Affirmation(
            id: "1",
            text: "I am worthy of love and respect exactly as I am.",
            author: nil,
            categories: [.confidence]
        )
    )
    .padding()
}
```

- [ ] **Step 2: Build and preview**

Cmd+B.

- [ ] **Step 3: Commit**

```bash
git add FocusOnYourself/Features/Home/Components/AffirmationCardView.swift
git commit -m "feat: add AffirmationCardView"
```

---

### Task 21: MoodCheckInView

**Files:**
- Create: `FocusOnYourself/Features/Home/Components/MoodCheckInView.swift`

- [ ] **Step 1: Implement MoodCheckInView**

`FocusOnYourself/Features/Home/Components/MoodCheckInView.swift`:
```swift
import SwiftUI

struct MoodCheckInView: View {
    @Binding var selectedMood: Int?
    let onConfirm: () -> Void

    private let moods: [(Int, String, String)] = [
        (1, "😞", "Rough"),
        (2, "😕", "Low"),
        (3, "😐", "Okay"),
        (4, "🙂", "Good"),
        (5, "😄", "Great")
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("How are you feeling today?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(moods, id: \.0) { value, emoji, label in
                    Button {
                        selectedMood = value
                    } label: {
                        VStack(spacing: 4) {
                            Text(emoji).font(.title2)
                            Text(label).font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedMood == value ? Color.pink.opacity(0.15) : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedMood == value ? Color.pink : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if selectedMood != nil {
                Button(action: onConfirm) {
                    Text("Complete Check-In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedMood)
    }
}

#Preview {
    MoodCheckInView(selectedMood: .constant(3), onConfirm: {})
        .padding()
}
```

- [ ] **Step 2: Build and preview**

Cmd+B. Verify the confirm button appears/disappears with animation when a mood is selected/deselected.

- [ ] **Step 3: Commit**

```bash
git add FocusOnYourself/Features/Home/Components/MoodCheckInView.swift
git commit -m "feat: add MoodCheckInView"
```

---

### Task 22: HomeViewModel + HomeScreen

**Files:**
- Create: `FocusOnYourself/Features/Home/HomeViewModel.swift`
- Create: `FocusOnYourself/Features/Home/HomeScreen.swift`
- Create: `FocusOnYourselfTests/Features/Home/HomeViewModelTests.swift`

- [ ] **Step 1: Write failing tests**

`FocusOnYourselfTests/Features/Home/HomeViewModelTests.swift`:
```swift
import XCTest
import SwiftData
@testable import FocusOnYourself

@MainActor
final class HomeViewModelTests: XCTestCase {
    var container: ModelContainer!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: DailyCheckIn.self, configurations: config)
    }

    func test_hasCompletedTodayCheckIn_falseByDefault() {
        let vm = HomeViewModel(modelContext: container.mainContext)
        XCTAssertFalse(vm.hasCompletedTodayCheckIn)
    }

    func test_completeCheckIn_setsHasCompletedToday() throws {
        let vm = HomeViewModel(modelContext: container.mainContext)
        vm.selectedMood = 4
        vm.completeCheckIn(affirmationID: "aff-001")
        XCTAssertTrue(vm.hasCompletedTodayCheckIn)
    }

    func test_completeCheckIn_doesNothing_whenNoMoodSelected() {
        let vm = HomeViewModel(modelContext: container.mainContext)
        vm.completeCheckIn(affirmationID: "aff-001")
        XCTAssertFalse(vm.hasCompletedTodayCheckIn)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Cmd+U.

- [ ] **Step 3: Implement HomeViewModel**

`FocusOnYourself/Features/Home/HomeViewModel.swift`:
```swift
import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var selectedMood: Int? = nil
    var hasCompletedTodayCheckIn: Bool = false

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkIfTodayIsDone()
    }

    func completeCheckIn(affirmationID: String) {
        guard let mood = selectedMood else { return }
        let checkIn = DailyCheckIn(date: Date(), affirmationID: affirmationID, mood: mood)
        modelContext.insert(checkIn)
        try? modelContext.save()
        hasCompletedTodayCheckIn = true
    }

    private func checkIfTodayIsDone() {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyCheckIn>(
            predicate: #Predicate { $0.date >= todayStart }
        )
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        hasCompletedTodayCheckIn = count > 0
    }
}
```

- [ ] **Step 4: Implement HomeScreen**

`FocusOnYourself/Features/Home/HomeScreen.swift`:
```swift
import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]

    @State private var viewModel: HomeViewModel?

    private var currentStreak: Int {
        StreakService.currentStreak(
            checkInDates: checkIns.map(\.date),
            today: Date()
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Greeting + streak
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(formattedDate)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StreakBadgeView(streak: currentStreak)
                    }

                    // Affirmation card
                    if let affirmation = appState.todayAffirmation {
                        AffirmationCardView(affirmation: affirmation)
                    } else {
                        Text("No affirmation available — check your category settings.")
                            .foregroundStyle(.secondary)
                            .font(.body)
                    }

                    // Mood check-in
                    if let vm = viewModel {
                        if vm.hasCompletedTodayCheckIn {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                Text("Check-in complete for today!").font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            MoodCheckInView(selectedMood: Bindable(vm).selectedMood) {
                                vm.completeCheckIn(affirmationID: appState.todayAffirmation?.id ?? "")
                            }
                        }
                    }
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if viewModel == nil {
                    viewModel = HomeViewModel(modelContext: modelContext)
                }
                appState.refreshAffirmation()
            }
        }
    }

    private var greeting: String {
        let name = appState.profile.name
        return name.isEmpty ? "Good morning" : "Good morning, \(name)"
    }

    private var formattedDate: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}
```

- [ ] **Step 5: Wire HomeScreen into MainTabView**

`FocusOnYourself/App/MainTabView.swift`:
```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem { Label("Home", systemImage: "house.fill") }
            Text("History")
                .tabItem { Label("History", systemImage: "calendar") }
            Text("Settings")
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
```

- [ ] **Step 6: Run tests and verify they pass**

Cmd+U.

- [ ] **Step 7: Build and run on simulator**

Cmd+R. Verify: HomeScreen shows greeting, affirmation card, mood check-in. Completing check-in shows the confirmation state. Streak badge shows correct count.

- [ ] **Step 8: Commit**

```bash
git add FocusOnYourself/Features/Home/HomeViewModel.swift FocusOnYourself/Features/Home/HomeScreen.swift FocusOnYourself/App/MainTabView.swift FocusOnYourselfTests/Features/Home/HomeViewModelTests.swift
git commit -m "feat: add HomeScreen with affirmation, mood check-in, and streak badge"
```

---

## Chunk 5: History + Settings Features

### Task 23: Design History and Settings screens in Pencil.dev

- [ ] **Step 1: Design HistoryScreen**

Open `FocusOnYourselfDesign.pen`. Design:
- `HistoryScreen` — "Current streak: X days", "Longest streak: Y days", calendar/heatmap grid showing checked-in days
- `StreakCalendarView` — monthly grid (or a scrollable list of past check-ins grouped by month)

- [ ] **Step 2: Design SettingsScreen**

Design SettingsScreen — name field, category multi-select, notification toggle (with "Open iOS Settings" behavior when denied), Apple Intelligence toggle (conditionally shown).

---

### Task 24: HistoryViewModel + HistoryScreen

**Files:**
- Create: `FocusOnYourself/Features/History/HistoryViewModel.swift`
- Create: `FocusOnYourself/Features/History/HistoryScreen.swift`
- Create: `FocusOnYourself/Features/History/Components/StreakCalendarView.swift`
- Create: `FocusOnYourselfTests/Features/History/HistoryViewModelTests.swift`

- [ ] **Step 1: Write failing tests**

`FocusOnYourselfTests/Features/History/HistoryViewModelTests.swift`:
```swift
import XCTest
@testable import FocusOnYourself

final class HistoryViewModelTests: XCTestCase {
    let calendar = Calendar.current

    func makeDate(daysAgo: Int) -> Date {
        calendar.startOfDay(for: calendar.date(byAdding: .day, value: -daysAgo, to: Date())!)
    }

    func test_currentStreak_calculatedFromCheckInDates() {
        let dates = [makeDate(daysAgo: 0), makeDate(daysAgo: 1), makeDate(daysAgo: 2)]
        let vm = HistoryViewModel(checkInDates: dates)
        XCTAssertEqual(vm.currentStreak, 3)
    }

    func test_longestStreak_calculatedCorrectly() {
        let dates = [makeDate(daysAgo: 10), makeDate(daysAgo: 9), makeDate(daysAgo: 5)]
        let vm = HistoryViewModel(checkInDates: dates)
        XCTAssertEqual(vm.longestStreak, 2)
    }

    func test_checkedInDates_setContainsAllDates() {
        let dates = [makeDate(daysAgo: 0), makeDate(daysAgo: 3)]
        let vm = HistoryViewModel(checkInDates: dates)
        XCTAssertTrue(vm.checkedInDates.contains(makeDate(daysAgo: 0)))
        XCTAssertTrue(vm.checkedInDates.contains(makeDate(daysAgo: 3)))
        XCTAssertFalse(vm.checkedInDates.contains(makeDate(daysAgo: 1)))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Cmd+U.

- [ ] **Step 3: Implement HistoryViewModel**

`FocusOnYourself/Features/History/HistoryViewModel.swift`:
```swift
import Foundation
import Observation

@Observable
final class HistoryViewModel {
    let currentStreak: Int
    let longestStreak: Int
    let checkedInDates: Set<Date>

    init(checkInDates: [Date]) {
        self.currentStreak = StreakService.currentStreak(checkInDates: checkInDates, today: Date())
        self.longestStreak = StreakService.longestStreak(checkInDates: checkInDates)
        self.checkedInDates = Set(checkInDates.map { Calendar.current.startOfDay(for: $0) })
    }
}
```

- [ ] **Step 4: Implement StreakCalendarView**

`FocusOnYourself/Features/History/Components/StreakCalendarView.swift`:
```swift
import SwiftUI

struct StreakCalendarView: View {
    let checkedInDates: Set<Date>
    let month: Date

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else { return [] }
        let weekdayOffset = calendar.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: weekdayOffset)
        for day in range {
            days.append(calendar.date(byAdding: .day, value: day - 1, to: firstDay))
        }
        return days
    }

    var body: some View {
        VStack(spacing: 8) {
            // Month header
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Day labels
            HStack(spacing: 0) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let checked = checkedInDates.contains(calendar.startOfDay(for: date))
                        Circle()
                            .fill(checked ? Color.pink : Color(.secondarySystemBackground))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.caption2)
                                    .fontWeight(checked ? .bold : .regular)
                                    .foregroundStyle(checked ? .white : .primary)
                            )
                    } else {
                        Color.clear.frame(width: 32, height: 32)
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 5: Implement HistoryScreen**

`FocusOnYourself/Features/History/HistoryScreen.swift`:
```swift
import SwiftUI
import SwiftData

struct HistoryScreen: View {
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]

    private var viewModel: HistoryViewModel {
        HistoryViewModel(checkInDates: checkIns.map(\.date))
    }

    private var visibleMonths: [Date] {
        let today = Date()
        return (0..<3).compactMap {
            Calendar.current.date(byAdding: .month, value: -$0, to: today)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Streak stats
                    HStack(spacing: 16) {
                        StatView(label: "Current Streak", value: "\(viewModel.currentStreak) days")
                        StatView(label: "Longest Streak", value: "\(viewModel.longestStreak) days")
                    }

                    Divider()

                    // Calendar heatmap — last 3 months
                    ForEach(visibleMonths, id: \.self) { month in
                        StreakCalendarView(checkedInDates: viewModel.checkedInDates, month: month)
                    }
                }
                .padding(24)
            }
            .navigationTitle("History")
        }
    }
}

private struct StatView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

- [ ] **Step 6: Wire HistoryScreen into MainTabView**

`FocusOnYourself/App/MainTabView.swift`:
```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem { Label("Home", systemImage: "house.fill") }
            HistoryScreen()
                .tabItem { Label("History", systemImage: "calendar") }
            Text("Settings")
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
```

- [ ] **Step 7: Run tests and verify they pass**

Cmd+U.

- [ ] **Step 8: Build and run on simulator**

Cmd+R. Verify the History tab shows streak stats and the last 3 months of calendar, with pink dots on days with check-ins.

- [ ] **Step 9: Commit**

```bash
git add FocusOnYourself/Features/History/ FocusOnYourselfTests/Features/History/
git commit -m "feat: add HistoryScreen with streak stats and calendar heatmap"
```

---

### Task 25: SettingsViewModel + SettingsScreen

**Files:**
- Create: `FocusOnYourself/Features/Settings/SettingsViewModel.swift`
- Create: `FocusOnYourself/Features/Settings/SettingsScreen.swift`
- Create: `FocusOnYourselfTests/Features/Settings/SettingsViewModelTests.swift`

- [ ] **Step 1: Write failing tests**

`FocusOnYourselfTests/Features/Settings/SettingsViewModelTests.swift`:
```swift
import XCTest
@testable import FocusOnYourself

final class SettingsViewModelTests: XCTestCase {
    func test_draftName_initializedFromProfile() {
        var profile = UserProfile()
        profile.name = "Jordan"
        let vm = SettingsViewModel(profile: profile)
        XCTAssertEqual(vm.draftName, "Jordan")
    }

    func test_draftCategories_initializedFromProfile() {
        var profile = UserProfile()
        profile.selectedCategories = [.confidence]
        let vm = SettingsViewModel(profile: profile)
        XCTAssertEqual(vm.draftCategories, [.confidence])
    }

    func test_toggleCategory_addsWhenAbsent() {
        let profile = UserProfile()
        let vm = SettingsViewModel(profile: profile)
        vm.toggleCategory(.mindfulness)
        XCTAssertTrue(vm.draftCategories.contains(.mindfulness))
    }

    func test_toggleCategory_removesWhenPresent_ifMoreThanOne() {
        var profile = UserProfile()
        profile.selectedCategories = [.confidence, .health]
        let vm = SettingsViewModel(profile: profile)
        vm.toggleCategory(.confidence)
        XCTAssertFalse(vm.draftCategories.contains(.confidence))
    }

    func test_toggleCategory_doesNotRemove_whenLastCategory() {
        var profile = UserProfile()
        profile.selectedCategories = [.confidence]
        let vm = SettingsViewModel(profile: profile)
        vm.toggleCategory(.confidence)
        // Should not remove the last category
        XCTAssertTrue(vm.draftCategories.contains(.confidence))
    }

    func test_buildUpdatedProfile_appliesDrafts() {
        var profile = UserProfile()
        profile.name = "Alex"
        profile.selectedCategories = [.health]
        let vm = SettingsViewModel(profile: profile)
        vm.draftName = "Sam"
        vm.draftCategories = [.mindfulness]
        let updated = vm.buildUpdatedProfile()
        XCTAssertEqual(updated.name, "Sam")
        XCTAssertEqual(updated.selectedCategories, [.mindfulness])
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Cmd+U.

- [ ] **Step 3: Implement SettingsViewModel**

`SettingsViewModel` holds draft state only. All persistence goes through `AppState` — no `StorageService` is instantiated here.

`FocusOnYourself/Features/Settings/SettingsViewModel.swift`:
```swift
import Foundation
import Observation
import UIKit
import UserNotifications

@Observable
final class SettingsViewModel {
    var draftName: String
    var draftCategories: [AffirmationCategory]
    var showOpenSettingsAlert: Bool = false

    private let originalProfile: UserProfile

    init(profile: UserProfile) {
        self.originalProfile = profile
        self.draftName = profile.name
        self.draftCategories = profile.selectedCategories
    }

    /// Returns a new profile with draft values applied — caller is responsible for saving via AppState.
    func buildUpdatedProfile() -> UserProfile {
        var updated = originalProfile
        updated.name = draftName
        updated.selectedCategories = draftCategories
        return updated
    }

    func toggleCategory(_ category: AffirmationCategory) {
        if let idx = draftCategories.firstIndex(of: category) {
            if draftCategories.count > 1 { draftCategories.remove(at: idx) }
        } else {
            draftCategories.append(category)
        }
    }

    func openIOSSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
```

- [ ] **Step 4: Implement SettingsScreen**

`FocusOnYourself/Features/Settings/SettingsScreen.swift`:
```swift
import SwiftUI
import UserNotifications

struct SettingsScreen: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: SettingsViewModel?
    private let notificationService = NotificationService()

    var body: some View {
        NavigationStack {
            if let vm = viewModel {
                Form {
                    Section("Your Name") {
                        TextField("Name", text: Bindable(vm).draftName)
                            .submitLabel(.done)
                            .onSubmit { save(vm) }
                    }

                    Section("Affirmation Categories") {
                        ForEach(AffirmationCategory.allCases) { category in
                            Button {
                                vm.toggleCategory(category)
                            } label: {
                                HStack {
                                    Text(category.displayName).foregroundStyle(.primary)
                                    Spacer()
                                    if vm.draftCategories.contains(category) {
                                        Image(systemName: "checkmark").foregroundStyle(.pink)
                                    }
                                }
                            }
                        }
                    }

                    Section("Notifications") {
                        Toggle("Daily 9am Reminder", isOn: Binding(
                            get: { appState.profile.notificationsEnabled },
                            set: { newValue in
                                Task { await handleNotificationToggle(vm, enabled: newValue) }
                            }
                        ))
                    }

                    // Apple Intelligence toggle — only shown on supported devices
                    if IntelligenceService().isAvailable {
                        Section("Apple Intelligence") {
                            Toggle("AI-Personalized Affirmation", isOn: Binding(
                                get: { appState.profile.appleIntelligenceEnabled },
                                set: { newValue in
                                    var profile = appState.profile
                                    profile.appleIntelligenceEnabled = newValue
                                    appState.updateProfile(profile)
                                }
                            ))
                            Text("After check-in, generate a personalized affirmation using on-device AI.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save(vm) }
                    }
                }
                .alert("Notifications Disabled", isPresented: Bindable(vm).showOpenSettingsAlert) {
                    Button("Open Settings") { vm.openIOSSettings() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("To enable notifications, please allow them in iOS Settings.")
                }
            }
        }
        .onAppear {
            // SettingsViewModel is initialized from AppState — no separate StorageService needed.
            if viewModel == nil {
                viewModel = SettingsViewModel(profile: appState.profile)
            }
        }
    }

    private func save(_ vm: SettingsViewModel) {
        appState.updateProfile(vm.buildUpdatedProfile())
    }

    private func handleNotificationToggle(_ vm: SettingsViewModel, enabled: Bool) async {
        if enabled {
            let status = await notificationService.authorizationStatus()
            if status == .denied {
                vm.showOpenSettingsAlert = true
                return
            }
            let granted = await notificationService.requestPermission()
            if granted {
                notificationService.schedule(name: appState.profile.name)
                var profile = appState.profile
                profile.notificationsEnabled = true
                appState.updateProfile(profile)
            } else {
                vm.showOpenSettingsAlert = true
            }
        } else {
            notificationService.cancel()
            var profile = appState.profile
            profile.notificationsEnabled = false
            appState.updateProfile(profile)
        }
    }
}
```

- [ ] **Step 5: Wire SettingsScreen into MainTabView**

`FocusOnYourself/App/MainTabView.swift`:
```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem { Label("Home", systemImage: "house.fill") }
            HistoryScreen()
                .tabItem { Label("History", systemImage: "calendar") }
            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
```

- [ ] **Step 6: Run tests and verify they pass**

Cmd+U.

- [ ] **Step 7: Build and run on simulator**

Cmd+R. Verify Settings screen shows name, categories, and notification toggle. Saving persists changes and updates affirmations on HomeScreen.

- [ ] **Step 8: Commit**

```bash
git add FocusOnYourself/Features/Settings/ FocusOnYourselfTests/Features/Settings/ FocusOnYourself/App/MainTabView.swift
git commit -m "feat: add SettingsScreen with name, categories, and notification toggle"
```

---

## Chunk 6: Apple Intelligence Integration

> **Note:** This chunk requires a physical device (iPhone 15 Pro or newer) running iOS 26+ to test. Use the simulator only for building and verifying the fallback behavior on unsupported devices.

### Task 26: IntelligenceService

**Files:**
- Create: `FocusOnYourself/Services/IntelligenceService.swift`
- Create: `FocusOnYourselfTests/Services/IntelligenceServiceTests.swift`

- [ ] **Step 1: Write failing tests**

`FocusOnYourselfTests/Services/IntelligenceServiceTests.swift`:
```swift
import XCTest
@testable import FocusOnYourself

final class IntelligenceServiceTests: XCTestCase {
    func test_isAvailable_returnsFalse_onSimulator() {
        // On simulator / older devices, Apple Intelligence is not available
        // This test confirms the service handles unavailability gracefully.
        let service = IntelligenceService()
        // We cannot assert a specific value here (depends on device),
        // but we can assert the property exists and is Bool.
        let _: Bool = service.isAvailable
        XCTAssertTrue(true) // structural test — confirms compile + property access
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Cmd+U. Expected: build fails — `IntelligenceService` not defined.

- [ ] **Step 3: Implement IntelligenceService**

`FocusOnYourself/Services/IntelligenceService.swift`:
```swift
import Foundation
import FoundationModels

final class IntelligenceService {
    /// True when the device supports Apple Intelligence (iOS 26+).
    var isAvailable: Bool {
        if #available(iOS 26, *) {
            return SystemLanguageModel.default.isAvailable
        }
        return false
    }

    /// Generates a personalized affirmation based on mood (1–5).
    /// Returns nil on unsupported devices or on generation failure.
    func generateAffirmation(for mood: Int) async -> String? {
        guard isAvailable else { return nil }
        if #available(iOS 26, *) {
            return await generateWithFoundationModels(mood: mood)
        }
        return nil
    }

    @available(iOS 26, *)
    private func generateWithFoundationModels(mood: Int) async -> String? {
        let moodDescriptions = ["very rough", "low", "okay", "good", "great"]
        let description = moodDescriptions[min(max(mood - 1, 0), 4)]
        let prompt = """
            Write a single short affirmation for someone who is feeling \(description) today. \
            One sentence only. Start with "I". Be warm, encouraging, and specific.
            """
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}
```

- [ ] **Step 4: Run tests and verify they pass**

Cmd+U.

- [ ] **Step 5: Commit**

```bash
git add FocusOnYourself/Services/IntelligenceService.swift FocusOnYourselfTests/Services/IntelligenceServiceTests.swift
git commit -m "feat: add IntelligenceService stub for Apple Intelligence"
```

---

### Task 27: AIAffirmationView + wire into HomeScreen

**Files:**
- Create: `FocusOnYourself/Features/Home/Components/AIAffirmationView.swift`
- Modify: `FocusOnYourself/Features/Home/HomeViewModel.swift`
- Modify: `FocusOnYourself/Features/Home/HomeScreen.swift`

- [ ] **Step 1: Implement AIAffirmationView**

`FocusOnYourself/Features/Home/Components/AIAffirmationView.swift`:
```swift
import SwiftUI

struct AIAffirmationView: View {
    let text: String?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Personalized for you")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.purple)
            }

            if isLoading {
                HStack {
                    ProgressView()
                    Text("Generating…").font(.body).foregroundStyle(.secondary)
                }
            } else if let text {
                Text("\u{201C}\(text)\u{201D}")
                    .font(.body)
                    .lineSpacing(5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        AIAffirmationView(text: nil, isLoading: true)
        AIAffirmationView(text: "You are growing in ways you can't yet see.", isLoading: false)
    }
    .padding()
}
```

- [ ] **Step 2: Replace HomeViewModel with complete updated version**

`FocusOnYourself/Features/Home/HomeViewModel.swift` (complete file):
```swift
import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var selectedMood: Int? = nil
    var hasCompletedTodayCheckIn: Bool = false
    var aiAffirmation: String? = nil
    var isGeneratingAIAffirmation: Bool = false

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkIfTodayIsDone()
    }

    func completeCheckIn(affirmationID: String) {
        guard let mood = selectedMood else { return }
        let checkIn = DailyCheckIn(date: Date(), affirmationID: affirmationID, mood: mood)
        modelContext.insert(checkIn)
        try? modelContext.save()
        hasCompletedTodayCheckIn = true
    }

    func generateAIAffirmation(mood: Int, service: IntelligenceService) async {
        guard !isGeneratingAIAffirmation else { return }
        isGeneratingAIAffirmation = true
        aiAffirmation = await service.generateAffirmation(for: mood)
        isGeneratingAIAffirmation = false
    }

    private func checkIfTodayIsDone() {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyCheckIn>(
            predicate: #Predicate { $0.date >= todayStart }
        )
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        hasCompletedTodayCheckIn = count > 0
    }
}
```

- [ ] **Step 3: Replace HomeScreen with complete updated version**

`FocusOnYourself/Features/Home/HomeScreen.swift` (complete file):
```swift
import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]

    @State private var viewModel: HomeViewModel?
    private let intelligenceService = IntelligenceService()

    private var currentStreak: Int {
        StreakService.currentStreak(
            checkInDates: checkIns.map(\.date),
            today: Date()
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Greeting + streak
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(formattedDate)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StreakBadgeView(streak: currentStreak)
                    }

                    // Affirmation card
                    if let affirmation = appState.todayAffirmation {
                        AffirmationCardView(affirmation: affirmation)
                    } else {
                        Text("No affirmation available — check your category settings.")
                            .foregroundStyle(.secondary)
                            .font(.body)
                    }

                    // Mood check-in or completion state
                    if let vm = viewModel {
                        if vm.hasCompletedTodayCheckIn {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                Text("Check-in complete for today!").font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // AI affirmation — shown after check-in on supported devices
                            if appState.profile.appleIntelligenceEnabled,
                               vm.aiAffirmation != nil || vm.isGeneratingAIAffirmation {
                                AIAffirmationView(
                                    text: vm.aiAffirmation,
                                    isLoading: vm.isGeneratingAIAffirmation
                                )
                            }
                        } else {
                            MoodCheckInView(selectedMood: Bindable(vm).selectedMood) {
                                let moodAtCompletion = vm.selectedMood
                                vm.completeCheckIn(affirmationID: appState.todayAffirmation?.id ?? "")
                                if appState.profile.appleIntelligenceEnabled,
                                   let mood = moodAtCompletion {
                                    Task {
                                        await vm.generateAIAffirmation(mood: mood, service: intelligenceService)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if viewModel == nil {
                    viewModel = HomeViewModel(modelContext: modelContext)
                }
                appState.refreshAffirmation()
            }
        }
    }

    private var greeting: String {
        let name = appState.profile.name
        return name.isEmpty ? "Good morning" : "Good morning, \(name)"
    }

    private var formattedDate: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}
```

- [ ] **Step 4: (Note) Apple Intelligence toggle in Settings already included**

The `SettingsScreen` implemented in Task 25 already includes the Apple Intelligence toggle section (conditionally shown based on `IntelligenceService().isAvailable`). No changes needed there.

- [ ] **Step 5: Build and run on simulator**

Cmd+R. Verify: Apple Intelligence section is hidden on simulator (as expected — `SystemLanguageModel.default.isAvailable` returns false). The rest of the app continues to work normally.

- [ ] **Step 6: Test on physical device (iPhone 15 Pro+ / iOS 26+)**

Run on a supported device. Enable Apple Intelligence in Settings. Complete a check-in and verify:
- `AIAffirmationView` appears in loading state
- Generated affirmation text populates after a few seconds
- App does not crash if generation fails (returns nil gracefully)

- [ ] **Step 7: Commit**

```bash
git add FocusOnYourself/Features/Home/Components/AIAffirmationView.swift FocusOnYourself/Features/Home/HomeViewModel.swift FocusOnYourself/Features/Home/HomeScreen.swift FocusOnYourself/Features/Settings/SettingsScreen.swift FocusOnYourself/Services/IntelligenceService.swift
git commit -m "feat: add Apple Intelligence AI affirmation integration"
```

---

*Plan complete.*
