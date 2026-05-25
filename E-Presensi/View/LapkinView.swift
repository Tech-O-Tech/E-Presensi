//
//  LapkinView.swift
//  E-Presensi
//
//  Setara LapkinActivity Android
//

import SwiftUI

struct LapkinView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var nama = ""
    @State private var nip = ""
    @State private var tanggal = ""
    @State private var kegiatan = ""
    @State private var hasData = false
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertMessage = ""

    private let primaryNavy = Color(red: 13/255, green: 23/255, blue: 95/255)
    private let pref = AppPreference.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerBar
                contentCard
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .onAppear { loadData() }
        .alert("Pemberitahuan", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
            }
            Text("Laporan Kegiatan")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(primaryNavy)
                .padding(.top, 16)
        }
    }

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kegiatan Hari Ini")
                .font(.system(size: 16, weight: .bold))

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if hasData {
                lapkinRow(label: "Nama", value: nama)
                lapkinRow(label: "NIP", value: nip)
                lapkinRow(label: "Tanggal", value: tanggal)
                lapkinRow(label: "Kegiatan", value: kegiatan)
            } else {
                Text("Belum ada laporan kegiatan hari ini")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 32)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(primaryNavy.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [8, 5]))
        )
    }

    private func lapkinRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value.isEmpty ? "-" : value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }

    private func loadData() {
        nama = pref.getValue(Keys.namaPegawai)
        nip = pref.getValue(Keys.nipPegawai)
        let token = pref.token
        let idPegawai = pref.idPegawai
        guard !token.isEmpty, !idPegawai.isEmpty else {
            isLoading = false
            return
        }

        ApiService.getKegiatan(token: token, idPegawai: idPegawai) { response, error in
            isLoading = false
            if let error = error as? URLError,
               error.code == .notConnectedToInternet || error.code == .timedOut {
                toast("Gagal tersambung. Periksa koneksi internet Anda.")
                return
            }
            if let error {
                toast(error.localizedDescription)
                return
            }
            guard let response else {
                toast("Terjadi kesalahan")
                return
            }

            switch response.code {
            case 404:
                hasData = false
            case 200:
                if let data = response.data {
                    hasData = true
                    tanggal = DateHelper.formatKegiatanDate(data.tanggalKegiatan)
                    kegiatan = data.kegiatan
                    pref.setValue(String(data.idPresensi), forKey: Keys.idPresensi)
                }
            case 401:
                NotificationCenter.default.post(name: .sessionExpired, object: nil)
            default:
                toast(response.message)
            }
        }
    }

    private func toast(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
