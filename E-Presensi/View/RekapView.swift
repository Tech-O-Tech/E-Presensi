//
//  RekapView.swift
//  E-Presensi
//
//  Setara RekapActivity + activity_rekap.xml
//

import SwiftUI
import Combine

struct RekapView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = RekapViewModel()

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection

                    RekapSlotCard(
                        title: PresensiCopy.pagiTitle,
                        slot: vm.pagi,
                        emptyMessage: PresensiCopy.belumPresensiPagi
                    )

                    if vm.showSiangCard {
                        RekapSlotCard(
                            title: PresensiCopy.siangTitle,
                            slot: vm.siang,
                            emptyMessage: PresensiCopy.belumPresensiSiang
                        )
                    }

                    if vm.showSoreCard {
                        RekapSlotCard(
                            title: PresensiCopy.soreTitle,
                            slot: vm.sore,
                            emptyMessage: PresensiCopy.belumPresensiSore
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }

            if vm.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
        .navigationBarHidden(true)
        .onAppear { vm.load() }
        .alert("Pemberitahuan", isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 8)

            Text("Rekap Hari Ini")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(PresensiTheme.navy)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

typealias RekapPlaceholderView = RekapView

#Preview {
    NavigationStack {
        RekapView()
    }
}
