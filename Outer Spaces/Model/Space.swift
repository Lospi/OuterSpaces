import Foundation
import SwiftData

struct Space: Identifiable, Hashable, Codable, Comparable {
    static func < (lhs: Space, rhs: Space) -> Bool {
        return lhs.spaceID != rhs.spaceID
    }

    var id = UUID()
    var displayID: String
    var spaceID: String
    var customName: String?
    var spaceIndex: Int
}
