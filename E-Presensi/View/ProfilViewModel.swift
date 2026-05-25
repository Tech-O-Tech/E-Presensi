//
//  ProfilViewModel.swift
//  E-Presensi
//

import SwiftUI
import UIKit
import Combine

@MainActor
final class ProfilViewModel: ObservableObject {

    @Published var fotoURL = ""
    @Published var isUploadingFoto = false
    @Published var showAlert = false
    @Published var alertMessage = ""

    private let pref = AppPreference.shared

    func refreshProfile() {
        fotoURL = pref.getValue(Keys.urlFotoPegawai)
    }

    func uploadFoto(_ image: UIImage) {
        let token = pref.token
        let nip = pref.nipPegawai
        guard !token.isEmpty, !nip.isEmpty else { return }

        isUploadingFoto = true
        ApiService.editFotoProfil(token: token, nipPegawai: nip, image: image) { [weak self] response, error in
            guard let self else { return }
            self.isUploadingFoto = false

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
            case 200:
                let url = response.data.urlFotoPegawai
                self.pref.setValue(url, forKey: Keys.urlFotoPegawai)
                self.fotoURL = url
            case 401:
                NotificationCenter.default.post(name: .sessionExpired, object: nil)
            default:
                self.toast(response.message)
            }
        }
    }

    func handleCameraResult(image: UIImage?) {
        guard let image else {
            toast("Ambil Foto Dibatalkan")
            return
        }
        uploadFoto(image)
    }

    private func toast(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
