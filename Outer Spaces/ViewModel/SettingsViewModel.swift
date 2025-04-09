import Foundation

// Result enum to better represent space switching outcomes
enum SpaceSwitchResult {
    case success
    case failure(Error)
    
    enum SpaceSwitchError: Error, LocalizedError {
        case scriptCreationFailed
        case executionFailed(String)
        case permissionDenied(String)
        
        var errorDescription: String? {
            switch self {
            case .scriptCreationFailed:
                return "Failed to create AppleScript"
            case .executionFailed(let message):
                return "Script execution failed: \(message)"
            case .permissionDenied(let message):
                return "Permission denied: \(message)"
            }
        }
    }
}

// Changed from struct to class to avoid mutability issues
class SettingsViewModel {
    var selectedFocusPresetId: UUID?
    var errorMessage: String?
    
    static let shared = SettingsViewModel()
    
    // Dependency on PermissionHandler for consistent handling
    private let permissionHandler = PermissionHandler.shared
    
    // Modern async implementation - removed 'mutating' keyword
    func updateSpacesOnScreen(focus: Focus) async throws -> Bool {
        var didError = false
        print("Updating spaces on screen for focus: \(focus.name)")
        
        // Process spaces sequentially to avoid race conditions
        for space in focus.spaces {
            let result = await switchToSpace(space: space, stageManager: focus.stageManager)
            
            switch result {
            case .success:
                // Space switched successfully
                continue
            case .failure(let error):
                // Handle different error types
                if let switchError = error as? SpaceSwitchResult.SpaceSwitchError {
                    switch switchError {
                    case .permissionDenied(let message):
                        // Permission-related error
                        errorMessage = message
                        permissionHandler.handleAppleScriptError(message)
                        didError = true
                        
                    case .executionFailed(let message):
                        // Other execution error
                        errorMessage = message
                        didError = true
                        
                    case .scriptCreationFailed:
                        // Script creation failed
                        errorMessage = "Failed to create AppleScript"
                        didError = true
                    }
                } else {
                    // Unknown error
                    errorMessage = error.localizedDescription
                    didError = true
                }
                
                // If we've already encountered an error, stop processing more spaces
                if didError {
                    break
                }
            }
        }
        
        return didError
    }
    
    // Synchronous version for backward compatibility - removed 'mutating' keyword
    func updateSpacesOnScreen(focus: Focus) -> Bool {
        var didError = false
        
        for space in focus.spaces {
            print(space.spaceIndex)
            let scriptSource = AppleScriptHelper.getCompleteAppleScriptPerIndex(
                index: space.spaceIndex * space.displayIndex,
                stageManager: focus.stageManager,
                shouldAffectStage: true
            )
            
            var error: NSDictionary?
            
            // Safely create the script
            guard let script = NSAppleScript(source: scriptSource) else {
                errorMessage = "Failed to create AppleScript"
                didError = true
                continue
            }
            
            // Execute script with proper error handling
            _ = script.executeAndReturnError(&error)
            
            if error == nil {
                // Success case
                print("Script executed successfully for space \(space.spaceIndex * space.displayIndex).")
            } else {
                // Error case
                if let errorDescription = error?["NSAppleScriptErrorMessage"] as? String {
                    print("Script failed: \(errorDescription)")
                    errorMessage = errorDescription
                    
                    // Check for common permission errors across languages
                    let permissionError = errorDescription.contains("System Events") ||
                        errorDescription.contains("permission") ||
                        errorDescription.contains("permissão") ||
                        errorDescription.contains("Berechtigung") ||
                        errorDescription.contains("permiso")
                    
                    if permissionError {
                        didError = true
                        permissionHandler.handleAppleScriptError(errorDescription)
                        break // Stop on permission errors
                    }
                }
            }
        }
        
        return didError
    }
    
    // Helper method to switch to a specific space
    private func switchToSpace(space: Space, stageManager: Bool) async -> SpaceSwitchResult {
        let scriptSource = AppleScriptHelper.getCompleteAppleScriptPerIndex(
            index: space.spaceIndex,
            stageManager: stageManager,
            shouldAffectStage: true
        )
        
        var error: NSDictionary?
        
        // Safely create the script
        guard let script = NSAppleScript(source: scriptSource) else {
            return .failure(SpaceSwitchResult.SpaceSwitchError.scriptCreationFailed)
        }
        
        // Execute script with proper error handling
        _ = script.executeAndReturnError(&error)
        
        if error == nil {
            // Success case
            return .success
        } else {
            // Error case
            if let errorDescription = error?["NSAppleScriptErrorMessage"] as? String {
                // Use the permission handler to detect error types
                if permissionHandler.isPermissionError(error) {
                    return .failure(SpaceSwitchResult.SpaceSwitchError.permissionDenied(errorDescription))
                } else {
                    return .failure(SpaceSwitchResult.SpaceSwitchError.executionFailed(errorDescription))
                }
            } else {
                return .failure(SpaceSwitchResult.SpaceSwitchError.executionFailed("Unknown error"))
            }
        }
    }
}
