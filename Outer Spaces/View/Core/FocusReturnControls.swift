import SwiftUI

struct AutoReturnPresetControls: View {
    @ObservedObject var focusViewModel: FocusViewModel

    var body: some View {
        if let preset = focusViewModel.selectedFocusPreset {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Automatically return to Focus Spaces", isOn: Binding(
                    get: { preset.autoReturn.enabled },
                    set: { focusViewModel.updateAutoReturn(AutoReturnSettings(enabled: $0, delayMinutes: preset.autoReturn.delayMinutes)) }
                ))
                if preset.autoReturn.enabled {
                    Stepper(value: Binding(
                        get: { preset.autoReturn.delayMinutes },
                        set: { focusViewModel.updateAutoReturn(AutoReturnSettings(enabled: true, delayMinutes: $0)) }
                    ), in: 1...60) {
                        Text("Return after \(preset.autoReturn.delayMinutes) minutes")
                    }
                }
            }
            .font(.caption)
        }
    }
}

struct FocusReturnStatusView: View {
    @ObservedObject var controller: FocusReturnController

    var body: some View {
        if let preset = controller.preset, preset.autoReturn.enabled {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(preset.name).lineLimit(1)
                    Spacer()
                    if let countdown = controller.countdownText {
                        Text(countdown).monospacedDigit()
                    } else {
                        statusText.foregroundStyle(.secondary)
                    }
                }
                HStack {
                    if controller.isPaused {
                        Button("Resume") { controller.resume() }
                    } else {
                        Button("Return Now") { Task { await controller.returnNow() } }
                            .disabled(controller.phase != .counting)
                        Button("Pause for This Focus") { controller.pause() }
                            .disabled(controller.phase == .suspended)
                    }
                }
                .buttonStyle(.bordered)
            }
            .font(.caption)
            .padding(8)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var statusText: Text {
        switch controller.phase {
        case .idle: return Text("On Focus Spaces")
        case .counting: return Text("Returning soon")
        case .returning: return Text("Returning…")
        case .paused: return Text("Automatic return paused")
        case .suspended: return Text("Waiting for Focus Spaces")
        }
    }
}
