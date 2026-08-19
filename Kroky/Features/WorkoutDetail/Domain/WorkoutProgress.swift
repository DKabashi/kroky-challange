import Foundation

enum WorkoutProgressState: Equatable, Sendable {
    case notStarted
    case inProgress
    case completed
}

struct WorkoutProgress: Codable, Equatable, Sendable {
    let workoutID: String
    var hasStarted: Bool
    var currentSegmentID: String?
    var completedSegmentIDs: Set<String>
    var completedAt: Date?

    static func notStarted(workoutID: String) -> WorkoutProgress {
        WorkoutProgress(
            workoutID: workoutID,
            hasStarted: false,
            currentSegmentID: nil,
            completedSegmentIDs: [],
            completedAt: nil
        )
    }

    func state(in workout: Workout) -> WorkoutProgressState {
        let segmentIDs = Set(workout.playbackSegments.map(\.id))

        if !segmentIDs.isEmpty, segmentIDs.isSubset(of: completedSegmentIDs) {
            return .completed
        }

        return hasStarted ? .inProgress : .notStarted
    }

    func isExerciseCompleted(_ exercise: WorkoutExercise, in workout: Workout) -> Bool {
        let exerciseSegmentIDs = Set(
            workout.playbackSegments
                .filter { $0.exercise.id == exercise.id }
                .map(\.id)
        )

        return !exerciseSegmentIDs.isEmpty
            && exerciseSegmentIDs.isSubset(of: completedSegmentIDs)
    }
}
