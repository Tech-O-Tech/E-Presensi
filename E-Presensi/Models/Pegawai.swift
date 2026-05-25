//
//  Pegawai.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 22/04/26.
//

import Foundation

struct Pegawai: Codable {
    let message: String
    let code: Int
    let data: DataPegawai
}

struct DataPegawai: Codable {
    let idPegawai: Int
    let namaPegawai: String
    let nipPegawai: String
    let idOpd: Int
    let namaOpd: String
    let idJabatan: Int
    let idPangkat: Int
    let idAtasan: Int
    let level: String
    let urlFotoPegawai: String
    let tukin: Int
    let deviceId: String
    
    enum CodingKeys: String, CodingKey {
        case idPegawai = "id_pegawai"
        case namaPegawai = "nama_pegawai"
        case nipPegawai = "nip_pegawai"
        case idOpd = "id_opd"
        case namaOpd = "nama_opd"
        case idJabatan = "id_jabatan"
        case idPangkat = "id_pangkat"
        case idAtasan = "id_atasan"
        case level
        case urlFotoPegawai = "url_foto_pegawai"
        case tukin
        case deviceId = "device_id"
    }
}
