//
//  KegiatanDatePickerSheet.swift
//  E-Presensi
//

import SwiftUI

struct KegiatanDatePickerSheet: View {
    @State var selectedDate: Date
    let maximumDate: Date
    let onSelect: (Date) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker(
                "Pilih Tanggal",
                selection: $selectedDate,
                in: ...maximumDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("Pilih Tanggal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pilih") {
                        onSelect(selectedDate)
                        dismiss()
                    }
                }
            }
        }
    }
}
