import SwiftUI

/// The advanced completed-workout screen shown once every segment is finished.
///
/// Layout mirrors the design: a floating evaluation card, the looping mascot in
/// an animated ring, a status pill, and a bottom sheet with the logged metrics
/// and a "Next" action. Confetti bursts on entry and each block reveals in turn.
struct WorkoutSummaryView: View {
    @StateObject private var viewModel: WorkoutSummaryViewModel

    @State private var isRevealed = false

    private let rosyState: KrokyRosyState = .steady

    init(viewModel: @autoclosure @escaping () -> WorkoutSummaryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                rosyState.background
                    .ignoresSafeArea()

                content(safeAreaInsets: geometry.safeAreaInsets)

                ConfettiView()
                    .ignoresSafeArea()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            viewModel.startMascot()
            isRevealed = true
        }
        .onDisappear(perform: viewModel.stopMascot)
    }

    private func content(safeAreaInsets: EdgeInsets) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                MascotRingView(player: viewModel.mascotVideoPlayer, accent: rosyState.accent)
                    .reveal(isRevealed, delay: 0.15, offset: 40)

                RosyStatePill(title: "Steady weight loss", accent: rosyState.accent)
                    .reveal(isRevealed, delay: 0.3)
            }
            .frame(maxHeight: .infinity)
            .padding(.top, safeAreaInsets.top)

            bottomSheet(safeAreaInsets: safeAreaInsets)
                .reveal(isRevealed, delay: 0.1, offset: 60)
        }
    }

    private func bottomSheet(safeAreaInsets: EdgeInsets) -> some View {
        VStack(spacing: 18) {
            Text("Workout logged")
                .font(.system(size: 30, weight: .bold))
                .tracking(-0.6)
                .foregroundStyle(KrokyColor.charcoal)
                .frame(maxWidth: .infinity, alignment: .center)

            WorkoutSummaryDetailCard(summary: viewModel.summary)

            nextButton
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
        .padding(.bottom, safeAreaInsets.bottom + 20)
        .frame(maxWidth: .infinity)
        .background(KrokyColor.porcelain)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: KrokyRadius.contentSheet,
                topTrailingRadius: KrokyRadius.contentSheet
            )
        )
        .krokyShadow(.contentSheet)
    }

    private var nextButton: some View {
        Button(action: viewModel.advance) {
            Text("Next")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(KrokyColor.white)
                .frame(maxWidth: .infinity)
                .frame(height: KrokySize.largeButtonHeight)
                .background(KrokyColor.charcoal, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Returns to the workout start screen")
    }
}
