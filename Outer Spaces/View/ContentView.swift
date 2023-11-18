//
//  ContentView.swift
//  AppleScriptTest
//
//  Created by Mark Alldritt on 2021-02-02.
//

import ActivityIndicatorView
import Carbon
import SwiftUI

extension NSAppleEventDescriptor {
    var display: String {
        //  A quick and dirty means of converting an descriptor to string
        switch self.descriptorType {
        case typeSInt16,
             typeUInt16,
             typeSInt32,
             typeUInt32:
            return "\(self.int32Value)"

        case typeBoolean:
            return self.booleanValue ? "true" : "false"

        case typeLongDateTime:
            return "\(self.dateValue!)"

        case typeAEText,
             typeIntlText,
             typeUnicodeText:
            return self.stringValue!

        case OSType(1954115685):
            return "<missing value>"

        case typeAEList:
            var items = [String]()

            for i in 1 ... self.numberOfItems {
                items.append(self.atIndex(i)!.display)
            }
            return "[" + items.joined(separator: ", ") + "]"

        default:
            return "\(self)"
        }
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(#colorLiteral(red: 0.137561053, green: 0.1773550212, blue: 0.1941199303, alpha: 1)))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 3)
    }
}

struct AppleScriptRunnerView: View {
    @ObservedObject var script: AppleScriptRunner
    @State var showActivity = true
    let title: String

    init(_ title: String, script: AppleScriptRunner) {
        self.title = title
        self.script = script
    }

    var body: some View {
        VStack {
            Text(self.title)
                .foregroundColor(.gray)
                .padding()
            switch self.script.state {
            case .running:
                ActivityIndicatorView(isVisible: self.$showActivity, type: .scalingDots())
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)

            case .complete(let result):
                Text(result.display)
                    .foregroundColor(.white)
                    .padding(.all, 10)

            case .error(let error):
                Text("\(error.number) - \(error.message)")
                    .foregroundColor(.red)
                    .padding(.all, 10)

            case .idle:
                Group {} // empty ...
            }
            Button("Run") {
                self.script.executeAsync()
            }
            .padding()
            .disabled(self.script.state == .running)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .modifier(CardModifier())
        .padding(.all, 10)
    }
}

struct ContentView: View {
    let spaceObserver = SpaceObserver()
    @State public var desktopSpaces: [DesktopSpaces] = []
    @State private var spaceCustomName: [String] = []

    var body: some View {
        VStack {
            Button("Refresh") {
                self.spaceObserver.updateSpaceInformation()
                self.desktopSpaces = self.spaceObserver.spaces
            }
            VStack {
                ForEach(Array(self.desktopSpaces.enumerated()), id: \.element) { indexDesktop, desktopSpace in
                    Text("Desktop \(indexDesktop + 1)")
                    ForEach(Array(desktopSpace.desktopSpaces.enumerated()), id: \.element) { index, _ in
                        Text("Space \(index)")
                    }
                }
            }
            .scaledToFit()
        }
    }
}
