//
//  Kantor.swift
//  E-Presensi
//

import Foundation

struct Kantor: Codable {
    let message: String
    let code: Int
    let data: DataKantor?
}

struct DataKantor: Codable {
    let idKantor: Int
    let namaKantor: String
    let latKantor: Double
    let longKantor: Double

    enum CodingKeys: String, CodingKey {
        case idKantor = "id_kantor"
        case namaKantor = "nama_kantor"
        case latKantor = "lat_kantor"
        case longKantor = "long_kantor"
    }
}
