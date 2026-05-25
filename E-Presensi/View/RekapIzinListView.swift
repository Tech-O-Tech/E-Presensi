//
//  RekapIzinListView.swift
//  E-Presensi
//
//  Setara `IzinListFragment.kt` + `IzinAdapter.kt` Android.
//  Riwayat izin pegawai. Server mengembalikan semua izin; filter Bulan & Tahun
//  dilakukan di sisi client. Default: bulan berjalan.
//  Sumber data: `GET izin?id_pegawai=`.
//

import SwiftUI
import Combine

@MainActor
final class RekapIzinListViewModel: ObservableObject {
    @Published var filtered: [RekapIzinItem] = []
    @Published var isLoading = false
    @Published var bulan: Int
    @Published var tahun: Int

    private var allIzin: [RekapIzinItem] = []
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
        applyFilter()
    }

    func resetToCurrentMonth() {
        let now = RekapDateHelper.currentMonthYear()
        setMonth(now.bulan, now.tahun)
    }

    func load() {
        let token = pref.token
        let idPegawai = pref.idPegawai
        guard !idPegawai.isEmpty else {
            allIzin = []
            filtered = []
            isLoading = false
            return
        }

        isLoading = true
        ApiService.getIzinList(token: token, idPegawai: idPegawai) { [weak self] response, _ in
            guard let self else { return }
            self.isLoading = false
            self.allIzin = response?.data ?? []
            self.applyFilter()
        }
    }

    /// Izin masuk bila rentang [tanggalIzin..tanggalSelesai] beririsan dengan bulan terpilih.
    private func applyFilter() {
        let monthStart = String(format: "%04d-%02d-01", tahun, bulan)
        let monthEnd = String(format: "%04d-%02d-31", tahun, bulan)
        filtered = allIzin.filter { izin in
            guard let start = RekapDateHelper.normalizeDate(izin.tanggalIzin) else { return false }
            let end = RekapDateHelper.normalizeDate(izin.tanggalSelesai) ?? start
            return start <= monthEnd && end >= monthStart
        }
    }
}

struct RekapIzinListView: View {
    @StateObject private var vm = RekapIzinListViewModel()
    @State private var showPicker = false
    @State private var detailItem: RekapIzinItem?

    var body: some View {
        VStack(spacing: 0) {
            filterBar

            ZStack {
                if vm.isLoading {
                    ProgressView()
                } else if vm.filtered.isEmpty {
                    Text("Belum ada riwayat izin")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(vm.filtered) { item in
                                IzinRekapRow(item: item)
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
            IzinDetailSheet(item: item)
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

enum RekapIzinStatus {
    static func info(_ verifikasi: Int?) -> (label: String, color: Color) {
        switch verifikasi {
        case 1: return ("Disetujui", Color(red: 0x2E/255, green: 0x7D/255, blue: 0x32/255))
        case 2: return ("Ditolak", Color(red: 0xC6/255, green: 0x28/255, blue: 0x28/255))
        default: return ("Menunggu", Color(red: 0xF9/255, green: 0xA8/255, blue: 0x25/255))
        }
    }

    static func formatRange(_ start: String?, _ end: String?) -> String {
        let a = start ?? ""
        let b = end ?? ""
        if a.isEmpty && b.isEmpty { return "-" }
        if a == b || b.isEmpty { return a }
        return "\(a) s/d \(b)"
    }
}

// MARK: - Row

struct IzinRekapRow: View {
    let item: RekapIzinItem

    var body: some View {
        let status = RekapIzinStatus.info(item.verifikasi)
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                Text((item.jenisIzin?.isEmpty == false ? item.jenisIzin! : "Izin"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PresensiTheme.navy)
                Spacer()
                Text(status.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(status.color))
            }

            Text(RekapIzinStatus.formatRange(item.tanggalIzin, item.tanggalSelesai))
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            Text((item.keterangan?.isEmpty == false ? item.keterangan! : "-"))
                .font(.system(size: 13))
                .lineLimit(3)
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
}

// MARK: - Detail sheet

struct IzinDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let item: RekapIzinItem
    @State private var fullscreenURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    infoRow("Jenis", item.jenisIzin?.isEmpty == false ? item.jenisIzin! : "Izin")
                    infoRow("Tanggal", RekapIzinStatus.formatRange(item.tanggalIzin, item.tanggalSelesai))
                    infoRow("Status", RekapIzinStatus.info(item.verifikasi).label)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Keterangan")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text(item.keterangan?.isEmpty == false ? item.keterangan! : "-")
                            .font(.system(size: 14))
                    }

                    buktiBlock
                }
                .padding(16)
            }
            .navigationTitle("Detail Izin")
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

    @ViewBuilder
    private var buktiBlock: some View {
        if let url = FileUrl.url(item.bukti) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Bukti")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                if FileUrl.isPdf(item.bukti) {
                    Button {
                        openURL(url)
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("Buka PDF")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(PresensiTheme.navy)
                        .cornerRadius(8)
                    }
                } else {
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
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture { fullscreenURL = url }
                }
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.system(size: 14, weight: .medium))
            Spacer()
        }
    }
}
