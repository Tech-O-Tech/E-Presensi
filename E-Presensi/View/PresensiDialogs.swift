//
//  PresensiDialogs.swift
//  E-Presensi
//
//  Dialog setara PresensiFragment Android
//

import SwiftUI

// MARK: - Konfirmasi OPD

struct OpdConfirmDialog: View {
    let namaOpd: String
    let onYes: () -> Void
    let onNo: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Konfirmasi Perangkat Daerah")
                .font(.headline)
            Text("Apakah Anda masih bekerja di \(namaOpd)?")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                Button("Tidak", action: onNo)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                Button("Ya", action: onYes)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 13/255, green: 23/255, blue: 95/255))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(32)
    }
}

// MARK: - Pilih OPD

struct OpdPickerSheet: View {
    let opdList: [DataAllOpd]
    let onSelect: (DataAllOpd) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [DataAllOpd] {
        if search.isEmpty { return opdList }
        return opdList.filter { $0.namaOpd.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { opd in
                Button(opd.namaOpd) { onSelect(opd) }
            }
            .searchable(text: $search, prompt: "Cari OPD")
            .navigationTitle("Pilih OPD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Pengumuman umum

struct PengumumanUmumSheet: View {
    let imageURL: String
    let onDismiss: () -> Void
    let onNeverShow: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            if let url = URL(string: imageURL), !imageURL.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFit()
                    default: ProgressView()
                    }
                }
                .frame(maxHeight: 300)
            }
            Button("Tutup") { onDismiss() }
            Button("Jangan tampilkan lagi", role: .destructive, action: onNeverShow)
                .font(.footnote)
        }
        .padding()
    }
}

// MARK: - Popup ulang tahun (popup_ultahfix.xml + Konfetti)

struct BirthdayPopupView: View {
    let nama: String
    let onClose: () -> Void

    @State private var showConfetti = true

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            if showConfetti {
                BirthdayConfettiView(burstDuration: 1.8, visibleDuration: 7)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            birthdayCard
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showConfetti = false
                }
            }
        }
    }

    private var birthdayCard: some View {
        Image("cardulangtahun")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 320)
            .overlay {
                GeometryReader { geo in
                    Text(nama.uppercased())
                        .font(.system(size: min(17, geo.size.width * 0.053), weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                        .frame(width: geo.size.width - 88)
                        .position(
                            x: geo.size.width / 2,
                            y: geo.size.height * 0.30
                        )
                }
            }
            .overlay(alignment: .topTrailing) {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 44))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.black.opacity(0.15))
                        .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                }
                .offset(x: 6, y: -6)
            }
            .padding(.horizontal, 24)
    }
}
