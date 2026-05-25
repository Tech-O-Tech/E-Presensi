//
//  CoordinateFormatter.swift
//  E-Presensi
//
//  Server membatasi lat/long maks. 8 digit/karakter per field.
//

import Foundation

enum CoordinateFormatter {

    /// Panjang maksimum string koordinat untuk API (sesuai batas server).
    static let serverMaxLength = 8

    /// Format koordinat untuk dikirim ke server (tanpa notasi ilmiah).
    static func formatForServer(_ value: Double, maxLength: Int = serverMaxLength) -> String {
        guard value.isFinite else { return "0" }
        if value == 0 { return "0" }

        let negative = value < 0
        let absVal = abs(value)
        let intPart = floor(absVal)
        let intDigitCount = intPart < 1 ? 1 : Int(log10(intPart)) + 1
        let reserved = intDigitCount + (negative ? 1 : 0) + 1 // titik desimal
        let decimalPlaces = max(0, maxLength - reserved)

        var formatted = String(format: "%.\(decimalPlaces)f", value)
        formatted = trimTrailingZeros(formatted)

        if formatted.count <= maxLength {
            return formatted
        }

        // Cadangan: potong desimal jika masih terlalu panjang
        formatted = String(format: "%.\(max(0, decimalPlaces - 1))f", value)
        formatted = trimTrailingZeros(formatted)
        if formatted.count <= maxLength {
            return formatted
        }

        var truncated = String(formatted.prefix(maxLength))
        if truncated.last == "." {
            truncated.removeLast()
        }
        return truncated.isEmpty ? "0" : truncated
    }

    private static func trimTrailingZeros(_ value: String) -> String {
        var s = value
        guard s.contains(".") else { return s }
        while s.last == "0" { s.removeLast() }
        if s.last == "." { s.removeLast() }
        return s
    }
}
