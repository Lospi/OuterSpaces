struct DesktopSpaces: Identifiable, Hashable, Codable {
    let id: UUID
    var displayID: String
    var displayIndex: Int
    var desktopSpaces: [Space]

    init(desktopSpaces: [Space]) {
        self.id = UUID()
        self.displayID = desktopSpaces.first?.displayID ?? "unknown"
        self.displayIndex = desktopSpaces.first?.displayIndex ?? 1
        self.desktopSpaces = desktopSpaces.sorted { $0.spaceIndex < $1.spaceIndex }
    }

    init(displayID: String, displayIndex: Int, spaces: [Space]) {
        self.id = UUID()
        self.displayID = displayID
        self.displayIndex = displayIndex
        self.desktopSpaces = spaces.sorted { $0.spaceIndex < $1.spaceIndex }
    }
}
