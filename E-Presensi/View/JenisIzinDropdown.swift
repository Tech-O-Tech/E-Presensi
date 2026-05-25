//
//  JenisIzinDropdown.swift
//  E-Presensi
//
//  Setara ExposedDropdownMenu + list_jenis_izin Android
//

import SwiftUI

struct JenisIzinDropdown: View {
    @Binding var selection: String
    let options: [String]
    var placeholder: String = "Pilih jenis izin"

    @State private var isExpanded = false

    private let primaryNavy = Color(red: 0.07, green: 0.13, blue: 0.36)
    private let cornerRadius: CGFloat = 10

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Text(displayText)
                        .font(.body)
                        .foregroundColor(selection.isEmpty ? Color.gray : Color.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(primaryNavy)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(fieldFill)
                .overlay(fieldBorder(expanded: isExpanded))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            selection = option
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                            }
                        } label: {
                            HStack {
                                Text(option)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if selection == option {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(primaryNavy)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(selection == option ? primaryNavy.opacity(0.08) : Color.clear)
                        }
                        .buttonStyle(.plain)

                        if option != options.last {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(primaryNavy.opacity(0.35), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var displayText: String {
        selection.isEmpty ? placeholder : selection
    }

    private var fieldFill: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemBackground))
    }

    private func fieldBorder(expanded: Bool) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                expanded ? primaryNavy.opacity(0.6) : Color.gray.opacity(0.35),
                lineWidth: expanded ? 1.5 : 1
            )
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var jenis = ""
        var body: some View {
            JenisIzinDropdown(
                selection: $jenis,
                options: ["DL", "SAKIT", "IZIN", "CUTI"]
            )
            .padding()
        }
    }
    return PreviewWrapper()
}
