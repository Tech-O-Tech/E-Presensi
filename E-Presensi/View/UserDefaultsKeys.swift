//
//  UserDefaultsKeys.swift
//  E-Presensi
//
//  Key sama dengan SharedPreference Android
//

struct Keys {
    static let isLogin = "isLogin"
    static let token = "token"
    static let password = "password"
    static let nipPegawai = "nip_pegawai"
    static let namaPegawai = "nama_pegawai"
    static let idPegawai = "id_pegawai"
    static let idPresensi = "id_presensi"
    static let idAtasan = "id_atasan"
    static let idOpd = "id_opd"
    static let namaOpd = "nama_opd"
    static let idKantor = "id_kantor"
    static let namaKantor = "nama_kantor"
    static let level = "level"
    static let urlFotoPegawai = "url_foto_pegawai"
    static let deviceId = "device_id"
    static let fingerEnabled = "finger_enabled"
    static let firstTime = "first_time"

    static let masuk = "masuk"
    static let siang = "siang"
    static let pulang = "pulang"
    static let statusIzin = "status_izin"

    static let latWfh = "lat"
    static let longWfh = "long"

    static let hasUltah = "has_ultah"
    static let namaUltah = "nama_ultah"
    static let ultahShown = "ultah_shown"
    static let kategori = "kategori"
    static let nama = "nama"
    static let hasUmum = "has_umum"
    static let fileUrl = "file_url"
    static let umumShown = "umum_shown"
    static let janganTampilkanUmum = "jangan_tampilkan_umum"

    static let opdConfirmOnce = "opd_confirm_once"
    static let permissionDialogShown = "permission_dialog_shown"

    /// Setara `ui_pref` dark_mode Android
    static let darkMode = "dark_mode"
}
