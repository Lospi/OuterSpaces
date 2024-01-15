//
//  SpacesAndPresetsView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 22/12/23.
//

import SwiftUI

struct SpacesAndPresetsView: View {
    @StateObject var spacesViewModel: SpacesViewModel
    @Environment(\.managedObjectContext) var managedObjectContext

    func saveNewSpaces() {
        let isUpdated = spacesViewModel.updateSystemSpaces()
        if isUpdated {
            CoreDataManager.shared.deleteCoreDataModel(modelName: "SpaceData", managedObjectContext: managedObjectContext)
            CoreDataManager.shared.saveSpacesToCoreData(spacesViewModel: spacesViewModel, managedObjectContext: managedObjectContext)
        }
    }

    var body: some View {
        VStack {
            Button(action: {
                       saveNewSpaces()
                   },
                   label: { Text("Refresh Available Spaces")
                   })
        }
    }
}
