//
//  AbsenTimePickerContent.swift
//  E-Presensi
//
//  Tiga kartu Pagi / Siang / Sore — setara absen_dialog.xml
//

import SwiftUI

struct AbsenTimePickerContent: View {
    let onPagi: () -> Void
    let onSiang: () -> Void
    let onSore: () -> Void

    var body: some View {
        VStack(spacing: PresensiTheme.cardSpacing) {
            timeButton(
                title: PresensiCopy.pagiTitle,
                subtitle: PresensiCopy.pagiSubtitle,
                image: "pagi",
                color: .green,
                action: onPagi
            )
            timeButton(
                title: PresensiCopy.siangTitle,
                subtitle: PresensiCopy.siangSubtitle,
                image: "siang",
                color: .blue,
                action: onSiang
            )
            timeButton(
                title: PresensiCopy.soreTitle,
                subtitle: PresensiCopy.soreSubtitle,
                image: "sore",
                color: .orange,
                action: onSore
            )
        }
    }

    private func timeButton(
        title: String,
        subtitle: String,
        image: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            PresensiCardView(title: title, subtitle: subtitle, image: image, color: color)
        }
        .buttonStyle(.plain)
    }
}
