//
//  Repository.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 27/11/23.
//

import Foundation

struct Repository {
    static var suiteUserDefaults: UserDefaults = UserDefaults(suiteName: "dev.Lospi.OuterSpaces") ?? .standard
}
