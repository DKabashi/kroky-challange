import Combine
import Foundation

final class WorkoutDetailViewModel: ObservableObject {
    @Published private(set) var workout: Workout?
    @Published private(set) var errorMessage: String?

    private let repository: any WorkoutProviding

    init(repository: any WorkoutProviding) {
        self.repository = repository
        loadWorkout()
    }

    private func loadWorkout() {
        do {
            workout = try repository.fetchWorkout()
            errorMessage = nil
        } catch {
            workout = nil
            errorMessage = error.localizedDescription
        }
    }
}
