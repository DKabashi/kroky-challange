# Kroky — Workout Session Player

A native iOS workout player built with SwiftUI and AVFoundation. Kroky streams a
guided, video-led workout: it downloads each exercise clip, runs pre-clip
countdowns, tracks progress and calories, and lands on an animated summary — with
graceful handling for the moments a video fails to load.

> Built as a focused take-home: one real feature, the session player, top to bottom.

## Screens

| Detail | In progress / Completed | Countdown | Player | Error | Summary |
|--------|-------------------------|-----------|--------|-------|---------|
| Start a workout | Resume or review | "Get ready" pre-roll | Video + controls | Retry on failure | Logged result |

## How playback works

The workout is a list of **exercises**, each with a remote `.mp4`. Every exercise
repeats `roundCount` times, so the domain flattens it into an ordered list of
**segments** (`Workout.playbackSegments`) — 4 exercises × 2 rounds = 8 clips.

`WorkoutPlayerViewModel` drives a small state machine over those segments:

```
preparing → countdown → playing → (next segment) … → completed
                ↑                        │
                └──────── failed ────────┘
```

- **`preparing`** — the next clip's video is fetched from cache (or downloaded),
  the asset is validated (`isPlayable`, finite non-zero duration), loaded into the
  shared `AVPlayer`, and seeked to the resume position.
- **`countdown`** — playback is held while an on-screen number ticks down.
  The **first** clip gets a **10s** countdown; every subsequent clip gets **3s**.
- **`playing`** — the `AVPlayer` plays the clip. A periodic time observer updates
  the progress bar, elapsed time, and calories (`kcalPerMinute × elapsed`). When the
  item plays to the end, the segment is marked complete and the next one prepares.
- **`failed`** — any load/playback error routes here. Progress is preserved;
  **Try again** invalidates the cached file and re-downloads from the same position.
- **`completed`** — all segments done; a summary with the mascot animation is shown.

### Interactions
- **Tap anywhere** toggles pause (works during both countdown and playback).
- **Skip / previous** jump between clips; previous is disabled on the first clip.
- **Backgrounding the app** auto-pauses the session.
- **Close (✕)** persists progress so the workout can be resumed later.

### Countdown sound (optional feature, implemented)
`CountdownSoundPlayer` synthesizes its cues at runtime — no audio assets. A short
pip plays on each of the final **3** seconds, and a brighter two-note "go" cue fires
when playback begins. All audio work runs on a private serial queue (off the main
thread), uses the `.playback` category so it's audible with the silent switch on,
and `.mixWithOthers` so the user's own music keeps playing.

## Video handling & caching

`RemoteVideoCache` is an `actor` that owns downloads and on-disk storage:

- Clips are cached in `Caches/KrokyVideoCache`, keyed by a SHA-256 of
  `version|url` so a bumped `videoVersion` transparently invalidates old files.
- In-flight downloads are de-duplicated — concurrent requests for the same clip
  await one task.
- Responses are validated (2xx status, `video/*` MIME type, non-empty file) before
  being committed with an atomic move.
- `prefetch` warms the opening clip first, then fills the rest with bounded
  concurrency, so a workout can start before everything has arrived.

## Architecture

MVVM with a clean feature-sliced layout. Each feature separates `Domain`,
`Data`, `Media`, and `Presentation`, and depends on protocols
(`VideoCaching`, `WorkoutProgressStoring`, `WorkoutSoundPlaying`,
`WorkoutProviding`) so views and view models are testable and swappable.

```
Kroky/
├─ DesignSystem/            Colors, typography, spacing, icons, shadows
├─ Resources/              workout.json, mascot video
└─ Features/
   ├─ WorkoutDetail/       Start screen + workout model/repository/progress
   ├─ WorkoutPlayer/       The session player (this feature)
   │  ├─ Data/            RemoteVideoCache
   │  ├─ Domain/          WorkoutSoundPlaying
   │  ├─ Media/           CountdownSoundPlayer, ToneSynthesizer
   │  └─ Presentation/    WorkoutPlayerView, ViewModel, PlayerLayerView
   └─ WorkoutSummary/      Completion screen + mascot animation
```

Video rendering uses a thin `AVPlayerLayer`-backed `UIViewRepresentable`
(`PlayerLayerView`) rather than `VideoPlayer`, for full control over gravity and
lifecycle. Workout content is loaded from a bundled `workout.json`; progress is
held by an in-memory store behind `WorkoutProgressStoring` (easy to swap for
persistence).

## Running

Open `Kroky.xcodeproj` in Xcode and run on a simulator or device (iOS 26.5+,
SwiftUI). No third-party dependencies. Exercise videos stream from a hosted
endpoint, so a network connection is needed on first play; the error screen covers
offline / failed loads.
