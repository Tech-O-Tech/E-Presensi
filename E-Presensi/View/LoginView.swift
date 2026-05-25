//
//  login.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 22/04/26.
//

import SwiftUI

struct LoginView: View {
    @AppStorage(Keys.isLogin) private var isLogin = ""
    @StateObject private var viewModel = LoginViewModel()
    @State private var isPasswordVisible = false

    let navyBlue = Color(red: 13/255, green: 23/255, blue: 95/255)

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    AsyncImage(url: URL(string: "https://dev.pringsewukab.go.id/foto/img_20210316_175131_scaled.jpg")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.32)
                    .clipped()

                    Spacer()
                }
                .edgesIgnoringSafeArea(.top)

                VStack {
                    Spacer().frame(height: UIScreen.main.bounds.height * 0.35)

                    VStack(alignment: .leading, spacing: 20) {
                        Text("Masuk")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(navyBlue)

                        Text("Masuk ke aplikasi untuk menggunakan E-Presensi!")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        TextField("NIP", text: $viewModel.nip)
                            .keyboardType(.numberPad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.4)))

                        HStack {
                            if isPasswordVisible {
                                TextField("Password", text: $viewModel.password)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("Password", text: $viewModel.password)
                            }

                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.4)))

                        // Tombol Masuk + ikon Face ID (setara activity_login.xml)
                        HStack(spacing: 10) {
                            Button(action: loginWithPassword) {
                                Group {
                                    if viewModel.isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Masuk")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(navyBlue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading)

                            if viewModel.showBiometricLogin {
                                Button(action: loginWithFaceID) {
                                    Image(systemName: viewModel.biometricIconName)
                                        .font(.system(size: 28, weight: .regular))
                                        .foregroundColor(navyBlue)
                                        .frame(width: 54, height: 54)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                                        )
                                }
                                .accessibilityLabel(viewModel.biometricAccessibilityLabel)
                                .disabled(viewModel.isLoading)
                            }
                        }
                        .padding(.top, 10)

                        Spacer()

                        HStack {
                            Spacer()
                            Text("E-Presensi Pringsewu v1.2.14")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.bottom, 10)
                    }
                    .padding(20)
                    .background(
                        RoundedCorner(radius: 40, corners: [.topLeft, .topRight])
                            .fill(Color.white)
                    )
                }

                VStack {
                    Spacer()
                    WaveShapeLogin()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 120)
                }
                .ignoresSafeArea()
            }
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
                viewModel.refreshBiometricAvailability()
            }
            .alert("Informasi", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }

    private func loginWithPassword() {
        viewModel.login { success in
            guard success else { return }
            isLogin = "1"
        }
    }

    private func loginWithFaceID() {
        viewModel.authenticateBiometric { success in
            guard success else { return }
            isLogin = "1"
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
