import CoreData
import Foundation

struct PersistenceController {
    // A singleton for our entire app to use
    static let shared = PersistenceController()

    // Storage for Core Data
    let container: NSPersistentContainer

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Show some error here
            }
        }
    }

    func loadFocusData(completion: @escaping ([FocusData]?) -> Void) {
        // Access the managed object context from the app delegate or another appropriate location
        let context = container.viewContext

        // Create a fetch request for your Core Data entity
        let fetchRequest: NSFetchRequest<FocusData> = FocusData.fetchRequest()

        do {
            // Perform the fetch request asynchronously
            let entities = try context.fetch(fetchRequest)
            completion(entities)
        } catch {
            print("Error fetching data: \(error)")
            completion(nil)
        }
    }

    func loadSpaceData(completion: @escaping ([SpaceData]?) -> Void) {
        // Access the managed object context from the app delegate or another appropriate location
        let context = container.viewContext

        // Create a fetch request for your Core Data entity
        let fetchRequest: NSFetchRequest<SpaceData> = SpaceData.fetchRequest()

        do {
            // Perform the fetch request asynchronously
            let entities = try context.fetch(fetchRequest)
            completion(entities)
        } catch {
            print("Error fetching data: \(error)")
            completion(nil)
        }
    }

    func initialLoadData() -> [SpaceAppEntity] {
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }

        var loadedSpaces: [SpaceData] = []
        loadSpaceData { loadedEntities in
            DispatchQueue.main.async {
                // Update the UI with the loaded data
                loadedSpaces = loadedEntities!
            }
        }

        let spaceData = loadedSpaces.map { space in
            Space(id: space.id!, displayID: space.displayId!, spaceID: space.spaceId!, customName: space.customName, spaceIndex: Int(space.spaceIndex))
        }

        var loadedFocus: [FocusData] = []

        loadFocusData { loadedEntities in
            DispatchQueue.main.async {
                // Update the UI with the loaded data
                loadedFocus = loadedEntities!
            }
        }

        let focusData = loadedFocus.map { focus in
            Focus(id: focus.id!, name: focus.name!, spaces: focus.spacesIds!.map { spaceId in
                spaceData.first(where: { $0.spaceID == spaceId })!
            })
        }

        let initialEntities = focusData.map { focus in
            SpaceAppEntity(id: focus.id, title: focus.name)
        }

        return initialEntities
    }

    // An initializer to load Core Data, optionally able
    // to use an in-memory store.
    init(inMemory: Bool = false) {
        // If you didn't name your model Main you'll need
        // to change this name below.
        container = NSPersistentContainer(name: "OuterSpace")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
    }
}
