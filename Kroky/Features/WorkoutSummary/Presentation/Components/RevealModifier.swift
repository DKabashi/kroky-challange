import SwiftUI

/// Fades and slides a view into place once `isRevealed` becomes true, with a
/// per-element `delay` so callers can stagger an entrance sequence.
struct RevealModifier: ViewModifier {
    let isRevealed: Bool
    var delay: Double = 0
    var offset: CGFloat = 26

    func body(content: Content) -> some View {
        content
            .opacity(isRevealed ? 1 : 0)
            .offset(y: isRevealed ? 0 : offset)
            .animation(
                .spring(response: 0.55, dampingFraction: 0.82).delay(delay),
                value: isRevealed
            )
    }
}

extension View {
    func reveal(_ isRevealed: Bool, delay: Double = 0, offset: CGFloat = 26) -> some View {
        modifier(RevealModifier(isRevealed: isRevealed, delay: delay, offset: offset))
    }
}
