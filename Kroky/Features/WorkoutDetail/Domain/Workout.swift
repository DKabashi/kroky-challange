import Foundation

struct Workout: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let eyebrow: String
    let title: String
    let heroImageName: String
    let overview: WorkoutOverview
    let roundCount: Int
    let exercises: [WorkoutExercise]
    let callToActionTitle: String

    var exerciseSummary: String {
        "\(exercises.count) exercises · \(roundCount) rounds"
    }

    var displayOverview: WorkoutOverview {
        WorkoutOverview(
            title: overview.title,
            description: overview.description,
            metrics: [
                WorkoutMetric(value: estimatedDurationText, label: "Duration"),
                WorkoutMetric(value: intensityText, label: "Intensity"),
                WorkoutMetric(value: "~\(Int(estimatedCalories.rounded()))", label: "kcal burned")
            ]
        )
    }

    var videoResources: [VideoResource] {
        exercises.map(\.videoResource)
    }

    var playbackSegments: [WorkoutSegment] {
        guard roundCount > 0 else { return [] }
        return exercises.flatMap { exercise in
            (1...roundCount).map { repetition in
                WorkoutSegment(exercise: exercise, repetition: repetition)
            }
        }
    }

    private var estimatedDurationSeconds: Double {
        exercises.reduce(0) { $0 + $1.durationSeconds } * Double(max(roundCount, 0))
    }

    private var estimatedCalories: Double {
        exercises.reduce(0) { total, exercise in
            total + (exercise.kcalPerMinute * exercise.durationSeconds / 60)
        } * Double(max(roundCount, 0))
    }

    private var estimatedDurationText: String {
        let roundedMinutes = max(Int((estimatedDurationSeconds / 60).rounded()), 1)
        return "\(roundedMinutes) min"
    }

    private var intensityText: String {
        switch exercises.map(\.difficulty).max() ?? 1 {
        case ...1: "Light"
        case 2: "Moderate"
        default: "Challenging"
        }
    }
}

struct WorkoutOverview: Codable, Equatable, Sendable {
    let title: String
    let description: String
    let metrics: [WorkoutMetric]
}

struct WorkoutMetric: Codable, Equatable, Sendable {
    let value: String
    let label: String
}

struct WorkoutExercise: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let duration: String
    let durationSeconds: Double
    let imageName: String
    let videoURL: URL
    let videoVersion: Int
    let kcalPerMinute: Double
    let style: String
    let difficulty: Int

    var videoResource: VideoResource {
        VideoResource(
            id: id,
            remoteURL: videoURL,
            version: videoVersion
        )
    }
}

struct WorkoutSegment: Identifiable, Equatable, Sendable {
    let exercise: WorkoutExercise
    let repetition: Int

    var id: String { "\(exercise.id)-\(repetition)" }
}

struct VideoResource: Hashable, Sendable {
    let id: String
    let remoteURL: URL
    let version: Int

    static func == (lhs: VideoResource, rhs: VideoResource) -> Bool {
        lhs.remoteURL == rhs.remoteURL && lhs.version == rhs.version
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(remoteURL)
        hasher.combine(version)
    }
}
