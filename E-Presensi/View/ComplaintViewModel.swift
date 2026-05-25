//
//  ComplaintViewModel.swift
//  E-Presensi
//
//  Setara ComplaintActivity Android
//

import SwiftUI
import UIKit
import Combine

@MainActor
final class ComplaintViewModel: ObservableObject {

    static let tujuanOptions = ["Admin OPD", "Admin Aplikasi"]
    static let defaultFileLabel = "Nama File.pdf"
    static let uploadHint = "Unggah File Pendukung dalam format .pdf, .jpg atau .jpeg"

    @Published var tujuan = ""
    @Published var deskripsi = ""
    @Published var fileName = defaultFileLabel
    @Published var previewImage: UIImage?
    @Published var isPDF = false
    @Published var showUploadHint = true

    @Published var isLoading = false
    @Published var loadingState: KegiatanViewModel.LoadingState = .progress
    @Published var showAlert = false
    @Published var alertMessage = ""

    private var fileURL: URL?
    private var hasFile = false
    private let pref = AppPreference.shared

    var tujuanAPI: String {
        switch tujuan {
        case "Admin OPD": return "ADMINOPD"
        case "Admin Aplikasi": return "ADMIN"
        default: return ""
        }
    }

    func handleImage(_ image: UIImage?) {
        guard let image else {
            toast("Ambil Foto dibatalkan")
            return
        }
        guard let data = ImageCompressor.compress(image) else {
            toast("Gagal memproses foto")
            return
        }
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).jpg")
        do {
            try data.write(to: temp)
            applyFile(url: temp, preview: image, pdf: false)
        } catch {
            toast("Gagal menyimpan file")
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
            applyFile(url: dest, preview: nil, pdf: true)
        } catch {
            toast("Gagal membuka dokumen")
        }
    }

    func handleDocumentCancelled() {
        toast("Ambil Dokumen dibatalkan")
    }

    private func applyFile(url: URL, preview: UIImage?, pdf: Bool) {
        fileURL = url
        fileName = url.lastPathComponent
        previewImage = preview
        isPDF = pdf
        hasFile = true
        showUploadHint = false
    }

    func clearUploadedFile() {
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        fileURL = nil
        hasFile = false
        fileName = Self.defaultFileLabel
        previewImage = nil
        isPDF = false
        showUploadHint = true
    }

    func resetFormAfterSuccess() {
        clearUploadedFile()
        deskripsi = ""
        tujuan = ""
    }

    func kirim(onSuccess: @escaping () -> Void) {
        if tujuanAPI.isEmpty {
            toast("Pilih tujuan keluhan")
            return
        }
        if deskripsi.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            toast("Mohon tuliskan deskripsi keluhan anda")
            return
        }
        guard hasFile, let fileURL else {
            toast("Mohon sertakan bukti keluhan")
            return
        }

        isLoading = true
        loadingState = .progress

        let isi = deskripsi.trimmingCharacters(in: .whitespacesAndNewlines)

        ApiService.buatComplaint(
            token: pref.token,
            idPegawai: pref.idPegawai,
            idOpd: pref.getValue(Keys.idOpd),
            tujuan: tujuanAPI,
            isi: isi,
            fileURL: fileURL
        ) { [weak self] response, error in
            guard let self else { return }
            if let error = error as? URLError,
               error.code == .notConnectedToInternet || error.code == .timedOut {
                self.isLoading = false
                self.toast("Gagal tersambung. Periksa koneksi internet Anda.")
                return
            }
            if let error {
                self.isLoading = false
                self.toast(error.localizedDescription)
                return
            }
            guard let response else {
                self.isLoading = false
                self.toast("Terjadi kesalahan")
                return
            }

            switch response.code {
            case 201:
                self.resetFormAfterSuccess()
                self.loadingState = .success("Berhasil mengunggah dokumen.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    self.isLoading = false
                    onSuccess()
                }
            case 401:
                self.isLoading = false
                self.toast("Waktu anda habis, silahkan login kembali")
                NotificationCenter.default.post(name: .sessionExpired, object: nil)
            default:
                self.isLoading = false
                self.toast(response.message)
            }
        }
    }

    private func toast(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
