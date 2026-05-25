//
//  RootView.swift
//  E-Presensi
//

import SwiftUI

struct RootView: View {
    @AppStorage(Keys.isLogin) private var isLogin = ""
    @State private var showUbahPassword = false
    @State private var showPasswordReauth = false

    var body: some View {
        Group {
            if isLogin == "1" {
                HomeView()
            } else {
                LoginView()
            }
        }
        .onAppear { handleLoggedInState() }
        .onChange(of: isLogin) { _, _ in handleLoggedInState() }
        .fullScreenCover(isPresented: $showUbahPassword) {
            UbahPasswordView(isMandatory: true)
        }
        .fullScreenCover(isPresented: $showPasswordReauth) {
            PasswordView {
                showPasswordReauth = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionExpired)) { _ in
            showPasswordReauth = true
        }
    }

    private func handleLoggedInState() {
        guard isLogin == "1" else { return }
        PresensiSessionService.syncPresensiHariIni()
        if AppPreference.shared.isFirstTime {
            showUbahPassword = true
        }
    }
}
