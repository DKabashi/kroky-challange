import Foundation

protocol WorkoutProviding {
    func fetchWorkout() throws -> Workout
}
