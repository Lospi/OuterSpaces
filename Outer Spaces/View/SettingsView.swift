//
//  WindowView.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 01/12/23.
//

import SFSafeSymbols
import SwiftUI

struct SettingsView: View {
    @State var showOnLogin = true
    @StateObject var spacesViewModel: SpacesViewModel
    @StateObject var licensingViewModel: LicensingViewModel
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.openWindow) var openWindow
    @State private var licenseKey = ""
    @State private var timeRemaining = 10
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(spacesViewModel: SpacesViewModel, licensingViewModel: LicensingViewModel) {
        _spacesViewModel = StateObject(wrappedValue: spacesViewModel)
        _licensingViewModel = StateObject(wrappedValue: licensingViewModel)
    }

    var body: some View {
        VStack {
            VStack {
                Text("Settings")
                    .font(.title)
                    .padding()
                UpdateView()
            }
            .padding()

            VStack {
                if !licensingViewModel.isLicenseRegistered {
                    Text("License Key")

                    TextField(
                        "License Key",
                        text: $licenseKey
                    )
                    .onSubmit {
                        Task {
                            await licensingViewModel.validateLicense(license: licenseKey)
                        }
                    }
                    .frame(width: 300)
                }
                else {
                    Text("License Key Active!")
                        .foregroundStyle(Color.green)
                    Button("Deactivate License") {
                        Task {
                            await licensingViewModel.deactivateLicense()
                        }
                    }
                }
                if licensingViewModel.isValidatingLicense {
                    Text("Validating License...")
                }
                else if licensingViewModel.failedToValidateLicense {
                    Text("Failed Validating License")
                }
            }
            .padding()

            Button("How to Use") {
                openWindow(id: "how-to-use")
            }
            .padding()

            VStack {
                Text("Shortcuts")
                    .font(.title)
                    .padding()
                Button("Keyboard Shortcuts") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.keyboard?Shortcuts")!)
                }
                .onDrag {
                    NSItemProvider()
                }
                Button("Privacy and Security") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension")!)
                }
            }

            VStack {
                Text("About")
                    .font(.title)
                    .padding()

                HStack {
                    Image(nsImage: NSImage(named: "AppIcon")!)
                        .resizable()
                        .frame(width: 100, height: 100)
                    VStack {
                        Text("Outer Spaces")
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)")
                        Text("Developed by Lospi")
                        Text("Contact: admin@lospi.dev")
                    }
                }
            }
        }
        .frame(width: 500, height: 800)
    }
}
