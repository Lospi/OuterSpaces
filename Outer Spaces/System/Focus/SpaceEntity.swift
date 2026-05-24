import AppIntents
import SwiftUI

struct SpaceAppEntity: AppEntity {
    let id: UUID
    let title: String

    var displayRepresentation: DisplayRepresentation {
        .init(
            title: .init(stringLiteral: title)
        )
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: .init(stringLiteral: "Focus Preset"),
        )
    }

    static var defaultQuery = SpaceAppEntityQuery()
}

struct SpaceAppEntityQuery: EntityQuery {
    func suggestedEntities() async throws -> [SpaceAppEntity] {
        return FocusViewModel.shared.availableFocusPresets.map {
            SpaceAppEntity(id: $0.id, title: $0.name)
        }
    }

    func entities(for identifiers: [UUID]) async throws -> [SpaceAppEntity] {
        return FocusViewModel.shared.availableFocusPresets
            .filter { identifiers.contains($0.id) }
            .map { SpaceAppEntity(id: $0.id, title: $0.name) }
    }
}
