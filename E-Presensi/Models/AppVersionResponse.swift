//
//  AppVersionResponse.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 22/04/26.
//

import Foundation

struct AppVersionResponse: Codable {
    let message: String
    let code: Int
    let data: AppVersionData
}

struct AppVersionData: Codable {
    let id: Int
    let platform: String
    let versionCode: Int
    let versionName: String
    let forceUpdate: Int
    let releaseNotes: String
    let updateURL: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case platform
        case versionCode = "version_code"
        case versionName = "version_name"
        case forceUpdate = "force_update"
        case releaseNotes = "release_notes"
        case updateURL = "update_url"
    }
}
