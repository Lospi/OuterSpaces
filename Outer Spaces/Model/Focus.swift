//
//  Focus.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 23/11/23.
//

import Foundation
import SwiftUI

struct Focus: Hashable, Codable, Identifiable {
    let id: UUID
    var name: String
    var spaces: [Space]
    var stageManager: Bool

    init(id: UUID = UUID(), name: String, spaces: [Space], stageManager: Bool) {
        self.id = id
        self.name = name
        self.spaces = spaces
        self.stageManager = stageManager
    }
}
