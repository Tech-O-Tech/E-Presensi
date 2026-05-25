//
//  DialogView.swift
//  E-Presensi
//

import SwiftUI

struct DialogView: View {
    @ObservedObject var state: PresensiState
    var tipe: String = "Biasa"

    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var navigateToActivity = false
    @State private var selectedJenis = ""

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 16) {
                Text(PresensiCopy.pilihWaktu)
                    .font(.system(size: 18, weight: .semibold))
                    .multilineTextAlignment(.center)

                AbsenTimePickerContent(
                    onPagi: handlePagi,
                    onSiang: handleSiang,
                    onSore: handleSore
                )
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
            .padding(.horizontal, 20)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToActivity) {
            PresensiActivity(jenis: selectedJenis, tipe: tipe)
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

private extension DialogView {
    func checkIzin() -> Bool {
        if state.statusIzin {
            alertMessage = "Anda sedang dalam status izin"
            showAlert = true
            return true
        }
        return false
    }

    func handlePagi() {
        if checkIzin() { return }
        if state.masuk {
            alertMessage = "Presensi pagi sudah dilakukan"
            showAlert = true
        } else {
            selectedJenis = "Pagi"
            navigateToActivity = true
        }
    }

    func handleSiang() {
        if checkIzin() { return }
        if state.siang {
            alertMessage = "Presensi siang sudah dilakukan"
            showAlert = true
        } else if !state.masuk {
            alertMessage = "Presensi pagi belum dilakukan"
            showAlert = true
        } else {
            selectedJenis = "Siang"
            navigateToActivity = true
        }
    }

    func handleSore() {
        if checkIzin() { return }
        if state.pulang {
            alertMessage = "Presensi sore sudah dilakukan"
            showAlert = true
        } else if !state.siang {
            alertMessage = "Presensi siang belum dilakukan"
            showAlert = true
        } else {
            selectedJenis = "Pulang"
            navigateToActivity = true
        }
    }
}
