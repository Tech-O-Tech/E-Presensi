//
//  RekapIzinCard.swift
//  E-Presensi
//
//  Kartu ringkasan izin aktif hari ini.
//  Sumber data: `GET izin/hari-ini/{id_pegawai}`.
//

import SwiftUI

struct RekapIzinCard: View {
    let data: DataIzin

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "doc.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(PresensiTheme.navy)
                Text("Rekap Izin Hari Ini")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }

            HStack(alignment: .top, spacing: 12) {
                buktiThumbnail
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(data.jenisIzin ?? "-")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(PresensiTheme.navy)

                    Text(data.tanggalRangeFormatted)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    if let ket = data.keterangan, !ket.isEmpty {
                        Text(ket)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
    private var buktiThumbnail: some View {
        Group {
            if let urlStr = data.bukti,
               let url = URL(string: urlStr),
               FileThumbnailHelper.isImage(urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        loadingPlaceholder
                    case .failure:
                        documentPlaceholder
                    @unknown default:
                        loadingPlaceholder
                    }
                }
            } else {
                documentPlaceholder
            }
        }
    }

    private var loadingPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.12))
            .overlay(ProgressView().scaleEffect(0.7))
    }

    private var documentPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(PresensiTheme.navy.opacity(0.12))
            .overlay(
                Image(systemName: "doc.text.fill")
                    .foregroundColor(PresensiTheme.navy)
            )
    }
}
