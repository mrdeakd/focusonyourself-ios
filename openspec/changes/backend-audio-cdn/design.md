## Context

`MeditationAudioService` currently loads `narration_map.json` from the app bundle synchronously in `init()`, maps instruction strings to MP3 filenames, then plays bundled MP3s via `AVAudioPlayer`. The MP3s are looked up with `Bundle.main.url(forResource: filename, withExtension: "mp3")` — filenames in the map do NOT include the `.mp3` extension.

The 135 MP3 files are now on Supabase Storage. The narration map needs to come from the backend (with full Supabase URLs instead of bare filenames), and audio files need to be downloaded and cached locally on first play.

`speak()` is synchronous (takes a callback, not async) — this must be preserved because `MeditationPlayerViewModel` calls it without `await`. All async work (map fetch, file download) happens inside internal `Task {}` blocks.

## Goals / Non-Goals

**Goals:**
- Add `NarrationEntry { id, instruction, audioUrl }` Prisma model; seed from `narration_map.json` with full Supabase URLs
- Expose `GET /api/narration-map` returning `{ instruction: audioUrl }` dictionary
- `MeditationAudioService` fetches the map from the backend once at init; caches MP3s to `Library/Caches/narrations/` on first play; plays from local file after that
- Remove `narration_map.json` and `Resources/Narrations/` from the iOS bundle
- Preserve the `AVSpeechSynthesizer` fallback for any instruction not in the map or if download fails

**Non-Goals:**
- Pre-downloading all 135 files eagerly — lazy per-instruction caching is sufficient
- Changing `speak()` to `async` — would require significant changes to `MeditationPlayerViewModel`
- Bell sound — generated programmatically, unchanged

## Decisions

### 1. `NarrationEntry` model with `@unique` instruction

```prisma
model NarrationEntry {
  id          Int    @id @default(autoincrement())
  instruction String @unique
  audioUrl    String
}
```

`instruction` is `@unique` because it's the lookup key and duplicates make no sense. Seeded via `createMany` from `narration_map.json`, prepending `SUPABASE_AUDIO_URL` to each filename and appending `.mp3` (filenames in the JSON have no extension).

*Alternatives considered:* Using `instruction` as the primary key — avoids `@unique` but SQLite string PKs have worse index performance than integers.

### 2. Endpoint returns a plain JSON object, not an array

```typescript
// { "Sit comfortably...": "https://supabase.../morning-001_step0.mp3", ... }
const entries = await prisma.narrationEntry.findMany()
const map = Object.fromEntries(entries.map(e => [e.instruction, e.audioUrl]))
res.json(map)
```

iOS decodes this as `[String: String]` — exactly the same type as the existing `narrationMap` property. No model changes on iOS.

*Alternatives considered:* Array of `{ instruction, audioUrl }` objects — requires iOS to transform it. Plain object is simpler.

### 3. `SUPABASE_AUDIO_URL` environment variable

The Supabase base URL is stored in the backend's `.env` and `docker-compose.yml`:
```
SUPABASE_AUDIO_URL=https://mvhqstlitwflobkstyxd.supabase.co/storage/v1/object/public/meditations
```

Changing CDN provider = one env var update, zero code changes.

### 4. Narration map loaded in init via `Task {}`

```swift
init(networkClient: NetworkClientProtocol) {
    super.init()
    synthesizer.delegate = self
    configureAudioSession()
    Task { await fetchNarrationMap() }
}
```

The map fetch is fast (small JSON). In practice, it completes before the user starts a meditation. If it hasn't loaded yet when `speak()` is called, the TTS fallback handles that instruction — acceptable degradation.

*Alternatives considered:* Loading lazily on first `speak()` call — races with playback; explicit `setup()` async method — adds caller complexity.

### 5. Audio cached to `Library/Caches/narrations/`

```swift
private func cachedAudio(for urlString: String) async -> URL? {
    let filename = URL(string: urlString)!.lastPathComponent
    let cacheDir = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("narrations")
    let localURL = cacheDir.appendingPathComponent(filename)

    if FileManager.default.fileExists(atPath: localURL.path) {
        return localURL       // cache hit — instant play
    }

    do {
        let (data, _) = try await URLSession.shared.data(from: URL(string: urlString)!)
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        try data.write(to: localURL)
        return localURL       // downloaded and cached
    } catch {
        return nil            // download failed — caller falls back to TTS
    }
}
```

`Library/Caches/` is managed by iOS — cleared when storage is low. Never backed up to iCloud. Correct for derived audio content.

### 6. `speak()` stays synchronous — async work in internal Task

```swift
func speak(_ text: String, onComplete: @escaping () -> Void) {
    activateAudioSession()
    stopSpeaking()

    if let audioUrl = narrationMap[text] {
        onNarrationComplete = onComplete
        Task {
            if let localURL = await cachedAudio(for: audioUrl) {
                if let player = try? AVAudioPlayer(contentsOf: localURL) {
                    narrationPlayer = player
                    narrationPlayer?.delegate = self
                    narrationPlayer?.play()
                }
            } else {
                fallbackToSpeechSynthesizer(text: text)
            }
        }
        return
    }
    fallbackToSpeechSynthesizer(text: text)
}
```

`MeditationPlayerViewModel` is completely unaffected.

## Risks / Trade-offs

**[Risk] First play of each narration has a download delay** → First time a step plays, the device downloads the MP3 (~100–300KB). On a fast connection this takes < 1s and is mostly masked by the meditation's natural pacing. Subsequent plays are instant from cache. Acceptable trade-off.

**[Risk] Narration map not loaded when first speak() is called** → TTS handles it. Given network speed and the time it takes for the user to navigate to a meditation and tap Start, the map will almost always be loaded in time.

**[Risk] Cache cleared by iOS mid-meditation** → iOS only clears `Library/Caches/` in the background, never during active playback. If a session starts, audio for that session will complete from cache.

## Migration Plan

1. Add `NarrationEntry` model, run migration, regenerate Prisma client
2. Copy `narration_map.json` to backend `prisma/` and add `SUPABASE_AUDIO_URL` to `.env` and `docker-compose.yml`
3. Extend `seed.ts` with narration seeding using `createMany`
4. Add `src/routes/narrationMap.ts` and mount in `src/index.ts`
5. Rebuild Docker: `docker compose up --build`
6. Verify endpoint: `curl localhost:3005/api/narration-map | head -c 200`
7. Update `MeditationAudioService`: add `networkClient`, fetch map from backend, implement disk cache
8. Update `Container+App.swift` to pass `networkClient` to `MeditationAudioService`
9. Delete `narration_map.json` and `Resources/Narrations/` from iOS project
10. Build iOS: `xcodebuild ... build 2>&1 | tail -20`
