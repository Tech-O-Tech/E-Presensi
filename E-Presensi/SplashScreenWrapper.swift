//
//  SplashScreenWrapper.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 21/04/26.
//

import SwiftUI

struct SplashScreenWrapper: View {
    @State private var isActive = false

    var body: some View {
        if isActive {
            RootView()
        } else {
            SplashView()
                .onAppear {
                    AbsensiReminderManager.scheduleAll()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isActive = true
                    }
                }
        }
    }
}
