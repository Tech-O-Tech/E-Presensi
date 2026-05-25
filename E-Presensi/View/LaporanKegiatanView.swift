//
//  LaporanKegiatanView.swift
//  E-Presensi
//
//  Form "Input Laporan Kegiatan" (sebelumnya isi langsung dari KegiatanView).
//  Kini menjadi salah satu tab di dalam halaman Rekap (setara tab "Laporan" Android).
//

import SwiftUI
import UniformTypeIdentifiers
import Combine
import Foundation
import UIKit

struct LaporanKegiatanView: View {
    @StateObject private var viewModel = KegiatanViewModel()

    @State private var showDatePicker = false
    @State private var showFileDialog = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showDocumentPicker = false

    private let primaryNavy = Color(red: 0.07, green: 0.13, blue: 0.36)
    private let accentOrange = Color(red: 0.93, green: 0.54, blue: 0.20)
    private let fieldBorder = Color.gray.opacity(0.35)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Input Laporan Kegiatan")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(primaryNavy)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                tanggalField
                    .padding(.bottom, 16)

                deskripsiField
                    .padding(.bottom, 20)

                fileSection
                    .padding(.bottom, 28)

                kirimButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .onAppear { viewModel.onAppear() }
        .sheet(isPresented: $showDatePicker) {
            KegiatanDatePickerSheet(
                selectedDate: viewModel.tanggalKegiatan,
                maximumDate: Date()
            ) { viewModel.setDate($0) }
            .presentationDetents([.medium])
        }
        .overlay {
            if showFileDialog {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { showFileDialog = false }
                    FileDialogView(
                        onCamera: {
                            showFileDialog = false
                            showCamera = true
                        },
                        onGallery: {
                            showFileDialog = false
                            showPhotoLibrary = true
                        },
                        onFile: {
                            showFileDialog = false
                            showDocumentPicker = true
                        },
                        onCancel: { showFileDialog = false }
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image, _ in
                viewModel.handleImage(image)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoLibrary) {
            ImagePicker(sourceType: .photoLibrary) { image, _ in
                viewModel.handleImage(image)
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(
                allowedTypes: [.pdf],
                onPick: { viewModel.handleDocument(url: $0) },
                onCancel: { viewModel.handleDocumentCancelled() }
            )
        }
        .overlay {
            if viewModel.isLoading {
                KegiatanLoadingOverlay(state: viewModel.loadingState)
            }
        }
        .alert("Pemberitahuan", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private var tanggalField: some View {
        Button { showDatePicker = true } label: {
            HStack {
                Text(viewModel.tanggalText.isEmpty ? "Tanggal Kegiatan" : viewModel.tanggalText)
                    .font(.system(size: 16))
                    .foregroundColor(viewModel.tanggalText.isEmpty ? Color.gray.opacity(0.7) : .primary)
                Spacer()
                Image(systemName: "calendar")
                    .font(.system(size: 18))
                    .foregroundColor(Color.gray.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(fieldBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var deskripsiField: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.deskripsi.isEmpty {
                Text("Deskripsi Kegiatan")
                    .font(.system(size: 16))
                    .foregroundColor(Color.gray.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }
            TextEditor(text: $viewModel.deskripsi)
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
        HStack(alignment: .top, spacing: 14) {
            Group {
                if let image = viewModel.previewImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.93, green: 0.93, blue: 0.93))
                        Image(systemName: viewModel.isPDF ? "doc.fill" : "doc.text")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(Color.gray.opacity(0.55))
                    }
                }
            }
            .frame(width: 82, height: 82)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.fileName.isEmpty ? "Nama File.pdf" : viewModel.fileName)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)

                if viewModel.showUploadHint {
                    Text("Unggah bukti kegiatan dengan format file .pdf, .jpg atau .jpeg")
                        .font(.system(size: 12))
                        .foregroundColor(Color.gray.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button { showFileDialog = true } label: {
                    Text("Pilih File")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 120, height: 38)
                        .background(accentOrange)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var kirimButton: some View {
        Button { viewModel.kirimLaporan() } label: {
            Text("Kirim Laporan")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(primaryNavy)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LaporanKegiatanView()
}
