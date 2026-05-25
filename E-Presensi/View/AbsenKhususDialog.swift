//
//  AbsenKhususDialog.swift
//  E-Presensi
//
//  Dialog "Pilih Jenis Absen Khusus" — setara absen_dialog_khusus.xml Android.
//  Tiga pilihan: Khusus Lisan, Dinas Luar Dalam Kabupaten, Dinas Luar Luar Kabupaten.
//

import SwiftUI

struct AbsenKhususDialogOverlay: View {

    let onLisan: () -> Void
    let onDLDalam: () -> Void
    let onDLLuar: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 12) {
                Text("Pilih Jenis Absen Khusus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.top, 4)

                AbsenKhususCard(
                    title: "Khusus Lisan",
                    titleSize: 24,
                    subtitle: "Tugas Dinas Luar Perintah Atasan Langsung",
                    imageName: "khususlisan",
                    tint: Color(red: 110/255, green: 180/255, blue: 230/255),
                    tintOpacity: 0.55,
                    action: onLisan
                )

                AbsenKhususCard(
                    title: "DINAS LUAR",
                    titleSize: 16,
                    subtitle: "Dalam Kabupaten",
                    subtitleSize: 18,
                    subtitleBold: true,
                    imageName: "khususdlluar",
                    action: onDLDalam
                )

                AbsenKhususCard(
                    title: "DINAS LUAR",
                    titleSize: 16,
                    subtitle: "Luar Kabupaten",
                    subtitleSize: 18,
                    subtitleBold: true,
                    imageName: "khususdlluar",
                    action: onDLLuar
                )
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
            .padding(.horizontal, 20)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

private struct AbsenKhususCard: View {
    let title: String
    let titleSize: CGFloat
    let subtitle: String
    let subtitleSize: CGFloat
    let subtitleBold: Bool
    let imageName: String
    /// Warna tint yang dioverlay di atas foto (mis. biru muda untuk Khusus Lisan).
    /// Kartu lain biarkan `nil` agar foto tampil tajam tanpa overlay.
    let tint: Color?
    let tintOpacity: Double
    let action: () -> Void

    init(
        title: String,
        titleSize: CGFloat = 22,
        subtitle: String,
        subtitleSize: CGFloat = 13,
        subtitleBold: Bool = false,
        imageName: String,
        tint: Color? = nil,
        tintOpacity: Double = 0.5,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.titleSize = titleSize
        self.subtitle = subtitle
        self.subtitleSize = subtitleSize
        self.subtitleBold = subtitleBold
        self.imageName = imageName
        self.tint = tint
        self.tintOpacity = tintOpacity
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
                    .allowsHitTesting(false)

                if let tint {
                    tint.opacity(tintOpacity)
                        .allowsHitTesting(false)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: titleSize, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)

                    Text(subtitle)
                        .font(.system(
                            size: subtitleSize,
                            weight: subtitleBold ? .bold : .regular
                        ))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
                }
                .padding(.leading, 20)
                .padding(.trailing, 16)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.18), radius: 5, x: 0, y: 2)
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AbsenKhususDialogOverlay(
        onLisan: {},
        onDLDalam: {},
        onDLLuar: {},
        onDismiss: {}
    )
}
