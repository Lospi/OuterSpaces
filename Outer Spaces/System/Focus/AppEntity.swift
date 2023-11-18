import AppIntents

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
    init() {}

    func suggestedEntities() async throws -> [SpaceAppEntity] {
        [] // Implement this
    }

    func entities(for identifiers: [UUID]) async throws -> [SpaceAppEntity] {
        return []
    }
}
