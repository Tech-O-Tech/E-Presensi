//
//  HomeView.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 22/04/26.
//
import SwiftUI

struct HomeView: View {
    @State private var selectedTab = 1

    private let tabTint = Color(red: 26/255, green: 35/255, blue: 126/255)

    var body: some View {
        TabView(selection: $selectedTab) {
            KegiatanView()
                .tabItem {
                    tabLabel(title: "Rekap", asset: "tab_kegiatan")
                }
                .tag(0)

            PresensiView()
                .tabItem {
                    tabLabel(title: "E-Presensi", asset: "tab_presensi")
                }
                .tag(1)

            NavigationStack {
                ApproveKhususView()
            }
            .tabItem {
                tabLabel(title: "Approve Khusus", systemImage: "checkmark.seal")
            }
            .tag(2)

            ProfilView()
                .tabItem {
                    tabLabel(title: "Profil", asset: "tab_profil")
                }
                .tag(3)
        }
        .tint(tabTint)
        .onAppear {
            PresensiSessionService.syncPresensiHariIni()
        }
    }

    @ViewBuilder
    private func tabLabel(title: String, asset: String) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(asset)
                .renderingMode(.template)
        }
    }

    @ViewBuilder
    private func tabLabel(title: String, systemImage: String) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
        }
    }
}
