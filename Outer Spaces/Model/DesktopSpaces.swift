struct DesktopSpaces: Identifiable, Hashable, Codable {
    var id = UUID()
    var displayID: String // Store the display ID for clarity
    var displayIndex: Int // 1-based index for UI presentation
    var desktopSpaces: [Space] // Spaces for this display
    
    // Original initializer for backward compatibility
    init(desktopSpaces: [Space]) {
        // Determine display ID from the first space in the list
        self.displayID = desktopSpaces.first?.displayID ?? "unknown"
        // Use display index from first space or default to 1
        self.displayIndex = desktopSpaces.first?.displayIndex ?? 1
        // Sort spaces by their index
        self.desktopSpaces = desktopSpaces.sorted { $0.spaceIndex < $1.spaceIndex }
    }
    
    // New detailed initializer
    init(displayID: String, displayIndex: Int, spaces: [Space]) {
        self.displayID = displayID
        self.displayIndex = displayIndex
        self.desktopSpaces = spaces.sorted { $0.spaceIndex < $1.spaceIndex }
    }
}
