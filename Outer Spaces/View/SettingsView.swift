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

    func formatRemainingTime(for startDate: Date) -> [String] {
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)! // Add 7 days to starting date
        let now = Date()

        guard endDate > now else {
            return ["Trial has ended"] // Handle case where trial has already ended
        }

        let remainingComponents = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: endDate)

        let days = remainingComponents.day ?? 0
        let hours = remainingComponents.hour ?? 0
        let minutes = remainingComponents.minute ?? 0

        return [String(format: "%02d", days), String(format: "%02d", hours), String(format: "%02d", minutes)]
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

            if !licensingViewModel.trialSpent {
                if !licensingViewModel.isOnTrial {
                    Button("Start Free Trial") {
                        licensingViewModel.startFreeTrialIfAvailable()
                    }
                    .padding()
                }
                else {
                    Text("Trial Active!")
                        .foregroundStyle(Color.green)
                        .padding()
                    Text("Your trial expires in: \(formatRemainingTime(for: licensingViewModel.trialStartDate!)[0]) days, \(formatRemainingTime(for: licensingViewModel.trialStartDate!)[1]) hours, \(formatRemainingTime(for: licensingViewModel.trialStartDate!)[2]) minutes")
                }
            }
            else if licensingViewModel.trialSpent && !licensingViewModel.isLicenseRegistered {
                Text("Trial Expired")
                    .foregroundStyle(Color.red)
            }

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
