# TestFlight Release Notes

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
