import Foundation

struct Workout: Codable, Identifiable, Equatable {
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
}

struct WorkoutOverview: Codable, Equatable {
    let title: String
    let description: String
    let metrics: [WorkoutMetric]
}

struct WorkoutMetric: Codable, Equatable {
    let value: String
    let label: String
}

struct WorkoutExercise: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let duration: String
    let imageName: String
}
