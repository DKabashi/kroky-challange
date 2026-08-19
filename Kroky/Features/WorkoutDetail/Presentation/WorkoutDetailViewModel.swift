import Combine
import Foundation

@MainActor
final class WorkoutDetailViewModel: ObservableObject {
    @Published private(set) var workout: Workout?
    @Published private(set) var progress: WorkoutProgress?
    @Published private(set) var errorMessage: String?

    private let repository: any WorkoutProviding
    private let progressStore: any WorkoutProgressStoring

    init(
        repository: any WorkoutProviding,
        progressStore: any WorkoutProgressStoring
    ) {
        self.repository = repository
        self.progressStore = progressStore
        loadWorkout()
    }

    var progressState: WorkoutProgressState {
        guard let workout, let progress else { return .notStarted }
        return progress.state(in: workout)
    }

    var completedExerciseIDs: Set<String> {
        guard let workout, let progress else { return [] }
        return Set(
            workout.exercises
                .filter { progress.isExerciseCompleted($0, in: workout) }
                .map(\.id)
        )
    }

    func prepareForPlayback() {
        guard let workout else { return }

        if progressState == .completed {
            progressStore.resetProgress(for: workout.id)
            refreshProgress()
        }
    }

    func refreshProgress() {
        guard let workout else { return }
        progress = progressStore.progress(for: workout.id)
    }

    private func loadWorkout() {
        do {
            workout = try repository.fetchWorkout()
            refreshProgress()
            errorMessage = nil
        } catch {
            workout = nil
            progress = nil
            errorMessage = error.localizedDescription
        }
    }
}
