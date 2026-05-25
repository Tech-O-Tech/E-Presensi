//
//  Opd.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 22/04/26.
//

import Foundation

struct Opd: Codable {
    let message: String
    let code: Int
    let data: DataOpd
}

struct DataOpd: Codable {
    let idOpd: Int
    let namaOpd: String
    let alamatOpd: String
    let idKepalaOpd: Int
    let latOpd: Double
    let longOpd: Double
    let editedBy: Int
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case idOpd = "id_opd"
        case namaOpd = "nama_opd"
        case alamatOpd = "alamat_opd"
        case idKepalaOpd = "id_kepala_opd"
        case latOpd = "lat_opd"
        case longOpd = "long_opd"
        case editedBy = "edited_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
