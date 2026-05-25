//
//  KegiatanLoadingOverlay.swift
//  E-Presensi
//
//  Setara R.layout.loading_dialog — popup sukses upload kegiatan
//

import SwiftUI

struct KegiatanLoadingOverlay: View {
    let state: KegiatanViewModel.LoadingState

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()

                cardContent
                    .frame(
                        width: min(geo.size.width * 0.88, 360),
                        height: min(geo.size.height * 0.72, 520)
                    )
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        switch state {
        case .progress:
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.8)
                Text("Mengunggah dokumen, mohon tunggu...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(cardBackground)

        case .success(let message):
            VStack(spacing: 0) {
                Text(message)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 36)

                Spacer(minLength: 24)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 120))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.green)
                    .shadow(color: Color.green.opacity(0.35), radius: 12, x: 0, y: 6)

                Spacer(minLength: 48)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(cardBackground)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 8)
    }
}
