import Testing
@testable import Outer_Spaces

struct SpaceSwitchCommandTests {
    @Test("Space index zero maps to Control+1")
    func zeroMapsToControlOne() throws {
        let command = try SpaceSwitchCommandFactory.command(forSpaceIndex: 0)

        #expect(command.keyCode == 18)
        #expect(command.usesOptionKey == false)
        #expect(command.appleScriptSource.contains("key code 18 using {control down}"))
    }

    @Test("Space index eight maps to Control+9")
    func eightMapsToControlNine() throws {
        let command = try SpaceSwitchCommandFactory.command(forSpaceIndex: 8)

        #expect(command.keyCode == 25)
        #expect(command.usesOptionKey == false)
        #expect(command.appleScriptSource.contains("key code 25 using {control down}"))
    }

    @Test("Space indexes at nine and above use Option-modified shortcuts")
    func indexesAtNineAndAboveUseOptionModifiedShortcuts() throws {
        let command = try SpaceSwitchCommandFactory.command(forSpaceIndex: 9)

        #expect(command.keyCode == 29)
        #expect(command.usesOptionKey == true)
        #expect(command.appleScriptSource.contains("key code 29 using {control down, option down}"))
    }

    @Test("Negative space indexes throw invalid index error")
    func negativeIndexesThrowInvalidIndexError() {
        do {
            _ = try SpaceSwitchCommandFactory.command(forSpaceIndex: -2)
            Issue.record("Expected a negative index to throw SpaceSwitchError.invalidSpaceIndex.")
        } catch SpaceSwitchError.invalidSpaceIndex {
            // Expected path.
        } catch {
            Issue.record("Unexpected error thrown: \(error)")
        }
    }
}
