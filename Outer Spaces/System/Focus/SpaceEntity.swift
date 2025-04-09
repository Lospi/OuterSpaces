import AppIntents
import Combine
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
    static var entities: [SpaceAppEntity] = FocusViewModel.shared.availableFocusPresets.map {
        SpaceAppEntity(id: $0.id, title: $0.name)
    }

    func suggestedEntities() async throws -> [SpaceAppEntity] {
        return SpaceAppEntityQuery.entities
    }

    func entities(for identifiers: [UUID]) async throws -> [SpaceAppEntity] {
        return SpaceAppEntityQuery.entities
    }
}
