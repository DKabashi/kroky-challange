import AVFoundation
import Combine
import Foundation

/// Drives the completed-workout screen: exposes the immutable summary, owns the
/// looping mascot player, and forwards the "Next" intent to its collaborator.
@MainActor
final class WorkoutSummaryViewModel: ObservableObject {
    let summary: WorkoutCompletionSummary

    private let mascotPlayer: LoopingVideoPlayer
    private let onAdvance: () -> Void

    init(
        summary: WorkoutCompletionSummary,
        mascotVideoName: String,
        onAdvance: @escaping () -> Void
    ) {
        self.summary = summary
        self.mascotPlayer = LoopingVideoPlayer(resourceName: mascotVideoName)
        self.onAdvance = onAdvance
    }

    var mascotVideoPlayer: AVPlayer {
        mascotPlayer.player
    }

    func startMascot() {
        mascotPlayer.play()
    }

    func stopMascot() {
        mascotPlayer.pause()
    }

    func advance() {
        mascotPlayer.pause()
        onAdvance()
    }
}
