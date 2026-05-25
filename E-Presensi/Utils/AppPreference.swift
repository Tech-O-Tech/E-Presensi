//
//  AppPreference.swift
//  E-Presensi
//

import Foundation

final class AppPreference {
    static let shared = AppPreference()
    private let defaults = UserDefaults.standard
    private init() {}

    func getValue(_ key: String) -> String {
        defaults.string(forKey: key) ?? ""
    }

    func setValue(_ value: String, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    var token: String { getValue(Keys.token) }
    var idPegawai: String { getValue(Keys.idPegawai) }
    var idPresensi: String { getValue(Keys.idPresensi) }
    var nipPegawai: String { getValue(Keys.nipPegawai) }
    var idOpd: String { getValue(Keys.idOpd) }
    var idAtasan: String { getValue(Keys.idAtasan) }
    var isLoggedIn: Bool { getValue(Keys.isLogin) == "1" }

    var masuk: Bool { getValue(Keys.masuk) == "1" }
    var siang: Bool { getValue(Keys.siang) == "1" }
    var pulang: Bool { getValue(Keys.pulang) == "1" }
    var statusIzin: Bool { getValue(Keys.statusIzin) == "1" }
    var isFirstTime: Bool { getValue(Keys.firstTime) == "0" }

    func saveLoginSession(_ data: DataUser, password: String) {
        setValue("0", forKey: Keys.ultahShown)
        setValue("1", forKey: Keys.isLogin)
        setValue(data.token, forKey: Keys.token)
        setValue(password, forKey: Keys.password)
        setValue(data.nipPegawai, forKey: Keys.nipPegawai)
        setValue(data.namaPegawai, forKey: Keys.namaPegawai)
        setValue(String(data.idPegawai), forKey: Keys.idPegawai)
        setValue(String(data.idOpd), forKey: Keys.idOpd)
        setValue(data.namaOpd, forKey: Keys.namaOpd)
        setValue(String(data.firstTime), forKey: Keys.firstTime)
        setValue(data.level, forKey: Keys.level)
        setValue(data.deviceId, forKey: Keys.deviceId)
        setValue(data.urlFotoPegawai ?? "", forKey: Keys.urlFotoPegawai)
        setValue("1", forKey: Keys.fingerEnabled)

        if let idAtasan = data.idAtasan {
            setValue(String(idAtasan), forKey: Keys.idAtasan)
        }
        if let idKantor = data.idKantor {
            setValue(String(idKantor), forKey: Keys.idKantor)
        }
        if let namaKantor = data.namaKantor {
            setValue(namaKantor, forKey: Keys.namaKantor)
        }

        if let ultah = data.pengumumanUltah {
            setValue("1", forKey: Keys.hasUltah)
            setValue(ultah.nama, forKey: Keys.namaUltah)
            setValue(ultah.kategori, forKey: Keys.kategori)
        } else {
            setValue("0", forKey: Keys.hasUltah)
            setValue("", forKey: Keys.namaUltah)
            setValue("", forKey: Keys.kategori)
        }

        if let umum = data.pengumumanUmum?.first {
            setValue("1", forKey: Keys.hasUmum)
            setValue(umum.nama, forKey: Keys.nama)
            setValue(umum.fileUrl ?? "", forKey: Keys.fileUrl)
            setValue("0", forKey: Keys.umumShown)
        } else {
            setValue("0", forKey: Keys.hasUmum)
        }
    }

    var isOpdConfirmShown: Bool { getValue(Keys.opdConfirmOnce) == "1" }
    var isPermissionDialogShown: Bool { getValue(Keys.permissionDialogShown) == "1" }

    func setOpdConfirmShown() { setValue("1", forKey: Keys.opdConfirmOnce) }
    func setPermissionDialogShown() { setValue("1", forKey: Keys.permissionDialogShown) }

    /// Logout — hapus sesi login, simpan NIP/password/fingerprint seperti Android.
    func logout() {
        AbsensiReminderManager.cancelAll()
        let finger = getValue(Keys.fingerEnabled)
        let nip = getValue(Keys.nipPegawai)
        let pass = getValue(Keys.password)

        setValue("0", forKey: Keys.isLogin)
        setValue("0", forKey: Keys.hasUltah)
        setValue("0", forKey: Keys.ultahShown)
        defaults.removeObject(forKey: Keys.token)
        defaults.removeObject(forKey: Keys.idPresensi)
        defaults.removeObject(forKey: Keys.idPegawai)

        setValue(finger, forKey: Keys.fingerEnabled)
        setValue(nip, forKey: Keys.nipPegawai)
        setValue(pass, forKey: Keys.password)
    }

    func clearSession() {
        logout()
    }

    /// User berulang tahun hari ini (dari `pengumuman_ultah` login).
    var shouldShowBirthdayPopup: Bool {
        guard getValue(Keys.hasUltah) == "1" else { return false }
        guard getValue(Keys.ultahShown) != "1" else { return false }
        let kategori = getValue(Keys.kategori)
        if kategori.isEmpty { return true }
        return kategori.lowercased().contains("ultah")
    }

    var birthdayDisplayName: String {
        let pegawai = getValue(Keys.namaPegawai)
        if !pegawai.isEmpty { return pegawai }
        return getValue(Keys.namaUltah)
    }
}
