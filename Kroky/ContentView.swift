import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: WorkoutDetailViewModel

    init(repository: any WorkoutProviding = BundleWorkoutRepository()) {
        _viewModel = StateObject(
            wrappedValue: WorkoutDetailViewModel(repository: repository)
        )
    }

    var body: some View {
        Group {
            if let workout = viewModel.workout {
                WorkoutDetailView(workout: workout)
            } else {
                ContentUnavailableView(
                    "Workout unavailable",
                    systemImage: "figure.strengthtraining.traditional",
                    description: Text(viewModel.errorMessage ?? "Please try again.")
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentViewPreview: PreviewProvider {
    static var previews: some View {
        ContentView(repository: PreviewWorkoutRepository())
    }
}

private struct PreviewWorkoutRepository: WorkoutProviding {
    func fetchWorkout() throws -> Workout {
        Workout(
            id: "preview",
            eyebrow: "Today",
            title: "Standing balance flow",
            heroImageName: "WorkoutHero",
            overview: WorkoutOverview(
                title: "In today’s workout",
                description: "Slow standing moves that tone legs and improve balance, all supported by the wall. No mat, no jumping, kind to your knees.",
                metrics: [
                    WorkoutMetric(value: "8 min", label: "Duration"),
                    WorkoutMetric(value: "Light", label: "Intensity"),
                    WorkoutMetric(value: "~65", label: "kcal burned")
                ]
            ),
            roundCount: 2,
            exercises: [
                WorkoutExercise(id: "1", title: "Wall-supported standing march", duration: "1 min", imageName: "WorkoutHero"),
                WorkoutExercise(id: "2", title: "Arm reach and calf raise", duration: "1 min", imageName: "WorkoutHero"),
                WorkoutExercise(id: "3", title: "Front kick hold, left", duration: "1 min", imageName: "WorkoutHero"),
                WorkoutExercise(id: "4", title: "Front kick hold, right", duration: "1 min", imageName: "WorkoutHero")
            ],
            callToActionTitle: "Start workout"
        )
    }
}
