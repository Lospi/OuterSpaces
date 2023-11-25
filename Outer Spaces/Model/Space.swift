//
//  Space.swift
//  Spaceman
//
//  Created by Sasindu Jayasinghe on 23/11/20.
//

import Foundation
import SwiftData

struct Space: Identifiable, Hashable, Codable {
    var id = UUID()
    var displayID: String
    var spaceID: String
    var customName: String?
}
