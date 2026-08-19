//
//  ContentView.swift
//  Kroky
//
//  Created by Donat Kabashi on 8/19/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KrokySpacing.x3) {
                header
                palette
                type
                metricCard
                icons
            }
            .padding(KrokySpacing.x3)
        }
        .background(KrokyColor.porcelain)
        .foregroundStyle(KrokyColor.charcoal)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: KrokySpacing.x1) {
            Text("Design system")
                .krokyTextStyle(.overline)
                .foregroundStyle(KrokyColor.deepRoseText)
            Text("Kroky foundations")
                .krokyTextStyle(.displayXL)
            Text("Reusable color, type, radius, shadow and icon tokens for every screen.")
                .krokyTextStyle(.body)
                .foregroundStyle(KrokyColor.warmGray)
        }
    }

    private var palette: some View {
        HStack(spacing: KrokySpacing.x1) {
            swatch(KrokyColor.charcoal)
            swatch(KrokyColor.deepRoseText)
            swatch(KrokyColor.petal)
            swatch(KrokyColor.rose)
            swatch(KrokyColor.peach)
        }
    }

    private var type: some View {
        VStack(alignment: .leading, spacing: KrokySpacing.x1) {
            Text("Typography")
                .krokyTextStyle(.overline)
                .foregroundStyle(KrokyColor.deepRoseText)
            Text("Warm, direct, human")
                .krokyTextStyle(.title)
            Text("Body copy remains readable and scales with the user's Dynamic Type setting.")
                .krokyTextStyle(.body)
                .foregroundStyle(KrokyColor.warmGray)
        }
        .padding(KrokySpacing.x2)
        .krokyCard()
    }

    private var metricCard: some View {
        HStack(spacing: KrokySpacing.x2) {
            KrokyIconView(icon: .water, size: 24, weight: .semibold, filled: true)
                .foregroundStyle(KrokyColor.Metric.water)
                .frame(width: KrokySize.minimumHitTarget, height: KrokySize.minimumHitTarget)
                .background(KrokyColor.petalTint, in: .rect(cornerRadius: KrokyRadius.tile))

            VStack(alignment: .leading, spacing: 2) {
                Text("Water")
                    .krokyTextStyle(.bodyStrong)
                Text("0.8 of 2 litres")
                    .krokyTextStyle(.caption)
                    .foregroundStyle(KrokyColor.warmGray)
            }

            Spacer()

            KrokyIconView(icon: .add, size: 18, weight: .bold)
                .foregroundStyle(KrokyColor.white)
                .frame(width: KrokySize.minimumHitTarget, height: KrokySize.minimumHitTarget)
                .background(KrokyColor.Metric.water, in: Circle())
                .accessibilityLabel("Log water")
        }
        .padding(KrokySpacing.x2)
        .krokyCard(radius: KrokyRadius.tile, shadow: .small)
    }

    private var icons: some View {
        VStack(alignment: .leading, spacing: KrokySpacing.x1) {
            Text("Iconography")
                .krokyTextStyle(.overline)
                .foregroundStyle(KrokyColor.deepRoseText)

            HStack(spacing: KrokySpacing.x1) {
                ForEach([KrokyIcon.flame, .restaurant, .exercise, .water, .satisfied]) { icon in
                    KrokyIconView(icon: icon, weight: .semibold, filled: true)
                        .foregroundStyle(KrokyColor.deepRoseText)
                        .frame(width: KrokySize.minimumHitTarget, height: KrokySize.minimumHitTarget)
                        .background(
                            KrokyColor.petalTint,
                            in: .rect(cornerRadius: KrokyRadius.iconWell)
                        )
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private func swatch(_ color: Color) -> some View {
        color
            .frame(maxWidth: .infinity)
            .frame(height: KrokySize.minimumHitTarget)
            .clipShape(.rect(cornerRadius: KrokyRadius.iconWell))
            .overlay {
                RoundedRectangle(cornerRadius: KrokyRadius.iconWell)
                    .stroke(KrokyColor.border, lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}

struct ContentViewPreview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
