//
//  PresensiCopy.swift
//  E-Presensi
//
//  Teks setara strings.xml Android
//

import SwiftUI

enum PresensiCopy {
    static let pilihWaktu = "Pilih Waktu Presensi"
    static let pagiTitle = "Presensi Pagi"
    static let pagiSubtitle = "Sebelum 7.30 Pagi"
    static let siangTitle = "Presensi Siang"
    static let siangSubtitle = "Senin - Kamis : 12.00 - 13.00\nJumat : 11.30 - 13.00"
    static let soreTitle = "Presensi Sore"
    static let soreSubtitle = "Senin - Kamis : Setelah 16.00\nJumat : Setelah 16.30"
    static let batal = "Batal"
    static let tandaiKehadiran = "Tandai Kehadiran"
    static let keteranganHint = "Keterangan"
    static let hai = "Hai, %@"
    static let belumAbsen = "Kamu belum mengisi kehadiran hari ini! Ketuk tombol dibawah"
    static let ringkasan = "Berikut ringkasan kehadiran terakhirmu"
    static let rekapSayaHariIni = "Rekap saya hari ini"
    static let belumPresensiPagi = "Belum membuat presensi pagi"
    static let belumPresensiSiang = "Belum membuat presensi siang"
    static let belumPresensiSore = "Belum membuat presensi sore"
}

enum PresensiTheme {
    static let navy = Color(red: 13/255, green: 23/255, blue: 95/255)
    static let cardHeight: CGFloat = 120
    static let cardRadius: CGFloat = 10
    static let cardSpacing: CGFloat = 12
    static let overlayAlpha: CGFloat = 0.8
}
