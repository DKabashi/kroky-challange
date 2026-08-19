import AVFoundation

/// Plays the countdown cues by synthesising each one once and reusing a
/// prepared `AVAudioPlayer` per cue.
///
/// Every audio operation — session activation, synthesis, decoding, and
/// playback — is confined to a private serial queue. That keeps the type
/// thread-safe without locks and, crucially, keeps all blocking calls off the
/// main thread: `play(_:)` only enqueues, so a cue never delays the UI or the
/// video's own `play()`.
///
/// The audio session is set to `.playback` so cues are heard even when the
/// silent switch is on — a guided workout needs its "go" to be audible — while
/// `.mixWithOthers` leaves any music the user is playing untouched.
final class CountdownSoundPlayer: WorkoutSoundPlaying, @unchecked Sendable {
    static let shared = CountdownSoundPlayer()

    /// The notes each cue is built from. Kept declarative so tuning a sound is a
    /// one-line change with no synthesis or playback code to touch.
    private static let recipes: [WorkoutCue: [Tone]] = [
        .countdownTick: [Tone(frequency: 880, duration: 0.12)],
        .go: [
            Tone(frequency: 783.99, duration: 0.12),   // G5
            Tone(frequency: 1174.66, duration: 0.24)   // D6 — a bright step up
        ]
    ]

    /// Serialises access to `players`/`isConfigured` and runs the blocking audio
    /// work off the main thread. `.userInitiated` keeps cue latency low.
    private let queue = DispatchQueue(label: "com.kroky.countdown-sound", qos: .userInitiated)

    // Both touched only on `queue`.
    private var players: [WorkoutCue: AVAudioPlayer] = [:]
    private var isConfigured = false

    private init() {}

    func prepare() {
        queue.async { [weak self] in
            self?.configureIfNeeded()
        }
    }

    func play(_ cue: WorkoutCue) {
        queue.async { [weak self] in
            guard let self else { return }
            self.configureIfNeeded()
            guard let player = self.players[cue] else { return }
            player.currentTime = 0
            player.play()
        }
    }

    /// Runs on `queue`. Activates the session and builds every prepared player
    /// exactly once, so subsequent cues are a lock-free dictionary lookup.
    private func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        activateSession()
        for (cue, tones) in Self.recipes {
            let peak = cue == .go ? 0.7 : 0.6
            guard let player = try? AVAudioPlayer(
                data: ToneSynthesizer.wavData(for: tones, peakAmplitude: peak)
            ) else { continue }
            player.prepareToPlay()
            players[cue] = player
        }
    }

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}
