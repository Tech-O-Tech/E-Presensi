//
//  AbsenDialogSheet.swift
//  E-Presensi
//
//  Dialog tengah layar seperti MaterialAlertDialog + absen_dialog Android
//

import SwiftUI

struct AbsenDialogOverlay: View {
    let onPagi: () -> Void
    let onSiang: () -> Void
    let onSore: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                Text(PresensiCopy.pilihWaktu)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                AbsenTimePickerContent(
                    onPagi: onPagi,
                    onSiang: onSiang,
                    onSore: onSore
                )
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
            .padding(.horizontal, 20)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

/// Alias agar pemanggilan lama tetap jalan
struct AbsenDialogSheet: View {
    let tipe: String
    let onPagi: () -> Void
    let onSiang: () -> Void
    let onSore: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AbsenDialogOverlay(
            onPagi: onPagi,
            onSiang: onSiang,
            onSore: onSore,
            onDismiss: { dismiss() }
        )
    }
}
