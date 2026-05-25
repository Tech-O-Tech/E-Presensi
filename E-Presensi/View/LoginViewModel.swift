//
//  LoginViewModel.swift
//  E-Presensi
//

import SwiftUI
import LocalAuthentication
import Combine


@MainActor
final class LoginViewModel: ObservableObject {
    @Published var nip = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var alertMessage = ""
    @Published var showAlert = false
    @Published var needsChangePassword = false
    @Published private(set) var showBiometricLogin = false
    @Published private(set) var biometricIconName = "faceid"
    @Published private(set) var biometricAccessibilityLabel = "Login dengan Face ID"

    func refreshBiometricAvailability() {
        biometricIconName = BiometricLoginHelper.iconSystemName
        biometricAccessibilityLabel = BiometricLoginHelper.promptTitle
        showBiometricLogin = BiometricLoginHelper.canShowLoginButton()
    }

    func login(completion: @escaping (Bool) -> Void) {
        let trimmedNip = nip.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedNip.isEmpty, !trimmedPassword.isEmpty else {
            alertMessage = "NIP dan Password tidak boleh kosong"
            showAlert = true
            completion(false)
            return
        }

        isLoading = true
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "ios_device"

        ApiService.login(nip: trimmedNip, password: trimmedPassword, deviceId: deviceId) { [weak self] response, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false

                if let error {
                    if let urlError = error as? URLError,
                       urlError.code == .notConnectedToInternet || urlError.code == .timedOut {
                        self.alertMessage = "Gagal tersambung. Periksa koneksi internet Anda."
                    } else if error is DecodingError {
                        self.alertMessage = "Gagal memproses data server. Perbarui aplikasi atau hubungi admin."
                    } else {
                        self.alertMessage = error.localizedDescription
                    }
                    self.showAlert = true
                    completion(false)
                    return
                }

                guard let res = response else {
                    self.alertMessage = "Gagal terhubung ke server"
                    self.showAlert = true
                    completion(false)
                    return
                }

                if res.code == 200, let userData = res.data {
                    AppPreference.shared.saveLoginSession(userData, password: trimmedPassword)
                    PresensiSessionService.syncPresensiHariIni()
                    AbsensiReminderManager.scheduleAll()
                    self.needsChangePassword = AppPreference.shared.isFirstTime
                    self.refreshBiometricAvailability()
                    completion(true)
                } else {
                    self.alertMessage = res.message.isEmpty ? "NIP atau Password salah" : res.message
                    self.showAlert = true
                    completion(false)
                }
            }
        }
    }

    /// Login cepat dengan Face ID / Touch ID (setara `btnFingerprint` Android).
    func authenticateBiometric(completion: @escaping (Bool) -> Void) {
        refreshBiometricAvailability()

        guard showBiometricLogin else {
            if AppPreference.shared.getValue(Keys.fingerEnabled) != "1" {
                alertMessage = "Login Face ID belum tersedia. Masuk dengan NIP dan password terlebih dahulu."
            } else if AppPreference.shared.nipPegawai.isEmpty || AppPreference.shared.getValue(Keys.password).isEmpty {
                alertMessage = "Data login tidak ditemukan. Masuk dengan NIP dan password."
            } else {
                alertMessage = "Face ID tidak tersedia di perangkat ini."
            }
            showAlert = true
            completion(false)
            return
        }

        let pref = AppPreference.shared
        let savedNip = pref.nipPegawai
        let savedPassword = pref.getValue(Keys.password)

        BiometricLoginHelper.authenticate { [weak self] success, error in
            Task { @MainActor in
                guard let self else { return }

                if success {
                    self.nip = savedNip
                    self.password = savedPassword
                    self.login(completion: completion)
                    return
                }

                if let laError = error as? LAError,
                   laError.code == .userCancel || laError.code == .appCancel || laError.code == .systemCancel {
                    completion(false)
                    return
                }

                self.alertMessage = "Face ID dibatalkan"
                self.showAlert = true
                completion(false)
            }
        }
    }
}
