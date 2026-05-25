//
//  AboutView.swift
//  E-Presensi
//
//  Setara AboutActivity Android
//

import SwiftUI

struct AboutView: View {

    @Environment(\.dismiss) private var dismiss

    private let primaryNavy = Color(red: 13/255, green: 23/255, blue: 95/255)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerBar

                aboutRow(title: "Email", value: "diskominfokabupaten@gmail.com")
                aboutRow(title: "WhatsApp", value: "0897-2944-144")
                aboutRow(title: "Website", value: "https://sikasn.pringsewukab.go.id")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Pengembang")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    Text("Aan Sanova\nRangkas Andreansyah\nDwi Amalia\nZuzlifatul Adnan")
                        .font(.body)
                }

                Text(
                    "Pringsewu Tech Service\nDinas Komunikasi dan Informatika Kabupaten Pringsewu\nPemerintah Daerah Kabupaten Pringsewu\nLampung\nIndonesia"
                )
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
    }

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
            }
            Text("Tentang Aplikasi")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(primaryNavy)
                .padding(.top, 16)
        }
    }

    private func aboutRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}
