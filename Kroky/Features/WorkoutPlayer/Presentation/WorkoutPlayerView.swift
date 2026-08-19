import SwiftUI

struct WorkoutPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: WorkoutPlayerViewModel

    init(
        workout: Workout,
        cache: any VideoCaching = RemoteVideoCache.shared
    ) {
        _viewModel = StateObject(
            wrappedValue: WorkoutPlayerViewModel(workout: workout, cache: cache)
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                KrokyColor.playerBackground

                switch viewModel.phase {
                case .failed:
                    WorkoutVideoErrorView(
                        progress: progressValues,
                        onRetry: viewModel.retry,
                        onExit: exitWorkout
                    )
                case .completed:
                    WorkoutCompleteView(onDone: exitWorkout)
                case .preparing, .countdown, .playing:
                    playerContent(safeAreaInsets: .init(top: geometry.safeAreaInsets.top + 52, leading: geometry.safeAreaInsets.leading, bottom: geometry.safeAreaInsets.bottom, trailing: geometry.safeAreaInsets.trailing))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(KrokyColor.playerBackground)
        .ignoresSafeArea()
        .task {
            viewModel.start()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                viewModel.pauseForBackground()
            }
        }
        .onDisappear {
            viewModel.stop()
        }
        .preferredColorScheme(.dark)
    }

    private var progressValues: [Double] {
        (0..<viewModel.totalSegmentCount).map(viewModel.progress(for:))
    }

    @ViewBuilder
    private func playerContent(safeAreaInsets: EdgeInsets) -> some View {
        PlayerLayerView(player: viewModel.player)
            .ignoresSafeArea()

        playerScrim
            .ignoresSafeArea()

        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: viewModel.togglePause)
            .accessibilityLabel(viewModel.isPaused ? "Resume workout" : "Pause workout")

        switch viewModel.phase {
        case .preparing:
            preparingOverlay(safeAreaInsets: safeAreaInsets)
        case .countdown:
            countdownOverlay(safeAreaInsets: safeAreaInsets)
        case .playing:
            playbackOverlay(safeAreaInsets: safeAreaInsets)
        case .failed, .completed:
            EmptyView()
        }
    }

    private var playerScrim: some View {
        ZStack {
            Color.black.opacity(viewModel.phase == .countdown ? 0.53 : 0.22)

            LinearGradient(
                colors: [.black.opacity(0.55), .clear, .black.opacity(0.70)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .allowsHitTesting(false)
    }

    private func preparingOverlay(safeAreaInsets: EdgeInsets) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)

                Text("Preparing workout…")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            closeButton
                .padding(.top, safeAreaInsets.top + 12)
                .padding(.trailing, 24)
        }
    }

    private func countdownOverlay(safeAreaInsets: EdgeInsets) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Text("\(viewModel.countdownRemaining)")
                    .font(.system(size: 104, weight: .heavy))
                    .tracking(-5)

                Text(viewModel.isPaused ? "Paused" : "Get ready")
                    .font(.system(size: 24, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(y: -24)
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                Text("Up next")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.72))

                Text(viewModel.currentTitle)
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(.white)
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.bottom, safeAreaInsets.bottom + 36)
            .allowsHitTesting(false)

            closeButton
                .padding(.top, safeAreaInsets.top + 12)
                .padding(.trailing, 24)
        }
    }

    private func playbackOverlay(safeAreaInsets: EdgeInsets) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                WorkoutProgressBar(values: progressValues, tint: KrokyColor.playerProgress)
                    .allowsHitTesting(false)

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.currentTitleWithRepetition)
                            .font(.system(size: 18, weight: .bold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)

                        if let nextTitle = viewModel.nextExerciseTitle {
                            Text("Next: \(nextTitle)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.64))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .allowsHitTesting(false)

                    closeButton
                }
            }
            .padding(.top, safeAreaInsets.top + 8)
            .padding(.horizontal, 20)

            Spacer(minLength: 24)

            WorkoutPlaybackControls(
                isPaused: viewModel.isPaused,
                canGoBack: viewModel.currentSegmentIndex > 0,
                onBack: viewModel.goToPreviousSegment,
                onPlayPause: viewModel.togglePause,
                onNext: viewModel.goToNextSegment
            )

            WorkoutMetricsView(
                elapsedTime: viewModel.elapsedTimeText,
                calories: viewModel.calorieText
            )
            .allowsHitTesting(false)
            .padding(.top, 20)
            .padding(.bottom, safeAreaInsets.bottom + 22)
        }
        .foregroundStyle(.white)
    }

    private var closeButton: some View {
        Button(action: exitWorkout) {
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(.white.opacity(0.22), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close workout")
    }

    private func exitWorkout() {
        viewModel.stop()
        dismiss()
    }
}

private struct WorkoutProgressBar: View {
    let values: [Double]
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, progress in
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.30))

                        Capsule()
                            .fill(tint)
                            .frame(width: geometry.size.width * min(max(progress, 0), 1))
                    }
                }
                .frame(height: 4)
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }
}

private struct WorkoutPlaybackControls: View {
    let isPaused: Bool
    let canGoBack: Bool
    let onBack: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 28) {
            controlButton(
                systemName: "backward.end.fill",
                accessibilityLabel: "Previous clip",
                action: onBack
            )
            .disabled(!canGoBack)
            .opacity(canGoBack ? 1 : 0.45)

            Button(action: onPlayPause) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(KrokyColor.charcoal)
                    .frame(width: 88, height: 88)
                    .background(.white.opacity(0.96), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPaused ? "Resume" : "Pause")

            controlButton(
                systemName: "forward.end.fill",
                accessibilityLabel: "Next clip",
                action: onNext
            )
        }
    }

    private func controlButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(.black.opacity(0.30), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct WorkoutMetricsView: View {
    let elapsedTime: String
    let calories: String

    var body: some View {
        HStack(spacing: 0) {
            metric(label: "Time", value: elapsedTime)

            Rectangle()
                .fill(.white.opacity(0.30))
                .frame(width: 1, height: 47)
                .padding(.horizontal, 34)

            metric(label: "Kcal", value: calories)
        }
    }

    private func metric(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .heavy))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.68))

            Text(value)
                .font(.system(size: 30, weight: .bold))
                .monospacedDigit()
        }
        .frame(minWidth: 96)
    }
}

private struct WorkoutVideoErrorView: View {
    let progress: [Double]
    let onRetry: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            WorkoutProgressBar(values: progress, tint: .white)
                .padding(.top, 58)
                .padding(.horizontal, 28)

            Spacer()

            VStack(spacing: 0) {
                KrokyIconView(icon: .videoOff, size: 42, weight: .regular)
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(width: 92, height: 92)
                    .background(.white.opacity(0.08), in: Circle())

                Text("That video didn’t load")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 26)

                Text("Check your connection — your\nworkout is paused, not lost.")
                    .font(.system(size: 17, weight: .regular))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .foregroundStyle(KrokyColor.playerMuted)
                    .padding(.top, 12)

                Button(action: onRetry) {
                    Text("Try again")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(KrokyColor.charcoal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(KrokyColor.porcelain, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 30)

                Button("Back to my plan", action: onExit)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(KrokyColor.playerMuted)
                    .buttonStyle(.plain)
                    .padding(.top, 18)
            }
            .padding(.horizontal, 42)

            Spacer()
            Spacer()
        }
    }
}

private struct WorkoutCompleteView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(KrokyColor.charcoal)
                .frame(width: 92, height: 92)
                .background(KrokyColor.petal, in: Circle())

            Text("Workout complete")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Button("Done", action: onDone)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(KrokyColor.charcoal)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(KrokyColor.porcelain, in: Capsule())
                .padding(.horizontal, 42)
                .padding(.top, 12)
        }
    }
}
