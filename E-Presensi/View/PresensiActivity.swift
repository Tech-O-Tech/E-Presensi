//
//  PresensiActivity.swift
//  E-Presensi
//
//  Setara activity_presensi.xml Android
//

import SwiftUI
import CoreLocation
import Combine

struct PresensiActivity: View {

    var jenis: String
    var tipe: String

    @Environment(\.dismiss) private var dismiss

    @State private var latKantor: Double = 0
    @State private var longKantor: Double = 0
    @State private var latRumah: Double = 0
    @State private var longRumah: Double = 0
    @State private var jarak: Double = 0
    @State private var radiusOk = false
    @State private var userLat: Double = 0
    @State private var userLong: Double = 0

    @State private var keterangan = ""
    @State private var currentTime = Date()
    @State private var showSmileCamera = false
    @State private var capturedImage: UIImage?
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var namaOpd = ""
    @State private var namaKantor = ""
    @State private var showInfoLokasi = false
    @State private var showGpsAlert = false
    @State private var showLocationPermissionAlert = false
    @State private var targetLocationReady = false

    @StateObject private var locationManager = LocationManager()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let pref = AppPreference.shared

    private var titleLabel: String {
        switch tipe {
        case "Khusus": return "Presensi \(jenis) - Di Luar Kantor"
        case "WFH": return "Presensi \(jenis) - Work From Home"
        default: return "Presensi \(jenis) - Di Kantor"
        }
    }

    private var jarakTargetName: String {
        if tipe == "WFH" { return "Rumah" }
        if !namaKantor.isEmpty { return namaKantor }
        if !namaOpd.isEmpty { return namaOpd }
        return "Kantor"
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerBar
                    selfieSection
                    keteranganSection
                    jamSection
                    submitButton
                    if showInfoLokasi {
                        infoLokasiCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }

            if isSubmitting { loadingOverlay }
            if showSuccess { successOverlay }
        }
        .navigationBarHidden(true)
        .onAppear {
            locationManager.refreshServices()
            showInfoLokasi = true
            if tipe == "Khusus" {
                radiusOk = true
            }
            locationManager.start()
            loadTargetLocation()
        }
        .onDisappear {
            locationManager.stop()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            locationManager.refreshServices()
        }
        .onReceive(locationManager.$location) { loc in
            updateJarak(loc)
        }
        .fullScreenCover(isPresented: $showSmileCamera) {
            SmileCameraView(
                onCapture: { image in
                    if let data = ImageCompressor.compress(image) {
                        capturedImage = UIImage(data: data) ?? image
                    } else {
                        capturedImage = image
                    }
                    showSmileCamera = false
                },
                onCancel: { showSmileCamera = false }
            )
        }
        .alert("Pemberitahuan", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("Lokasi Tidak Aktif", isPresented: $showGpsAlert) {
            Button("Buka Pengaturan") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Kembali", role: .cancel) { dismiss() }
        } message: {
            Text("Aktifkan layanan lokasi (GPS) di pengaturan perangkat untuk melanjutkan presensi.")
        }
        .alert("Izin Lokasi Diperlukan", isPresented: $showLocationPermissionAlert) {
            Button("Buka Pengaturan") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Kembali", role: .cancel) { dismiss() }
        } message: {
            Text("Berikan izin lokasi untuk aplikasi E-Presensi agar presensi dapat diverifikasi.")
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        ZStack {
            Text(titleLabel)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 44)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44, alignment: .leading)
                }
                Spacer()
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Foto selfie

    private var selfieSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let img = capturedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 150, height: 150)
            .background(PresensiTheme.navy)
            .clipShape(Circle())

            if capturedImage == nil {
                Button { showSmileCamera = true } label: {
                    editBadge
                }
                .offset(x: 4, y: 4)
            } else {
                Button {
                    capturedImage = nil
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.red, .white)
                }
                .offset(x: 4, y: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Keterangan

    private var keteranganSection: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $keterangan)
                .font(.body)
                .frame(minHeight: 100)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))

            if keterangan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(PresensiCopy.keteranganHint)
                    .font(.body)
                    .foregroundColor(Color(.placeholderText))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .allowsHitTesting(false)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: PresensiTheme.cardRadius)
                .stroke(Color.gray.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Jam

    private var jamSection: some View {
        Text(formatTime(currentTime))
            .font(.system(size: 28, weight: .semibold))
            .monospacedDigit()
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .onReceive(timer) { currentTime = $0 }
    }

    // MARK: - Tombol

    private var submitButton: some View {
        Button(action: submitPresensi) {
            Text(PresensiCopy.tandaiKehadiran)
                .font(.system(size: 16, weight: .semibold))
                .tracking(0.5)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSubmit ? PresensiTheme.navy : Color.gray.opacity(0.45))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: PresensiTheme.cardRadius))
        }
        .disabled(!canSubmit || isSubmitting)
    }

    // MARK: - Info OPD & jarak

    private var infoLokasiCard: some View {
        VStack(spacing: 10) {
            if !namaOpd.isEmpty {
                Text("OPD: \(namaOpd)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if !namaKantor.isEmpty {
                Text("Kantor: \(namaKantor)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            Text(jarakDisplayText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(jarakTextColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: PresensiTheme.cardRadius)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    private var jarakDisplayText: String {
        if !locationManager.isGpsEnabled {
            return "GPS tidak aktif"
        }
        if !locationManager.isAuthorized {
            return "Izin lokasi belum diberikan"
        }
        if tipe != "Khusus", !targetLocationReady {
            return "Memuat titik lokasi \(jarakTargetName)..."
        }
        if userLat == 0 {
            return "Menunggu sinyal GPS..."
        }
        let jarakStr = formatJarak(jarak)
        if radiusOk {
            return "Jarak ke \(jarakTargetName): \(jarakStr) m"
        }
        return "Jarak ke \(jarakTargetName): \(jarakStr) m (di luar radius)"
    }

    private var jarakTextColor: Color {
        if !locationManager.isGpsEnabled || !locationManager.isAuthorized {
            return .red
        }
        if tipe != "Khusus", !targetLocationReady {
            return .orange
        }
        if userLat == 0 {
            return .orange
        }
        return radiusOk ? .green : .red
    }

    private func formatJarak(_ value: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "id_ID")
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    // MARK: - Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            ProgressView("Mengunggah presensi...")
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.green)
                Text("Presensi berhasil")
                    .font(.headline)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }

    private func resetSelfie() {
        capturedImage = nil
    }

    private var editBadge: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 36, height: 36)
            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
            .overlay(
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(PresensiTheme.navy)
            )
    }

    private var canSubmit: Bool {
        guard !isSubmitting else { return false }
        guard locationManager.isGpsEnabled, locationManager.isAuthorized else { return false }
        guard capturedImage != nil, userLat != 0, userLong != 0 else { return false }
        if tipe == "Khusus" { return true }
        return targetLocationReady && radiusOk
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }

    private func loadTargetLocation() {
        namaOpd = pref.getValue(Keys.namaOpd)
        namaKantor = pref.getValue(Keys.namaKantor)
        let token = pref.token
        let idPegawai = pref.idPegawai

        if tipe == "WFH" {
            ApiService.fetchWfhLocation(token: token, idPegawai: idPegawai) { found, lat, lng in
                if found, let lat, let lng {
                    latRumah = lat
                    longRumah = lng
                    pref.setValue(CoordinateFormatter.formatForServer(lat), forKey: Keys.latWfh)
                    pref.setValue(CoordinateFormatter.formatForServer(lng), forKey: Keys.longWfh)
                } else {
                    latRumah = Double(pref.getValue(Keys.latWfh)) ?? 0
                    longRumah = Double(pref.getValue(Keys.longWfh)) ?? 0
                }
                targetLocationReady = latRumah != 0 && longRumah != 0
                if !targetLocationReady {
                    toast("Lokasi WFH belum terdaftar. Silakan daftar di menu WFH.")
                }
                showInfoLokasi = true
                if let loc = locationManager.location {
                    updateJarak(loc)
                }
            }
            return
        }

        let idOpd = pref.getValue(Keys.idOpd)
        guard !idOpd.isEmpty else { return }

        ApiService.getOpd(token: token, idOpd: idOpd) { opd, _ in
            guard let data = opd?.data else { return }
            latKantor = data.latOpd
            longKantor = data.longOpd
            namaOpd = data.namaOpd
            targetLocationReady = latKantor != 0 && longKantor != 0
            showInfoLokasi = true

            let idKantor = pref.getValue(Keys.idKantor)
            if tipe == "Biasa", !idKantor.isEmpty {
                ApiService.getKantor(token: token, idKantor: idKantor) { kantor, _ in
                    if let k = kantor?.data {
                        latKantor = k.latKantor
                        longKantor = k.longKantor
                        namaKantor = k.namaKantor
                        pref.setValue(k.namaKantor, forKey: Keys.namaKantor)
                    }
                    targetLocationReady = latKantor != 0 && longKantor != 0
                    if let loc = locationManager.location {
                        updateJarak(loc)
                    }
                }
            } else if let loc = locationManager.location {
                updateJarak(loc)
            }
        }
    }

    private func updateJarak(_ location: CLLocation?) {
        guard let location else { return }
        userLat = location.coordinate.latitude
        userLong = location.coordinate.longitude

        if tipe == "Khusus" {
            radiusOk = true
            showInfoLokasi = true
            if latKantor != 0 {
                let target = CLLocation(latitude: latKantor, longitude: longKantor)
                jarak = location.distance(from: target)
            }
            return
        }

        let targetLat = tipe == "WFH" ? latRumah : latKantor
        let targetLong = tipe == "WFH" ? longRumah : longKantor
        guard targetLat != 0, targetLong != 0 else {
            radiusOk = false
            return
        }

        targetLocationReady = true
        let target = CLLocation(latitude: targetLat, longitude: targetLong)
        jarak = location.distance(from: target)

        switch tipe {
        case "Biasa": radiusOk = jarak <= 100
        case "WFH": radiusOk = jarak <= 50
        default: radiusOk = true
        }

        #if targetEnvironment(simulator)
        if userLat != 0 {
            radiusOk = true
        }
        #endif

        showInfoLokasi = true
    }

    private func submitPresensi() {
        guard let image = capturedImage else {
            toast("Harus ada foto selfie")
            return
        }
        if !locationManager.isGpsEnabled {
            toast("Aktifkan GPS terlebih dahulu")
            return
        }
        if !locationManager.isAuthorized {
            toast("Berikan izin lokasi pada aplikasi")
            showLocationPermissionAlert = true
            return
        }
        guard userLat != 0, userLong != 0 else {
            toast("Lokasi belum terdeteksi, tunggu GPS")
            return
        }
        if tipe != "Khusus" {
            if !targetLocationReady {
                toast("Titik lokasi \(jarakTargetName) belum dimuat")
                return
            }
            if !radiusOk {
                let max = tipe == "WFH" ? 50 : 100
                toast("Anda berada di luar radius \(max) meter dari \(jarakTargetName)")
                return
            }
        }

        let trimmed = keterangan.trimmingCharacters(in: .whitespacesAndNewlines)
        if tipe == "Khusus" {
            if trimmed.isEmpty {
                toast("Keterangan wajib diisi untuk absen khusus")
                return
            }
            if trimmed.count < 20 {
                toast("Keterangan minimal 20 karakter")
                return
            }
        }

        let ketText = trimmed.isEmpty ? "Tanpa Keterangan" : trimmed
        let latStr = CoordinateFormatter.formatForServer(userLat)
        let lngStr = CoordinateFormatter.formatForServer(userLong)
        let keteranganAPI = "\(tipe);\(latStr),\(lngStr);\(ketText)"
        let token = pref.token
        let idPegawai = pref.idPegawai
        let idPresensi = pref.idPresensi

        isSubmitting = true

        let finish: (Presensi?, Error?) -> Void = { response, error in
            isSubmitting = false
            if let error {
                toast(error.localizedDescription)
                return
            }
            guard let response else {
                toast("Terjadi kesalahan")
                return
            }
            switch response.code {
            case 201, 200:
                if let id = response.data?.idPresensi {
                    pref.setValue(String(id), forKey: Keys.idPresensi)
                }
                PresensiSessionService.syncPresensiHariIni()
                showSuccess = true
                locationManager.stop()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            case 401:
                locationManager.stop()
                NotificationCenter.default.post(name: .sessionExpired, object: nil)
                dismiss()
            default:
                toast(humanReadablePresensiError(response.message))
            }
        }

        switch jenis {
        case "Pagi":
            ApiService.tandaiJamMasuk(
                token: token,
                idPegawai: idPegawai,
                keterangan: keteranganAPI,
                image: image,
                completion: finish
            )
        case "Siang":
            ApiService.tandaiJamSiang(
                token: token,
                idPresensi: idPresensi,
                idPegawai: idPegawai,
                keterangan: keteranganAPI,
                image: image,
                completion: finish
            )
        default:
            ApiService.tandaiJamPulang(
                token: token,
                idPresensi: idPresensi,
                idPegawai: idPegawai,
                keterangan: keteranganAPI,
                image: image,
                completion: finish
            )
        }
    }

    private func toast(_ message: String) {
        alertMessage = message
        showAlert = true
    }

    /// iOS tidak memblokir fake GPS di sisi app; pesan dari server ditulis lebih jelas.
    private func humanReadablePresensiError(_ message: String) -> String {
        let lower = message.lowercased()
        if lower.contains("fake") || lower.contains("mock") || lower.contains("palsu") || lower.contains("simulasi") {
            return "Presensi ditolak server (bukan deteksi fake GPS di aplikasi iOS). Pastikan GPS perangkat asli aktif dan Anda berada dalam radius kantor/rumah. Pesan server: \(message)"
        }
        return message
    }
}
