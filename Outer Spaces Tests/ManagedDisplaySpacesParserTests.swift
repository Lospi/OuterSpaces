import Foundation
import Testing
@testable import Outer_Spaces

struct ManagedDisplaySpacesParserTests {
    @Test("Parser creates spaces for one display and marks active space")
    func parsesOneDisplayAndMarksActiveSpace() throws {
        let snapshot = ManagedDisplaySpacesParser.parse([
            display(
                id: "main",
                activeSpaceID: 102,
                spaces: [
                    regularSpace(id: 101),
                    regularSpace(id: 102),
                ]
            ),
        ])

        #expect(snapshot.activeSpaceID == "102")
        #expect(snapshot.desktopSpaces.count == 1)
        #expect(snapshot.allSpaces.map(\.spaceID) == ["101", "102"])
        #expect(snapshot.allSpaces.map(\.spaceIndex) == [0, 1])
        #expect(snapshot.allSpaces.first(where: { $0.spaceID == "102" })?.isActive == true)
    }

    @Test("Parser skips fullscreen spaces and keeps regular indexes compact")
    func skipsFullscreenSpacesAndKeepsIndexesCompact() {
        let snapshot = ManagedDisplaySpacesParser.parse([
            display(
                id: "main",
                activeSpaceID: 103,
                spaces: [
                    regularSpace(id: 101),
                    fullscreenSpace(id: 102),
                    regularSpace(id: 103),
                ]
            ),
        ])

        #expect(snapshot.allSpaces.map(\.spaceID) == ["101", "103"])
        #expect(snapshot.allSpaces.map(\.spaceIndex) == [0, 1])
    }

    @Test("Parser uses one-based display indexes for multiple displays")
    func parsesMultipleDisplaysWithOneBasedIndexes() {
        let snapshot = ManagedDisplaySpacesParser.parse([
            display(id: "main", activeSpaceID: 101, spaces: [regularSpace(id: 101)]),
            display(id: "secondary", activeSpaceID: 201, spaces: [regularSpace(id: 201)]),
        ])

        #expect(snapshot.desktopSpaces.map(\.displayID) == ["main", "secondary"])
        #expect(snapshot.desktopSpaces.map(\.displayIndex) == [1, 2])
        #expect(snapshot.allSpaces.map(\.displayIndex) == [1, 2])
    }

    @Test("Parser ignores malformed display entries")
    func ignoresMalformedDisplayEntries() {
        let malformed = NSDictionary(dictionary: [
            "Display Identifier": "broken",
            "Spaces": [regularSpace(id: 1)],
        ])

        let snapshot = ManagedDisplaySpacesParser.parse([
            display(id: "main", activeSpaceID: 101, spaces: [regularSpace(id: 101)]),
            malformed,
        ])

        #expect(snapshot.desktopSpaces.count == 1)
        #expect(snapshot.desktopSpaces.first?.displayID == "main")
        #expect(snapshot.allSpaces.map(\.spaceID) == ["101"])
    }

    private func display(id: String, activeSpaceID: Int, spaces: [[String: Any]]) -> NSDictionary {
        NSDictionary(dictionary: [
            "Display Identifier": id,
            "Current Space": ["ManagedSpaceID": activeSpaceID],
            "Spaces": spaces,
        ])
    }

    private func regularSpace(id: Int) -> [String: Any] {
        [
            "ManagedSpaceID": id,
            "type": 0,
        ]
    }

    private func fullscreenSpace(id: Int) -> [String: Any] {
        [
            "ManagedSpaceID": id,
            "type": 4,
        ]
    }
}
