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
            id: "pilates-workout-preview",
            eyebrow: "Today",
            title: "Pilates workout",
            heroImageName: "WorkoutHero",
            overview: WorkoutOverview(
                title: "In today’s workout",
                description: "Four beginner-friendly Pilates exercises focused on strength and control. Complete each 15-second move twice.",
                metrics: [
                    WorkoutMetric(value: "8 min", label: "Duration"),
                    WorkoutMetric(value: "Light", label: "Intensity"),
                    WorkoutMetric(value: "~65", label: "kcal burned")
                ]
            ),
            roundCount: 2,
            exercises: [
                WorkoutExercise(id: "p-001", title: "Standing Squats", duration: "15 sec", durationSeconds: 15.042, imageName: "WorkoutHero", videoURL: URL(string: "https://workoutvideos.vercel.app/p-001.mp4")!, videoVersion: 1, kcalPerMinute: 12.1, style: "Pilates", difficulty: 1),
                WorkoutExercise(id: "p-002", title: "Flat Ab Crunches", duration: "15 sec", durationSeconds: 15.042, imageName: "WorkoutHero", videoURL: URL(string: "https://workoutvideos.vercel.app/p-002.mp4")!, videoVersion: 1, kcalPerMinute: 14, style: "Pilates", difficulty: 1),
                WorkoutExercise(id: "p-003", title: "Pushups", duration: "15 sec", durationSeconds: 15.042, imageName: "WorkoutHero", videoURL: URL(string: "https://workoutvideos.vercel.app/p-003.mp4")!, videoVersion: 1, kcalPerMinute: 12.5, style: "Pilates", difficulty: 1),
                WorkoutExercise(id: "p-004", title: "Lunges", duration: "15 sec", durationSeconds: 15.042, imageName: "WorkoutHero", videoURL: URL(string: "https://workoutvideos.vercel.app/p-004.mp4")!, videoVersion: 1, kcalPerMinute: 11.4, style: "Pilates", difficulty: 1)
            ],
            callToActionTitle: "Start workout"
        )
    }
}
