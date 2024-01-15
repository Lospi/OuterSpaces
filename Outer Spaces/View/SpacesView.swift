//
//  SwiftUIView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 20/11/23.
//

import SwiftUI

struct SpacesView: View {
    @State var desktopSpaces: [DesktopSpaces] = []
    @State var error: NSDictionary?

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
                                if let result = try? NSAppleScript(source: """
                                -- Set the index of the Space you want to switch to
                                set targetSpaceIndex to \(index) -- Change this to the desired Space index

                                -- Change to the specified Space index
                                tell application "System Events"
                                    key code (18 + targetSpaceIndex) using {control down} -- Press Ctrl + (targetSpaceIndex)
                                end tell

                                """)!.executeAndReturnError(&error) {
                                    if let stringValue = result.stringValue {
                                        print("Script executed successfully. Result: \(stringValue)")
                                    } else {
                                        print("Script executed successfully.")
                                    }
                                } else {
                                    if let errorDescription = error?["NSAppleScriptErrorMessage"] as? String {
                                        if errorDescription.contains("System Events") {
                                            didError = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
