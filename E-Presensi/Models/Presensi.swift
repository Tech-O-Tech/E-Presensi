//
//  Presensi.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 22/04/26.
//
import Foundation

struct Presensi: Codable {
    let message: String
    let code: Int
    let data: DataPresensi?
}

struct DataPresensi: Codable {
    let idPresensi: Int
    let idPegawai: Int
    let jamMasuk: String
    let ketMasuk: String
    let fotoMasuk: String
    
    let fotoSiang: String?
    let jamSiang: String
    let ketSiang: String?
    
    let jamPulang: String
    let fotoPulang: String?
    let ketPulang: String?
    
    let editedBy: Int?
    let createdAt: String
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case idPresensi = "id_presensi"
        case idPegawai = "id_pegawai"
        case jamMasuk = "jam_masuk"
        case ketMasuk = "ket_masuk"
        case fotoMasuk = "foto_masuk"
        case fotoSiang = "foto_siang"
        case jamSiang = "jam_siang"
        case ketSiang = "ket_siang"
        case jamPulang = "jam_pulang"
        case fotoPulang = "foto_pulang"
        case ketPulang = "ket_pulang"
        case editedBy = "edited_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
