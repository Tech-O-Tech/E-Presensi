//
//  UbahPasswordView.swift
//  E-Presensi
//
//  Setara UbahPasswordActivity + activity_ubah_password.xml
//

import SwiftUI

struct UbahPasswordView: View {

    /// Login pertama (`first_time == 0`) — tanpa tombol kembali.
    var isMandatory: Bool = false

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UbahPasswordViewModel()
    @State private var isPasswordVisible = false

    private let navy = Color(red: 13/255, green: 23/255, blue: 95/255)
    private let hintGray = Color(red: 0.46, green: 0.46, blue: 0.46)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerIllustration
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)

                VStack(alignment: .leading, spacing: 24) {
                    Text("Ubah Kata Sandi")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(navy)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Gunakan kata sandi yang mudah diingat untuk kemudahan akses aplikasi!")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    passwordField

                    if let error = viewModel.passwordError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button(action: { viewModel.ubahPassword() }) {
                        Group {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Ubah Password")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(navy)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .topLeading) {
            if !isMandatory {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(20)
                }
            }
        }
        .interactiveDismissDisabled(isMandatory)
        .alert("Pemberitahuan", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {
                viewModel.handleAlertDismissed()
                if viewModel.didSucceed || viewModel.needsReauth {
                    dismiss()
                }
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private var headerIllustration: some View {
        Image("ic_data_security_03")
            .resizable()
            .scaledToFit()
            .padding(.top, isMandatory ? 8 : 40)
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 4) {
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
                .onChange(of: viewModel.password) { _, _ in
                    viewModel.passwordError = nil
                }

                Button { isPasswordVisible.toggle() } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(hintGray)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        viewModel.passwordError != nil ? Color.red : Color.gray.opacity(0.4),
                        lineWidth: 1
                    )
            )
        }
    }
}

#Preview {
    UbahPasswordView()
}
