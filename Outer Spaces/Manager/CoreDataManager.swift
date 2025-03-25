import CoreData
import Foundation

extension FocusData {
    var spacesIds: [String]? {
        get {
            if let data = spacesIdsData {
                return try? JSONDecoder().decode([String].self, from: data)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                spacesIdsData = try? JSONEncoder().encode(newValue)
            } else {
                spacesIdsData = nil
            }
        }
    }
}

class CoreDataService {
    static let shared = CoreDataService()
    
    private init() {}
    
    // MARK: - Space Management
    
    func syncSpaces(allSpaces: [Space], in context: NSManagedObjectContext) {
        context.perform {
            // Fetch existing spaces
            let fetchRequest: NSFetchRequest<SpaceData> = SpaceData.fetchRequest()
            let existingSpaces = try? context.fetch(fetchRequest)
            let existingSpaceMap = Dictionary(uniqueKeysWithValues: (existingSpaces ?? []).map { ($0.spaceId!, $0) })
            
            // Create sets for efficient comparison
            let newSpaceIDs = Set(allSpaces.map { $0.spaceID })
            let existingSpaceIDs = Set(existingSpaceMap.keys)
            
            // Spaces to delete
            let spacesToDelete = existingSpaceIDs.subtracting(newSpaceIDs)
            for spaceID in spacesToDelete {
                if let spaceToDelete = existingSpaceMap[spaceID] {
                    context.delete(spaceToDelete)
                }
            }
            
            // Update or create spaces
            for space in allSpaces {
                if let existingSpace = existingSpaceMap[space.spaceID] {
                    // Update existing space
                    existingSpace.displayId = space.displayID
                    existingSpace.customName = space.customName
                    existingSpace.spaceIndex = Int16(space.spaceIndex)
                } else {
                    // Create new space
                    let newSpace = SpaceData(context: context)
                    newSpace.id = space.id
                    newSpace.displayId = space.displayID
                    newSpace.spaceId = space.spaceID
                    newSpace.customName = space.customName
                    newSpace.spaceIndex = Int16(space.spaceIndex)
                }
            }
            
            // Save changes
            if context.hasChanges {
                try? context.save()
            }
        }
    }
    
    // MARK: - Focus Management
    
    func syncFocusPresets(focusPresets: [Focus], in context: NSManagedObjectContext) {
        context.perform {
            // Fetch existing focus presets
            let fetchRequest: NSFetchRequest<FocusData> = FocusData.fetchRequest()
            let existingPresets = try? context.fetch(fetchRequest)
            let existingPresetMap = Dictionary(uniqueKeysWithValues: (existingPresets ?? []).map { ($0.id!, $0) })
            
            // Create sets for efficient comparison
            let newPresetIDs = Set(focusPresets.map { $0.id })
            let existingPresetIDs = Set(existingPresetMap.keys)
            
            // Presets to delete
            let presetsToDelete = existingPresetIDs.subtracting(newPresetIDs)
            for presetID in presetsToDelete {
                if let presetToDelete = existingPresetMap[presetID] {
                    context.delete(presetToDelete)
                }
            }
            
            // Update or create presets
            for preset in focusPresets {
                if let existingPreset = existingPresetMap[preset.id] {
                    // Update existing preset
                    existingPreset.name = preset.name
                    
                    // Convert spaceIDs array to serialized data
                    let spaceIDs = preset.spaces.map { $0.spaceID }
                    if let serializedIDs = try? JSONEncoder().encode(spaceIDs) {
                        existingPreset.spacesIdsData = serializedIDs
                    }
                    
                    existingPreset.stageManager = preset.stageManager
                } else {
                    // Create new preset
                    let newPreset = FocusData(context: context)
                    newPreset.id = preset.id
                    newPreset.name = preset.name
                    
                    // Convert spaceIDs array to serialized data
                    let spaceIDs = preset.spaces.map { $0.spaceID }
                    if let serializedIDs = try? JSONEncoder().encode(spaceIDs) {
                        newPreset.spacesIdsData = serializedIDs
                    }
                    
                    newPreset.stageManager = preset.stageManager
                }
            }
            
            // Save changes
            if context.hasChanges {
                try? context.save()
            }
        }
    }
    
    // Load spaces from Core Data
    func loadSpaces(from context: NSManagedObjectContext) -> (spaces: [Space], desktops: [DesktopSpaces]) {
        var spaces: [Space] = []
        var desktopSpaces: [DesktopSpaces] = []
        
        let fetchRequest: NSFetchRequest<SpaceData> = SpaceData.fetchRequest()
        
        context.performAndWait {
            if let spaceData = try? context.fetch(fetchRequest) {
                spaces = spaceData.map { space in
                    Space(
                        id: space.id!,
                        displayID: space.displayId!,
                        spaceID: space.spaceId!,
                        customName: space.customName,
                        spaceIndex: Int(space.spaceIndex)
                    )
                }
                
                // Group spaces by display
                let displayIDs = Array(Set(spaces.map { $0.displayID }))
                desktopSpaces = displayIDs.map { displayID in
                    let spacesForDisplay = spaces.filter { $0.displayID == displayID }
                    return DesktopSpaces(desktopSpaces: spacesForDisplay)
                }
            }
        }
        
        return (spaces: spaces, desktops: desktopSpaces)
    }
    
    // Load focus presets from Core Data
    func loadFocusPresets(from context: NSManagedObjectContext, allSpaces: [Space]) -> [Focus] {
        var focusPresets: [Focus] = []
        
        let fetchRequest: NSFetchRequest<FocusData> = FocusData.fetchRequest()
        
        context.performAndWait {
            if let presetData = try? context.fetch(fetchRequest) {
                focusPresets = presetData.compactMap { focusData in
                    guard let id = focusData.id, let name = focusData.name else {
                        return nil
                    }
                    
                    // Deserialize space IDs from Data
                    var spaceIDs: [String] = []
                    if let spacesIdsData = focusData.spacesIdsData {
                        spaceIDs = (try? JSONDecoder().decode([String].self, from: spacesIdsData)) ?? []
                    }
                    
                    let spaces = spaceIDs.compactMap { spaceID in
                        allSpaces.first { $0.spaceID == spaceID }
                    }
                    
                    return Focus(
                        id: id,
                        name: name,
                        spaces: spaces,
                        stageManager: focusData.stageManager
                    )
                }
            }
        }
        
        return focusPresets
    }
}
