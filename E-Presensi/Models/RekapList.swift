//
//  RekapList.swift
//  E-Presensi
//
//  Setara `PresensiListResponse.kt` + `IzinListResponse.kt` Android.
//  Untuk endpoint LIST:
//   - `GET presensi?id_opd=&id_pegawai=&bulan=&tahun=`  (riwayat presensi per bulan)
//   - `GET izin?id_pegawai=`                            (riwayat izin pegawai)
//

import Foundation

// MARK: - Rekap Presensi

struct PresensiListResponse: Codable {
    let message: String?
    let code: Int?
    let data: [RekapPresensiItem]?
}

/// Satu baris rekap presensi dari `listPresensi`.
/// `id_presensi` bisa string sintetis ("ALPA-5-…", "IZIN-…", "LIBUR-…") sehingga
/// tetap String?. `jenis` = HADIR / IZIN / LIBUR / ALPA (nil pada presensi biasa).
struct RekapPresensiItem: Codable, Identifiable {
    let idPresensi: String?
    let jamMasuk: String?
    let ketMasuk: String?
    let jamSiang: String?
    let jamPulang: String?
    let jenis: String?
    let fotoMasuk: String?
    let fotoSiang: String?
    let fotoPulang: String?
    let createdAt: String?

    var id: String { (idPresensi ?? "") + (createdAt ?? "") }

    enum CodingKeys: String, CodingKey {
        case idPresensi = "id_presensi"
        case jamMasuk = "jam_masuk"
        case ketMasuk = "ket_masuk"
        case jamSiang = "jam_siang"
        case jamPulang = "jam_pulang"
        case jenis
        case fotoMasuk = "foto_masuk"
        case fotoSiang = "foto_siang"
        case fotoPulang = "foto_pulang"
        case createdAt = "created_at"
    }

    /// `id_presensi` kadang dikirim sebagai angka, kadang sebagai string sintetis.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decodeIfPresent(String.self, forKey: .idPresensi) {
            idPresensi = s
        } else if let i = try? c.decodeIfPresent(Int.self, forKey: .idPresensi) {
            idPresensi = String(i)
        } else {
            idPresensi = nil
        }
        jamMasuk = try c.decodeIfPresent(String.self, forKey: .jamMasuk)
        ketMasuk = try c.decodeIfPresent(String.self, forKey: .ketMasuk)
        jamSiang = try c.decodeIfPresent(String.self, forKey: .jamSiang)
        jamPulang = try c.decodeIfPresent(String.self, forKey: .jamPulang)
        jenis = try c.decodeIfPresent(String.self, forKey: .jenis)
        fotoMasuk = try c.decodeIfPresent(String.self, forKey: .fotoMasuk)
        fotoSiang = try c.decodeIfPresent(String.self, forKey: .fotoSiang)
        fotoPulang = try c.decodeIfPresent(String.self, forKey: .fotoPulang)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
    }
}

// MARK: - Rekap Izin

struct IzinListResponse: Codable {
    let message: String?
    let code: Int?
    let data: [RekapIzinItem]?
}

/// Satu baris riwayat izin. Semua nullable agar item rusak tidak meledakkan list.
struct RekapIzinItem: Codable, Identifiable {
    let idIzin: Int?
    let jenisIzin: String?
    let keterangan: String?
    let bukti: String?
    /// 0 = menunggu, 1 = disetujui, 2 = ditolak.
    let verifikasi: Int?
    let tanggalIzin: String?
    let tanggalSelesai: String?
    let createdAt: String?

    var id: String { idIzin.map(String.init) ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case idIzin = "id_izin"
        case jenisIzin = "jenis_izin"
        case keterangan
        case bukti
        case verifikasi
        case tanggalIzin = "tanggal_izin"
        case tanggalSelesai = "tanggal_selesai"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        idIzin = try c.decodeIfPresent(Int.self, forKey: .idIzin)
        jenisIzin = try c.decodeIfPresent(String.self, forKey: .jenisIzin)
        keterangan = try c.decodeIfPresent(String.self, forKey: .keterangan)
        bukti = try c.decodeIfPresent(String.self, forKey: .bukti)
        tanggalIzin = try c.decodeIfPresent(String.self, forKey: .tanggalIzin)
        tanggalSelesai = try c.decodeIfPresent(String.self, forKey: .tanggalSelesai)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)

        if let intVal = try? c.decodeIfPresent(Int.self, forKey: .verifikasi) {
            verifikasi = intVal
        } else if let strVal = try? c.decodeIfPresent(String.self, forKey: .verifikasi) {
            verifikasi = Int(strVal)
        } else {
            verifikasi = nil
        }
    }
}
