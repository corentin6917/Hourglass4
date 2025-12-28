//
//  VictoryFilterBar.swift
//  Hourglass 4
//
//  Created by Assistant on 26/11/2025.
//

import SwiftUI

/// Période d'affichage des victoires
enum VictoryPeriod: String, CaseIterable, Identifiable {
    case today
    case thisWeek
    case thisMonth
    case thisYear
    case allTime

    var id: String { rawValue }
}

/// Audience de visibilité des victoires
enum VictoryAudience: String, CaseIterable, Identifiable {
    case friends
    case `public`
    case me

    var id: String { rawValue }
}

/// Barre de filtres pour le Fil des Victoires
/// - Parameters:
///   - audience: Filtre d'audience (amis, public, moi)
///   - period: Période de temps (aujourd'hui, semaine, mois, année, tout)
struct VictoryFilterBar: View {
    @Binding var audience: VictoryAudience
    @Binding var period: VictoryPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Audience picker
            Picker("Audience", selection: $audience) {
                ForEach(VictoryAudience.allCases) { audience in
                    Text(label(for: audience)).tag(audience)
                }
            }
            .pickerStyle(.segmented)

            // Period picker
            Picker("Période", selection: $period) {
                ForEach(VictoryPeriod.allCases) { period in
                    Text(label(for: period)).tag(period)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Labels
    private func label(for audience: VictoryAudience) -> String {
        switch audience {
        case .friends: return "Amis"
        case .public: return "Public"
        case .me: return "Moi"
        }
    }

    private func label(for period: VictoryPeriod) -> String {
        switch period {
        case .today: return "Aujourd'hui"
        case .thisWeek: return "Semaine"
        case .thisMonth: return "Mois"
        case .thisYear: return "Année"
        case .allTime: return "Tout"
        }
    }
}

#Preview {
    StatefulPreviewWrapper((VictoryAudience.friends, VictoryPeriod.thisWeek)) { audience, period in
        VictoryFilterBar(audience: audience, period: period)
            .padding()
    }
}

// Helper for binding previews
struct StatefulPreviewWrapper<Value1, Value2, Content: View>: View {
    @State private var value1: Value1
    @State private var value2: Value2
    let content: (_ binding1: Binding<Value1>, _ binding2: Binding<Value2>) -> Content

    init(_ initial: (Value1, Value2), @ViewBuilder content: @escaping (_ binding1: Binding<Value1>, _ binding2: Binding<Value2>) -> Content) {
        _value1 = State(initialValue: initial.0)
        _value2 = State(initialValue: initial.1)
        self.content = content
    }

    var body: some View { content($value1, $value2) }
}
