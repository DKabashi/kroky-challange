import SwiftUI

/// The "Workout logged" detail card listing the finished workout's metrics.
struct WorkoutSummaryDetailCard: View {
    let summary: WorkoutCompletionSummary

    private var rows: [DetailRow] {
        [
            DetailRow(label: "Workout", value: summary.workoutTitle),
            DetailRow(label: "Duration", value: summary.durationText),
            DetailRow(label: "Calories burned", value: summary.caloriesText),
            DetailRow(label: "Exercises", value: summary.exercisesText)
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.label) { index, row in
                WorkoutSummaryDetailRow(row: row)

                if index < rows.count - 1 {
                    Divider().overlay(KrokyColor.hairline)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
        .background(KrokyColor.white)
        .clipShape(.rect(cornerRadius: KrokyRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: KrokyRadius.card)
                .stroke(KrokyColor.border, lineWidth: 1)
        }
    }
}

private struct WorkoutSummaryDetailRow: View {
    let row: DetailRow

    var body: some View {
        HStack(spacing: 16) {
            Text(row.label)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(KrokyColor.warmGray)

            Spacer(minLength: 12)

            Text(row.value)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(KrokyColor.charcoal)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(height: 56)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.label): \(row.value)")
    }
}

private struct DetailRow {
    let label: String
    let value: String
}
