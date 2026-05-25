//
//  PresensiState.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 29/04/26.
//

import Foundation
import Combine

class PresensiState: ObservableObject {
    @Published var masuk: Bool
    @Published var siang: Bool
    @Published var pulang: Bool
    @Published var statusIzin: Bool

    init(
        masuk: Bool = false,
        siang: Bool = false,
        pulang: Bool = false,
        statusIzin: Bool = false
    ) {
        self.masuk = masuk
        self.siang = siang
        self.pulang = pulang
        self.statusIzin = statusIzin
    }
}
