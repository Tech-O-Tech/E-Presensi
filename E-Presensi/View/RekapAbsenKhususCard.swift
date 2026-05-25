//
//  RekapAbsenKhususCard.swift
//  E-Presensi
//
//  Kartu ringkasan absen khusus hari ini (DL/Khusus Lisan).
//  Sumber data: `GET absen-khusus/hari-ini/{id_pegawai}`.
//

import SwiftUI

struct RekapAbsenKhususCard: View {
    let data: DataAbsenKhusus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(PresensiTheme.navy)
                Text("Rekap Absen Khusus Hari Ini")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }

            HStack(alignment: .top, spacing: 12) {
                fileThumbnail
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(data.jenisKhusus ?? "-")
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

                    statusBadge
                        .padding(.top, 2)
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
    private var fileThumbnail: some View {
        Group {
            if let urlStr = data.file,
               let url = URL(string: urlStr),
               FileThumbnailHelper.isImage(urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        placeholder
                    case .failure:
                        documentPlaceholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                documentPlaceholder
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.12))
            .overlay(
                ProgressView().scaleEffect(0.7)
            )
    }

    private var documentPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(PresensiTheme.navy.opacity(0.12))
            .overlay(
                Image(systemName: "doc.text.fill")
                    .foregroundColor(PresensiTheme.navy)
            )
    }

    private var statusBadge: some View {
        let color = statusColor
        return Text(data.verifikasiText)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch data.verifikasiAtasan {
        case 1: return Color(red: 36/255, green: 145/255, blue: 70/255)
        case 2: return .red
        default: return Color.orange
        }
    }
}
