//
//  KegiatanView.swift
//  E-Presensi
//
//  Setara `KegiatanFragment.kt` + `fragment_kegiatan.xml` Android.
//  Halaman ber-tab: Rekap Presensi | Rekap Izin | Laporan (input kegiatan).
//

import SwiftUI

struct KegiatanView: View {
    @State private var selectedTab = 0

    private let tabs = ["Rekap Presensi", "Rekap Izin", "Laporan"]

    var body: some View {
        VStack(spacing: 0) {
            header
            tabBar

            TabView(selection: $selectedTab) {
                RekapPresensiListView()
                    .tag(0)
                RekapIzinListView()
                    .tag(1)
                LaporanKegiatanView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .top)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Rekap")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PresensiTheme.navy)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, title in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index }
                } label: {
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 14, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? PresensiTheme.navy : .secondary)
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .fill(selectedTab == index ? PresensiTheme.navy : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

#Preview {
    KegiatanView()
}
