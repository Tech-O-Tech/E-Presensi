//
//  FileThumbnailHelper.swift
//  E-Presensi
//
//  Membedakan file gambar vs dokumen (PDF/dll) berdasarkan URL/nama file.
//  Dipakai oleh kartu rekap untuk memutuskan apakah memuat preview gambar
//  atau cukup menampilkan ikon dokumen.
//

import Foundation

enum FileThumbnailHelper {
    /// Ekstensi file yang dianggap gambar dan layak dimuat sebagai thumbnail.
    static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif", "webp", "heic", "heif", "bmp"
    ]

    /// `true` jika URL/path merujuk ke file gambar.
    /// `.pdf` atau ekstensi lain akan mengembalikan `false`.
    static func isImage(_ urlString: String?) -> Bool {
        guard let urlString, !urlString.isEmpty else { return false }
        let lower = urlString.lowercased()
        // Buang query string (mis. "...jpg?token=..." atau "...pdf#page=1").
        let cleaned = lower
            .components(separatedBy: "?").first ?? lower
        let pathOnly = cleaned
            .components(separatedBy: "#").first ?? cleaned
        let ext = (pathOnly as NSString).pathExtension
        guard !ext.isEmpty else { return false }
        return imageExtensions.contains(ext)
    }
}
