# TestFlight Release Notes

## Build 2 — 2026-03-14

### What's New

- **Affirmations dataset**: Replaced placeholder with 17,994 curated first-person affirmations (confidence: 4,496 · health: 4,499 · mindfulness: 4,499 · relationships: 4,500). Affirmations are filtered by your selected categories.
- **Apple Intelligence availability check**: The app now only activates on-device AI generation when both the user toggle is on AND the device supports it (iPhone 15 Pro+). Previously the toggle had no device guard.
- **Home screen layout**: Removed the large gap (~48pt) between the last content card and the tab bar. The bottom of the Home screen now has minimal breathing room (4pt) matching the rest of the UI.

### What to Test

1. **Static affirmations load** — With Apple Intelligence OFF, open Home and confirm 10 affirmations appear. Verify they match your selected categories (Settings → Categories).
2. **Category filtering** — Deselect all but one category in Settings; return to Home and confirm all 10 affirmations belong to that category only.
3. **Apple Intelligence guard** — On a non-supported device (pre-iPhone 15 Pro), enable the Apple Intelligence toggle in Settings; confirm the app falls back to the static dataset without crashing.
4. **Apple Intelligence on supported device** — On iPhone 15 Pro+, enable the toggle; confirm affirmations are dynamically generated and feel distinct from the curated set.
5. **Dataset variety** — Open Home on multiple days (or clear today's cache); confirm different affirmations appear each day.
6. **Home screen bottom gap** — Scroll to the bottom of Home; confirm there is no large empty space above the tab bar.
