//
//  User.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 28/02/24.
//

import Foundation

struct User: Codable {
    let deviceUUID: String
    let licenseKey: String?
    let isLicenseKeyValid: Bool
}
