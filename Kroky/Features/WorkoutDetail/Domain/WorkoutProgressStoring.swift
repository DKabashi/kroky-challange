import Foundation

@MainActor
protocol WorkoutProgressStoring {
    func progress(for workoutID: String) -> WorkoutProgress
    func save(_ progress: WorkoutProgress)
    func resetProgress(for workoutID: String)
}
