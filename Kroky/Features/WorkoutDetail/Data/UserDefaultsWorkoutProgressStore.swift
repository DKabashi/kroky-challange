import Foundation

@MainActor
struct UserDefaultsWorkoutProgressStore: WorkoutProgressStoring {
    private let userDefaults: UserDefaults
    private let keyPrefix: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        userDefaults: UserDefaults = .standard,
        keyPrefix: String = "workout-progress",
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.keyPrefix = keyPrefix
        self.encoder = encoder
        self.decoder = decoder
    }

    func progress(for workoutID: String) -> WorkoutProgress {
        guard
            let data = userDefaults.data(forKey: key(for: workoutID)),
            let progress = try? decoder.decode(WorkoutProgress.self, from: data),
            progress.workoutID == workoutID
        else {
            return .notStarted(workoutID: workoutID)
        }

        return progress
    }

    func save(_ progress: WorkoutProgress) {
        guard let data = try? encoder.encode(progress) else { return }
        userDefaults.set(data, forKey: key(for: progress.workoutID))
    }

    func resetProgress(for workoutID: String) {
        userDefaults.removeObject(forKey: key(for: workoutID))
    }

    private func key(for workoutID: String) -> String {
        "\(keyPrefix).\(workoutID)"
    }
}
