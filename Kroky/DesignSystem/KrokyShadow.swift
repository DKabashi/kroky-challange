import SwiftUI

struct KrokyShadow: Sendable {
    let color: Color
    let blur: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let small = KrokyShadow(
        color: KrokyColor.charcoal.opacity(0.06), blur: 2, x: 0, y: 1
    )
    static let card = KrokyShadow(
        color: KrokyColor.charcoal.opacity(0.08), blur: 28, x: 0, y: 8
    )
    static let lifted = KrokyShadow(
        color: KrokyColor.charcoal.opacity(0.12), blur: 48, x: 0, y: 18
    )
    static let pill = KrokyShadow(
        color: KrokyColor.charcoal.opacity(0.18), blur: 18, x: 0, y: 6
    )
    static let contentSheet = KrokyShadow(
        color: KrokyColor.charcoal.opacity(0.10), blur: 26, x: 0, y: -8
    )
    static let device = KrokyShadow(
        color: KrokyColor.charcoal.opacity(0.24), blur: 70, x: 0, y: 34
    )

    /// CSS blur is approximately twice Core Animation's shadow radius.
    fileprivate var nativeRadius: CGFloat { blur / 2 }
}

extension View {
    func krokyShadow(_ shadow: KrokyShadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.nativeRadius,
            x: shadow.x,
            y: shadow.y
        )
    }
}
