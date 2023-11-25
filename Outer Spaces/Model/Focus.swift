//
//  Focus.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 23/11/23.
//

import Foundation
import SwiftUI

struct Focus: Hashable, Codable, Identifiable {
    var id = UUID()
    var name: String
    var spaces: [Space]
}
