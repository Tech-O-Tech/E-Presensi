//
//  RekapHariIniCard.swift
//  E-Presensi
//
//  Kartu cl1 fragment_presensi — border putus-putus, tap ke RekapView
//

import SwiftUI
import Combine

struct RekapHariIniCard: View {
    let jenisAbsen: String
    let keteranganAbsen: String
    let fotoURL: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(PresensiCopy.rekapSayaHariIni)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            HStack(alignment: .top, spacing: 12) {
                fotoThumbnail
                VStack(alignment: .leading, spacing: 4) {
                    Text(jenisAbsen)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(keteranganAbsen)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(PresensiTheme.navy.opacity(0.6))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    PresensiTheme.navy.opacity(0.55),
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 5])
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var fotoThumbnail: some View {
        Group {
            if !fotoURL.isEmpty, let url = URL(string: fotoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        fotoPlaceholder
                    }
                }
            } else {
                fotoPlaceholder
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var fotoPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.15))
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
            )
    }
}
