//
//  RekapSlotCard.swift
//  E-Presensi
//
//  Kartu rekap dengan border putus-putus (ic_dashed_square)
//

import SwiftUI
import Combine

struct RekapSlotCard: View {
    let title: String
    let slot: RekapSlotUI
    let emptyMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            if slot.hasData {
                HStack(alignment: .top, spacing: 12) {
                    fotoView
                    VStack(alignment: .leading, spacing: 6) {
                        Text(slot.jam)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.primary)
                        Text(slot.jenis)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(slot.keterangan)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 24)
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
    }

    @ViewBuilder
    private var fotoView: some View {
        Group {
            if !slot.fotoURL.isEmpty, let url = URL(string: slot.fotoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholderFoto
                    }
                }
            } else {
                placeholderFoto
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var placeholderFoto: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.15))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            )
    }
}
