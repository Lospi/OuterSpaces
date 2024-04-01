//
//  Repository.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 27/11/23.
//

import CryptoKit
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

    func updateLicenseKey() {
        if Repository.suiteUserDefaults.data(forKey: "LicenseKey") != nil {
            createLicenseKey()
        }
    }

    func createLicenseKey() {
        let key = SymmetricKey(size: .bits256)
        let encodedKey = key.withUnsafeBytes { Data(Array($0)) }
        Repository.suiteUserDefaults.set(encodedKey, forKey: "LicenseKey")
    }

    func fetchLicenseKey() -> SymmetricKey? {
        let encodedKey = Repository.suiteUserDefaults.data(forKey: "LicenseKey")
        if encodedKey != nil {
            return SymmetricKey(data: encodedKey!)
        } else {
            createLicenseKey()
            return fetchLicenseKey()
        }
    }

    func updateLicenseState(state: Bool) {
        let key = fetchLicenseKey()

        if let key = key {
            let data = "\(state)".data(using: .utf8)!
            let encryptedContent = try! ChaChaPoly.seal(data, using: key).combined
            Repository.suiteUserDefaults.set(encryptedContent, forKey: "LicenseState")
        }
    }

    func fetchLicenseState() -> Bool {
        let key = fetchLicenseKey()
        let encryptedState = Repository.suiteUserDefaults.data(forKey: "LicenseState")
        if let key = key, let encryptedState = encryptedState {
            let sealedBox = try! ChaChaPoly.SealedBox(combined: encryptedState)
            let decryptedState = try! ChaChaPoly.open(sealedBox, using: key)
            let state = String(data: decryptedState, encoding: .utf8)
            return state == "true"
        }
        return false
    }

    func createOfflinePermission() {
        let key = SymmetricKey(size: .bits256)
        let encodedKey = key.withUnsafeBytes { Data(Array($0)) }
        Repository.suiteUserDefaults.set(encodedKey, forKey: "OfflinePermission")
    }

    func fetchOfflinePermissionKey() -> SymmetricKey? {
        let encodedKey = Repository.suiteUserDefaults.data(forKey: "OfflinePermission")
        if encodedKey != nil {
            return SymmetricKey(data: encodedKey!)
        } else {
            createOfflinePermission()
            return fetchOfflinePermissionKey()
        }
    }

    func updateOfflinePermissionStatus(status: Bool) {
        let key = fetchOfflinePermissionKey()

        if let key = key {
            let data = "\(status)".data(using: .utf8)!
            let encryptedContent = try! ChaChaPoly.seal(data, using: key).combined
            Repository.suiteUserDefaults.set(encryptedContent, forKey: "OfflinePermissionStatus")
        }
    }

    func fetchOfflinePermissionStatus() -> Bool {
        let key = fetchOfflinePermissionKey()
        let encryptedState = Repository.suiteUserDefaults.data(forKey: "OfflinePermissionStatus")
        if let key = key, let encryptedState = encryptedState {
            let sealedBox = try! ChaChaPoly.SealedBox(combined: encryptedState)
            let decryptedState = try! ChaChaPoly.open(sealedBox, using: key)
            let state = String(data: decryptedState, encoding: .utf8)
            return state == "true"
        }
        return false
    }

    func updateOfflineDate(_ date: Date) {
        let key = fetchOfflinePermissionKey()

        if let key = key {
            let data = "\(date)".data(using: .utf8)!
            let encryptedContent = try! ChaChaPoly.seal(data, using: key).combined
            Repository.suiteUserDefaults.set(encryptedContent, forKey: "OfflineDate")
        }
    }

    func fetchOfflineDate() -> Date? {
        let key = fetchOfflinePermissionKey()
        let encryptedDate = Repository.suiteUserDefaults.data(forKey: "OfflineDate")
        if let key = key, let encryptedDate = encryptedDate {
            let dateFormatter = DateFormatter()

            let sealedBox = try! ChaChaPoly.SealedBox(combined: encryptedDate)
            let decryptedDate = try! ChaChaPoly.open(sealedBox, using: key)
            let date = String(data: decryptedDate, encoding: .utf8)
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            if let date = dateFormatter.date(from: date!) {
                return date
            }
        }
        return nil
    }

    func createTrialKey() {
        let key = SymmetricKey(size: .bits256)
        let encodedKey = key.withUnsafeBytes { Data(Array($0)) }
        Repository.suiteUserDefaults.set(encodedKey, forKey: "TrialKey")
    }

    func fetchTrialKey() -> SymmetricKey? {
        let encodedKey = Repository.suiteUserDefaults.data(forKey: "TrialKey")
        if encodedKey != nil {
            return SymmetricKey(data: encodedKey!)
        } else {
            createTrialKey()
            return fetchTrialKey()
        }
    }

    func fetchTrialState() -> Bool {
        let key = fetchTrialKey()
        let encryptedState = Repository.suiteUserDefaults.data(forKey: "TrialState")
        if let key = key, let encryptedState = encryptedState {
            let sealedBox = try! ChaChaPoly.SealedBox(combined: encryptedState)
            let decryptedState = try! ChaChaPoly.open(sealedBox, using: key)
            let state = String(data: decryptedState, encoding: .utf8)
            return state == "true"
        }
        return false
    }

    func updateTrialEnd(_ state: Bool) {
        let key = fetchTrialKey()

        if let key = key {
            let data = "\(state)".data(using: .utf8)!
            let encryptedContent = try! ChaChaPoly.seal(data, using: key).combined
            Repository.suiteUserDefaults.set(encryptedContent, forKey: "TrialEnd")
        }
    }

    func fetchTrialEndState() -> Bool {
        let key = fetchTrialKey()
        let encryptedState = Repository.suiteUserDefaults.data(forKey: "TrialEnd")
        if let key = key, let encryptedState = encryptedState {
            let sealedBox = try! ChaChaPoly.SealedBox(combined: encryptedState)
            let decryptedState = try! ChaChaPoly.open(sealedBox, using: key)
            let state = String(data: decryptedState, encoding: .utf8)
            return state == "true"
        }
        return false
    }

    func updateTrialState(state: Bool) {
        let key = fetchTrialKey()

        if let key = key {
            let data = "\(state)".data(using: .utf8)!
            let encryptedContent = try! ChaChaPoly.seal(data, using: key).combined
            Repository.suiteUserDefaults.set(encryptedContent, forKey: "TrialState")
        }
    }

    func fetchTrialDate() -> Date? {
        let key = fetchTrialKey()
        let encryptedDate = Repository.suiteUserDefaults.data(forKey: "TrialDate")
        if let key = key, let encryptedDate = encryptedDate {
            let dateFormatter = DateFormatter()

            let sealedBox = try! ChaChaPoly.SealedBox(combined: encryptedDate)
            let decryptedDate = try! ChaChaPoly.open(sealedBox, using: key)
            let date = String(data: decryptedDate, encoding: .utf8)
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            if let date = dateFormatter.date(from: date!) {
                return date
            }
        }
        return nil
    }

    func updateTrialDate(_ date: Date) {
        let key = fetchTrialKey()

        if let key = key {
            let data = "\(date)".data(using: .utf8)!
            let encryptedContent = try! ChaChaPoly.seal(data, using: key).combined
            Repository.suiteUserDefaults.set(encryptedContent, forKey: "TrialDate")
        }
    }
}
