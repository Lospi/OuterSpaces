//
//  SwiftUIView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 20/11/23.
//

import SwiftUI

struct SpacesView: View {
    @State var desktopSpaces: [DesktopSpaces] = []

    var body: some View {
        VStack {
            ForEach(Array(self.desktopSpaces.enumerated()), id: \.element) { indexDesktop, desktopSpace in
                VStack {
                    Text("Display \(indexDesktop + 1)")
                    HStack {
                        Text("Desktop Name")
                        Spacer()
                        Text("Switch to Space")
                    }
                    ForEach(Array(desktopSpace.desktopSpaces.enumerated()), id: \.element) { index, _ in
                        HStack {
                            Text("Desktop \(index)")
                            Spacer()
                            Button("Set") {
                                NSAppleScript(source: """
                                -- Set the index of the Space you want to switch to
                                set targetSpaceIndex to \(index) -- Change this to the desired Space index

                                -- Change to the specified Space index
                                tell application "System Events"
                                    key code (18 + targetSpaceIndex) using {control down} -- Press Ctrl + (targetSpaceIndex)
                                end tell

                                """)!.executeAndReturnError(nil)
                            }
                        }
                    }
                }
            }
        }
    }
}
