//
//  WfhView.swift
//  E-Presensi
//
//  Pendaftaran & presensi WFH ditangani di PresensiView (cvAbsenWFH).
//  View ini tersedia jika ingin layar WFH terpisah di masa depan.
//

import SwiftUI

struct WfhView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "house.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(red: 0.07, green: 0.13, blue: 0.36))
            Text("Work From Home")
                .font(.title2.bold())
            Text("Daftarkan lokasi WFH dan lakukan presensi dari tab Presensi → kartu WFH.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .navigationTitle("WFH")
        .navigationBarTitleDisplayMode(.inline)
    }
}
