//
//  PresensiViewModel.swift
//  E-Presensi
//

import SwiftUI
import CoreLocation
import Combine

@MainActor
final class PresensiViewModel: ObservableObject {

    @Published var tanggalText = ""
    @Published var isRefreshing = false
    @Published var showSummary = false
    @Published var showEmptyHint = true
    @Published var jenisAbsen = ""
    @Published var keteranganAbsen = ""
    @Published var fotoURL = ""

    /// Data absen khusus hari ini (DL/Khusus Lisan) untuk ditampilkan di dashboard.
    @Published var absenKhususHariIni: DataAbsenKhusus?

    /// Data izin hari ini (jika user sedang dalam status izin).
    @Published var izinHariIni: DataIzin?

    @Published var masuk = false
    @Published var siang = false
    @Published var pulang = false
    @Published var statusIzin = false

    @Published var showAlert = false
    @Published var alertMessage = ""

    @Published var showAbsenSheet = false
    @Published var absenSheetTipe = "Biasa"

    /// Dialog "Pilih Jenis Absen Khusus" (Lisan / DL Dalam / DL Luar)
    @Published var showAbsenKhususSheet = false

    @Published var showWfhRegisterAlert = false
    @Published var showWfhLocationConfirm = false
    @Published var isCheckingWfhLocation = false
    @Published var wfhAddress = ""
    @Published var wfhLat: Double = 0
    @Published var wfhLng: Double = 0

    @Published var showOpdConfirm = false
    @Published var showOpdPicker = false
    @Published var showBirthday = false
    @Published var showPengumuman = false
    @Published var showUbahPassword = false
    @Published var opdList: [DataAllOpd] = []
    @Published var selectedOpdForConfirm: DataAllOpd?
    @Published var birthdayName = ""
    @Published var pengumumanImageURL = ""

    @Published var navigateToActivity: PresensiDestination?

    private let pref = AppPreference.shared
    private var didSetup = false
    private var pendingBirthdayPopup = false

    init() {
        loadFlagsFromPreferences()
        tanggalText = formatToday()
    }

    /// Setara onViewCreated + onResume Android
    func onAppear() {
        loadFlagsFromPreferences()
        tanggalText = formatToday()

        if !didSetup {
            didSetup = true
            runInitialSetup()
        }
        refreshData()
        syncWfhLocationFromServer()
        tryPresentBirthdayPopup()
    }

    func onResume() {
        refreshData()
    }

    private func runInitialSetup() {
        if pref.isFirstTime {
            showUbahPassword = true
        }

        if !pref.isOpdConfirmShown {
            showOpdConfirm = true
        }

        tryPresentBirthdayPopup()
        checkPengumumanUmum()
    }

    /// Tampilkan kartu `cardulangtahun` + confetti (setelah dialog OPD/password selesai).
    func tryPresentBirthdayPopup() {
        guard pref.shouldShowBirthdayPopup else {
            pendingBirthdayPopup = false
            return
        }

        let nama = pref.birthdayDisplayName
        guard !nama.isEmpty else { return }

        guard !showOpdConfirm, !showUbahPassword, !showOpdPicker else {
            pendingBirthdayPopup = true
            return
        }

        birthdayName = nama
        showBirthday = true
        pendingBirthdayPopup = false
    }

    func closeBirthdayPopup() {
        showBirthday = false
        pref.setValue("1", forKey: Keys.ultahShown)
        pendingBirthdayPopup = false
    }

    private func checkPengumumanUmum() {
        let umum = pref.getValue(Keys.nama)
        let belumDitampilkan = pref.getValue(Keys.umumShown) != "1"
        let bolehTampil = pref.getValue(Keys.janganTampilkanUmum) != "1"
        let url = pref.getValue(Keys.fileUrl)

        if !umum.isEmpty, belumDitampilkan, bolehTampil {
            pengumumanImageURL = url
            showPengumuman = true
            pref.setValue("1", forKey: Keys.umumShown)
        }
    }

    func confirmOpdYes() {
        pref.setOpdConfirmShown()
        showOpdConfirm = false
        scheduleBirthdayAfterDialog()
    }

    func confirmOpdNo() {
        pref.setOpdConfirmShown()
        showOpdConfirm = false
        loadOpdList()
        showOpdPicker = true
        scheduleBirthdayAfterDialog()
    }

    func loadOpdList() {
        ApiService.getAllOpd { [weak self] response, _ in
            guard let self else { return }
            self.opdList = response?.data ?? []
        }
    }

    func selectOpd(_ opd: DataAllOpd) {
        selectedOpdForConfirm = opd
        showOpdPicker = false
        scheduleBirthdayAfterDialog()
    }

    private func scheduleBirthdayAfterDialog() {
        guard pendingBirthdayPopup || pref.shouldShowBirthdayPopup else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            tryPresentBirthdayPopup()
        }
    }

    func confirmSelectedOpd() {
        guard let opd = selectedOpdForConfirm else { return }
        let token = pref.token
        let nip = pref.nipPegawai

        ApiService.editOpd(token: token, nip: nip, idOpd: String(opd.idOpd)) { [weak self] response, _ in
            guard let self else { return }
            if response?.code == 200 {
                self.pref.setValue(String(opd.idOpd), forKey: Keys.idOpd)
                self.pref.setValue(opd.namaOpd, forKey: Keys.namaOpd)
                self.toast("OPD berhasil diperbarui")
            } else {
                self.toast(response?.message ?? "Gagal update OPD")
            }
            self.selectedOpdForConfirm = nil
            self.scheduleBirthdayAfterDialog()
        }
    }

    func refreshData() {
        let token = pref.token
        let idPegawai = pref.idPegawai
        guard !token.isEmpty, !idPegawai.isEmpty else { return }

        isRefreshing = true

        // Ketiga endpoint dijalankan paralel & independen agar kegagalan/lambatnya
        // salah satu tidak memblokir yang lain (mis. izin lambat tidak menahan rekap khusus).
        fetchIzinHariIni(token: token, idPegawai: idPegawai)
        fetchPresensi(token: token, idPegawai: idPegawai)
        fetchAbsenKhususHariIni(token: token, idPegawai: idPegawai)
    }

    private func fetchIzinHariIni(token: String, idPegawai: String) {
        ApiService.getIzinHariIni(token: token, idPegawai: idPegawai) { [weak self] response, _ in
            guard let self else { return }
            let izinAktif = response?.code == 200
            self.statusIzin = izinAktif
            self.izinHariIni = izinAktif ? response?.data : nil
            self.pref.setValue(izinAktif ? "1" : "0", forKey: Keys.statusIzin)
            self.updateEmptyHint()
        }
    }

    private func fetchAbsenKhususHariIni(token: String, idPegawai: String) {
        ApiService.getAbsenKhususHariIni(token: token, idPegawai: idPegawai) { [weak self] response, _ in
            guard let self else { return }
            if response?.code == 200, let data = response?.data {
                self.absenKhususHariIni = data
            } else {
                self.absenKhususHariIni = nil
            }
            self.updateEmptyHint()
        }
    }

    /// `showEmptyHint` benar hanya jika user belum melakukan presensi (biasa/WFH),
    /// belum mengajukan izin, dan belum mengisi absen khusus (DL/Lisan) hari ini.
    private func updateEmptyHint() {
        let hasPresensi = masuk || siang || pulang
        let hasIzin = statusIzin
        let hasAbsenKhusus = absenKhususHariIni != nil
        showEmptyHint = !(hasPresensi || hasIzin || hasAbsenKhusus)
    }

    private func fetchPresensi(token: String, idPegawai: String) {
        ApiService.getPresensi(token: token, idPegawai: idPegawai) { [weak self] response, error in
            guard let self else { return }
            self.isRefreshing = false
            self.loadFlagsFromPreferences()

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
                self.resetPresensiFlags()
                self.clearSummaryDisplay()
                self.showSummary = false
                self.updateEmptyHint()

            case 200:
                guard let data = response.data else {
                    self.toast("Data presensi kosong")
                    return
                }
                self.applyPresensiData(data)
                let hasAny = self.masuk || self.siang || self.pulang
                self.showSummary = hasAny
                self.updateEmptyHint()

            case 401:
                NotificationCenter.default.post(name: .sessionExpired, object: nil)

            default:
                self.toast(response.message)
            }
        }
    }

    private func applyPresensiData(_ data: DataPresensi) {
        pref.setValue(String(data.idPresensi), forKey: Keys.idPresensi)

        var jenis = ""
        var foto = ""
        var ket = ""

        if isValidJam(data.jamMasuk) {
            jenis = "Presensi Pagi"
            foto = data.fotoMasuk
            ket = data.ketMasuk
            masuk = true
            pref.setValue("1", forKey: Keys.masuk)
        } else {
            masuk = false
            pref.setValue("0", forKey: Keys.masuk)
        }

        if isValidJam(data.jamSiang) {
            jenis = "Presensi Siang"
            foto = data.fotoSiang ?? ""
            ket = data.ketSiang ?? ket
            siang = true
            pref.setValue("1", forKey: Keys.siang)
        } else {
            siang = false
            pref.setValue("0", forKey: Keys.siang)
        }

        if isValidJam(data.jamPulang) {
            jenis = "Presensi Pulang"
            foto = data.fotoPulang ?? ""
            ket = data.ketPulang ?? ket
            pulang = true
            pref.setValue("1", forKey: Keys.pulang)
        } else {
            pulang = false
            pref.setValue("0", forKey: Keys.pulang)
        }

        let parsed = PresensiKetParser.parse(ket)
        jenisAbsen = jenis
        keteranganAbsen = parsed.keterangan
        fotoURL = foto
    }

    private func resetPresensiFlags() {
        masuk = false
        siang = false
        pulang = false
        pref.setValue("0", forKey: Keys.masuk)
        pref.setValue("0", forKey: Keys.siang)
        pref.setValue("0", forKey: Keys.pulang)
        pref.setValue("", forKey: Keys.idPresensi)
    }

    private func clearSummaryDisplay() {
        jenisAbsen = ""
        keteranganAbsen = ""
        fotoURL = ""
    }

    private func loadFlagsFromPreferences() {
        masuk = pref.masuk
        siang = pref.siang
        pulang = pref.pulang
        statusIzin = pref.statusIzin
    }

    private func formatToday() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "id_ID")
        f.dateFormat = "EEEE, d MMM yyyy"
        return f.string(from: Date())
    }

    private func isValidJam(_ jam: String) -> Bool {
        PresensiSessionService.isValidJam(jam)
    }

    // MARK: - Menu

    func tapBiasa() {
        if checkIzinBlock() { return }
        absenSheetTipe = "Biasa"
        showAbsenSheet = true
    }

    func tapKhusus() {
        if checkIzinBlock() { return }

        // ── Perilaku lama (langsung membuka dialog Pagi/Siang/Sore) ─────────
        // Dipertahankan sebagai komentar agar mudah dikembalikan jika diperlukan.
        // absenSheetTipe = "Khusus"
        // showAbsenSheet = true

        // ── Perilaku baru: tampilkan dialog pilihan jenis absen khusus ──────
        absenSheetTipe = "Khusus"
        showAbsenKhususSheet = true
    }

    // MARK: - Absen khusus (Lisan / DL Dalam / DL Luar)

    func tapKhususLisan() {
        showAbsenKhususSheet = false
        absenSheetTipe = "Khusus"
        showAbsenSheet = true
    }

    func tapDinasLuarDalam() {
        showAbsenKhususSheet = false
        navigateToActivity = .dinasLuar(jenis: "DL DALAM KABUPATEN")
    }

    func tapDinasLuarLuar() {
        showAbsenKhususSheet = false
        navigateToActivity = .dinasLuar(jenis: "DL LUAR KABUPATEN")
    }

    func tapWFH() {
        if checkIzinBlock() { return }
        if isCheckingWfhLocation { return }

        isCheckingWfhLocation = true
        fetchWfhLocationFromServer { [weak self] hasLocation in
            guard let self else { return }
            self.isCheckingWfhLocation = false

            if hasLocation || self.hasStoredWfhLocation() {
                self.openWfhAbsenSheet()
            } else {
                self.showWfhRegisterAlert = true
            }
        }
    }

    func tapIzin() {
        if statusIzin {
            toast("Anda sudah mengajukan izin hari ini")
            return
        }
        if masuk {
            toast("Anda sudah presensi dan tidak dapat mengajukan izin")
            return
        }
        navigateToActivity = .izin
    }

    func tapRekap() {
        navigateToActivity = .rekap
    }

    // MARK: - Absen dialog

    func tapPagi(tipe: String) {
        if checkIzinBlock() { return }
        if masuk {
            toast("Presensi pagi sudah dilakukan")
            return
        }
        showAbsenSheet = false
        navigateToActivity = .activity(jenis: "Pagi", tipe: tipe)
    }

    func tapSiang(tipe: String) {
        if checkIzinBlock() { return }
        if siang {
            toast("Presensi siang sudah dilakukan")
            return
        }
        if !masuk {
            toast("Presensi pagi belum dilakukan")
            return
        }
        showAbsenSheet = false
        navigateToActivity = .activity(jenis: "Siang", tipe: tipe)
    }

    func tapSore(tipe: String) {
        if checkIzinBlock() { return }
        if pulang {
            toast("Presensi sore sudah dilakukan")
            return
        }
        if !siang {
            toast("Presensi siang belum dilakukan")
            return
        }
        showAbsenSheet = false
        navigateToActivity = .activity(jenis: "Pulang", tipe: tipe)
    }

    private func checkIzinBlock() -> Bool {
        if statusIzin {
            alertMessage = "Anda sedang dalam status izin dan tidak dapat melakukan presensi hari ini."
            showAlert = true
            return true
        }
        return false
    }

    func registerWfhLocation(lat: Double, lng: Double, address: String) {
        wfhLat = lat
        wfhLng = lng
        wfhAddress = address
        showWfhLocationConfirm = true
    }

    func submitWfhLocation() {
        let token = pref.token
        let idPegawai = pref.idPegawai
        showWfhLocationConfirm = false

        fetchWfhLocationFromServer { [weak self] hasLocation in
            guard let self else { return }
            if hasLocation {
                self.toast("Lokasi WFH sudah terdaftar di server")
                self.openWfhAbsenSheet()
                return
            }
            self.uploadWfhLocation(token: token, idPegawai: idPegawai)
        }
    }

    private func uploadWfhLocation(token: String, idPegawai: String) {
        let latStr = CoordinateFormatter.formatForServer(wfhLat)
        let lngStr = CoordinateFormatter.formatForServer(wfhLng)

        ApiService.setWFH(
            token: token,
            idPegawai: idPegawai,
            lat: latStr,
            long: lngStr
        ) { [weak self] success, code, message in
            guard let self else { return }
            if success {
                self.pref.setValue(latStr, forKey: Keys.latWfh)
                self.pref.setValue(lngStr, forKey: Keys.longWfh)
                self.toast("Lokasi WFH Berhasil Terdaftar")
                self.openWfhAbsenSheet()
            } else if code == 401 {
                NotificationCenter.default.post(name: .sessionExpired, object: nil)
            } else {
                self.toast(message ?? "Gagal mendaftarkan lokasi WFH")
            }
        }
    }

    private func openWfhAbsenSheet() {
        absenSheetTipe = "WFH"
        showAbsenSheet = true
    }

    private func hasStoredWfhLocation() -> Bool {
        guard let lat = Double(pref.getValue(Keys.latWfh)),
              let lng = Double(pref.getValue(Keys.longWfh)) else { return false }
        return lat != 0 && lng != 0
    }

    /// Selalu cek server; simpan ke prefs jika lokasi WFH ditemukan.
    private func fetchWfhLocationFromServer(completion: @escaping (Bool) -> Void) {
        let token = pref.token
        let idPegawai = pref.idPegawai
        guard !token.isEmpty, !idPegawai.isEmpty else {
            completion(false)
            return
        }

        ApiService.fetchWfhLocation(token: token, idPegawai: idPegawai) { [weak self] found, lat, lng in
            guard let self else {
                completion(false)
                return
            }
            if found, let lat, let lng {
                self.pref.setValue(CoordinateFormatter.formatForServer(lat), forKey: Keys.latWfh)
                self.pref.setValue(CoordinateFormatter.formatForServer(lng), forKey: Keys.longWfh)
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    private func syncWfhLocationFromServer() {
        fetchWfhLocationFromServer { _ in }
    }

    func clearNavigation() {
        navigateToActivity = nil
    }

    func toast(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
