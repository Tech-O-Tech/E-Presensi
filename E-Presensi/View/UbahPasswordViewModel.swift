//
//  UbahPasswordViewModel.swift
//  E-Presensi
//
//  Setara UbahPasswordActivity.ubahPass
//

import SwiftUI
import Combine

@MainActor
final class UbahPasswordViewModel: ObservableObject {

    @Published var password = ""
    @Published var passwordError: String?
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var didSucceed = false
    @Published var needsReauth = false

    private let pref = AppPreference.shared

    func ubahPassword() {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        passwordError = nil

        if trimmed.count < 8 {
            passwordError = "Minimal 8 karakter"
            return
        }

        let token = pref.token
        let nip = pref.nipPegawai
        guard !token.isEmpty, !nip.isEmpty else {
            toast("Sesi tidak valid, silahkan login kembali")
            needsReauth = true
            return
        }

        isLoading = true

        ApiService.ubahPassword(token: token, nip: nip, password: trimmed) { [weak self] response, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false

                if let urlError = error as? URLError,
                   urlError.code == .notConnectedToInternet || urlError.code == .timedOut {
                    self.toast("Gagal tersambung. Periksa koneksi internet Anda!")
                    return
                }

                if let error {
                    if error is DecodingError {
                        self.toast("Gagal memproses data server.")
                    } else {
                        self.toast(error.localizedDescription)
                    }
                    return
                }

                guard let response else {
                    self.toast("Terjadi kesalahan")
                    return
                }

                switch response.code {
                case 200:
                    self.pref.setValue("1", forKey: Keys.firstTime)
                    if self.pref.getValue(Keys.fingerEnabled) == "1" {
                        self.pref.setValue(trimmed, forKey: Keys.password)
                    }
                    self.toast("Password berhasil diubah")
                    self.didSucceed = true
                case 401:
                    self.toast("Waktu anda habis, silahkan login kembali")
                    self.needsReauth = true
                default:
                    self.toast(response.message.isEmpty ? "Gagal mengubah password" : response.message)
                }
            }
        }
    }

    func handleAlertDismissed() {
        if needsReauth {
            NotificationCenter.default.post(name: .sessionExpired, object: nil)
        }
    }

    private func toast(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
