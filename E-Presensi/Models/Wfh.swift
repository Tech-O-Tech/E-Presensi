//
//  Wfh.swift
//  E-Presensi
//

import Foundation

struct WfhResponse: Codable {
    let message: String?
    let code: Int
    let data: DataWfh?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        message = try c.decodeIfPresent(String.self, forKey: .message)
        code = Self.decodeCode(from: c)
        data = try c.decodeIfPresent(DataWfh.self, forKey: .data)
    }

    enum CodingKeys: String, CodingKey {
        case message, code, data
    }

    private static func decodeCode(from c: KeyedDecodingContainer<CodingKeys>) -> Int {
        if let i = try? c.decode(Int.self, forKey: .code) { return i }
        if let l = try? c.decode(Int64.self, forKey: .code) { return Int(l) }
        if let s = try? c.decode(String.self, forKey: .code), let i = Int(s) { return i }
        return 0
    }
}

struct DataWfh: Codable {
    let idPegawai: String?
    let lat: Double?
    let long: Double?

    enum CodingKeys: String, CodingKey {
        case idPegawai = "id_pegawai"
        case lat
        case long
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        idPegawai = Self.decodeString(c, forKey: .idPegawai)
        lat = Self.decodeCoordinate(c, forKey: .lat)
        long = Self.decodeCoordinate(c, forKey: .long)
    }

    private static func decodeString(
        _ c: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> String? {
        if let s = try? c.decode(String.self, forKey: key) { return s }
        if let i = try? c.decode(Int.self, forKey: key) { return String(i) }
        if let l = try? c.decode(Int64.self, forKey: key) { return String(l) }
        return nil
    }

    private static func decodeCoordinate(
        _ c: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Double? {
        if let d = try? c.decode(Double.self, forKey: key) { return d }
        if let s = try? c.decode(String.self, forKey: key) {
            return Double(s.replacingOccurrences(of: ",", with: "."))
        }
        if let i = try? c.decode(Int.self, forKey: key) { return Double(i) }
        if let l = try? c.decode(Int64.self, forKey: key) { return Double(l) }
        return nil
    }
}
