import AVFoundation

/// Plays a bundled video on a seamless loop.
///
/// Wrapping `AVQueuePlayer` + `AVPlayerLooper` keeps the looping mechanics out
/// of the view model and view, which only need `play()` / `pause()`.
@MainActor
final class LoopingVideoPlayer {
    let player: AVQueuePlayer

    private var looper: AVPlayerLooper?

    init(
        resourceName: String,
        withExtension fileExtension: String = "mp4",
        bundle: Bundle = .main
    ) {
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .advance
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = false
        self.player = queuePlayer

        guard let url = bundle.url(forResource: resourceName, withExtension: fileExtension) else {
            return
        }
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }
}
