import Foundation
import Testing
@testable import Outer_Spaces

struct ModelTests {
    @Test("Space sorts by display index, then space index")
    func spaceSortsByDisplayThenSpaceIndex() {
        let spaces = [
            Space(displayID: "secondary", displayIndex: 2, spaceID: "3", spaceIndex: 0),
            Space(displayID: "main", displayIndex: 1, spaceID: "2", spaceIndex: 1),
            Space(displayID: "main", displayIndex: 1, spaceID: "1", spaceIndex: 0),
        ]

        #expect(spaces.sorted().map(\.spaceID) == ["1", "2", "3"])
    }

    @Test("Space codable round trip excludes active state")
    func spaceCodableRoundTripExcludesActiveState() throws {
        let original = Space(
            displayID: "main",
            displayIndex: 1,
            spaceID: "10",
            customName: "Writing",
            spaceIndex: 0,
            isActive: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Space.self, from: data)

        #expect(decoded.displayID == original.displayID)
        #expect(decoded.displayIndex == original.displayIndex)
        #expect(decoded.spaceID == original.spaceID)
        #expect(decoded.customName == original.customName)
        #expect(decoded.spaceIndex == original.spaceIndex)
        #expect(decoded.isActive == false)
    }

    @Test("DesktopSpaces sorts contained spaces by space index")
    func desktopSpacesSortsContainedSpaces() {
        let spaces = [
            Space(displayID: "main", spaceID: "3", spaceIndex: 2),
            Space(displayID: "main", spaceID: "1", spaceIndex: 0),
            Space(displayID: "main", spaceID: "2", spaceIndex: 1),
        ]

        let desktopSpaces = DesktopSpaces(displayID: "main", displayIndex: 1, spaces: spaces)

        #expect(desktopSpaces.desktopSpaces.map(\.spaceID) == ["1", "2", "3"])
    }

    @Test("Focus codable round trip preserves values")
    func focusCodableRoundTripPreservesValues() throws {
        let focusID = UUID()
        let spaceID = UUID()
        let focus = Focus(
            id: focusID,
            name: "Deep Work",
            spaces: [
                Space(
                    id: spaceID,
                    displayID: "main",
                    displayIndex: 1,
                    spaceID: "42",
                    customName: "Editor",
                    spaceIndex: 0,
                    isActive: true
                )
            ],
            stageManager: true
        )

        let data = try JSONEncoder().encode(focus)
        let decoded = try JSONDecoder().decode(Focus.self, from: data)

        #expect(decoded.id == focusID)
        #expect(decoded.name == "Deep Work")
        #expect(decoded.stageManager == true)
        #expect(decoded.spaces.count == 1)
        #expect(decoded.spaces.first?.id == spaceID)
        #expect(decoded.spaces.first?.spaceID == "42")
    }
}
