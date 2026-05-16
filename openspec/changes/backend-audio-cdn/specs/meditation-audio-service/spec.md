## MODIFIED Requirements

### Requirement: MeditationAudioService fetches narration map from backend
`MeditationAudioService` SHALL accept a `networkClient: NetworkClientProtocol` constructor parameter and SHALL fetch the narration map from `GET /api/narration-map` once at initialisation via an async `Task`. The map SHALL be stored as `[String: String]` mapping instruction text to full audio URLs. If the fetch fails, the map remains empty and all narrations fall back to `AVSpeechSynthesizer`.

#### Scenario: Map loaded on init
- **WHEN** `MeditationAudioService` is initialised
- **THEN** a background Task starts to fetch the narration map from the backend

#### Scenario: Map unavailable — TTS fallback
- **WHEN** the backend is unreachable at init time and `speak()` is called
- **THEN** `AVSpeechSynthesizer` handles the instruction

### Requirement: speak() downloads and caches audio files on first play
`speak(_:onComplete:)` SHALL remain synchronous. When an instruction has a URL in the narration map, it SHALL start an internal `Task` that: checks `Library/Caches/narrations/<filename>` for a cached file; if found plays it immediately via `AVAudioPlayer`; if not found downloads the file from the URL, writes it to the cache directory, then plays it. If the download fails, it SHALL fall back to `AVSpeechSynthesizer`.

#### Scenario: Cache miss — download and play
- **WHEN** `speak()` is called for an instruction whose audio has never been downloaded
- **THEN** the file is downloaded from the Supabase URL, saved to `Library/Caches/narrations/`, and played via `AVAudioPlayer`

#### Scenario: Cache hit — instant play
- **WHEN** `speak()` is called for an instruction whose audio is already in the cache
- **THEN** the file is played directly from disk without a network request

#### Scenario: Download fails — silent, user advances manually
- **WHEN** `speak()` is called and the Supabase URL is unreachable
- **THEN** nothing is played; the instruction text is visible on screen so the user reads it and advances manually

#### Scenario: MeditationPlayerViewModel unaffected
- **WHEN** `MeditationPlayerViewModel` calls `speak(_:onComplete:)`
- **THEN** the call site is identical to before — no async/await changes required

## REMOVED Requirements

### Requirement: MeditationAudioService loads narration map from app bundle
**Reason**: Replaced by backend API fetch. Bundle-based loading is no longer needed.
**Migration**: Narration map is served by `GET /api/narration-map`. The `narration_map.json` bundle file is deleted from the iOS project.

### Requirement: MeditationAudioService plays MP3s from app bundle
**Reason**: Replaced by CDN download + local disk cache. Bundle MP3s are deleted.
**Migration**: Audio files are hosted on Supabase Storage. First play downloads and caches; subsequent plays are instant from disk.

### Requirement: AVSpeechSynthesizer fallback for narrations
**Reason**: Removed in favour of silent fallback. The instruction text is visible on screen — the user reads it and advances manually. TTS fallback added complexity and inconsistent audio quality without meaningful benefit.
**Migration**: `AVSpeechSynthesizer`, its delegate, and related properties are removed from `MeditationAudioService`. No replacement.
