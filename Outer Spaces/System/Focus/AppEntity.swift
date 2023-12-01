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

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Space"

    static var defaultQuery = SpaceAppEntityQuery()
}

struct SpaceAppEntityQuery: EntityQuery {
    static let entities: [SpaceAppEntity] = FocusManager.loadFocusModels().map {
        SpaceAppEntity(id: $0.id, title: $0.name)
    }

    func suggestedEntities() async throws -> [SpaceAppEntity] {
        return SpaceAppEntityQuery.entities
    }

    func entities(for identifiers: [UUID]) async throws -> [SpaceAppEntity] {
        return SpaceAppEntityQuery.entities
    }
}
