import AVFoundation
import Combine
import Foundation

@MainActor
final class WorkoutPlayerViewModel: ObservableObject {
    enum Phase: Equatable {
        case preparing
        case countdown
        case playing
        case failed
        case completed
    }

    @Published private(set) var phase: Phase = .preparing
    @Published private(set) var currentSegmentIndex = 0
    @Published private(set) var countdownRemaining = 10
    @Published private(set) var isPaused = false
    @Published private(set) var segmentProgress = 0.0
    @Published private(set) var elapsedActiveSeconds = 0.0
    @Published private(set) var caloriesBurned = 0.0

    let player = AVPlayer()

    private let workout: Workout
    private let segments: [WorkoutSegment]
    private let cache: any VideoCaching
    private let progressStore: any WorkoutProgressStoring
    private var workoutProgress: WorkoutProgress

    private var preparationTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var currentPreparationID = UUID()
    private var endCancellable: AnyCancellable?
    private var failureCancellable: AnyCancellable?
    private var itemStatusObservation: NSKeyValueObservation?
    private var timeObserver: Any?

    private var currentItemDuration = 0.0
    private var currentPosition = 0.0
    private var completedElapsedSeconds = 0.0
    private var completedCalories = 0.0
    private var hasStarted = false
    private var isStopped = false

    init(
        workout: Workout,
        cache: any VideoCaching,
        progressStore: any WorkoutProgressStoring
    ) {
        self.workout = workout
        self.segments = workout.playbackSegments
        self.cache = cache
        self.progressStore = progressStore

        var savedProgress = progressStore.progress(for: workout.id)
        let validSegmentIDs = Set(workout.playbackSegments.map(\.id))
        savedProgress.completedSegmentIDs.formIntersection(validSegmentIDs)
        self.workoutProgress = savedProgress

        if
            let currentSegmentID = savedProgress.currentSegmentID,
            let savedIndex = workout.playbackSegments.firstIndex(where: { $0.id == currentSegmentID })
        {
            currentSegmentIndex = savedIndex
        } else if let firstIncompleteIndex = workout.playbackSegments.firstIndex(
            where: { !savedProgress.completedSegmentIDs.contains($0.id) }
        ) {
            currentSegmentIndex = firstIncompleteIndex
        }

        let completedSegments = workout.playbackSegments.filter {
            savedProgress.completedSegmentIDs.contains($0.id)
        }
        completedElapsedSeconds = completedSegments.reduce(0) {
            $0 + $1.exercise.durationSeconds
        }
        completedCalories = completedSegments.reduce(0) {
            $0 + ($1.exercise.kcalPerMinute * $1.exercise.durationSeconds / 60)
        }
        elapsedActiveSeconds = completedElapsedSeconds
        caloriesBurned = completedCalories

        player.actionAtItemEnd = .pause
        player.automaticallyWaitsToMinimizeStalling = true
        player.preventsDisplaySleepDuringVideoPlayback = true
        installPeriodicTimeObserver()
    }

    deinit {
        preparationTask?.cancel()
        countdownTask?.cancel()
        endCancellable?.cancel()
        failureCancellable?.cancel()
        itemStatusObservation?.invalidate()
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }

    var totalSegmentCount: Int { segments.count }

    /// A display-ready snapshot of the finished workout for the summary screen.
    var completionSummary: WorkoutCompletionSummary {
        let completedCount = segments.filter {
            workoutProgress.completedSegmentIDs.contains($0.id)
        }.count

        return WorkoutCompletionSummary(
            workoutTitle: workout.title,
            durationSeconds: elapsedActiveSeconds,
            caloriesBurned: caloriesBurned,
            completedExerciseCount: completedCount,
            totalExerciseCount: segments.count
        )
    }

    var currentSegment: WorkoutSegment? {
        guard segments.indices.contains(currentSegmentIndex) else { return nil }
        return segments[currentSegmentIndex]
    }

    var currentTitle: String {
        currentSegment?.exercise.title ?? workout.title
    }

    var currentRepetitionText: String {
        guard let segment = currentSegment else { return "" }
        return "\(segment.repetition)/\(workout.roundCount)"
    }

    var currentTitleWithRepetition: String {
        "\(currentTitle) \(currentRepetitionText)"
    }

    var nextExerciseTitle: String? {
        guard let currentSegment else { return nil }
        return segments
            .dropFirst(currentSegmentIndex + 1)
            .first(where: { $0.exercise.id != currentSegment.exercise.id })?
            .exercise.title
    }

    var elapsedTimeText: String {
        let totalSeconds = max(Int(elapsedActiveSeconds.rounded(.down)), 0)
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    var calorieText: String {
        String(max(Int(caloriesBurned.rounded(.down)), 0))
    }

    func progress(for segmentIndex: Int) -> Double {
        guard segments.indices.contains(segmentIndex) else { return 0 }
        if workoutProgress.completedSegmentIDs.contains(segments[segmentIndex].id) { return 1 }
        if segmentIndex == currentSegmentIndex { return segmentProgress }
        return 0
    }

    func start() {
        guard !hasStarted, !segments.isEmpty else { return }
        hasStarted = true
        isStopped = false
        workoutProgress.hasStarted = true
        workoutProgress.currentSegmentID = currentSegment?.id
        workoutProgress.completedAt = nil
        saveProgress()
        prepareCurrentSegment(countdownSeconds: 10, resumeAt: 0)
    }

    func togglePause() {
        switch phase {
        case .countdown:
            if isPaused {
                isPaused = false
                runCountdown()
            } else {
                isPaused = true
                countdownTask?.cancel()
                countdownTask = nil
            }
        case .playing:
            if isPaused {
                isPaused = false
                player.play()
            } else {
                updateProgress(using: player.currentTime())
                isPaused = true
                player.pause()
            }
        case .preparing, .failed, .completed:
            break
        }
    }

    func pauseForBackground() {
        guard !isPaused, phase == .countdown || phase == .playing else { return }
        togglePause()
    }

    func goToPreviousSegment() {
        guard currentSegmentIndex > 0 else { return }
        commitCurrentProgress(useFullDuration: false)
        currentSegmentIndex -= 1
        workoutProgress.currentSegmentID = currentSegment?.id
        saveProgress()
        prepareCurrentSegment(countdownSeconds: 3, resumeAt: 0)
    }

    func goToNextSegment() {
        commitCurrentProgress(useFullDuration: false)
        advanceToNextSegment()
    }

    func retry() {
        guard phase == .failed, let currentSegment else { return }
        let resumePosition = currentPosition
        let countdown = currentSegmentIndex == 0 && completedElapsedSeconds == 0 ? 10 : 3
        prepareCurrentSegment(
            countdownSeconds: countdown,
            resumeAt: resumePosition,
            invalidating: currentSegment.exercise.videoResource
        )
    }

    func stop() {
        guard !isStopped else { return }
        isStopped = true
        if workoutProgress.state(in: workout) != .completed {
            workoutProgress.currentSegmentID = currentSegment?.id
            saveProgress()
        }
        preparationTask?.cancel()
        countdownTask?.cancel()
        removeCurrentItemObservers()
        player.pause()
        player.replaceCurrentItem(with: nil)
    }

    /// Clears all saved progress so the workout returns to its clean, not-started
    /// state. Used by the summary screen's "Next" action.
    func resetForFreshStart() {
        isStopped = true
        preparationTask?.cancel()
        countdownTask?.cancel()
        removeCurrentItemObservers()
        player.pause()
        player.replaceCurrentItem(with: nil)
        progressStore.resetProgress(for: workout.id)
        workoutProgress = .notStarted(workoutID: workout.id)
    }

    private func prepareCurrentSegment(
        countdownSeconds: Int,
        resumeAt resumePosition: Double,
        invalidating resourceToInvalidate: VideoResource? = nil
    ) {
        guard let segment = currentSegment else {
            completeWorkout()
            return
        }

        preparationTask?.cancel()
        countdownTask?.cancel()
        removeCurrentItemObservers()
        player.pause()
        isPaused = false
        phase = .preparing

        let preparationID = UUID()
        currentPreparationID = preparationID
        let resource = segment.exercise.videoResource

        preparationTask = Task { [weak self, cache] in
            do {
                if let resourceToInvalidate {
                    await cache.remove(resourceToInvalidate)
                }

                let localURL = try await cache.localURL(for: resource)
                try Task.checkCancellation()

                let asset = AVURLAsset(url: localURL)
                let (isPlayable, duration) = try await asset.load(.isPlayable, .duration)
                try Task.checkCancellation()

                let durationSeconds = CMTimeGetSeconds(duration)
                guard isPlayable, durationSeconds.isFinite, durationSeconds > 0 else {
                    throw WorkoutPlayerError.unplayableVideo
                }

                guard let self, self.currentPreparationID == preparationID else { return }

                let item = AVPlayerItem(asset: asset)
                self.player.replaceCurrentItem(with: item)
                self.currentItemDuration = durationSeconds
                self.currentPosition = min(max(resumePosition, 0), durationSeconds)
                await self.player.seek(
                    to: CMTime(seconds: self.currentPosition, preferredTimescale: 600),
                    toleranceBefore: .zero,
                    toleranceAfter: .zero
                )
                self.installObservers(for: item)
                self.updatePublishedMetrics()
                self.beginCountdown(seconds: countdownSeconds)
            } catch is CancellationError {
                return
            } catch {
                guard let self, self.currentPreparationID == preparationID else { return }
                self.showFailure()
            }
        }
    }

    private func beginCountdown(seconds: Int) {
        player.pause()
        countdownRemaining = seconds
        phase = .countdown
        isPaused = false
        runCountdown()
    }

    private func runCountdown() {
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }

                guard let self, self.phase == .countdown, !self.isPaused else { return }

                if self.countdownRemaining > 1 {
                    self.countdownRemaining -= 1
                } else {
                    self.countdownRemaining = 0
                    self.beginPlayback()
                    return
                }
            }
        }
    }

    private func beginPlayback() {
        countdownTask = nil
        phase = .playing
        isPaused = false
        player.play()
    }

    private func playbackDidEnd() {
        guard phase == .playing else { return }
        commitCurrentProgress(useFullDuration: true)
        advanceToNextSegment()
    }

    private func advanceToNextSegment() {
        if let currentSegment {
            workoutProgress.completedSegmentIDs.insert(currentSegment.id)
        }

        guard currentSegmentIndex + 1 < segments.count else {
            completeWorkout()
            return
        }

        currentSegmentIndex += 1
        workoutProgress.currentSegmentID = currentSegment?.id
        saveProgress()
        prepareCurrentSegment(countdownSeconds: 3, resumeAt: 0)
    }

    private func completeWorkout() {
        preparationTask?.cancel()
        countdownTask?.cancel()
        removeCurrentItemObservers()
        player.pause()
        player.replaceCurrentItem(with: nil)
        segmentProgress = 1
        isPaused = false
        workoutProgress.hasStarted = true
        workoutProgress.completedSegmentIDs.formUnion(segments.map(\.id))
        workoutProgress.currentSegmentID = nil
        workoutProgress.completedAt = Date()
        saveProgress()
        phase = .completed
    }

    private func showFailure() {
        countdownTask?.cancel()
        countdownTask = nil
        updateProgress(using: player.currentTime())
        player.pause()
        isPaused = true
        phase = .failed
    }

    private func installPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self, self.phase == .playing else { return }
                self.updateProgress(using: time)
            }
        }
    }

    private func installObservers(for item: AVPlayerItem) {
        endCancellable = NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.playbackDidEnd()
                }
            }

        failureCancellable = NotificationCenter.default
            .publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: item)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.showFailure()
                }
            }

        itemStatusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            Task { @MainActor [weak self] in
                self?.showFailure()
            }
        }
    }

    private func removeCurrentItemObservers() {
        endCancellable?.cancel()
        endCancellable = nil
        failureCancellable?.cancel()
        failureCancellable = nil
        itemStatusObservation?.invalidate()
        itemStatusObservation = nil
    }

    private func updateProgress(using time: CMTime) {
        let seconds = CMTimeGetSeconds(time)
        guard seconds.isFinite else { return }
        currentPosition = min(max(seconds, 0), currentItemDuration)
        updatePublishedMetrics()
    }

    private func updatePublishedMetrics() {
        let duration = max(currentItemDuration, 0)
        segmentProgress = duration > 0 ? min(max(currentPosition / duration, 0), 1) : 0
        elapsedActiveSeconds = completedElapsedSeconds + currentPosition

        let rate = currentSegment?.exercise.kcalPerMinute ?? 0
        caloriesBurned = completedCalories + (rate * currentPosition / 60)
    }

    private func commitCurrentProgress(useFullDuration: Bool) {
        if useFullDuration {
            currentPosition = currentItemDuration
        } else {
            updateProgress(using: player.currentTime())
        }

        updatePublishedMetrics()
        completedElapsedSeconds = elapsedActiveSeconds
        completedCalories = caloriesBurned
        currentPosition = 0
        currentItemDuration = 0
        segmentProgress = 0
    }

    private func saveProgress() {
        progressStore.save(workoutProgress)
    }
}

enum WorkoutPlayerError: LocalizedError {
    case unplayableVideo

    var errorDescription: String? {
        "The downloaded video is not playable."
    }
}
