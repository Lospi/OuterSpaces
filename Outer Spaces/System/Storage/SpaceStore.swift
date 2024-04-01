//
//  SpaceStore.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 20/11/23.
//

import Foundation

@MainActor class SpaceStore: ObservableObject {
    @Published var spaces: [DesktopSpaces] = []

    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
            .appendingPathComponent("spaces.data")
    }

    func load() async throws {
        let space = Task<[DesktopSpaces], Error> {
            let fileURL = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return []
            }
            let dailyScrums = try JSONDecoder().decode([DesktopSpaces].self, from: data)
            return dailyScrums
        }
        let spaces = try await space.value
        self.spaces = spaces
    }

    func save(spaces: [DesktopSpaces]) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(spaces)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
}
