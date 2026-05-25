//
//  LoginResponse.swift
//  E-Presensi
//

import Foundation

struct LoginResponse: Codable {
    let message: String
    let code: Int
    let data: DataUser?
}

struct DataUser: Codable {
    let level: String
    let idPegawai: Int
    let idAtasan: Int?
    let nipPegawai: String
    let namaPegawai: String
    let urlFotoPegawai: String?
    let idOpd: Int
    let namaOpd: String
    let firstTime: Int
    let token: String
    let deviceId: String
    let idKantor: Int?
    let namaKantor: String?

    let pengumumanUmum: [Pengumuman]?
    let pengumumanPresensi: [Pengumuman]?
    let pengumumanUltah: Pengumuman?

    enum CodingKeys: String, CodingKey {
        case level
        case idPegawai = "id_pegawai"
        case idAtasan = "id_atasan"
        case nipPegawai = "nip_pegawai"
        case namaPegawai = "nama_pegawai"
        case urlFotoPegawai = "url_foto_pegawai"
        case idOpd = "id_opd"
        case namaOpd = "nama_opd"
        case firstTime = "first_time"
        case token
        case deviceId = "device_id"
        case idKantor = "id_kantor"
        case namaKantor = "nama_kantor"
        case pengumumanUmum = "pengumuman_umum"
        case pengumumanPresensi = "pengumuman_presensi"
        case pengumumanUltah = "pengumuman_ultah"
    }
}

struct Pengumuman: Codable, Identifiable {
    let id: String
    let nama: String
    let kategori: String
    let file: String?
    let fileUrl: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case nama
        case kategori
        case file
        case fileUrl = "file_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decode(String.self, forKey: .id) {
            id = s
        } else if let n = try? c.decode(Int.self, forKey: .id) {
            id = String(n)
        } else {
            id = ""
        }
        nama = try c.decode(String.self, forKey: .nama)
        kategori = try c.decode(String.self, forKey: .kategori)
        file = try c.decodeIfPresent(String.self, forKey: .file)
        fileUrl = try c.decodeIfPresent(String.self, forKey: .fileUrl)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
    }
}
