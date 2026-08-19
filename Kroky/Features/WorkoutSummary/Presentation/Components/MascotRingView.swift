import AVFoundation
import SwiftUI

/// The mascot disc: a looping video inside a glass circle, wrapped by a
/// deep-rose arc that animates in to fill a small portion of the ring and holds.
struct MascotRingView: View {
    let player: AVPlayer
    var accent: Color = KrokyColor.deepRoseText

    @State private var ringFill: CGFloat = 0

    private enum Layout {
        static let size: CGFloat = 250
        static let discInset: CGFloat = 26
        static let ringWidth: CGFloat = 9
        static let fillFraction: CGFloat = 0.1
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(KrokyColor.white.opacity(0.55), lineWidth: Layout.ringWidth)

            Circle()
                .trim(from: 0, to: ringFill)
                .stroke(
                    accent,
                    style: StrokeStyle(lineWidth: Layout.ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            mascotDisc
                .padding(Layout.discInset)
        }
        .frame(width: Layout.size, height: Layout.size)
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.35)) {
                ringFill = Layout.fillFraction
            }
        }
        .accessibilityHidden(true)
    }

    private var mascotDisc: some View {
        PlayerLayerView(player: player)
            .background(KrokyColor.white)
            .clipShape(Circle())
            .overlay {
                Circle().stroke(KrokyColor.white, lineWidth: 6)
            }
            .krokyShadow(.card)
    }
}
