//
//  CameraView.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 29/04/26.
//

import SwiftUI

struct CameraView: View {
    
    var jenis: String
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("Presensi")
                .font(.title)
            
            Text(jenis)
                .font(.headline)
            
            Button("Simulasi Absen") {
                print("Submit: \(jenis)")
            }
            
            Spacer()
        }
        .padding()
    }
}
