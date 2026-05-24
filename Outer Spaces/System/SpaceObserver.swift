import Cocoa
import Combine
import Foundation
import SwiftUI

// Space observer with macOS private API integration
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
            let snapshot = ManagedDisplaySpacesParser.parse(displays)

            allSpaces = snapshot.allSpaces
            spaces = snapshot.desktopSpaces
            activeSpaceID = snapshot.activeSpaceID
            
            // Log for debugging
            logger.logInfo("Updated spaces: \(spaces.count) displays, \(allSpaces.count) total spaces")
            for (i, display) in spaces.enumerated() {
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
