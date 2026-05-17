# TestFlight Release Notes

## Build 5 — 2026-05-17

### What's New

- **Check-in widget** — log your mood directly from the home screen using the new interactive widget (no need to open the app)
- **Apple Health integration** — mood check-ins are written to the Health app as State of Mind entries (iOS 18+)
- **Backend content** — articles, meditations, and affirmations now served from our API; content can update without an app release
- **Meditation audio CDN** — narration MP3s streamed from Supabase and cached locally on first play; app bundle is significantly smaller
- **CheckInFactors** — sleep quality, stress level, exercise, and social quality tracked per check-in
- **SwiftUI improvements** — modern API usage, accessibility labels, structural identity fixes throughout

### What to Test

1. Add the check-in widget to your home screen → tap to log a mood → confirm it appears in the app without opening it
2. Complete a check-in → open Apple Health → verify a State of Mind entry was recorded (iOS 18 required)
3. Open the Home tab → confirm articles load from the backend (not from a bundle)
4. Open the Meditate tab → start a session → confirm narration audio plays on the first step
5. Close and reopen the app → start the same session → confirm audio plays instantly from cache (no download delay)
6. Open Settings → check that context factors (sleep, stress, exercise, social) appear in the check-in flow
7. Kill the backend connection (airplane mode) → open the app → confirm graceful fallback with no crash

## Build 2 — 2026-03-18

### What's New

- **Meditation narration** — sessions now read aloud with natural voice narration (Apple TTS fallback when needed)
- **Countdown timer** — see exactly how much time remains during a meditation session
- **Performance** — faster date formatting, smarter caching, smoother overall experience

### What to Test

1. Start a meditation session → verify narration plays during the session
2. Test with a session that has no ElevenLabs audio → confirm Apple TTS fallback activates
3. During a session, verify the countdown timer counts down correctly
4. Open the Insights tab → confirm charts and stats load without delay
5. Check in → verify the Home tab updates correctly

## Build 1 — 2026-03-16

### What's New

- **Insights tab** — mood distribution, current & longest streaks, trends over time
- **Home screen widgets** — Mood widget and Streak widget, updates after each check-in
- **New mood icons** — custom illustrated icons for all 5 moods
- **Appearance setting** — choose System, Light, or Dark mode in Settings
- **iCloud sync** — preferences now sync across your Apple devices
- **History** — calendar day cells polished and extracted as a dedicated component
- **Dark app icon** — alternate dark variant now available

### What to Test

1. Complete a check-in → verify Mood and Streak widgets update on the Home Screen
2. Open the Insights tab → confirm mood distribution and streak stats are correct
3. Settings → Appearance → tap Light/Dark/System → verify the app switches immediately
4. Settings → Appearance → background-kill the app → verify preference persists on relaunch
5. Sign in to iCloud on two devices → check in on one → confirm data appears on the other
6. Check all 5 mood icons render correctly in the check-in picker and history calendar

## Build 2 — 2026-03-14

### What's New

- **Pro subscription / Paywall**: In-app purchase flow with a dedicated Paywall screen showing the benefits list, pricing, and a restore-purchases option.
- **Pro-gated categories**: Two new focus categories — **Career & Success** and **Resilience & Strength** — are exclusive to Pro subscribers. Lock badges appear on these categories in the category picker and in Settings.
- **AI affirmations require Pro**: The Apple Intelligence affirmations toggle in Settings is now gated behind Pro. Attempting to enable it without a subscription opens the Paywall.
- **History — Day Detail Sheet**: Tap any checked-in day in the History tab to open a detail sheet showing the mood emoji, mood level dots, and journal notes recorded that day.

### What to Test

1. **Paywall flow** — Tap a locked (Pro) category; confirm the Paywall sheet opens with the benefits list and pricing. Test Subscribe, Restore Purchases, and Close/dismiss.
2. **Locked categories** — In the category picker and Settings, confirm **Career & Success** and **Resilience & Strength** display a Pro lock badge and launch the Paywall when tapped (without an active subscription).
3. **AI affirmations gate** — With no Pro subscription, go to Settings and attempt to enable the Apple Intelligence toggle; confirm it is blocked and the Paywall appears.
4. **Free categories** — Confirm Confidence, Health & Wellness, Mindfulness, and Relationships remain freely selectable with no lock badge.
5. **Day Detail Sheet (checked-in day)** — Open the History tab, tap a day that has a check-in; confirm the detail sheet appears with the correct mood emoji, mood level dots, and journal notes.
6. **Day Detail Sheet (unchecked day)** — Tap a day with no check-in; confirm no sheet appears (or that any fallback is handled gracefully without a crash).
