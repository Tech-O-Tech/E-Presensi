//
//  E_PresensiApp.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 21/04/26.
//

import SwiftUI

@main
struct E_PresensiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(Keys.darkMode) private var darkMode = false

    var body: some Scene {
        WindowGroup {
            SplashScreenWrapper()
                .preferredColorScheme(darkMode ? .dark : .light)
        }
    }
}
