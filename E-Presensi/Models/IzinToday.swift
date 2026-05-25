//
//  IzinToday.swift
//  E-Presensi
//
//  Setara `IzinResponse.kt` Android.
//  Untuk endpoint `GET izin/hari-ini/{id_pegawai}`.
//

import Foundation

struct IzinTodayResponse: Codable {
    let code: Int
    let message: String
    let data: DataIzin?
}

struct DataIzin: Codable {
    let idIzin: Int?
    let idPegawai: Int?
    let idOpd: Int?
    let keterangan: String?
    let bukti: String?
    /// 0 = pending, 1 = disetujui, 2 = ditolak (mengikuti backend).
    let verifikasi: Int?
    let tanggalIzin: String?
    let tanggalSelesai: String?
    let jenisIzin: String?
    let editedBy: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case idIzin = "id_izin"
        case idPegawai = "id_pegawai"
        case idOpd = "id_opd"
        case keterangan
        case bukti
        case verifikasi
        case tanggalIzin = "tanggal_izin"
        case tanggalSelesai = "tanggal_selesai"
        case jenisIzin = "jenis_izin"
        case editedBy = "edited_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        idIzin = try c.decodeIfPresent(Int.self, forKey: .idIzin)
        idPegawai = try c.decodeIfPresent(Int.self, forKey: .idPegawai)
        idOpd = try c.decodeIfPresent(Int.self, forKey: .idOpd)
        keterangan = try c.decodeIfPresent(String.self, forKey: .keterangan)
        bukti = try c.decodeIfPresent(String.self, forKey: .bukti)
        tanggalIzin = try c.decodeIfPresent(String.self, forKey: .tanggalIzin)
        tanggalSelesai = try c.decodeIfPresent(String.self, forKey: .tanggalSelesai)
        jenisIzin = try c.decodeIfPresent(String.self, forKey: .jenisIzin)
        editedBy = try c.decodeIfPresent(Int.self, forKey: .editedBy)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)

        if let intVal = try? c.decodeIfPresent(Int.self, forKey: .verifikasi) {
            verifikasi = intVal
        } else if let strVal = try? c.decodeIfPresent(String.self, forKey: .verifikasi) {
            verifikasi = Int(strVal)
        } else {
            verifikasi = nil
        }
    }
}

extension DataIzin {
    var verifikasiText: String {
        switch verifikasi {
        case 1: return "Disetujui"
        case 2: return "Ditolak"
        default: return "Menunggu verifikasi atasan"
        }
    }

    var tanggalRangeFormatted: String {
        let mulai = formatIsoDate(tanggalIzin)
        let akhir = formatIsoDate(tanggalSelesai)
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
