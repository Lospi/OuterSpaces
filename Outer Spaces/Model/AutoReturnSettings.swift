import Foundation

struct AutoReturnSettings: Codable, Hashable {
    var enabled: Bool
    var delayMinutes: Int {
        didSet { delayMinutes = min(60, max(1, delayMinutes)) }
    }

    init(enabled: Bool = false, delayMinutes: Int = 5) {
        self.enabled = enabled
        self.delayMinutes = min(60, max(1, delayMinutes))
    }

    private enum CodingKeys: String, CodingKey { case enabled, delayMinutes }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(enabled: try values.decodeIfPresent(Bool.self, forKey: .enabled) ?? false,
                  delayMinutes: try values.decodeIfPresent(Int.self, forKey: .delayMinutes) ?? 5)
    }
}
