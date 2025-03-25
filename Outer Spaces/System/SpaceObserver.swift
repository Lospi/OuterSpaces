import Cocoa
import Combine
import Foundation
import SwiftUI

// Protocol for space observation updates
protocol SpaceObserverDelegate: AnyObject {
    func didUpdateSpaces(spaces: [Space])
}

// A more robust space observer with better error handling and optimization
// Note: This uses Swift concurrency, so the app's deployment target should be iOS 15+ or macOS 12+
class SpaceObserver: ObservableObject {
    private let workspace = NSWorkspace.shared
    private let conn = _CGSDefaultConnection()
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger.shared
    
    @Published var spaces: [DesktopSpaces] = []
    @Published var allSpaces: [Space] = []
    @Published var activeSpaceID: String?
    @Published var isRefreshing: Bool = false
    
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.updateSpaceInformation()
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func updateSpaceInformation() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            let displays = try fetchDisplaySpaces()
            
            // Process the displays
            var allSpacesList: [Space] = []
            var desktopSpacesList: [DesktopSpaces] = []
            
            // Process each display and its spaces
            for (displayIndex, display) in displays.enumerated() {
                guard let currentSpaces = display["Current Space"] as? [String: Any],
                      let spaces = display["Spaces"] as? [[String: Any]],
                      let displayID = display["Display Identifier"] as? String
                else {
                    continue
                }
                
                // Get the active space for this display
                guard let activeSpaceID = currentSpaces["ManagedSpaceID"] as? Int else {
                    continue
                }
                
                // If this is the main display, save the active space ID
                if displayIndex == 0 {
                    self.activeSpaceID = String(activeSpaceID)
                }
                
                // Process all spaces for this display
                var spacesForDisplay: [Space] = []
                
                for (spaceIndex, spaceInfo) in spaces.enumerated() {
                    // Skip spaces that aren't regular desktop spaces (like fullscreen apps)
                    guard let type = spaceInfo["type"] as? Int, type == 0,
                          let spaceID = spaceInfo["ManagedSpaceID"] as? Int
                    else {
                        continue
                    }
                    
                    // Create the space object with display-specific indexing
                    let space = Space(
                        displayID: displayID,
                        displayIndex: displayIndex + 1, // 1-based for UI
                        spaceID: String(spaceID),
                        spaceIndex: spaceIndex,
                        isActive: spaceID == activeSpaceID
                    )
                    
                    spacesForDisplay.append(space)
                    allSpacesList.append(space)
                }
                
                // Create the desktop spaces container for this display
                let desktopSpace = DesktopSpaces(
                    displayID: displayID,
                    displayIndex: displayIndex + 1, // 1-based for UI
                    spaces: spacesForDisplay
                )
                
                desktopSpacesList.append(desktopSpace)
            }
            
            // Update the published properties
            allSpaces = allSpacesList
            spaces = desktopSpacesList
            
            // Log for debugging
            logger.logInfo("Updated spaces: \(desktopSpacesList.count) displays, \(allSpacesList.count) total spaces")
            for (i, display) in desktopSpacesList.enumerated() {
                logger.logInfo("Display \(i + 1) (\(display.displayID)): \(display.desktopSpaces.count) spaces")
                for space in display.desktopSpaces {
                    logger.logInfo("  - \(space.debugDescription)")
                }
            }
            
        } catch {
            logger.logError("Failed to update space information: \(error.localizedDescription)")
        }
    }
    
    private func fetchDisplaySpaces() throws -> [NSDictionary] {
        guard let displays = CGSCopyManagedDisplaySpaces(conn) as? [NSDictionary] else {
            throw NSError(domain: "com.outerSpaces.error", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to get display spaces information"
            ])
        }
        return displays
    }
}

// Helper method to load spaces from Core Data with proper display grouping
func loadSpacesFromCoreData(spaceModel: FetchedResults<SpaceData>) -> (spaces: [Space], desktops: [DesktopSpaces]) {
    // Step 1: Convert Core Data objects to Space objects
    let spaces = spaceModel.map { space -> Space in
        let displayID = space.displayId ?? "unknown"
        return Space(
            id: space.id ?? UUID(),
            displayID: displayID,
            spaceID: space.spaceId ?? "unknown",
            customName: space.customName,
            spaceIndex: Int(space.spaceIndex)
        )
    }
    
    // Step 2: Group spaces by display ID
    let groupedSpaces = Dictionary(grouping: spaces) { $0.displayID }
    
    // Step 3: Create DesktopSpaces objects for each display
    var desktopSpaces: [DesktopSpaces] = []
    
    // Group and sort by display ID
    for (displayIndex, (displayID, spacesForDisplay)) in groupedSpaces.sorted(by: { $0.key < $1.key }).enumerated() {
        // Add displayIndex to each space
        let spacesWithDisplayIndex = spacesForDisplay.map { space -> Space in
            var updatedSpace = space
            updatedSpace.displayIndex = displayIndex + 1
            return updatedSpace
        }
        
        // Create DesktopSpaces with proper display information
        let desktop = DesktopSpaces(
            displayID: displayID,
            displayIndex: displayIndex + 1,
            spaces: spacesWithDisplayIndex.sorted { $0.spaceIndex < $1.spaceIndex }
        )
        
        desktopSpaces.append(desktop)
    }
    
    return (spaces: spaces, desktops: desktopSpaces)
}

// Function to save spaces to Core Data with correct display organization
func saveSpacesToCoreData(spaces: [DesktopSpaces], context: NSManagedObjectContext) {
    // Clear existing data
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SpaceData")
    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    
    do {
        try context.execute(batchDeleteRequest)
        
        // Save new spaces
        for displaySpaces in spaces {
            for space in displaySpaces.desktopSpaces {
                let spaceData = SpaceData(context: context)
                spaceData.id = space.id
                spaceData.displayId = space.displayID
                spaceData.spaceId = space.spaceID
                spaceData.customName = space.customName
                spaceData.spaceIndex = Int16(space.spaceIndex)
                // Add additional metadata for debugging
                spaceData.displayIndex = Int16(space.displayIndex)
            }
        }
        
        try context.save()
    } catch {
        print("Error saving spaces to Core Data: \(error)")
    }
}

// Simple logging utility
class Logger {
    static let shared = Logger()
    
    private init() {}
    
    func logInfo(_ message: String) {
        log(level: "INFO", message: message)
    }
    
    func logError(_ message: String) {
        log(level: "ERROR", message: message)
    }
    
    func logWarning(_ message: String) {
        log(level: "WARNING", message: message)
    }
    
    private func log(level: String, message: String) {
        #if DEBUG
        print("[\(level)] \(Date()): \(message)")
        #endif
        
        // Could also write to file or send to crash reporting service
    }
}
