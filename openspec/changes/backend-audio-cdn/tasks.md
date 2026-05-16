## 1. Backend — Prisma Schema & Environment

- [x] 1.1 Add `NarrationEntry` model to `prisma/schema.prisma`: `id Int @id @default(autoincrement())`, `instruction String @unique`, `audioUrl String`
- [x] 1.2 Add `SUPABASE_AUDIO_URL=https://mvhqstlitwflobkstyxd.supabase.co/storage/v1/object/public/meditations` to `focusonyourself_backend/.env`
- [x] 1.3 Add `SUPABASE_AUDIO_URL` to `docker-compose.yml` environment section
- [x] 1.4 Run `DATABASE_URL="file:./prisma/dev.db" npx prisma migrate dev --name add-narration-entries` to generate migration SQL
- [x] 1.5 Run `DATABASE_URL="file:./prisma/dev.db" npx prisma generate` to regenerate Prisma client

## 2. Backend — Seed

- [x] 2.1 Copy `narration_map.json` from iOS bundle (`FocusOnYourself/Resources/narration_map.json`) to `focusonyourself_backend/prisma/narration_map.json`
- [x] 2.2 Add `seedNarrationEntries()` to `prisma/seed.ts` — check `prisma.narrationEntry.count() > 0` and skip; otherwise read `narration_map.json` via `process.cwd()` path, build `audioUrl` as `${SUPABASE_AUDIO_URL}/${filename}.mp3` for each entry, call `prisma.narrationEntry.createMany({ data: [...] })`
- [x] 2.3 Call `seedNarrationEntries()` from `main()` alongside existing seed functions
- [x] 2.4 Build: `npm run build`
- [x] 2.5 Run `DATABASE_URL="file:./prisma/dev.db" SUPABASE_AUDIO_URL="https://mvhqstlitwflobkstyxd.supabase.co/storage/v1/object/public/meditations" npx prisma db seed` and verify narration entries are inserted
- [x] 2.6 Spot-check: confirm a sample `audioUrl` looks like `https://mvhqstlitwflobkstyxd.supabase.co/storage/v1/object/public/meditations/morning-001_step0.mp3`
- [x] 2.7 Run seed a second time and confirm count is unchanged (idempotent)

## 3. Backend — Narration Map Endpoint

- [x] 3.1 Create `src/routes/narrationMap.ts` with `GET /` route handler that queries all `NarrationEntry` rows and returns `Object.fromEntries(entries.map(e => [e.instruction, e.audioUrl]))`
- [x] 3.2 Mount the narration map router in `src/index.ts` at `/api/narration-map`
- [x] 3.3 Rebuild Docker: `docker compose up --build`
- [x] 3.4 Verify: `curl "localhost:3005/api/narration-map" | python3 -m json.tool | head -20` — confirm JSON object with instruction keys and Supabase URL values

## 4. iOS — MeditationAudioService Rewrite

- [ ] 4.1 Read `MeditationAudioService.swift` in full before editing to note all existing properties and methods
- [ ] 4.2 Add `private let networkClient: NetworkClientProtocol` property
- [ ] 4.3 Add `init(networkClient: NetworkClientProtocol)` — call `super.init()`, set delegate, configure audio session, start `Task { await fetchNarrationMap() }`
- [ ] 4.4 Replace `loadNarrationMap()` with `fetchNarrationMap() async` — calls `networkClient.get("/api/narration-map")` decoded as `[String: String]`, assigns to `narrationMap`; on error leaves map empty (TTS fallback handles it)
- [ ] 4.5 Add `private func cachedAudio(for urlString: String) async -> URL?` — checks `Library/Caches/narrations/<filename>`, downloads and caches if missing, returns nil on failure
- [ ] 4.6 Update `speak(_:onComplete:)` — when `narrationMap[text]` returns a URL, start a `Task` that calls `cachedAudio(for:)` and plays from local file via `AVAudioPlayer` if successful; if nil (download failed) or no map entry, do nothing — user reads the instruction on screen and advances manually
- [ ] 4.7 Remove `AVSpeechSynthesizer`, its delegate extension, `synthesizer` property, `currentUtterance` property, and `bestEnglishVoice` from `MeditationAudioService` — no longer needed

## 5. iOS — DI and Cleanup

- [x] 5.1 Update `meditationAudioService` registration in `Container+App.swift` to pass `self.networkClient()` to the initialiser
- [x] 5.2 Build the iOS project — no compilation errors
- [x] 5.3 Delete `FocusOnYourself/Resources/narration_map.json` from the iOS project
- [x] 5.4 Delete the entire `FocusOnYourself/Resources/Narrations/` folder (135 MP3 files) from the iOS project
- [x] 5.5 Build the iOS project — no compilation errors

## 6. Verification

- [ ] 6.1 Run the app in Simulator with backend running — start a morning meditation and confirm narration audio plays (first play downloads, subsequent plays from cache)
- [ ] 6.2 Check `Library/Caches/narrations/` in the simulator to confirm MP3 files are being written
- [ ] 6.3 Run the same meditation step again — confirm it plays instantly without a network request (cache hit)
- [ ] 6.4 Stop the backend and run a meditation — confirm nothing plays and the instruction text is visible on screen; user can advance manually
