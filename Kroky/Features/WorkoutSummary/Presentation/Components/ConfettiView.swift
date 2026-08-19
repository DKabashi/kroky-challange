import SwiftUI

/// A one-shot pink confetti burst that rains down when the view appears.
///
/// Pieces are generated once and animated declaratively, so the effect stays
/// lightweight and needs no timer or external dependency.
struct ConfettiView: View {
    var pieceCount = 90
    var palette: [Color] = [
        KrokyColor.petal,
        KrokyColor.rose,
        KrokyColor.peach,
        KrokyColor.deepRose,
        KrokyColor.playerProgress
    ]

    @State private var pieces: [ConfettiPiece] = []
    @State private var isFalling = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPieceView(piece: piece, isFalling: isFalling, size: geometry.size)
                }
            }
            .onAppear {
                if pieces.isEmpty {
                    pieces = ConfettiPiece.makeBurst(count: pieceCount, palette: palette)
                }
                withAnimation(nil) { isFalling = false }
                DispatchQueue.main.async {
                    isFalling = true
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let isFalling: Bool
    let size: CGSize

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
            .fill(piece.color)
            .frame(width: piece.width, height: piece.height)
            .rotationEffect(.degrees(isFalling ? piece.endRotation : piece.startRotation))
            .position(
                x: piece.startX * size.width + (isFalling ? piece.horizontalDrift : 0),
                y: isFalling ? size.height + 60 : -60
            )
            .opacity(isFalling ? 0 : 1)
            .animation(
                .easeIn(duration: piece.duration).delay(piece.delay),
                value: isFalling
            )
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let startX: CGFloat
    let horizontalDrift: CGFloat
    let width: CGFloat
    let height: CGFloat
    let startRotation: Double
    let endRotation: Double
    let duration: Double
    let delay: Double

    static func makeBurst(count: Int, palette: [Color]) -> [ConfettiPiece] {
        (0..<count).map { _ in
            let side = CGFloat.random(in: 5...9)
            return ConfettiPiece(
                color: palette.randomElement() ?? KrokyColor.rose,
                startX: .random(in: 0.02...0.98),
                horizontalDrift: .random(in: -70...70),
                width: side,
                height: side * .random(in: 1.2...2.1),
                startRotation: .random(in: 0...360),
                endRotation: .random(in: 180...900),
                duration: .random(in: 1.9...3.2),
                delay: .random(in: 0...0.55)
            )
        }
    }
}
