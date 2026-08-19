import Foundation

/// The audible cues played during a workout's countdown.
enum WorkoutCue {
    /// A short pip for each of the final countdown seconds (…3, 2, 1).
    case countdownTick
    /// A brighter tone marking the moment the exercise starts.
    case go
}

/// Plays short countdown cues. Kept behind a protocol so the view model stays
/// free of `AVFoundation` and can be driven by a silent test double.
///
/// Callable from any thread (`Sendable`): implementations must do their own
/// work off the main thread so a cue never blocks UI or video playback.
protocol WorkoutSoundPlaying: Sendable {
    /// Warms up the audio pipeline so the first cue fires without latency.
    func prepare()
    func play(_ cue: WorkoutCue)
}
