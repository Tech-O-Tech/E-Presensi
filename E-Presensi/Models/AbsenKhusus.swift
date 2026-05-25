//
//  AbsenKhusus.swift
//  E-Presensi
//
//  Setara `AbsenKhusus.kt` Android.
//  Untuk endpoint `GET absen-khusus/hari-ini/{id_pegawai}`.
//

import Foundation

struct AbsenKhususResponse: Codable {
    let message: String
    let code: Int
    let data: DataAbsenKhusus?
}

struct DataAbsenKhusus: Codable {
    let id: Int?
    let idPegawai: Int?
    let idOpd: Int?
    let idAtasan: Int?
    let jenisKhusus: String?
    let keterangan: String?
    let tanggalMulai: String?
    let tanggalAkhir: String?
    let file: String?
    /// 0 = belum diverifikasi atasan, 1 = sudah disetujui, 2 = ditolak (mengikuti backend).
    let verifikasiAtasan: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case idPegawai = "id_pegawai"
        case idOpd = "id_opd"
        case idAtasan = "id_atasan"
        case jenisKhusus = "jenis_khusus"
        case keterangan
        case tanggalMulai = "tanggal_mulai"
        case tanggalAkhir = "tanggal_akhir"
        case file
        case verifikasiAtasan = "verifikasi_atasan"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Field `verifikasi_atasan` server bisa muncul sebagai Int atau String.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(Int.self, forKey: .id)
        idPegawai = try c.decodeIfPresent(Int.self, forKey: .idPegawai)
        idOpd = try c.decodeIfPresent(Int.self, forKey: .idOpd)
        idAtasan = try c.decodeIfPresent(Int.self, forKey: .idAtasan)
        jenisKhusus = try c.decodeIfPresent(String.self, forKey: .jenisKhusus)
        keterangan = try c.decodeIfPresent(String.self, forKey: .keterangan)
        tanggalMulai = try c.decodeIfPresent(String.self, forKey: .tanggalMulai)
        tanggalAkhir = try c.decodeIfPresent(String.self, forKey: .tanggalAkhir)
        file = try c.decodeIfPresent(String.self, forKey: .file)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)

        if let intVal = try? c.decodeIfPresent(Int.self, forKey: .verifikasiAtasan) {
            verifikasiAtasan = intVal
        } else if let strVal = try? c.decodeIfPresent(String.self, forKey: .verifikasiAtasan) {
            verifikasiAtasan = Int(strVal)
        } else {
            verifikasiAtasan = nil
        }
    }
}

extension DataAbsenKhusus {
    /// Teks status verifikasi atasan untuk ditampilkan di kartu rekap.
    var verifikasiText: String {
        switch verifikasiAtasan {
        case 1: return "Disetujui"
        case 2: return "Ditolak"
        default: return "Menunggu verifikasi atasan"
        }
    }

    /// Rentang tanggal yang sudah diformat (mis. "26 Mei 2026" atau
    /// "26 Mei 2026 - 27 Mei 2026").
    var tanggalRangeFormatted: String {
        let mulai = formatIsoDate(tanggalMulai)
        let akhir = formatIsoDate(tanggalAkhir)
        if mulai.isEmpty { return akhir }
        if akhir.isEmpty || mulai == akhir { return mulai }
        return "\(mulai) - \(akhir)"
    }

    private func formatIsoDate(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        for format in ["yyyy-MM-dd", "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", "yyyy-MM-dd HH:mm:ss"] {
            f.dateFormat = format
            if let date = f.date(from: raw) {
                let out = DateFormatter()
                out.locale = Locale(identifier: "id_ID")
                out.dateFormat = "dd MMMM yyyy"
                return out.string(from: date)
            }
        }
        return raw
    }
}
