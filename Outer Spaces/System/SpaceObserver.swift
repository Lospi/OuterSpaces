import Cocoa
import Foundation
import SwiftUI

class SpaceObserver: ObservableObject {
    private let workspace = NSWorkspace.shared
    private let conn = _CGSDefaultConnection()
    weak var delegate: SpaceObserverDelegate?
    @Published var spaces: [DesktopSpaces] = []
    @Published var allSpaces: [Space] = []
    
    init() {
        workspace.notificationCenter.addObserver(
            self,
            selector: #selector(updateSpaceInformation),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: workspace)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateSpaceInformation),
            name: NSNotification.Name("ButtonPressed"),
            object: nil)
    }
    
    public func setSpace(indexDesktop: Int, index: Int) {}
    
    @MainActor @objc public func updateSpaceInformation() {
        let displays = CGSCopyManagedDisplaySpaces(conn) as! [NSDictionary]
        var activeSpaceID = -1
        var spacesIndex = 0
        var allSpaces = [Space]()
        
        for d in displays {
            guard let currentSpaces = d["Current Space"] as? [String: Any],
                  let spaces = d["Spaces"] as? [[String: Any]],
                  let displayID = d["Display Identifier"] as? String
            else {
                continue
            }
            
            activeSpaceID = currentSpaces["ManagedSpaceID"] as! Int
            
            if activeSpaceID == -1 {
                DispatchQueue.main.async {
                    print("Can't find current space")
                }
                return
            }

            for s in spaces {
                if s["type"] as! Int != 0 {
                    continue
                }
                    
                let spaceID = String(s["ManagedSpaceID"] as! Int)
                let space = Space(displayID: displayID,
                                  spaceID: spaceID, spaceIndex: spacesIndex)
                
                allSpaces.append(space)
                spacesIndex += 1
            }
        }
        var desktopIds: [String] = []
        
        self.allSpaces = allSpaces
        
        allSpaces.forEach {
            if !desktopIds.contains($0.displayID) {
                desktopIds.append($0.displayID)
            }
        }
        
        spaces = []
        desktopIds.forEach { desktopId in
            let desktopSpaces = allSpaces.filter { $0.displayID == desktopId }
            spaces.append(DesktopSpaces(desktopSpaces: desktopSpaces))
        }
        
        delegate?.didUpdateSpaces(spaces: allSpaces)
    }
}

protocol SpaceObserverDelegate: AnyObject {
    func didUpdateSpaces(spaces: [Space])
}
