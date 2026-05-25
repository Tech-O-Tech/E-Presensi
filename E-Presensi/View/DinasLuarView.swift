//
//  DinasLuarView.swift
//  E-Presensi
//
//  Halaman "Upload SPT DL" — setara activity_dinas_luar.xml Android.
//

import SwiftUI
import UniformTypeIdentifiers

struct DinasLuarView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: DinasLuarViewModel

    @State private var showDateRange = false
    @State private var showFileDialog = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showDocumentPicker = false

    private let primaryNavy = Color(red: 0.07, green: 0.13, blue: 0.36)
    private let orange = Color(red: 0.95, green: 0.55, blue: 0.10)

    init(initialJenis: String = "DL LUAR KABUPATEN") {
        _vm = StateObject(wrappedValue: DinasLuarViewModel(initialJenis: initialJenis))
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerBar
                    tanggalField
                    jenisDropdown
                    keteranganField
                    uploadCard
                    submitButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
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
            if vm.isLoading { loadingOverlay }
        }
        .overlay {
            if vm.showSuccess { successOverlay }
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

    // MARK: - Subviews

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(primaryNavy)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            Text("Upload SPT DL")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(primaryNavy)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    private var tanggalField: some View {
        Button { showDateRange = true } label: {
            HStack(spacing: 12) {
                Text(vm.tanggalText.isEmpty ? "Tanggal DL" : vm.tanggalText)
                    .font(.body)
                    .foregroundColor(vm.tanggalText.isEmpty ? .gray : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "calendar")
                    .foregroundColor(primaryNavy)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(fieldFill)
            .overlay(fieldBorder)
        }
        .buttonStyle(.plain)
    }

    private var jenisDropdown: some View {
        JenisIzinDropdown(
            selection: $vm.jenisDL,
            options: vm.jenisOptions,
            placeholder: "Jenis DL"
        )
    }

    private var keteranganField: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $vm.keterangan)
                .font(.body)
                .frame(minHeight: 90)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(fieldFill)
                .overlay(fieldBorder)

            if vm.keterangan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Keterangan")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
        }
    }

    private var uploadCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.18))
                    .frame(width: 96, height: 110)

                if let preview = vm.filePreview {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 38))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(vm.fileName.isEmpty ? "Nama File.pdf" : vm.fileName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text("Unggah bukti Izin dengan format .pdf, .jpg atau .jpeg")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    showFileDialog = true
                } label: {
                    Text("Pilih File")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(orange)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    private var submitButton: some View {
        Button(action: vm.submit) {
            Text("Kirim Izin")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(primaryNavy)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(vm.isLoading)
        .padding(.top, 6)
    }

    // MARK: - Helpers

    private var fieldFill: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemBackground))
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.gray.opacity(0.35), lineWidth: 1)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().scaleEffect(1.4)
                Text("Mengunggah dokumen...")
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
                Text("Upload SPT DL berhasil")
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
            .appendingPathComponent("spt_dl_\(UUID().uuidString).jpg")
        try? data.write(to: url)
        return url
    }
}

#Preview {
    NavigationStack {
        DinasLuarView()
    }
}
