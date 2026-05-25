//
//  IzinDateRangeSheet.swift
//  E-Presensi
//

import SwiftUI

struct IzinDateRangeSheet: View {
    @State private var mulai: Date
    @State private var selesai: Date
    let onSelect: (Date, Date) -> Void

    @Environment(\.dismiss) private var dismiss

    init(
        mulai: Date = Date(),
        selesai: Date = Date(),
        onSelect: @escaping (Date, Date) -> Void
    ) {
        _mulai = State(initialValue: mulai)
        _selesai = State(initialValue: selesai)
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "Tanggal mulai",
                    selection: $mulai,
                    in: Date()...,
                    displayedComponents: .date
                )
                DatePicker(
                    "Tanggal selesai",
                    selection: $selesai,
                    in: mulai...,
                    displayedComponents: .date
                )
            }
            .navigationTitle("Pilih Tanggal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pilih") {
                        onSelect(mulai, selesai)
                        dismiss()
                    }
                }
            }
        }
    }
}
