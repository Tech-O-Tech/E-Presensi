//
//  DateHelper.swift
//  E-Presensi
//
//  Setara Constant.convertLongDate & MaterialDatePicker millis
//

import Foundation

enum DateHelper {

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "id_ID")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "dd MMMM yyyy"
        return f
    }()

    /// Konversi millis UTC (MaterialDatePicker) ke teks tanggal Indonesia
    static func convertLongDate(_ millis: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
        return displayFormatter.string(from: date)
    }

    static func todayUtcMillis() -> Int64 {
        utcMillis(from: Date())
    }

    static func utcMillis(from date: Date) -> Int64 {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        if let utcDate = calendar.date(from: components) {
            return Int64(utcDate.timeIntervalSince1970 * 1000)
        }
        return Int64(date.timeIntervalSince1970 * 1000)
    }

    static func displayText(from date: Date) -> String {
        displayFormatter.string(from: date)
    }

    static func convertRangeText(mulai: Int64, selesai: Int64) -> String {
        if mulai == selesai {
            return convertLongDate(mulai)
        }
        return "\(convertLongDate(mulai)) - \(convertLongDate(selesai))"
    }

    /// Millis UTC untuk upload kegiatan — default hari ini jika belum pilih tanggal.
    static func millisForKegiatanUpload(selectedMillis: Int64, tanggalText: String) -> Int64 {
        let hasLabel = !tanggalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if hasLabel, selectedMillis > 0 {
            return selectedMillis
        }
        return todayUtcMillis()
    }

    /// Format `tanggal_kegiatan` dari API (millis atau teks invalid) untuk tampilan.
    static func formatKegiatanDate(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "Invalid Date" {
            return displayText(from: Date())
        }
        if let millis = Int64(trimmed), millis > 0 {
            return convertLongDate(millis)
        }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: trimmed) {
            return displayText(from: date)
        }
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: trimmed) {
            return displayText(from: date)
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        for format in ["yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"] {
            f.dateFormat = format
            if let date = f.date(from: trimmed) {
                return displayText(from: date)
            }
        }
        return trimmed
    }

    /// Parse tanggal kegiatan dari API ke millis (untuk prefill form).
    static func millis(fromKegiatanRaw raw: String) -> Int64? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "Invalid Date" { return nil }
        if let millis = Int64(trimmed), millis > 0 { return millis }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: trimmed) {
            return utcMillis(from: date)
        }
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: trimmed) {
            return utcMillis(from: date)
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        for format in ["yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"] {
            f.dateFormat = format
            if let date = f.date(from: trimmed) {
                return utcMillis(from: date)
            }
        }
        return nil
    }
}
