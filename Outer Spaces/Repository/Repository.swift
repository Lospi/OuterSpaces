//
//  Repository.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 27/11/23.
//

import Foundation

struct Repository {
    static var suiteUserDefaults = UserDefaults(suiteName: "dev.Lospi.OuterSpaces")!

    static let shared = Repository()

    func updateAppDataModelStore(_ settings: SettingsModel) {
        let encoder = JSONEncoder()
        do {
            let appDataModelEncoded = try encoder.encode(settings)
            Self.suiteUserDefaults.set(appDataModelEncoded, forKey: "AppData")
        } catch {}
    }

    func updateLicensing(_ licenseStatus: Bool) {
        Self.suiteUserDefaults.set(licenseStatus, forKey: "localLicenseStatus")
        print("License active: \(licenseStatus)")
    }
}
