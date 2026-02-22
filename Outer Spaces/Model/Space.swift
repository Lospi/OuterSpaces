struct Space: Identifiable, Hashable, Codable, Comparable {
    static func < (lhs: Space, rhs: Space) -> Bool {
        if lhs.displayIndex != rhs.displayIndex {
            return lhs.displayIndex < rhs.displayIndex
        }
        return lhs.spaceIndex < rhs.spaceIndex
    }

    let id: UUID
    var displayID: String
    var displayIndex: Int
    var spaceID: String
    var customName: String?
    var spaceIndex: Int
    var isActive: Bool = false

    // Exclude isActive from Codable persistence
    enum CodingKeys: String, CodingKey {
        case id, displayID, displayIndex, spaceID, customName, spaceIndex
    }

    init(id: UUID = UUID(), displayID: String, displayIndex: Int = 1, spaceID: String, customName: String? = nil, spaceIndex: Int, isActive: Bool = false) {
        self.id = id
        self.displayID = displayID
        self.displayIndex = displayIndex
        self.spaceID = spaceID
        self.customName = customName
        self.spaceIndex = spaceIndex
        self.isActive = isActive
    }

    var debugDescription: String {
        return "Space(display: \(displayID) [\(displayIndex)], spaceID: \(spaceID), index: \(spaceIndex), name: \(customName ?? "nil"), active: \(isActive))"
    }
}
