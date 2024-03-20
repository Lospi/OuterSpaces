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
    var gameTimer: Timer?
    let entryURL = "https://8ixo388z6c.execute-api.us-east-1.amazonaws.com/Prod/users/"
    
    @Published var isLicenseRegistered: Bool = false
    @Published var isOnTrial: Bool = false
    @Published var trialStartDate: Date?
    @Published var trialSpent = false
    @Published var isValidatingLicense: Bool = false
    @Published var failedToValidateLicense: Bool = false
    
    init() {
        fetchInitialValidation()
    }
    
    func resetTrial() {
        Repository.shared.updateTrialState(state: false)
        Repository.shared.updateTrialEnd(false)
        isOnTrial = false
        trialStartDate = nil
        trialSpent = false
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
        checkFreeTrialInitialValidation()
        Timer.scheduledTimer(withTimeInterval: 14400, repeats: true) { _ in
            self.fetchUser()
        }
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.revalidateFreeTrial()
        }
    }
    
    func offlineValidation() {
        print("Offline Validation started")
        print("License State: \(Repository.shared.fetchLicenseState())")
        print("Offline Permission Status: \(Repository.shared.fetchOfflinePermissionStatus())")
        print("Offline Date: \(Repository.shared.fetchOfflineDate())")
        if !Repository.shared.fetchOfflinePermissionStatus(), Repository.shared.fetchLicenseState() == true {
            Repository.shared.updateOfflinePermissionStatus(status: true)
            Repository.shared.updateOfflineDate(Date.now)
            print("Validation OK")
            isLicenseRegistered = true
        }
        else if Repository.shared.fetchOfflinePermissionStatus(), Repository.shared.fetchLicenseState() {
            if Date.now.timeIntervalSince(Repository.shared.fetchOfflineDate()!) > 10080 {
                print("Past offline permission")
                Repository.shared.updateLicenseState(state: false)
                disableOfflinePermission()
            }
            else {
                print("Validation OK, but past")
                isLicenseRegistered = true
            }
        }
        else {
            print("Validation failed")
            isLicenseRegistered = false
        }
    }
    
    func isFreeTrialUsed() -> Bool {
        return Repository.shared.fetchTrialState()
    }
    
    func isFreeTrialExpired() -> Bool {
        if !Repository.shared.fetchTrialEndState() {
            if let trialStartDate = Repository.shared.fetchTrialDate() {
                trialSpent = Date.now.timeIntervalSince(trialStartDate) > 604800
                return Date.now.timeIntervalSince(trialStartDate) > 604800
            }
            return false
        }
        else {
            return true
        }
    }
    
    func revalidateFreeTrial() {
        if isFreeTrialExpired() {
            isOnTrial = false
            trialSpent = true
            Repository.shared.updateTrialEnd(true)
        }
    }
    
    func checkFreeTrialInitialValidation() {
        print("Is Free Trial Used: \(isFreeTrialUsed())")
        print("Is Free Trial Expired: \(isFreeTrialExpired())")
        if isFreeTrialUsed(), !isFreeTrialExpired() {
            trialStartDate = Repository.shared.fetchTrialDate()
            isOnTrial = true
        }
        else {
            if isFreeTrialExpired() {
                isOnTrial = false
                trialSpent = true
                Repository.shared.updateTrialEnd(true)
            }
        }
    }
    
    func checkFreeTrialEndedState() -> Bool {
        return Repository.shared.fetchTrialEndState()
    }
    
    func startFreeTrialIfAvailable() {
        print("Starting Free Trial")
        print("Is Free Trial Used: \(isFreeTrialUsed())")
        print("Is Free Trial Expired: \(isFreeTrialExpired())")
        print("Is Free Trial Ended: \(checkFreeTrialEndedState())")
        if !isFreeTrialUsed(), !checkFreeTrialEndedState(), !isFreeTrialExpired() {
            Repository.shared.updateTrialState(state: true)
            Repository.shared.updateTrialDate(Date.now)
            isOnTrial = true
            trialStartDate = Repository.shared.fetchTrialDate()
        }
    }
    
    func forceTrialEnd() {
        isOnTrial = false
        trialSpent = true
        Repository.shared.updateTrialEnd(true)
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
                Repository.shared.updateOfflinePermissionStatus(status: true)
                self.failedToValidateLicense = !(user.isLicenseKeyValid)
                self.isValidatingLicense = false
                Repository.shared.updateLicenseState(state: user.isLicenseKeyValid)
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
                Repository.shared.updateLicenseState(state: user.isLicenseKeyValid)
                self.disableOfflinePermission()
                print("Success fetching user: \(user)")
            case let .failure(error):
                print("Error fetching user: \(error)")
                self.createUser()
            }
        })
    }
    
    func disableOfflinePermission() {
        Repository.shared.updateOfflinePermissionStatus(status: false)
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
            case .success:
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
                Repository.shared.updateLicenseState(state: false)
                self.fetchUser()
            case .failure:
                print("Failed to deactivate license")
            }
        })
    }
}
