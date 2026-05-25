//
//  WaveShape.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 21/04/26.
//

import SwiftUI

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Mulai dari kiri
        path.move(to: CGPoint(x: 0, y: rect.height * 0.55))

        // Kurva utama (lebih landai & lebar)
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.50),
            control1: CGPoint(x: rect.width * 0.3, y: rect.height * 0.75),
            control2: CGPoint(x: rect.width * 0.7, y: rect.height * 0.30)
        )

        // Tutup ke bawah
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}
