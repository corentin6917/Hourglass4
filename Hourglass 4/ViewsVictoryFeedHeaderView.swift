//
//  ViewsVictoryFeedHeaderView.swift
//  Hourglass 4
//
//  Created by Assistant on 26/11/2025.
//

import SwiftUI

/// En-tête du Fil des Victoires
struct VictoryFeedHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Fil des victoires")
                .font(.largeTitle).bold()
                .accessibilityAddTraits(.isHeader)
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
