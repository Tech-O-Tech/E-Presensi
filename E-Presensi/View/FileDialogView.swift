//
//  FileDialogView.swift
//  E-Presensi
//

import SwiftUI

struct FileDialogView: View {
    let onCamera: () -> Void
    let onGallery: () -> Void
    let onFile: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            dialogRow(title: "Ambil Foto", icon: "camera.fill", action: onCamera)
            Divider()
            dialogRow(title: "Dari Galeri", icon: "photo.on.rectangle", action: onGallery)
            Divider()
            dialogRow(title: "Pilih File", icon: "doc.fill", action: onFile)
            Divider()
            Button(action: onCancel) {
                Text("Batal")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 24)
    }

    private func dialogRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.07, green: 0.13, blue: 0.36))
                    .frame(width: 28)
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        FileDialogView(onCamera: {}, onGallery: {}, onFile: {}, onCancel: {})
    }
}
