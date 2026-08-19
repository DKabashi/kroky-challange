import SwiftUI

/// A reusable card treatment that keeps fill, border, radius and elevation together.
struct KrokyCardModifier: ViewModifier {
    var radius: CGFloat = KrokyRadius.card
    var shadow: KrokyShadow = .card

    func body(content: Content) -> some View {
        content
            .background(KrokyColor.white)
            .clipShape(.rect(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .stroke(KrokyColor.hairline, lineWidth: 1)
            }
            .krokyShadow(shadow)
    }
}

extension View {
    func krokyCard(
        radius: CGFloat = KrokyRadius.card,
        shadow: KrokyShadow = .card
    ) -> some View {
        modifier(KrokyCardModifier(radius: radius, shadow: shadow))
    }
}
