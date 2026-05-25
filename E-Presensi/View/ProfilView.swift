//
//  ProfilView.swift
//  E-Presensi
//
//  Setara ProfilFragment Android
//

import SwiftUI
import Combine


enum ProfilDestination: Hashable {
    case lapkin
    case complaint
    case about
    case privacy
}

struct ProfilView: View {

    @AppStorage(Keys.namaPegawai) private var namaPegawai = ""
    @AppStorage(Keys.nipPegawai) private var nipPegawai = ""
    @AppStorage(Keys.isLogin) private var isLogin = ""
    @AppStorage(Keys.darkMode) private var darkMode = false

    @StateObject private var vm = ProfilViewModel()
    @State private var path = NavigationPath()
    @State private var showCamera = false
    @State private var showUbahPassword = false
    @State private var showLogoutConfirm = false

    private let primaryNavy = Color(red: 13/255, green: 23/255, blue: 95/255)
    private let logoutRed = Color(red: 198/255, green: 40/255, blue: 40/255)

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    mainMenuCard
                        .padding(.horizontal, 16)
                        .offset(y: -8)
                    infoMenuCard
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    logoutButton
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .toolbarBackground(primaryNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: ProfilDestination.self) { dest in
                switch dest {
                case .lapkin: LapkinView()
                case .complaint: ComplaintView()
                case .about: AboutView()
                case .privacy: PrivacyView()
                }
            }
        }
        .onAppear { vm.refreshProfile() }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image, _ in
                vm.handleCameraResult(image: image)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showUbahPassword) {
            UbahPasswordView()
        }
        .overlay {
            if vm.isUploadingFoto {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    ProgressView("Mengunggah foto...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
        }
        .alert("Pemberitahuan", isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
        .alert("Keluar Akun", isPresented: $showLogoutConfirm) {
            Button("Batal", role: .cancel) {}
            Button("Keluar", role: .destructive) {
                AppPreference.shared.logout()
                isLogin = "0"
            }
        } message: {
            Text("Apakah Anda yakin ingin keluar dari akun?")
        }
    }

  // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Profil")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 8)

            HStack(alignment: .center, spacing: 16) {
                fotoProfil
                VStack(alignment: .leading, spacing: 4) {
                    Text(namaPegawai.isEmpty ? "-" : namaPegawai)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(nipPegawai.isEmpty ? "-" : nipPegawai)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer(minLength: 0)
                Button { showCamera = true } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(primaryNavy)
                        .frame(width: 40, height: 40)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .top) {
            primaryNavy
                .ignoresSafeArea(edges: .top)
        }
        .safeAreaPadding(.top, 44)
    }

    @ViewBuilder
    private var fotoProfil: some View {
        Group {
            if let url = URL(string: vm.fotoURL), !vm.fotoURL.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        profilPlaceholder
                    }
                }
            } else {
                profilPlaceholder
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(Circle())
    }

    private var profilPlaceholder: some View {
        Circle()
            .fill(Color.white.opacity(0.2))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.9))
            )
    }

    // MARK: - Menu cards

    private var mainMenuCard: some View {
        VStack(spacing: 0) {
            profilMenuRow(icon: "doc.text.fill", title: "Laporan Kegiatan") {
                path.append(ProfilDestination.lapkin)
            }
            divider
            profilMenuRow(icon: "exclamationmark.bubble.fill", title: "Buat Keluhan") {
                path.append(ProfilDestination.complaint)
            }
            divider
            HStack(spacing: 0) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 18))
                    .foregroundColor(primaryNavy)
                    .frame(width: 40, height: 40)
                Text("Mode Gelap")
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .padding(.leading, 12)
                Spacer()
                Toggle("", isOn: $darkMode)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            divider
            profilMenuRow(icon: "lock.fill", title: "Ubah Kata Sandi") {
                showUbahPassword = true
            }
        }
        .background(cardBackground)
    }

    private var infoMenuCard: some View {
        VStack(spacing: 0) {
            profilMenuRow(icon: "info.circle.fill", title: "Tentang Aplikasi") {
                path.append(ProfilDestination.about)
            }
            divider
            profilMenuRow(icon: "hand.raised.fill", title: "Kebijakan Privasi") {
                path.append(ProfilDestination.privacy)
            }
        }
        .background(cardBackground)
    }

    private var logoutButton: some View {
        Button { showLogoutConfirm = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                Text("Keluar Akun")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(logoutRed)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(logoutRed, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }

    private func profilMenuRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(primaryNavy)
                    .frame(width: 40, height: 40)
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .padding(.leading, 12)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.gray.opacity(0.45))
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfilView()
}
