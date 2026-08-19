import SwiftUI

/// The floating status pill beneath the mascot (e.g. "Steady weight loss").
struct RosyStatePill: View {
    let title: String
    var accent: Color = KrokyRosyState.steady.accent

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(accent)
                .frame(width: 12, height: 12)

            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(KrokyColor.charcoal)
        }
        .padding(.leading, 16)
        .padding(.trailing, 14)
        .frame(height: 52)
        .background(KrokyColor.white, in: Capsule())
        .krokyShadow(.pill)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}
