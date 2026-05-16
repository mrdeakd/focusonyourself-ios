## Why

135 pre-recorded narration MP3 files and `narration_map.json` are bundled inside the iOS app. This is the last remaining bundled content asset. Moving narrations to Supabase Storage (CDN) and the narration map to the backend completes the full content migration. It also introduces URL indirection — the iOS app never hardcodes where files are stored, so the hosting provider can change without an App Store update.

Audio files are cached locally on the device after first play, so each narration only downloads once per device regardless of how many times the meditation is played.

## What Changes

- **Backend: new Prisma model** `NarrationEntry { id, instruction, audioUrl }` — seeded from `narration_map.json` with Supabase base URL prepended to each filename; `SUPABASE_AUDIO_URL` environment variable controls the base URL
- **Backend: new endpoint** `GET /api/narration-map` — queries all `NarrationEntry` rows and returns a `{ instruction: audioUrl }` map
- **iOS: `MeditationAudioService`** — on first use, fetch the narration map from the backend and cache it in memory; look up instruction → full URL; download MP3 to the app's cache directory; play from local file via `AVAudioPlayer`; fall back to `AVSpeechSynthesizer` if download fails
- **iOS: remove** `narration_map.json` and the entire `Resources/Narrations/` folder from the app bundle

## Capabilities

### New Capabilities

- `narration-map-api`: Prisma `NarrationEntry` model seeded from `narration_map.json`; backend endpoint `GET /api/narration-map` returning `{ instruction: audioUrl }` map; Supabase base URL configured via `SUPABASE_AUDIO_URL` environment variable

### Modified Capabilities

- `meditation-audio-service`: `MeditationAudioService.speak(_:onComplete:)` — replaces bundle MP3 lookup with network map fetch + local disk cache; `AVAudioPlayer` plays from cached local file; `AVSpeechSynthesizer` fallback preserved

## Impact

**Backend files modified:**
- `src/routes/narrationMap.ts` — new route file
- `src/index.ts` — mount narration map router
- `prisma/schema.prisma` — add `NarrationEntry` model
- `prisma/seed.ts` — seed narration entries from `narration_map.json` with Supabase URLs
- `prisma/narration_map.json` — copied from iOS bundle for seeding

**iOS files modified:**
- `FocusOnYourself/Services/MeditationAudioService.swift` — fetch map from backend, cache audio files on disk

**iOS files deleted:**
- `FocusOnYourself/Resources/narration_map.json`
- `FocusOnYourself/Resources/Narrations/` (135 MP3 files)

**No changes to:**
- `MeditationPlayerViewModel` — calls `audioService.speak()` as before
- Bell sound — generated programmatically, unaffected
- `AVSpeechSynthesizer` fallback — preserved as-is
