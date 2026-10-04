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
    var autoReturn: AutoReturnSettings

    init(id: UUID = UUID(), name: String, spaces: [Space], stageManager: Bool, autoReturn: AutoReturnSettings = .init()) {
        self.id = id
        self.name = name
        self.spaces = spaces
        self.stageManager = stageManager
        self.autoReturn = autoReturn
    }

    private enum CodingKeys: String, CodingKey { case id, name, spaces, stageManager, autoReturn }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        spaces = try values.decode([Space].self, forKey: .spaces)
        stageManager = try values.decode(Bool.self, forKey: .stageManager)
        autoReturn = try values.decodeIfPresent(AutoReturnSettings.self, forKey: .autoReturn) ?? .init()
    }
}
