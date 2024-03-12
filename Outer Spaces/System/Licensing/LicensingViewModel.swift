//
//  LicensingViewModel.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 22/01/24.
//

import Alamofire
import Foundation
import SwiftUI

class LicensingViewModel: ObservableObject {
    static var isLicensed: Bool = false
    static var isOnTrial: Bool = false
    let entryURL = "https://8ixo388z6c.execute-api.us-east-1.amazonaws.com/Prod/users/"
    
    @Published var isLicenseRegistered: Bool = false
    @Published var isValidatingLicense: Bool = false
    @Published var failedToValidateLicense: Bool = false
    
    init() {
        fetchInitialValidation()
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
        fetchUser()
    }
    
    func offlineValidation() {
        print("Offline Permission Status: \(KeychainManager.loadOfflinePermission())")
        print("License State: \(KeychainManager.loadLicenseState())")
        if (KeychainManager.loadOfflinePermission() == false || KeychainManager.loadOfflinePermission() == nil) && KeychainManager.loadLicenseState() == true {
            KeychainManager.saveOfflinePermission(true)
            KeychainManager.saveOfflinePermissionStartDate(Date.now)
            isLicenseRegistered = true
        }
        else if KeychainManager.loadOfflinePermission() == true, KeychainManager.loadLicenseState() == true {
            if Date.now.timeIntervalSince(KeychainManager.loadOfflinePermissionStartDate()!) > 10080 {
                KeychainManager.deleteLicenseState()
                disableOfflinePermission()
            }
            else {
                isLicenseRegistered = true
            }
        }
        else {
            isLicenseRegistered = false
        }
    }
    
    func validateLicense(license: String) async {
        isValidatingLicense = true
        failedToValidateLicense = false
        print("Device License: \(getDeviceUUID()!)")
        
        let data = ["licenseKey": license] as [String: String]
        AF.request("\(entryURL)\(getDeviceUUID()!)", method: .patch, parameters: data,
                   encoding: JSONEncoding.default).responseDecodable(of: User.self, completionHandler: {
            (response: DataResponse<User, AFError>) in
            switch response.result {
            case let .success(user):
                self.isLicenseRegistered = user.isLicenseKeyValid
                self.failedToValidateLicense = !(user.isLicenseKeyValid)
                self.isValidatingLicense = false
                KeychainManager.saveLicenseState(user.isLicenseKeyValid)
            case let .failure(error):
                print(error)
                self.failedToValidateLicense = true
                self.isValidatingLicense = false
                self.offlineValidation()
            }
        })
    }
    
    func fetchUser() {
        AF.request("\(entryURL)\(getDeviceUUID()!)", method: .get, encoding: JSONEncoding.default).responseDecodable(of: User.self, completionHandler: {
            (response: DataResponse<User, AFError>) in
            switch response.result {
            case let .success(user):
                self.isLicenseRegistered = user.isLicenseKeyValid
                KeychainManager.saveLicenseState(user.isLicenseKeyValid)
                self.disableOfflinePermission()
                print("Success fetching user: \(user)")
            case let .failure(error):
                print("Error fetching user: \(error)")
                self.createUser()
            }
        })
    }
    
    func disableOfflinePermission() {
        KeychainManager.saveOfflinePermission(false)
        print("Offline Permission Status: \(KeychainManager.loadOfflinePermission())")
    }
    
    func createUser() {
        let data = ["deviceUUID": getDeviceUUID()!] as [String: String]
        isLicenseRegistered = false
        
        print("Creating user with: \(data)")
        
        AF.request("\(entryURL)", method: .post, parameters: data,
                   encoding: JSONEncoding.default).responseDecodable(completionHandler: {
            (response: DataResponse<User, AFError>) in
            print("Response from creating user: \(response)")
            switch response.result {
            case let .success(user):
                print("Success creating user")
            case let .failure(error):
                print("Error creating user: \(error)")
                self.offlineValidation()
            }
        })
    }
    
    func deactivateLicense() async {
        AF.request("\(entryURL)\(getDeviceUUID()!)/deactivateLicenseKey", method: .patch, encoding: JSONEncoding.default).response(completionHandler: {
            response in
            print(response)
            switch response.result {
            case .success:
                print("License deactivated")
                KeychainManager.deleteLicenseState()
                self.fetchUser()
            case .failure:
                print("Failed to deactivate license")
            }
        })
    }
}
