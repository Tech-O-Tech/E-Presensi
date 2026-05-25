//
//  FileUrl.swift
//  E-Presensi
//
//  Setara `FileUrl.kt` Android.
//  Menormalkan path bukti/foto dari server menjadi URL penuh yang bisa dibuka:
//  - `http://` dinaikkan ke `https://`.
//  - path relatif diberi prefix host.
//

import Foundation

enum FileUrl {
    private static let host = "https://dev.pringsewukab.go.id"

    /// Kembalikan URL absolut yang valid, atau `nil` bila kosong/"null".
    static func normalize(_ raw: String?) -> String? {
        var s = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if s.isEmpty || s.lowercased() == "null" { return nil }
        if s.hasPrefix("http://") {
            s = "https://" + s.dropFirst("http://".count)
        }
        if s.hasPrefix("https://") { return s }
        if s.hasPrefix("/") { return host + s }
        return "\(host)/\(s)"
    }

    /// `URL` siap pakai hasil normalisasi.
    static func url(_ raw: String?) -> URL? {
        guard let s = normalize(raw) else { return nil }
        return URL(string: s)
    }

    /// `true` jika URL menunjuk ke berkas PDF.
    static func isPdf(_ raw: String?) -> Bool {
        guard let s = raw?.lowercased() else { return false }
        let path = s.components(separatedBy: "?").first ?? s
        return path.hasSuffix(".pdf")
    }
}
