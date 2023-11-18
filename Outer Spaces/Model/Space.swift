//
//  Space.swift
//  Spaceman
//
//  Created by Sasindu Jayasinghe on 23/11/20.
//

import Foundation

struct Space: Identifiable, Hashable {
    var id = UUID()
    var displayID: String
    var spaceID: String
    var spaceName: String
    var spaceNumber: Int
    var desktopNumber: Int?
    var isCurrentSpace: Bool
    var isFullScreen: Bool
}
