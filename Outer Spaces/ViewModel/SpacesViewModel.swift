import Combine
import Foundation
import SwiftUI

@MainActor
class SpacesViewModel: ObservableObject {
    let spaceObserver: SpaceObserver
    @Published private(set) var snapshot: ManagedDisplaySpacesSnapshot?
    @Published var desktopSpaces: [DesktopSpaces] = []
    @Published var allSpaces: [Space] = []
    static let shared = SpacesViewModel()
    private let defaults: UserDefaults
    private var observation: AnyCancellable?

    init(observer: SpaceObserver? = nil, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        spaceObserver = observer ?? SpaceObserver()
        loadSpaces()
        observation = spaceObserver.$snapshot.sink { [weak self] value in
            self?.accept(value)
        }
    }

    @discardableResult
    func refreshSnapshot() throws -> ManagedDisplaySpacesSnapshot {
        _ = try spaceObserver.refresh()
        guard let snapshot else { throw SpaceSwitchError.snapshotUnavailable }
        return snapshot
    }

    func updateSystemSpaces() async -> Bool {
        do { _ = try refreshSnapshot(); return true }
        catch { Logger.shared.logError("Space refresh failed: \(error.localizedDescription)"); return false }
    }

    private func accept(_ value: ManagedDisplaySpacesSnapshot?) {
        guard var value else { snapshot = nil; return }
        // Preserve user-facing identity and names while accepting every live field.
        value.allSpaces = value.allSpaces.map { fresh in
            guard let previous = allSpaces.first(where: { $0.spaceID == fresh.spaceID }) else { return fresh }
            return Space(id: previous.id, displayID: fresh.displayID, displayIndex: fresh.displayIndex,
                         spaceID: fresh.spaceID, customName: previous.customName,
                         spaceIndex: fresh.spaceIndex, isActive: fresh.isActive)
        }
        value.desktopSpaces = value.desktopSpaces.map { display in
            DesktopSpaces(displayID: display.displayID, displayIndex: display.displayIndex,
                          spaces: value.allSpaces.filter { $0.displayID == display.displayID })
        }
        let persistedFields: (Space) -> Space = { space in
            var copy = space
            copy.isActive = false
            return copy
        }
        let layoutChanged = allSpaces.map(persistedFields) != value.allSpaces.map(persistedFields)
        allSpaces = value.allSpaces
        desktopSpaces = value.desktopSpaces
        snapshot = value
        if layoutChanged { saveSpaces() }
    }

    func loadSpaces() {
        guard let data = defaults.data(forKey: Constants.StorageKeys.availableSpaces) else { return }
        do {
            allSpaces = try JSONDecoder().decode([Space].self, from: data)
            desktopSpaces = Dictionary(grouping: allSpaces, by: \.displayID).values
                .map { DesktopSpaces(desktopSpaces: $0) }.sorted { $0.displayIndex < $1.displayIndex }
        } catch { Logger.shared.logError("Error decoding spaces: \(error)") }
    }

    func saveSpaces() {
        do { defaults.set(try JSONEncoder().encode(allSpaces), forKey: Constants.StorageKeys.availableSpaces) }
        catch { Logger.shared.logError("Error encoding spaces: \(error)") }
    }
}

// Testing and debugging utilities
extension SpacesViewModel {
    // Check for inconsistencies in space organization
    func validateSpaceOrganization() -> [String] {
        var issues: [String] = []

        // Check if there are duplicates in the display groups
        let displayIDs = desktopSpaces.map { $0.displayID }
        if Set(displayIDs).count != displayIDs.count {
            issues.append("Duplicate display IDs detected")
        }

        // Check if spaces are correctly assigned to their displays
        for display in desktopSpaces {
            for space in display.desktopSpaces {
                if space.displayID != display.displayID {
                    issues.append("Space \(space.spaceID) has displayID \(space.displayID) but is assigned to display \(display.displayID)")
                }
            }
        }

        // Check for missing displayIndex values
        for display in desktopSpaces {
            if display.displayIndex == 0 {
                issues.append("Display \(display.displayID) has an invalid displayIndex (0)")
            }

            for space in display.desktopSpaces {
                if space.displayIndex == 0 {
                    issues.append("Space \(space.spaceID) has an invalid displayIndex (0)")
                }

                if space.displayIndex != display.displayIndex {
                    issues.append("Space \(space.spaceID) has displayIndex \(space.displayIndex) but is in display with index \(display.displayIndex)")
                }
            }
        }

        return issues
    }
}
