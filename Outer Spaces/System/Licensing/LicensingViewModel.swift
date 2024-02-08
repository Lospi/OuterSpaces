//
//  LicensingViewModel.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 22/01/24.
//

import Firebase
import Foundation
import SwiftUI

class LicensingViewModel: ObservableObject {
    static var isLicensed: Bool = false
    static var isOnTrial: Bool = false

    @Published var isLicenseRegistered: Bool = false
    @Published var isValidatingLicense: Bool = false
    @Published var failedToValidateLicense: Bool = false
    @Published var listener: ListenerRegistration?
    let db = Firestore.firestore()

    init() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false

        db.settings = settings
        fetchInitialValidation()
        listener = db.collection("users").document(getDeviceUUID()!)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }

                DispatchQueue.main.async {
                    self.isValidatingLicense = data["isValidating"] as? Bool ?? false
                    print("Is Validating: \(self.isValidatingLicense)")

                    self.isLicenseRegistered = data["isLicenseKeyValid"] as? Bool ?? false
                    LicensingViewModel.isLicensed = self.isLicenseRegistered
                    self.failedToValidateLicense = !((data["isLicenseKeyValid"] as? Bool) ?? true)
                    Repository.shared.updateLicensing((data["isLicenseKeyValid"] as? Bool) ?? false)
                    KeychainManager.saveLicenseState(self.isLicenseRegistered)
                }
            }
    }

    func getDeviceUUID() -> String? {
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

        guard platformExpert != 0 else {
            return nil
        }

        defer {
            IOObjectRelease(platformExpert)
        }

        if let serialNumber = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String) {
            return serialNumber
        }

        return nil
    }

    func fetchInitialValidation() {
        db.collection("users").document(getDeviceUUID()!).getDocument { document, _ in
            if let document = document, document.exists {
                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                print("Document data: \(dataDescription)")
                DispatchQueue.main.async {
                    self.isValidatingLicense = document.data()?["isValidating"] as? Bool ?? false
                    self.isLicenseRegistered = document.data()?["isLicenseKeyValid"] as? Bool ?? false
                    LicensingViewModel.isLicensed = self.isLicenseRegistered
                    self.failedToValidateLicense = !((document.data()?["isLicenseKeyValid"] as? Bool) ?? true)
                    Repository.shared.updateLicensing((document.data()?["isLicenseKeyValid"] as? Bool) ?? false)
                }
            } else {
                print("Document does not exist")
                self.db.collection("users").document(self.getDeviceUUID()!).setData([
                    "deviceUUID": self.getDeviceUUID()!,
                    "freeTrialAvailable": true,
                    "isLicenseKeyValid": false,
                    "isValidating": true])
            }
        }
    }

    func validateLicense(license: String) async {
        isValidatingLicense = true
        failedToValidateLicense = false
        do {
            try await db.collection("users").document(getDeviceUUID()!).setData([
                "deviceUUID": getDeviceUUID()!,
                "freeTrialAvailable": true,
                "licenseKey": license,
                "isLicenseKeyValid": false,
                "isValidating": true
            ])

        } catch {
            failedToValidateLicense = true
            isValidatingLicense = false
            print("Error adding document: \(error)")
        }
    }

    func deactivateLicense() async {
        do {
            try await db.collection("users").document(getDeviceUUID()!).updateData([
                "freeTrialAvailable": false,
                "licenseKey": "",
                "isLicenseKeyValid": false
            ])
            isLicenseRegistered = false
            LicensingViewModel.isLicensed = false
        } catch {
            print("Error updating document: \(error)")
        }
    }

    func activateTrial() async {
        do {
            try await db.collection("users").document(getDeviceUUID()!).updateData([
                "freeTrialAvailable": false,
                "trialStartDate": Timestamp(date: Date())
            ])
        } catch {
            print("Error updating document: \(error)")
        }
    }
}
