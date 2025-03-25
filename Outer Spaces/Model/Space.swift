struct Space: Identifiable, Hashable, Codable, Comparable {
    static func < (lhs: Space, rhs: Space) -> Bool {
        // First compare by displayID
        if lhs.displayID != rhs.displayID {
            return lhs.displayID < rhs.displayID
        }
        // Then by spaceIndex if on same display
        return lhs.spaceIndex < rhs.spaceIndex
    }

    var id = UUID()
    var displayID: String // Unique identifier for the display
    var displayIndex: Int = 1 // Display index (1-based) for UI clarity
    var spaceID: String // Unique identifier for the space
    var customName: String? // User-provided name
    var spaceIndex: Int // Index within the display (0-based)
    var isActive: Bool = false // Whether this space is currently active
    
    // Original initializer
    init(id: UUID = UUID(), displayID: String, spaceID: String, customName: String? = nil, spaceIndex: Int) {
        self.id = id
        self.displayID = displayID
        self.spaceID = spaceID
        self.customName = customName
        self.spaceIndex = spaceIndex
        // Default values
        self.displayIndex = 1
        self.isActive = false
    }
    
    // Extended initializer with all properties
    init(id: UUID = UUID(), displayID: String, displayIndex: Int = 1, spaceID: String, customName: String? = nil, spaceIndex: Int, isActive: Bool = false) {
        self.id = id
        self.displayID = displayID
        self.displayIndex = displayIndex
        self.spaceID = spaceID
        self.customName = customName
        self.spaceIndex = spaceIndex
        self.isActive = isActive
    }
    
    // Debug description
    var debugDescription: String {
        return "Space(display: \(displayID) [\(displayIndex)], spaceID: \(spaceID), index: \(spaceIndex), name: \(customName ?? "nil"), active: \(isActive))"
    }
}
