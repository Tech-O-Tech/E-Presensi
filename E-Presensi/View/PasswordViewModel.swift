//
//  PasswordViewModel.swift
//  E-Presensi
//
//  Setara PasswordActivity.pushLogin
//

import SwiftUI
import UIKit
import Combine

@MainActor
final class PasswordViewModel: ObservableObject {

    @Published var password = ""
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""

    private let pref = AppPreference.shared

    func masuk(completion: @escaping (Bool) -> Void) {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            toast("Password tidak boleh kosong")
            completion(false)
            return
        }

        let nip = pref.nipPegawai
        guard !nip.isEmpty else {
            toast("NIP tidak ditemukan, silahkan login dari awal")
            completion(false)
            return
        }

        let deviceId = pref.getValue(Keys.deviceId).isEmpty
            ? (UIDevice.current.identifierForVendor?.uuidString ?? "ios_device")
            : pref.getValue(Keys.deviceId)

        isLoading = true

        ApiService.login(nip: nip, password: trimmed, deviceId: deviceId) { [weak self] response, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false

                if let error = error as? URLError,
                   error.code == .notConnectedToInternet || error.code == .timedOut {
                    self.toast("Gagal tersambung. Periksa koneksi internet Anda.")
                    completion(false)
                    return
                }

                if let error {
                    if error is DecodingError {
                        self.toast("Gagal memproses data server.")
                    } else {
                        self.toast(error.localizedDescription)
                    }
                    completion(false)
                    return
                }

                guard let response else {
                    self.toast("Terjadi kesalahan")
                    completion(false)
                    return
                }

                if response.code == 200, let userData = response.data {
                    self.pref.saveLoginSession(userData, password: trimmed)
                    self.pref.setValue("1", forKey: Keys.isLogin)
                    PresensiSessionService.syncPresensiHariIni()
                    AbsensiReminderManager.scheduleAll()
                    completion(true)
                } else {
                    self.toast(response.message.isEmpty ? "Password salah" : response.message)
                    completion(false)
                }
            }
        }
    }

    private func toast(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
