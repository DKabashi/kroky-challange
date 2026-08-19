import SwiftUI

/// Semantic icon names keep feature code independent from the underlying icon set.
///
/// The source library uses Material Symbols Rounded. This iOS implementation maps
/// those meanings to native SF Symbols so rendering, accessibility and weight
/// variants follow the platform automatically.
enum KrokyIcon: String, CaseIterable, Identifiable {
    case add
    case send
    case balance
    case bedtime
    case energy
    case heart
    case check
    case chevronRight
    case close
    case delete
    case run
    case egg
    case error
    case exercise
    case hourglass
    case info
    case flame
    case logout
    case weight
    case noMeals
    case play
    case restaurant
    case satisfied
    case stressed
    case mealPlan
    case star
    case thumbUp
    case tune
    case vibration
    case videoOff
    case water
    case wifiOff

    var id: Self { self }

    func systemName(filled: Bool = false) -> String {
        switch self {
        case .add: "plus"
        case .send: "arrow.up"
        case .balance: "scale.3d"
        case .bedtime: filled ? "moon.fill" : "moon"
        case .energy: filled ? "bolt.fill" : "bolt"
        case .heart: "waveform.path.ecg"
        case .check: "checkmark"
        case .chevronRight: "chevron.right"
        case .close: "xmark"
        case .delete: filled ? "trash.fill" : "trash"
        case .run: "figure.run"
        case .egg: "frying.pan"
        case .error: filled ? "exclamationmark.circle.fill" : "exclamationmark.circle"
        case .exercise: "figure.strengthtraining.traditional"
        case .hourglass: "hourglass.tophalf.filled"
        case .info: filled ? "info.circle.fill" : "info.circle"
        case .flame: filled ? "flame.fill" : "flame"
        case .logout: "rectangle.portrait.and.arrow.right"
        case .weight: "scalemass"
        case .noMeals: "fork.knife.circle"
        case .play: filled ? "play.fill" : "play"
        case .restaurant: "fork.knife"
        case .satisfied: "face.smiling"
        case .stressed: "face.dashed"
        case .mealPlan: "list.bullet.clipboard"
        case .star: filled ? "star.fill" : "star"
        case .thumbUp: filled ? "hand.thumbsup.fill" : "hand.thumbsup"
        case .tune: "slider.horizontal.3"
        case .vibration: "wave.3.right"
        case .videoOff: "video.slash"
        case .water: filled ? "drop.fill" : "drop"
        case .wifiOff: "wifi.slash"
        }
    }
}

struct KrokyIconView: View {
    let icon: KrokyIcon
    var size: CGFloat = 22
    var weight: Font.Weight = .regular
    var filled = false

    var body: some View {
        Image(systemName: icon.systemName(filled: filled))
            .font(.system(size: size, weight: weight, design: .rounded))
            .symbolRenderingMode(.monochrome)
    }
}
