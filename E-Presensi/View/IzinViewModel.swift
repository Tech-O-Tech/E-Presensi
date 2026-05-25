//
//  IzinViewModel.swift
//  E-Presensi
//

import SwiftUI
import UIKit
import Combine

@MainActor
final class IzinViewModel: ObservableObject {

    @Published var jenisIzin = ""
    @Published var tanggalText = ""
    @Published var deskripsi = ""
    @Published var fileName = ""
    @Published var filePreview: UIImage?
    @Published var isPDF = false

    @Published var isLoading = false
    @Published var showSuccess = false
    @Published var alertMessage = ""
    @Published var showAlert = false

    private var tanggalMulai: Int64 = DateHelper.todayUtcMillis()
    private var tanggalSelesai: Int64 = DateHelper.todayUtcMillis()
    private var fileURL: URL?

    let jenisOptions = ["DL", "SAKIT", "IZIN", "CUTI"]

    private let pref = AppPreference.shared

    func onAppear() {
        let today = DateHelper.todayUtcMillis()
        tanggalMulai = today
        tanggalSelesai = today
        tanggalText = DateHelper.convertLongDate(today)
    }

    func setDateRange(mulai: Date, selesai: Date) {
        tanggalMulai = DateHelper.utcMillis(from: mulai)
        tanggalSelesai = DateHelper.utcMillis(from: selesai)
        if tanggalMulai > tanggalSelesai {
            swap(&tanggalMulai, &tanggalSelesai)
        }
        tanggalText = DateHelper.convertRangeText(mulai: tanggalMulai, selesai: tanggalSelesai)
    }

    func setImage(_ image: UIImage, url: URL) {
        if let data = ImageCompressor.compress(image) {
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent("bukti_izin_\(UUID().uuidString).jpg")
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
        guard !jenisIzin.isEmpty else {
            toast("Jenis Izin tidak boleh kosong")
            return
        }
        guard let fileURL else {
            toast("File bukti tidak boleh kosong")
            return
        }

        isLoading = true
        let ket = deskripsi.trimmingCharacters(in: .whitespacesAndNewlines)
        let keterangan = ket.isEmpty ? "-" : ket

        ApiService.tambahIzin(
            token: pref.token,
            idPegawai: pref.idPegawai,
            idOpd: pref.getValue(Keys.idOpd),
            keterangan: keterangan,
            tanggalIzin: String(tanggalMulai),
            tanggalSelesai: String(tanggalSelesai),
            jenisIzin: jenisIzin,
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
            case 201:
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
