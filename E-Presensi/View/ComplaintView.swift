//
//  ComplaintView.swift
//  E-Presensi
//
//  Setara ComplaintActivity + activity_complaint.xml
//

import SwiftUI
import UniformTypeIdentifiers
import Combine
import Foundation



struct ComplaintView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ComplaintViewModel()

    @State private var showFileDialog = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showDocumentPicker = false

    private let primaryNavy = Color(red: 13/255, green: 23/255, blue: 95/255)
    private let accentOrange = Color(red: 0.93, green: 0.54, blue: 0.20)
    private let fieldBorder = Color.gray.opacity(0.35)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                headerBar
                    .padding(.bottom, 24)

                tujuanField
                    .padding(.bottom, 8)

                deskripsiField
                    .padding(.bottom, 24)

                fileSection
                    .padding(.bottom, 8)

                kirimButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .overlay {
            if showFileDialog {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                        .onTapGesture { showFileDialog = false }
                    FileDialogView(
                        onCamera: { showFileDialog = false; showCamera = true },
                        onGallery: { showFileDialog = false; showPhotoLibrary = true },
                        onFile: { showFileDialog = false; showDocumentPicker = true },
                        onCancel: { showFileDialog = false }
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image, _ in vm.handleImage(image) }
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoLibrary) {
            ImagePicker(sourceType: .photoLibrary) { image, _ in vm.handleImage(image) }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(
                allowedTypes: [.pdf],
                onPick: { vm.handleDocument(url: $0) },
                onCancel: { vm.handleDocumentCancelled() }
            )
        }
        .overlay {
            if vm.isLoading {
                KegiatanLoadingOverlay(state: vm.loadingState)
            }
        }
        .alert("Pemberitahuan", isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
    }

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
            }
            Text("Buat Keluhan")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(primaryNavy)
                .padding(.top, 48)
        }
    }

    private var tujuanField: some View {
        Menu {
            ForEach(ComplaintViewModel.tujuanOptions, id: \.self) { opt in
                Button(opt) { vm.tujuan = opt }
            }
        } label: {
            HStack {
                Text(vm.tujuan.isEmpty ? "Kepada" : vm.tujuan)
                    .font(.system(size: 16))
                    .foregroundColor(vm.tujuan.isEmpty ? Color.gray.opacity(0.7) : .primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(fieldBorder, lineWidth: 1)
            )
        }
    }

    private var deskripsiField: some View {
        ZStack(alignment: .topLeading) {
            if vm.deskripsi.isEmpty {
                Text("Keterangan")
                    .font(.system(size: 16))
                    .foregroundColor(Color.gray.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }
            TextEditor(text: $vm.deskripsi)
                .font(.system(size: 16))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(minHeight: 130)
                .scrollContentBackground(.hidden)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(fieldBorder, lineWidth: 1)
        )
    }

    private var fileSection: some View {
        HStack(alignment: .top, spacing: 8) {
            filePreview
                .frame(width: 90, height: 125)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 0) {
                Text(vm.fileName)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                    .padding(.top, 8)

                if vm.showUploadHint {
                    Text(ComplaintViewModel.uploadHint)
                        .font(.system(size: 13))
                        .foregroundColor(Color.gray.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 24)
                }

                Spacer(minLength: 8)

                Button { showFileDialog = true } label: {
                    Text("Pilih File")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(accentOrange)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 4)
            }
            .frame(minHeight: 125)
        }
    }

    @ViewBuilder
    private var filePreview: some View {
        if let img = vm.previewImage {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else if vm.isPDF {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.93, green: 0.93, blue: 0.93))
                .overlay(
                    Image(systemName: "doc.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(Color.gray.opacity(0.55))
                )
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.93, green: 0.93, blue: 0.93))
                .overlay(
                    Image(systemName: "doc.text")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(Color.gray.opacity(0.55))
                )
        }
    }

    private var kirimButton: some View {
        Button {
            vm.kirim { dismiss() }
        } label: {
            Text("Kirim Keluhan")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(primaryNavy)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
}

