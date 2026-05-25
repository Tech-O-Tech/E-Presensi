//
//  PresensiSessionService.swift
//  E-Presensi
//

import Foundation

enum PresensiSessionService {

    static func syncPresensiHariIni(completion: ((Bool) -> Void)? = nil) {
        let pref = AppPreference.shared
        let token = pref.token
        let idPegawai = pref.idPegawai
        guard !token.isEmpty, !idPegawai.isEmpty else {
            completion?(false)
            return
        }

        ApiService.getPresensi(token: token, idPegawai: idPegawai) { response, _ in
            guard response?.code == 200, let data = response?.data else {
                completion?(false)
                return
            }
            pref.setValue(String(data.idPresensi), forKey: Keys.idPresensi)
            pref.setValue(Self.isValidJam(data.jamMasuk) ? "1" : "0", forKey: Keys.masuk)
            pref.setValue(Self.isValidJam(data.jamSiang) ? "1" : "0", forKey: Keys.siang)
            pref.setValue(Self.isValidJam(data.jamPulang) ? "1" : "0", forKey: Keys.pulang)
            completion?(true)
        }
    }

    static func isValidJam(_ jam: String) -> Bool {
        !jam.isEmpty && jam != "Invalid Date"
    }
}
