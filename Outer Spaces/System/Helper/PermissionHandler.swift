import Cocoa
import SwiftUI

// Enum to categorize different permission errors
enum PermissionErrorType {
    case accessibility
    case automation
    case screenRecording
    case fileAccess
    case unknown
}

// This class handles checking and requesting accessibility permissions
class PermissionHandler: ObservableObject {
    @Published var hasAccessibilityPermission = false
    @Published var showingPermissionAlert = false
    @Published var lastError: String?
    @Published var lastErrorType: PermissionErrorType = .unknown
    
    static let shared = PermissionHandler()
    
    // Dictionary mapping error patterns to error types in multiple languages
    private let errorPatterns: [String: PermissionErrorType] = [
        // English patterns
        "System Events got an error": .accessibility,
        "permission to trigger": .accessibility,
        "permission to send keystrokes": .accessibility,
        "not allowed to send keystrokes": .accessibility,
        "doesn't have permission": .accessibility,
        "cannot be opened for": .fileAccess,
        
        // Portuguese patterns
        "System Events obteve um erro": .accessibility,
        "permissão para acionar": .accessibility,
        "não tem permissão": .accessibility,
        
        // Spanish patterns
        "System Events obtuvo un error": .accessibility,
        "permiso para activar": .accessibility,
        "no tiene permiso": .accessibility,
        
        // German patterns
        "System Events hat einen Fehler erhalten": .accessibility,
        "Berechtigung zum Auslösen": .accessibility,
        "keine Berechtigung": .accessibility,
        
        // French patterns
        "System Events a rencontré une erreur": .accessibility,
        "autorisation pour déclencher": .accessibility,
        "n'a pas l'autorisation": .accessibility,
        
        // Italian patterns
        "System Events ha riscontrato un errore": .accessibility,
        "autorizzazione per attivare": .accessibility,
        "non dispone dell'autorizzazione": .accessibility,
        
        // Japanese patterns
        "System Eventsでエラーが起きました": .accessibility,
        "キーストロークを送信する権限": .accessibility,
        "権限がありません": .accessibility,
        
        // Generic patterns that could apply to multiple languages
        "System Events": .accessibility,
        "keystrokes": .accessibility,
        "permission": .accessibility,
        "permissão": .accessibility,
        "Berechtigung": .accessibility,
        "permiso": .accessibility,
        "autorizzazione": .accessibility,
        "autorisation": .accessibility,
        "権限": .accessibility,
    ]
    
    private init() {
        self.checkAccessibilityPermission()
    }
    
    // Check if the app has accessibility permission
    func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        self.hasAccessibilityPermission = accessEnabled
    }
    
    // Request accessibility permission
    func requestAccessibilityPermission() {
        // This will prompt the user to go to System Preferences
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // Open system settings to the accessibility section
    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback for older macOS versions
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security")!)
        }
    }
    
    // Detect the error type from an error message
    func detectErrorType(from errorMessage: String) -> PermissionErrorType {
        for (pattern, errorType) in self.errorPatterns {
            if errorMessage.localizedCaseInsensitiveContains(pattern) {
                return errorType
            }
        }
        return .unknown
    }
    
    // Handle AppleScript error
    func handleAppleScriptError(_ error: String) {
        let errorType = self.detectErrorType(from: error)
        
        self.lastError = error
        self.lastErrorType = errorType
        
        switch errorType {
        case .accessibility:
            self.showingPermissionAlert = true
            self.hasAccessibilityPermission = false
        case .automation, .screenRecording, .fileAccess, .unknown:
            // Handle other error types if needed
            self.showingPermissionAlert = true
        }
    }
    
    // Check if an NSAppleScript error is permission-related
    func isPermissionError(_ error: NSDictionary?) -> Bool {
        guard let errorDict = error,
              let errorDescription = errorDict["NSAppleScriptErrorMessage"] as? String
        else {
            return false
        }
        
        let errorType = self.detectErrorType(from: errorDescription)
        return errorType != .unknown
    }
}

// A view modifier to add permission handling
struct AccessibilityPermissionModifier: ViewModifier {
    @ObservedObject private var permissionHandler = PermissionHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Accessibility Permission Required", isPresented: self.$permissionHandler.showingPermissionAlert) {
                Button("Open Settings", action: self.permissionHandler.openAccessibilitySettings)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("""
                Outer Spaces needs accessibility permissions to switch spaces. 
                
                Please go to System Settings → Privacy & Security → Accessibility and enable Outer Spaces.
                
                Error: \(self.permissionHandler.lastError ?? "")
                """)
            }
    }
}

// Extension to easily add the permission handling to any view
extension View {
    func withAccessibilityPermissionHandling() -> some View {
        modifier(AccessibilityPermissionModifier())
    }
}
