//
//  Repository.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 27/11/23.
//

import Foundation

struct Repository {
    static let suiteUserDefaults: UserDefaults = UserDefaults(suiteName: Constants.StorageKeys.suiteName) ?? .standard
}
