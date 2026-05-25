//
//  RekapViewModel.swift
//  E-Presensi
//
//  Setara RekapActivity Android
//

import SwiftUI
import Combine

struct RekapSlotUI: Equatable {
    var hasData = false
    var jam = ""
    var jenis = ""
    var keterangan = ""
    var fotoURL = ""
}

@MainActor
final class RekapViewModel: ObservableObject {

    @Published var pagi = RekapSlotUI()
    @Published var siang = RekapSlotUI()
    @Published var sore = RekapSlotUI()
    @Published var showSiangCard = true
    @Published var showSoreCard = true
    @Published var isLoading = false
    @Published var alertMessage = ""
    @Published var showAlert = false

    private let pref = AppPreference.shared

    func load() {
        let token = pref.token
        let idPegawai = pref.idPegawai
        guard !token.isEmpty, !idPegawai.isEmpty else { return }

        isLoading = true

        ApiService.getPresensi(token: token, idPegawai: idPegawai) { [weak self] response, error in
            guard let self else { return }
            self.isLoading = false

            if let error = error as? URLError,
               error.code == .notConnectedToInternet || error.code == .timedOut {
                self.toast("Gagal tersambung. Periksa koneksi internet Anda.")
                return
            }
            if let error {
                self.toast(error.localizedDescription)
                return
            }
            guard let response else {
                self.toast("Terjadi kesalahan")
                return
            }

            switch response.code {
            case 404:
                self.applyNotFound()
            case 200:
                if let data = response.data {
                    self.applyPresensi(data)
                }
            case 401:
                NotificationCenter.default.post(name: .sessionExpired, object: nil)
            default:
                self.toast(response.message)
            }
        }
    }

    private func applyNotFound() {
        pagi = RekapSlotUI(hasData: false)
        siang = RekapSlotUI(hasData: false)
        sore = RekapSlotUI(hasData: false)
        showSiangCard = false
        showSoreCard = false
        pref.setValue("", forKey: Keys.idPresensi)
        pref.setValue("0", forKey: Keys.masuk)
        pref.setValue("0", forKey: Keys.siang)
        pref.setValue("0", forKey: Keys.pulang)
    }

    private func applyPresensi(_ data: DataPresensi) {
        showSiangCard = true
        showSoreCard = true
        pref.setValue(String(data.idPresensi), forKey: Keys.idPresensi)

        if PresensiSessionService.isValidJam(data.jamMasuk) {
            pagi = slot(
                jam: data.jamMasuk,
                ket: data.ketMasuk,
                foto: data.fotoMasuk
            )
        } else {
            pagi = RekapSlotUI(hasData: false)
        }

        if PresensiSessionService.isValidJam(data.jamSiang) {
            siang = slot(
                jam: data.jamSiang,
                ket: data.ketSiang ?? "",
                foto: data.fotoSiang ?? ""
            )
        } else {
            siang = RekapSlotUI(hasData: false)
        }

        if PresensiSessionService.isValidJam(data.jamPulang) {
            sore = slot(
                jam: data.jamPulang,
                ket: data.ketPulang ?? "",
                foto: data.fotoPulang ?? ""
            )
        } else {
            sore = RekapSlotUI(hasData: false)
        }

        pref.setValue(pagi.hasData ? "1" : "0", forKey: Keys.masuk)
        pref.setValue(siang.hasData ? "1" : "0", forKey: Keys.siang)
        pref.setValue(sore.hasData ? "1" : "0", forKey: Keys.pulang)
    }

    private func slot(jam: String, ket: String, foto: String) -> RekapSlotUI {
        let parsed = PresensiKetParser.parse(ket)
        return RekapSlotUI(
            hasData: true,
            jam: jam,
            jenis: PresensiKetParser.jenisLabel(tipe: parsed.tipe, koordinat: parsed.koordinat),
            keterangan: parsed.keterangan,
            fotoURL: foto
        )
    }

    private func toast(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
