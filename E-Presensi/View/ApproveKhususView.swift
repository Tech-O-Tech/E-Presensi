//
//  ApproveKhususView.swift
//  E-Presensi
//
//  Halaman daftar pengajuan absen khusus yang menunggu approval atasan.
//  Placeholder awal — endpoint detail akan dihubungkan saat tersedia.
//

import SwiftUI

struct ApproveKhususView: View {

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                headerSection

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        placeholderEmptyState
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Approve Khusus")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(PresensiTheme.navy)
                .padding(.top, 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    private var placeholderEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.full")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Belum ada pengajuan absen khusus")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    NavigationStack {
        ApproveKhususView()
    }
}
