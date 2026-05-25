//
//  KegiatanResponse.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 19/05/26.
//

import Foundation

// MARK: - Response wrapper

struct KegiatanResponse: Codable {
    let message: String
    let code: Int
    let data: DataKegiatanp?
}

// MARK: - Data item

struct DataKegiatanp: Codable {
    let tanggalKegiatan: String
    let verifikasi: String
    let updatedAt: String?
    let kegiatan: String
    let idPresensi: Int64
    let urlFile: String?
    let catatan: String?
    let createdAt: String
    let idPegawai: Int64
    let idKegiatan: Int64
    let editedBy: String?

    enum CodingKeys: String, CodingKey {
        case tanggalKegiatan = "tanggal_kegiatan"
        case verifikasi
        case updatedAt = "updated_at"
        case kegiatan
        case idPresensi = "id_presensi"
        case urlFile = "url_file"
        case catatan
        case createdAt = "created_at"
        case idPegawai = "id_pegawai"
        case idKegiatan = "id_kegiatan"
        case editedBy = "edited_by"
    }
}
