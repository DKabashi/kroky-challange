import Foundation

/// A presentation-ready snapshot of a finished workout.
///
/// The type is a pure value with no UIKit/AVFoundation dependencies so the
/// formatting and progress rules can be unit-tested in isolation.
struct WorkoutCompletionSummary: Equatable, Sendable {
    let workoutTitle: String
    let durationSeconds: Double
    let caloriesBurned: Double
    let completedExerciseCount: Int
    let totalExerciseCount: Int

    var durationText: String {
        let totalSeconds = max(Int(durationSeconds.rounded()), 0)
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    var caloriesText: String {
        "\(roundedCalories) kcal"
    }

    var exercisesText: String {
        "\(completedExerciseCount) of \(totalExerciseCount)"
    }

    private var roundedCalories: Int {
        max(Int(caloriesBurned.rounded()), 0)
    }
}
