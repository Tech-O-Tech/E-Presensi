//
//  DinasLuarViewModel.swift
//  E-Presensi
//
//  ViewModel untuk Upload SPT Dinas Luar — setara DinasLuarActivity Android.
//  Mengunggah dokumen ke endpoint `POST absen-khusus`.
//

import SwiftUI
import UIKit
import Combine

@MainActor
final class DinasLuarViewModel: ObservableObject {

    @Published var jenisDL = ""
    @Published var tanggalText = ""
    @Published var keterangan = ""

    @Published var fileName = ""
    @Published var filePreview: UIImage?
    @Published var isPDF = false

    @Published var isLoading = false
    @Published var showSuccess = false
    @Published var alertMessage = ""
    @Published var showAlert = false

    /// Pilihan default — sesuai `list_jenis_dl` Android (mode "DL LUAR KABUPATEN").
    /// `initialJenis` boleh diset dari layar pemanggil (mis. "DL DALAM KABUPATEN").
    let jenisOptions: [String]
    private let defaultJenis: String

    private var tanggalMulai: Int64 = DateHelper.todayUtcMillis()
    private var tanggalAkhir: Int64 = DateHelper.todayUtcMillis()
    private var fileURL: URL?

    private let pref = AppPreference.shared

    init(initialJenis: String = "DL LUAR KABUPATEN") {
        defaultJenis = initialJenis
        jenisOptions = Array(
            Set([initialJenis, "DL DALAM KABUPATEN", "DL LUAR KABUPATEN"])
        ).sorted()
    }

    func onAppear() {
        let today = DateHelper.todayUtcMillis()
        tanggalMulai = today
        tanggalAkhir = today
        tanggalText = DateHelper.convertLongDate(today)
        if jenisDL.isEmpty {
            jenisDL = defaultJenis
        }
    }

    func setDateRange(mulai: Date, selesai: Date) {
        tanggalMulai = DateHelper.utcMillis(from: mulai)
        tanggalAkhir = DateHelper.utcMillis(from: selesai)
        if tanggalMulai > tanggalAkhir {
            swap(&tanggalMulai, &tanggalAkhir)
        }
        tanggalText = DateHelper.convertRangeText(mulai: tanggalMulai, selesai: tanggalAkhir)
    }

    func setImage(_ image: UIImage, url: URL) {
        if let data = ImageCompressor.compress(image) {
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent("spt_dl_\(UUID().uuidString).jpg")
            try? data.write(to: temp)
            fileURL = temp
        } else {
            fileURL = url
        }
        fileName = url.lastPathComponent
        filePreview = image
        isPDF = false
    }

    func setDocument(url: URL) {
        fileURL = url
        fileName = url.lastPathComponent
        filePreview = nil
        isPDF = url.pathExtension.lowercased() == "pdf"
    }

    func submit() {
        guard !jenisDL.isEmpty else {
            toast("Jenis DL tidak boleh kosong")
            return
        }
        guard let fileURL else {
            toast("File bukti tidak boleh kosong")
            return
        }

        let ket = keterangan.trimmingCharacters(in: .whitespacesAndNewlines)
        let ketAPI = ket.isEmpty ? "-" : ket

        // `id_atasan` diambil dari sesi login (lihat AppPreference.saveLoginSession).
        let idAtasan = pref.idAtasan
        guard !idAtasan.isEmpty, idAtasan != "0" else {
            toast("Data atasan belum tersedia, silakan login ulang")
            return
        }

        isLoading = true

        ApiService.tambahKhusus(
            token: pref.token,
            idPegawai: pref.idPegawai,
            idOpd: pref.idOpd,
            idAtasan: idAtasan,
            keterangan: ketAPI,
            tanggalMulai: String(tanggalMulai),
            tanggalAkhir: String(tanggalAkhir),
            jenisKhusus: jenisDL,
            fileURL: fileURL
        ) { [weak self] response, error in
            guard let self else { return }
            self.isLoading = false

            if let error {
                self.toast(error.localizedDescription)
                return
            }
            guard let response else {
                self.toast("Terjadi kesalahan")
                return
            }

            switch response.code {
            case 200, 201:
                self.showSuccess = true
            case 401:
                NotificationCenter.default.post(name: .sessionExpired, object: nil)
            default:
                self.toast(response.message)
            }
        }
    }

    private func toast(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
