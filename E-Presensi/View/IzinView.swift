//
//  IzinView.swift
//  E-Presensi
//
//  Setara IzinActivity Android
//

import SwiftUI
import UniformTypeIdentifiers

struct IzinView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = IzinViewModel()

    @State private var showDateRange = false
    @State private var showFileDialog = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showDocumentPicker = false

    private let primaryNavy = Color(red: 0.07, green: 0.13, blue: 0.36)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                fieldLabel("Jenis Izin")
                JenisIzinDropdown(
                    selection: $vm.jenisIzin,
                    options: vm.jenisOptions,
                    placeholder: "Pilih jenis izin"
                )

                fieldLabel("Tanggal Izin")
                Button { showDateRange = true } label: {
                    HStack(spacing: 12) {
                        Text(vm.tanggalText.isEmpty ? "Pilih tanggal izin" : vm.tanggalText)
                            .font(.body)
                            .foregroundColor(vm.tanggalText.isEmpty ? .gray : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)

                        Image(systemName: "calendar")
                            .foregroundColor(primaryNavy)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(fieldFill)
                    .overlay(fieldBorder)
                }
                .buttonStyle(.plain)

                fieldLabel("Keterangan")
                TextEditor(text: $vm.deskripsi)
                    .frame(minHeight: 100)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(fieldFill)
                    .overlay(fieldBorder)

                fieldLabel("Bukti Izin")
                buktiSection

                Button(action: vm.submit) {
                    Text("Kirim Pengajuan")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(primaryNavy)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(vm.isLoading)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Pengajuan Izin")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.onAppear() }
        .sheet(isPresented: $showDateRange) {
            IzinDateRangeSheet { mulai, selesai in
                vm.setDateRange(mulai: mulai, selesai: selesai)
            }
            .presentationDetents([.medium, .large])
        }
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
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image, url in
                if let image {
                    let fileURL = url ?? saveTempImage(image)
                    if let fileURL { vm.setImage(image, url: fileURL) }
                }
            }
        }
        .sheet(isPresented: $showPhotoLibrary) {
            ImagePicker(sourceType: .photoLibrary) { image, url in
                if let image {
                    let fileURL = url ?? saveTempImage(image)
                    if let fileURL { vm.setImage(image, url: fileURL) }
                }
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(
                allowedTypes: [.pdf, .jpeg, .png, .image],
                onPick: { url in vm.setDocument(url: url) }
            )
        }
        .overlay {
            if vm.isLoading { izinLoadingOverlay }
        }
        .overlay {
            if vm.showSuccess {
                successOverlay
            }
        }
        .alert("Pemberitahuan", isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
        .onChange(of: vm.showSuccess) { _, ok in
            if ok {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        }
    }

    private var fieldFill: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemBackground))
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.gray.opacity(0.35), lineWidth: 1)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text).font(.subheadline.bold()).foregroundColor(primaryNavy)
    }

    private var buktiSection: some View {
        VStack(spacing: 12) {
            if let preview = vm.filePreview {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 120)
                    .cornerRadius(8)
            } else if vm.isPDF {
                Label(vm.fileName, systemImage: "doc.fill")
                    .foregroundColor(primaryNavy)
            }

            Button { showFileDialog = true } label: {
                HStack {
                    Image(systemName: "arrow.up.doc")
                    Text(vm.fileName.isEmpty ? "Upload Bukti" : vm.fileName)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }

    private var izinLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.4)
                Text("Mengunggah izin...")
                    .font(.subheadline)
            }
            .padding(28)
            .background(Color.white)
            .cornerRadius(14)
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.green)
                Text("Pengajuan izin berhasil")
                    .font(.headline)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }

    private func saveTempImage(_ image: UIImage) -> URL? {
        guard let data = ImageCompressor.compress(image) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("izin_\(UUID().uuidString).jpg")
        try? data.write(to: url)
        return url
    }
}
