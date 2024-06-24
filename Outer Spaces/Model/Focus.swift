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
    var stageManager: Bool
}

class FocusManager {
    static let shared = FocusManager()

    // Load Focus models from UserDefaults
    static func loadFocusModels() -> [Focus] {
        let defaults = UserDefaults.standard

        if let savedData = defaults.data(forKey: "SavedFocusModels") {
            let decoder = JSONDecoder()

            do {
                let loadedFocusModels = try decoder.decode([Focus].self, from: savedData)
                return loadedFocusModels
            } catch {
                print("Error decoding Focus models: \(error)")
            }
        }

        return []
    }

    // Save Focus models to UserDefaults
    static func saveFocusModels(_ focusModels: [Focus]) {
        let encoder = JSONEncoder()

        do {
            let encodedData = try encoder.encode(focusModels)
            let defaults = UserDefaults.standard
            defaults.set(encodedData, forKey: "SavedFocusModels")
        } catch {
            print("Error encoding Focus models: \(error)")
        }

        SpaceAppEntityQuery.entities = loadFocusModels().map {
            SpaceAppEntity(id: $0.id, title: $0.name)
        }
    }
}
