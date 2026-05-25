//
//  PresensiView.swift
//  E-Presensi
//

import SwiftUI
import CoreLocation
import Combine

enum PresensiDestination: Hashable {
    case activity(jenis: String, tipe: String)
    case izin
    case rekap
    case dinasLuar(jenis: String)
}

struct PresensiView: View {
    @AppStorage(Keys.namaPegawai) private var namaPegawai = "USER"
    @AppStorage(Keys.namaOpd) private var namaOpd = ""
    @StateObject private var vm = PresensiViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var currentTime = Date()
    @State private var path = NavigationPath()
    @State private var showPengumumanDismissConfirm = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                headerSection

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        greetingSection

                        if vm.showSummary {
                            rekapPresensiSection
                        }

                        if let izin = vm.izinHariIni {
                            rekapIzinSection(data: izin)
                        }

                        if let khusus = vm.absenKhususHariIni {
                            rekapAbsenKhususSection(data: khusus)
                        }

                        menuSection
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .refreshable { vm.refreshData() }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .navigationDestination(for: PresensiDestination.self) { dest in
                switch dest {
                case .activity(let jenis, let tipe):
                    PresensiActivity(jenis: jenis, tipe: tipe)
                case .izin:
                    IzinView()
                case .rekap:
                    RekapView()
                case .dinasLuar(let jenis):
                    DinasLuarView(initialJenis: jenis)
                }
            }
            .overlay { opdConfirmOverlay }
            .overlay {
                if vm.showAbsenSheet {
                    AbsenDialogOverlay(
                        onPagi: { vm.tapPagi(tipe: vm.absenSheetTipe) },
                        onSiang: { vm.tapSiang(tipe: vm.absenSheetTipe) },
                        onSore: { vm.tapSore(tipe: vm.absenSheetTipe) },
                        onDismiss: { vm.showAbsenSheet = false }
                    )
                    .zIndex(20)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: vm.showAbsenSheet)
            .overlay {
                if vm.showAbsenKhususSheet {
                    AbsenKhususDialogOverlay(
                        onLisan: { vm.tapKhususLisan() },
                        onDLDalam: { vm.tapDinasLuarDalam() },
                        onDLLuar: { vm.tapDinasLuarLuar() },
                        onDismiss: { vm.showAbsenKhususSheet = false }
                    )
                    .zIndex(25)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: vm.showAbsenKhususSheet)
            .overlay {
                if vm.showBirthday {
                    BirthdayPopupView(nama: vm.birthdayName) {
                        vm.closeBirthdayPopup()
                    }
                    .zIndex(100)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: vm.showBirthday)
            .overlay {
                if vm.isCheckingWfhLocation {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView("Memeriksa lokasi WFH...")
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }
                    .zIndex(30)
                }
            }
        }
        .onAppear { vm.onAppear() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            vm.onResume()
        }
        .onChange(of: vm.navigateToActivity) { _, dest in
            if let dest {
                path.append(dest)
                vm.clearNavigation()
            }
        }
        .sheet(isPresented: $vm.showOpdPicker) {
            OpdPickerSheet(opdList: vm.opdList) { opd in
                vm.selectOpd(opd)
            }
        }
        .sheet(isPresented: $vm.showPengumuman) {
            PengumumanUmumSheet(
                imageURL: vm.pengumumanImageURL,
                onDismiss: { showPengumumanDismissConfirm = true },
                onNeverShow: {
                    AppPreference.shared.setValue("1", forKey: Keys.janganTampilkanUmum)
                    vm.showPengumuman = false
                }
            )
        }
        .fullScreenCover(isPresented: $vm.showUbahPassword) {
            UbahPasswordView(isMandatory: true)
        }
        .onChange(of: vm.showUbahPassword) { _, isShowing in
            if !isShowing { vm.tryPresentBirthdayPopup() }
        }
        .alert("Pemberitahuan", isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
        .alert(
            "Konfirmasi Perangkat Daerah",
            isPresented: Binding(
                get: { vm.selectedOpdForConfirm != nil },
                set: { if !$0 { vm.selectedOpdForConfirm = nil } }
            )
        ) {
            Button("Ya, Benar") { vm.confirmSelectedOpd() }
            Button("Tidak") {
                vm.selectedOpdForConfirm = nil
                vm.showOpdPicker = true
            }
        } message: {
            if let opd = vm.selectedOpdForConfirm {
                Text("Apakah Anda yakin memilih Perangkat Daerah berikut?\n\n\(opd.namaOpd)")
            }
        }
        .alert("Daftarkan Lokasi WFH", isPresented: $vm.showWfhRegisterAlert) {
            Button("Ya, Saya di Rumah") {
                locationManager.start()
                requestWfhLocation()
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Pastikan Anda sedang berada di rumah untuk mendaftarkan titik lokasi WFH baru. Apakah Anda ingin melanjutkan?")
        }
        .alert("Daftarkan Lokasi WFH", isPresented: $vm.showWfhLocationConfirm) {
            Button("Daftarkan") { vm.submitWfhLocation() }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Apakah Anda ingin menjadikan lokasi saat ini sebagai titik presensi WFH Anda?\n\n\(vm.wfhAddress)\n\nLat: \(vm.wfhLat)\nLng: \(vm.wfhLng)")
        }
        .alert("Tutup Pengumuman", isPresented: $showPengumumanDismissConfirm) {
            Button("Ya, Jangan Tampilkan Lagi") {
                AppPreference.shared.setValue("1", forKey: Keys.janganTampilkanUmum)
                vm.showPengumuman = false
            }
            Button("Tidak") {
                vm.showPengumuman = false
            }
        } message: {
            Text("Apakah Anda ingin menutup pengumuman ini dan tidak menampilkannya lagi?")
        }
    }

    @ViewBuilder
    private var opdConfirmOverlay: some View {
        if vm.showOpdConfirm {
            ZStack {
                Color.black.opacity(0.45).ignoresSafeArea()
                OpdConfirmDialog(
                    namaOpd: namaOpd.isEmpty ? "-" : namaOpd,
                    onYes: { vm.confirmOpdYes() },
                    onNo: { vm.confirmOpdNo() }
                )
            }
        }
    }

    private var headerSection: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(vm.tanggalText.isEmpty ? formatDate(currentTime) : vm.tanggalText)
                        .font(.subheadline)
                    Text(formatTime(currentTime))
                        .font(.system(size: 36, weight: .bold))
                        .onReceive(timer) { currentTime = $0 }
                }
                .foregroundColor(.white)
                .padding(.top, 60)
                .padding(.leading, 20)
                Spacer()
            }
            .padding(.bottom, 30)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 13/255, green: 23/255, blue: 95/255),
                    Color.blue.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(String(format: PresensiCopy.hai, namaPegawai.uppercased()))
                .font(.headline)
                .bold()
            Text(vm.showEmptyHint ? PresensiCopy.belumAbsen : PresensiCopy.ringkasan)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }

    // Kartu rekap di dashboard — ketuk membuka RekapView
    private var rekapPresensiSection: some View {
        Button {
            path.append(PresensiDestination.rekap)
        } label: {
            RekapHariIniCard(
                jenisAbsen: vm.jenisAbsen,
                keteranganAbsen: vm.keteranganAbsen,
                fotoURL: vm.fotoURL
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private func rekapAbsenKhususSection(data: DataAbsenKhusus) -> some View {
        RekapAbsenKhususCard(data: data)
            .padding(.horizontal)
            .padding(.top, 4)
    }

    private func rekapIzinSection(data: DataIzin) -> some View {
        RekapIzinCard(data: data)
            .padding(.horizontal)
            .padding(.top, 4)
    }

    private var menuSection: some View {
        VStack(spacing: PresensiTheme.cardSpacing) {
            menuButton(title: "Presensi", subtitle: "Biasa", imageName: "absenbiasaasn", action: vm.tapBiasa)
            menuButton(title: "Presensi", subtitle: "Khusus", imageName: "khususf", action: vm.tapKhusus)
            menuButton(title: "Presensi", subtitle: "WFH", imageName: "wfhasnf", action: vm.tapWFH)
            menuButton(title: "Izin", subtitle: "Ajukan Izin", imageName: "izin", action: vm.tapIzin)
        }
        .padding(.horizontal)
    }

    private func menuButton(
        title: String,
        subtitle: String,
        imageName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            MenuCard(title: title, subtitle: subtitle, imageName: imageName)
        }
        .buttonStyle(.plain)
    }

    private func requestWfhLocation() {
        guard let loc = locationManager.location else {
            vm.toast("Gagal mendapatkan lokasi. Pastikan GPS aktif dan akurat.")
            return
        }
        let lat = loc.coordinate.latitude
        let lng = loc.coordinate.longitude
        vm.registerWfhLocation(lat: lat, lng: lng, address: "Memuat alamat...")
        CLGeocoder().reverseGeocodeLocation(loc) { placemarks, _ in
            Task { @MainActor in
                if let p = placemarks?.first {
                    let jalan = p.thoroughfare ?? ""
                    let kel = p.subLocality ?? ""
                    let kec = p.locality ?? ""
                    vm.wfhAddress = "\(jalan), Kel. \(kel), Kec. \(kec)"
                } else {
                    vm.wfhAddress = "Lat: \(lat), Lng: \(lng)"
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "id_ID")
        f.dateFormat = "EEEE, d MMM yyyy"
        return f.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }
}

// MARK: - Menu Card

struct MenuCard: View {
    var title: String
    var subtitle: String
    var imageName: String
    private var isIzin: Bool { title == "Izin" }

    var body: some View {
        ZStack {
            if isIzin { Color.black }
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .clipped()
                .allowsHitTesting(false)
            if isIzin {
                LinearGradient(
                    colors: [Color.black.opacity(0.4), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .allowsHitTesting(false)
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).foregroundColor(.white.opacity(0.9))
                    Text(subtitle).font(.title2).bold().foregroundColor(.white)
                }
                .padding(.leading, 20)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: PresensiTheme.cardRadius))
        .shadow(color: .black.opacity(0.18), radius: 5, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: PresensiTheme.cardRadius))
    }
}

#Preview {
    PresensiView()
}


