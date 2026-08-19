import SwiftUI

struct WorkoutDetailView: View {
    private enum Layout {
        static let heroHeight: CGFloat = 320
        static let sheetOverlap: CGFloat = 24
        static let horizontalInset: CGFloat = 22
        static let buttonHeight: CGFloat = 52
        static let heroTitleHeight: CGFloat = 68
    }

    let workout: Workout

    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                WorkoutHeroBackground(
                    imageName: workout.heroImageName,
                    height: Layout.heroHeight
                )

                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Color.clear
                            .frame(height: heroTitleTopInset(safeAreaTop: geometry.safeAreaInsets.top))

                        Section {
                            workoutSheet
                        } header: {
                            heroTitle(safeAreaTop: geometry.safeAreaInsets.top)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top
                } action: { _, newOffset in
                    scrollOffset = max(newOffset, 0)
                }

                startButton
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.horizontal, Layout.horizontalInset)
                    .padding(.bottom, 16)
            }
            .background(KrokyColor.porcelain)
            .ignoresSafeArea()
        }
        .foregroundStyle(KrokyColor.charcoal)
    }

    private func heroTitleTopInset(safeAreaTop: CGFloat) -> CGFloat {
        max(
            Layout.heroHeight
                - Layout.sheetOverlap
                - Layout.heroTitleHeight
                - safeAreaTop,
            0
        )
    }

    private func heroTitle(safeAreaTop: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: safeAreaTop)

            VStack(alignment: .leading, spacing: 6) {
                Text(workout.eyebrow)
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(0.6)
                    .textCase(.uppercase)

                Text(workout.title)
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.7)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(height: Layout.heroTitleHeight, alignment: .topLeading)
            .padding(.horizontal, Layout.horizontalInset)
        }
        .foregroundStyle(isTitlePinned(safeAreaTop: safeAreaTop) ? KrokyColor.charcoal : KrokyColor.white)
        .animation(.easeOut(duration: 0.15), value: isTitlePinned(safeAreaTop: safeAreaTop))
        .accessibilityElement(children: .combine)
    }

    private func isTitlePinned(safeAreaTop: CGFloat) -> Bool {
        scrollOffset >= heroTitleTopInset(safeAreaTop: safeAreaTop) + 24
    }

    private var workoutSheet: some View {
        VStack(spacing: 14) {
            WorkoutSummaryCard(overview: workout.overview)
            ExerciseListCard(
                summary: workout.exerciseSummary,
                exercises: workout.exercises
            )
        }
        .padding(.top, 22)
        .padding(.horizontal, Layout.horizontalInset)
        .padding(.bottom, Layout.buttonHeight + 64)
        .frame(maxWidth: .infinity)
        .background(KrokyColor.porcelain)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: KrokyRadius.contentSheet,
                topTrailingRadius: KrokyRadius.contentSheet
            )
        )
    }

    private var startButton: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                KrokyIconView(icon: .play, size: 16, weight: .bold, filled: true)
                Text(workout.callToActionTitle)
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(KrokyColor.white)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.buttonHeight)
            .background(KrokyColor.charcoal, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Workout playback is not available yet")
    }
}

private struct WorkoutHeroBackground: View {
    let imageName: String
    let height: CGFloat

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.34),
                        .init(color: KrokyColor.charcoal.opacity(0.10), location: 0.58),
                        .init(color: KrokyColor.charcoal.opacity(0.72), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .accessibilityHidden(true)
    }
}

private struct WorkoutSummaryCard: View {
    let overview: WorkoutOverview

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(overview.title)
                .krokyTextStyle(.blockTitle)

            Text(overview.description)
                .krokyTextStyle(.body)
                .foregroundStyle(KrokyColor.warmGray)
                .lineSpacing(4)
                .padding(.top, 8)

            Divider()
                .overlay(KrokyColor.hairline)
                .padding(.top, 17)
                .padding(.bottom, 13)

            HStack(spacing: 0) {
                ForEach(Array(overview.metrics.enumerated()), id: \.offset) { index, metric in
                    WorkoutMetricView(metric: metric)
                        .frame(maxWidth: .infinity)

                    if index < overview.metrics.count - 1 {
                        Rectangle()
                            .fill(KrokyColor.hairline)
                            .frame(width: 1, height: 34)
                    }
                }
            }
        }
        .padding(18)
        .background(KrokyColor.white)
        .clipShape(.rect(cornerRadius: KrokyRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: KrokyRadius.card)
                .stroke(KrokyColor.border, lineWidth: 1)
        }
    }
}

private struct WorkoutMetricView: View {
    let metric: WorkoutMetric

    var body: some View {
        VStack(spacing: 2) {
            Text(metric.value)
                .font(.system(size: 17, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(metric.label)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(KrokyColor.mutedGray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

private struct ExerciseListCard: View {
    let summary: String
    let exercises: [WorkoutExercise]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(summary)
                .krokyTextStyle(.blockTitle)
                .padding(.bottom, 8)

            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseRow(exercise: exercise)

                if index < exercises.count - 1 {
                    Divider()
                        .overlay(KrokyColor.hairline)
                        .padding(.leading, 62)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 10)
        .background(KrokyColor.white)
        .clipShape(.rect(cornerRadius: KrokyRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: KrokyRadius.card)
                .stroke(KrokyColor.border, lineWidth: 1)
        }
    }
}

private struct ExerciseRow: View {
    let exercise: WorkoutExercise

    var body: some View {
        HStack(spacing: 12) {
            Image(exercise.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(.rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)

                Text(exercise.duration)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(KrokyColor.mutedGray)
            }

            Spacer(minLength: 0)
        }
        .frame(minHeight: 70)
        .accessibilityElement(children: .combine)
    }
}
