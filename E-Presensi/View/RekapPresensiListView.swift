//
//  RekapPresensiListView.swift
//  E-Presensi
//
//  Setara `AbsenListFragment.kt` + `AbsenAdapter.kt` Android.
//  Riwayat presensi per BULAN (filter Bulan & Tahun, default bulan berjalan).
//  Sumber data: `GET presensi?id_opd=&id_pegawai=&bulan=&tahun=`.
//

import SwiftUI
import Combine

@MainActor
final class RekapPresensiListViewModel: ObservableObject {
    @Published var items: [RekapPresensiItem] = []
    @Published var isLoading = false
    @Published var bulan: Int
    @Published var tahun: Int

    private let pref = AppPreference.shared

    init() {
        let now = RekapDateHelper.currentMonthYear()
        bulan = now.bulan
        tahun = now.tahun
    }

    var monthLabel: String { RekapDateHelper.monthLabel(bulan: bulan, tahun: tahun) }

    var isCurrentMonth: Bool {
        let now = RekapDateHelper.currentMonthYear()
        return bulan == now.bulan && tahun == now.tahun
    }

    func setMonth(_ b: Int, _ y: Int) {
        bulan = b
        tahun = y
        load()
    }

    func resetToCurrentMonth() {
        let now = RekapDateHelper.currentMonthYear()
        setMonth(now.bulan, now.tahun)
    }

    func load() {
        let token = pref.token
        let idPegawai = pref.idPegawai
        let idOpd = pref.idOpd
        guard !idPegawai.isEmpty, !idOpd.isEmpty else {
            items = []
            isLoading = false
            return
        }

        isLoading = true
        ApiService.getPresensiList(
            token: token,
            idOpd: idOpd,
            idPegawai: idPegawai,
            bulan: String(bulan),
            tahun: String(tahun)
        ) { [weak self] response, _ in
            guard let self else { return }
            self.isLoading = false
            self.items = response?.data ?? []
        }
    }
}

struct RekapPresensiListView: View {
    @StateObject private var vm = RekapPresensiListViewModel()
    @State private var showPicker = false
    @State private var detailItem: RekapPresensiItem?

    var body: some View {
        VStack(spacing: 0) {
            filterBar

            ZStack {
                if vm.isLoading {
                    ProgressView()
                } else if vm.items.isEmpty {
                    Text("Belum ada riwayat presensi")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(vm.items) { item in
                                AbsenRekapRow(item: item)
                                    .onTapGesture { detailItem = item }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { vm.load() }
        .sheet(isPresented: $showPicker) {
            MonthYearPickerSheet(bulan: vm.bulan, tahun: vm.tahun) { b, y in
                vm.setMonth(b, y)
            }
        }
        .sheet(item: $detailItem) { item in
            PresensiDetailSheet(item: item)
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            Button { showPicker = true } label: {
                HStack {
                    Text(vm.monthLabel)
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                    Image(systemName: "calendar")
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(PresensiTheme.navy.opacity(0.4), lineWidth: 1)
                )
                .foregroundColor(PresensiTheme.navy)
            }

            if !vm.isCurrentMonth {
                Button("Reset") { vm.resetToCurrentMonth() }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(PresensiTheme.navy)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: - Status helper

enum RekapPresensiStatus {
    static func info(_ jenisRaw: String?) -> (label: String, color: Color) {
        switch (jenisRaw ?? "HADIR").uppercased() {
        case "HADIR": return ("Hadir", Color(red: 0x2E/255, green: 0x7D/255, blue: 0x32/255))
        case "IZIN": return ("Izin", Color(red: 0xF9/255, green: 0xA8/255, blue: 0x25/255))
        case "LIBUR": return ("Libur", Color(red: 0x75/255, green: 0x75/255, blue: 0x75/255))
        case "ALPA", "ALFA": return ("Tidak Hadir", Color(red: 0xC6/255, green: 0x28/255, blue: 0x28/255))
        default:
            let j = (jenisRaw ?? "").lowercased().capitalized
            return (j, Color(red: 0x60/255, green: 0x7D/255, blue: 0x8B/255))
        }
    }

    static func safeJam(_ s: String?) -> String {
        guard let s, !s.isEmpty else { return "-" }
        if s == "null" || s == "0" || s.caseInsensitiveCompare("Invalid Date") == .orderedSame {
            return "-"
        }
        return s
    }

    /// `ket_masuk` berformat "Jenis;lat,long;keterangan" → ambil bagian keterangan.
    static func parseKeterangan(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "" }
        let parts = raw.components(separatedBy: ";")
        let ket = parts.count > 2 ? parts[2].trimmingCharacters(in: .whitespaces) : ""
        if !ket.isEmpty && ket.caseInsensitiveCompare("Tanpa Keterangan") != .orderedSame {
            return ket
        }
        return ""
    }
}

// MARK: - Row

struct AbsenRekapRow: View {
    let item: RekapPresensiItem

    private var jenis: String { (item.jenis ?? "HADIR").uppercased() }

    var body: some View {
        let status = RekapPresensiStatus.info(item.jenis)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text(RekapDateHelper.extractDate(item.createdAt))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(PresensiTheme.navy)
                Spacer()
                Text(status.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(status.color))
            }

            switch jenis {
            case "LIBUR":
                EmptyView()
            case "IZIN":
                Text((item.ketMasuk?.isEmpty == false ? item.ketMasuk! : "Izin"))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            default:
                HStack(spacing: 0) {
                    jamColumn(title: "Masuk", value: RekapPresensiStatus.safeJam(item.jamMasuk))
                    jamColumn(title: "Siang", value: RekapPresensiStatus.safeJam(item.jamSiang))
                    jamColumn(title: "Pulang", value: RekapPresensiStatus.safeJam(item.jamPulang))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private func jamColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Detail sheet

struct PresensiDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: RekapPresensiItem
    @State private var fullscreenURL: URL?

    private var jenis: String { (item.jenis ?? "HADIR").uppercased() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    infoRow("Tanggal", RekapDateHelper.extractDate(item.createdAt))
                    infoRow("Status", RekapPresensiStatus.info(item.jenis).label)

                    switch jenis {
                    case "LIBUR":
                        EmptyView()
                    case "IZIN":
                        keteranganBlock(item.ketMasuk?.isEmpty == false ? item.ketMasuk! : "Izin")
                    default:
                        infoRow("Jam Masuk", RekapPresensiStatus.safeJam(item.jamMasuk))
                        infoRow("Jam Siang", RekapPresensiStatus.safeJam(item.jamSiang))
                        infoRow("Jam Pulang", RekapPresensiStatus.safeJam(item.jamPulang))
                        let ket = RekapPresensiStatus.parseKeterangan(item.ketMasuk)
                        if !ket.isEmpty { keteranganBlock(ket) }
                    }

                    fotoBlock("Foto Masuk", item.fotoMasuk)
                    fotoBlock("Foto Siang", item.fotoSiang)
                    fotoBlock("Foto Pulang", item.fotoPulang)
                }
                .padding(16)
            }
            .navigationTitle("Detail Presensi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tutup") { dismiss() }
                }
            }
            .fullScreenCover(item: $fullscreenURL) { url in
                FullscreenImageView(url: url)
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.system(size: 14, weight: .medium))
            Spacer()
        }
    }

    private func keteranganBlock(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Keterangan")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Text(text)
                .font(.system(size: 14))
        }
    }

    @ViewBuilder
    private func fotoBlock(_ label: String, _ raw: String?) -> some View {
        if let url = FileUrl.url(raw) {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        Color.gray.opacity(0.12).overlay(ProgressView())
                    default:
                        Color.gray.opacity(0.12)
                            .overlay(Image(systemName: "photo").foregroundColor(.gray))
                    }
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture { fullscreenURL = url }
            }
        }
    }
}

// MARK: - Fullscreen image (zoomable)

extension URL: Identifiable { public var id: String { absoluteString } }

struct FullscreenImageView: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL
    @State private var scale: CGFloat = 1

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { scale = max(1, $0) }
                                .onEnded { _ in withAnimation { scale = max(1, scale) } }
                        )
                case .empty:
                    ProgressView().tint(.white)
                default:
                    Image(systemName: "exclamationmark.triangle").foregroundColor(.white)
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}
