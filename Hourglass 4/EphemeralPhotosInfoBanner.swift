import SwiftUI

/// A small yellow info banner explaining ephemeral photos behavior in the Victory feed.
struct EphemeralPhotosInfoBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
                .padding(8)
                .background(
                    Circle().fill(Color.yellow.opacity(0.9))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Photos éphémères")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Les photos partagées dans le fil peuvent disparaître après un certain temps pour protéger votre vie privée.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.yellow.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.yellow.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Information: Photos éphémères. Les photos partagées dans le fil peuvent disparaître après un certain temps pour protéger votre vie privée.")
    }
}

#Preview {
    VStack {
        EphemeralPhotosInfoBanner()
            .padding()
        Spacer()
    }
}
