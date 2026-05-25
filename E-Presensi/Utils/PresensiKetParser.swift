//
//  PresensiKetParser.swift
//  E-Presensi
//
//  Parse ket_masuk format: Tipe;lat,lng;keterangan
//

import Foundation

enum PresensiKetParser {

    struct Parsed: Equatable {
        var tipe = ""
        var koordinat = ""
        var keterangan = "-"
    }

    static func parse(_ ket: String) -> Parsed {
        let parts = ket.split(separator: ";", omittingEmptySubsequences: false).map(String.init)
        let tipe = parts.indices.contains(0) ? parts[0] : ""
        let koordinat = parts.indices.contains(1) ? parts[1] : ""
        var keterangan = parts.indices.contains(2) ? parts[2] : "-"
        if keterangan.isEmpty { keterangan = "-" }
        return Parsed(tipe: tipe, koordinat: koordinat, keterangan: keterangan)
    }

    static func jenisLabel(tipe: String, koordinat: String) -> String {
        switch tipe {
        case "Biasa":
            return "Di Kantor (\(koordinat))"
        case "WFH":
            return "Di Rumah (\(koordinat))"
        default:
            return tipe.isEmpty ? "-" : "Absen Khusus (\(koordinat))"
        }
    }
}
