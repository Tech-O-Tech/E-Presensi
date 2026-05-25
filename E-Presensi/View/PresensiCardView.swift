//
//  PresensiCardView.swift
//  E-Presensi
//
//  Setara CardView absen_dialog.xml (120dp, radius 10dp, overlay 0.8)
//

import SwiftUI

struct PresensiCardView: View {
    var title: String
    var subtitle: String
    var image: String
    var color: Color

    var body: some View {
        ZStack {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: PresensiTheme.cardHeight)
                .clipped()
                .allowsHitTesting(false)

            LinearGradient(
                colors: [color.opacity(PresensiTheme.overlayAlpha), color.opacity(0.25)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .allowsHitTesting(false)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 20)
                .padding(.vertical, 12)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: PresensiTheme.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: PresensiTheme.cardRadius))
        .shadow(color: .black.opacity(0.18), radius: 5, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: PresensiTheme.cardRadius))
    }
}

#Preview {
    PresensiCardView(
        title: PresensiCopy.pagiTitle,
        subtitle: PresensiCopy.pagiSubtitle,
        image: "pagi",
        color: .green
    )
    .padding()
}
