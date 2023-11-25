//
//  DesktopSpaces.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 17/11/23.
//

import Foundation

struct DesktopSpaces: Identifiable, Hashable, Codable {
    var id = UUID()
    var desktopSpaces: [Space]
}
