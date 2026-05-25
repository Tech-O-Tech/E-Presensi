//
//  KegiatanViewModel.swift
//  E-Presensi
//

import SwiftUI
import UIKit
import Foundation
import Combine

@MainActor
final class KegiatanViewModel: ObservableObject {

    enum LoadingState {
        case progress
        case success(String)
    }

    @Published var tanggalKegiatan = Date()
    @Published var tanggalText = ""
    @Published var tanggalMillis: Int64 = 0
    @Published var deskripsi = ""

    @Published var fileName = ""
    @Published var previewImage: UIImage?
    @Published var isPDF = false
    @Published var showUploadHint = true

    @Published var isLoading = false
    @Published var loadingState: LoadingState = .progress

    @Published var showAlert = false
    @Published var alertMessage = ""

    private var fileURL: URL?
    private var hasFile = false
    private let pref = AppPreference.shared

    init() {
        applyTodayAsDefaultDate()
    }

    func onAppear() {
        PresensiSessionService.syncPresensiHariIni()
        if tanggalText.isEmpty || tanggalMillis <= 0 {
            applyTodayAsDefaultDate()
        }
        loadKegiatanHariIni()
    }

    func setDate(_ date: Date) {
        tanggalKegiatan = date
        tanggalText = DateHelper.displayText(from: date)
        tanggalMillis = DateHelper.utcMillis(from: date)
    }

    /// Jika pengguna tidak memilih tanggal, pakai hari ini (setara default MaterialDatePicker Android).
    func applyTodayAsDefaultDate() {
        setDate(Date())
    }

    private func millisForUpload() -> Int64 {
        DateHelper.millisForKegiatanUpload(
            selectedMillis: tanggalMillis,
            tanggalText: tanggalText
        )
    }

    func loadKegiatanHariIni() {
        let token = pref.token
        let idPegawai = pref.idPegawai
        guard !token.isEmpty, !idPegawai.isEmpty else { return }

        ApiService.getKegiatan(token: token, idPegawai: idPegawai) { [weak self] response, _ in
            guard let self, let data = response?.data else { return }
            self.deskripsi = data.kegiatan
            if let millis = DateHelper.millis(fromKegiatanRaw: data.tanggalKegiatan) {
                let date = Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
                self.setDate(date)
            }
        }
    }

    func handleImage(_ image: UIImage?) {
        guard let image else {
            showToast("Ambil Foto dibatalkan")
            return
        }
        previewImage = image
        isPDF = false
        showUploadHint = false

        let compressed = compress(image: image)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).jpg")
        do {
            try compressed.write(to: tempURL)
            fileURL = tempURL
            fileName = tempURL.lastPathComponent
            hasFile = true
        } catch {
            showToast("Gagal menyimpan file sementara")
        }
    }

    func handleDocument(url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.copyItem(at: url, to: dest)
            fileURL = dest
            fileName = dest.lastPathComponent
            previewImage = nil
            isPDF = true
            showUploadHint = false
            hasFile = true
        } catch {
            showToast("Gagal membuka dokumen")
        }
    }

    func handleDocumentCancelled() {
        showToast("Ambil Dokumen dibatalkan")
    }

    func kirimLaporan() {
        let token = pref.token
        let idPegawai = pref.idPegawai
        let idPresensi = pref.idPresensi

        guard !idPresensi.isEmpty else {
            showToast("Kamu harus membuat presensi sebelum melaporkan kegiatan")
            return
        }
        guard hasFile, let fileURL else {
            showToast("File tidak boleh kosong")
            return
        }

        if tanggalText.isEmpty || tanggalMillis <= 0 {
            applyTodayAsDefaultDate()
        }

        let kegiatan = deskripsi.isEmpty ? "-" : deskripsi
        let uploadMillis = millisForUpload()
        tanggalMillis = uploadMillis
        tanggalText = DateHelper.convertLongDate(uploadMillis)

        isLoading = true
        loadingState = .progress

        ApiService.buatKegiatan(
            token: token,
            idPegawai: idPegawai,
            idPresensi: idPresensi,
            kegiatan: kegiatan,
            tanggal: String(uploadMillis),
            fileURL: fileURL
        ) { [weak self] response, error in
            guard let self else { return }

            if let error = error as? URLError,
               error.code == .notConnectedToInternet || error.code == .timedOut {
                self.isLoading = false
                self.showToast("Gagal tersambung. Periksa koneksi internet Anda.")
                return
            }

            if let error {
                self.isLoading = false
                self.showToast(error.localizedDescription)
                return
            }

            guard let response else {
                self.isLoading = false
                self.showToast("Terjadi kesalahan")
                return
            }

            switch response.code {
            case 201:
                self.resetFormAfterUpload()
                self.loadingState = .success("Berhasil mengunggah dokumen.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    self.isLoading = false
                }

            case 401:
                self.isLoading = false
                self.showToast("Waktu anda habis, silahkan login kembali")
                NotificationCenter.default.post(name: .sessionExpired, object: nil)

            default:
                self.isLoading = false
                self.showToast(response.message)
            }
        }
    }

    private func showToast(_ message: String) {
        alertMessage = message
        showAlert = true
    }

    /// Kosongkan file upload & form setelah laporan terkirim (setara reset Android).
    private func resetFormAfterUpload() {
        clearUploadedFile()
        deskripsi = ""
        applyTodayAsDefaultDate()
    }

    func clearUploadedFile() {
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        fileURL = nil
        hasFile = false
        fileName = ""
        previewImage = nil
        isPDF = false
        showUploadHint = true
    }

    private func compress(image: UIImage, maxBytes: Int = 1_000_000) -> Data {
        var quality: CGFloat = 0.9
        var data = image.jpegData(compressionQuality: quality) ?? Data()
        while data.count > maxBytes && quality > 0.1 {
            quality -= 0.1
            data = image.jpegData(compressionQuality: quality) ?? data
        }
        return data
    }
}
