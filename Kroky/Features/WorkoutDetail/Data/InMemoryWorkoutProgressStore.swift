import Foundation

@MainActor
final class InMemoryWorkoutProgressStore: WorkoutProgressStoring {
    private var progressByWorkoutID: [String: WorkoutProgress] = [:]

    func progress(for workoutID: String) -> WorkoutProgress {
        progressByWorkoutID[workoutID] ?? .notStarted(workoutID: workoutID)
    }

    func save(_ progress: WorkoutProgress) {
        progressByWorkoutID[progress.workoutID] = progress
    }

    func resetProgress(for workoutID: String) {
        progressByWorkoutID.removeValue(forKey: workoutID)
    }
}
