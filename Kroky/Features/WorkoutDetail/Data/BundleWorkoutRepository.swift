import Foundation

struct BundleWorkoutRepository: WorkoutProviding {
    private let bundle: Bundle
    private let decoder: JSONDecoder

    init(bundle: Bundle = .main, decoder: JSONDecoder = JSONDecoder()) {
        self.bundle = bundle
        self.decoder = decoder
    }

    func fetchWorkout() throws -> Workout {
        guard let url = bundle.url(forResource: "workout", withExtension: "json") else {
            throw BundleWorkoutRepositoryError.missingResource
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(Workout.self, from: data)
        } catch let error as BundleWorkoutRepositoryError {
            throw error
        } catch {
            throw BundleWorkoutRepositoryError.invalidResource(underlying: error)
        }
    }
}

enum BundleWorkoutRepositoryError: LocalizedError {
    case missingResource
    case invalidResource(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingResource:
            "The bundled workout data could not be found."
        case .invalidResource:
            "The bundled workout data could not be read."
        }
    }
}
