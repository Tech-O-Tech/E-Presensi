//
//  PasswordView.swift
//  E-Presensi
//
//  Setara PasswordActivity + activity_password.xml
//

import SwiftUI

struct PasswordView: View {

    var onSuccess: (() -> Void)?

    @StateObject private var viewModel = PasswordViewModel()
    @State private var isPasswordVisible = false

    private let navyBlue = Color(red: 13/255, green: 23/255, blue: 95/255)
    private let lockGray = Color(red: 0.55, green: 0.55, blue: 0.55)

    var body: some View {
        VStack(spacing: 0) {
            padlockIllustration
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 40)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 24) {
                Text("Masukkan Kata Sandi")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(navyBlue)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Demi keamanan data Anda, silahkan masukkan kembali password Anda!")
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                passwordField

                Button(action: submit) {
                    Group {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Masuk")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(navyBlue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .alert("Pemberitahuan", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private var padlockIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(lockGray.opacity(0.35))
                .frame(width: 140, height: 120)
            VStack(spacing: 0) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 56))
                    .foregroundColor(lockGray)
                    .offset(y: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(navyBlue)
                    .frame(width: 100, height: 8)
                    .offset(y: -8)
            }
            Image(systemName: "key.fill")
                .font(.system(size: 22))
                .foregroundColor(navyBlue)
                .offset(y: 4)
        }
        .frame(height: 180)
    }

    private var passwordField: some View {
        HStack(spacing: 12) {
            Group {
                if isPasswordVisible {
                    TextField("Password", text: $viewModel.password)
                } else {
                    SecureField("Password", text: $viewModel.password)
                }
            }
            .font(.system(size: 16))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button { isPasswordVisible.toggle() } label: {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(lockGray)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }

    private func submit() {
        viewModel.masuk { success in
            if success { onSuccess?() }
        }
    }
}

#Preview {
    PasswordView()
}
