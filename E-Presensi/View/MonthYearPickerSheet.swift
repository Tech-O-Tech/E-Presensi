//
//  MonthYearPickerSheet.swift
//  E-Presensi
//
//  Setara `MonthYearPicker.kt` Android — pemilih Bulan & Tahun dengan dua roda
//  (wheel) yang dipakai bersama oleh rekap presensi maupun rekap izin.
//

import SwiftUI

/// Util tanggal khusus layar rekap (label bulan, normalisasi tanggal server).
enum RekapDateHelper {
    static let monthNames = [
        "Januari", "Februari", "Maret", "April", "Mei", "Juni",
        "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ]

    /// Label "Januari 2026" untuk tombol filter.
    static func monthLabel(bulan: Int, tahun: Int) -> String {
        let name = monthNames[safe: bulan - 1] ?? "-"
        return "\(name) \(tahun)"
    }

    /// `(bulan 1...12, tahun)` untuk saat ini.
    static func currentMonthYear() -> (bulan: Int, tahun: Int) {
        let c = Calendar.current.dateComponents([.month, .year], from: Date())
        return (c.month ?? 1, c.year ?? 2026)
    }

    /// Ambil bagian tanggal dari timestamp ("2026-01-05 08:00" / "...T..." ) apa adanya.
    static func extractDate(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "-" }
        if let i = raw.firstIndex(where: { $0 == " " || $0 == "T" }) {
            return String(raw[raw.startIndex..<i])
        }
        return raw
    }

    /// Normalisasi berbagai format tanggal server → "yyyy-MM-dd" (nil jika gagal).
    static func normalizeDate(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let datePart = raw.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " ").first?
            .components(separatedBy: "T").first ?? raw
        let patterns = ["yyyy-MM-dd", "d/M/yyyy", "dd/MM/yyyy", "dd-MM-yyyy", "d-M-yyyy"]
        let out = DateFormatter()
        out.locale = Locale(identifier: "en_US_POSIX")
        out.dateFormat = "yyyy-MM-dd"
        for p in patterns {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.isLenient = false
            f.dateFormat = p
            if let d = f.date(from: datePart) {
                return out.string(from: d)
            }
        }
        return nil
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct MonthYearPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var bulan: Int
    @State private var tahun: Int
    let onPicked: (Int, Int) -> Void

    private let years: [Int]

    init(bulan: Int, tahun: Int, onPicked: @escaping (Int, Int) -> Void) {
        _bulan = State(initialValue: bulan)
        _tahun = State(initialValue: tahun)
        self.onPicked = onPicked
        let thisYear = Calendar.current.component(.year, from: Date())
        years = Array((thisYear - 5)...(thisYear + 1))
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("Bulan", selection: $bulan) {
                    ForEach(1...12, id: \.self) { m in
                        Text(RekapDateHelper.monthNames[m - 1]).tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                Picker("Tahun", selection: $tahun) {
                    ForEach(years, id: \.self) { y in
                        Text(String(y)).tag(y)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 8)
            .navigationTitle("Pilih Bulan & Tahun")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pilih") {
                        onPicked(bulan, tahun)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(320)])
    }
}
