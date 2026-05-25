//
//  BiometricLoginHelper.swift
//  E-Presensi
//

import LocalAuthentication

enum BiometricLoginHelper {

    static var iconSystemName: String {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        switch context.biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "lock.fill"
        }
    }

    static var toggleTitle: String {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        switch context.biometryType {
        case .faceID:
            return "Gunakan Face ID"
        case .touchID:
            return "Gunakan Touch ID"
        default:
            return "Gunakan login biometrik"
        }
    }

    static var promptTitle: String {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        switch context.biometryType {
        case .faceID:
            return "Login dengan Face ID"
        case .touchID:
            return "Login dengan Touch ID"
        default:
            return "Login dengan Biometrik"
        }
    }

    static var promptReason: String {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        switch context.biometryType {
        case .faceID:
            return "Gunakan Face ID untuk masuk ke E-Presensi"
        case .touchID:
            return "Gunakan sidik jari untuk masuk ke E-Presensi"
        default:
            return "Masuk ke E-Presensi"
        }
    }

    static func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    static func canShowLoginButton(pref: AppPreference = .shared) -> Bool {
        guard pref.getValue(Keys.fingerEnabled) == "1" else { return false }
        guard !pref.nipPegawai.isEmpty, !pref.getValue(Keys.password).isEmpty else { return false }
        return canUseBiometrics()
    }

    static func authenticate(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, error)
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: promptReason
        ) { success, authError in
            DispatchQueue.main.async {
                completion(success, authError)
            }
        }
    }
}
