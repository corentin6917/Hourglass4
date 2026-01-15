//
//  ViewsVictoryFeedHeaderView.swift
//  Hourglass 4
//
//  Created by Assistant on 26/11/2025.
//

import SwiftUI

/// En-tête du Fil des Victoires
struct VictoryFeedHeaderView: View {
    @State private var showInfoPopover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text("Fil des victoires")
                    .font(.largeTitle).bold()
                    .accessibilityAddTraits(.isHeader)

                Button(action: {
                    showInfoPopover = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }
                .popover(isPresented: $showInfoPopover, arrowEdge: .top) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Photos éphémères")
                            .font(.headline)

                        Text("Le feed se rafraîchit chaque soir à 21h avec les photos de la journée. Validation possible jusqu'à 20h59.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .frame(width: 280)
                    .presentationCompactAdaptation(.popover)
                }
            }

            Text("Découvrez vos accomplissements récents")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

#Preview {
    VictoryFeedHeaderView()
        .previewLayout(.sizeThatFits)
        .padding()
}
