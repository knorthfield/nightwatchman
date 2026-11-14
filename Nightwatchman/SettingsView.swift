import SwiftUI

struct SettingsView: View {
    let durations: ActivationDurations

    @AppStorage(Settings.activateOnLaunch) private var activatesOnLaunch = false
    @AppStorage(Settings.allowDisplaySleep) private var allowsDisplaySleep = false
    @AppStorage(Settings.quitWhenTimerEnds) private var quitsWhenTimerEnds = false
    @AppStorage(Settings.batteryCutOffEnabled) private var isBatteryCutOffEnabled = true
    @AppStorage(Settings.batteryCutOffLevel) private var batteryCutOffLevel = 20.0
    @AppStorage(Settings.lowPowerModeCutOffEnabled) private var isLowPowerModeCutOffEnabled = true

    @State private var opensAtLogin = LoginItem.isEnabled
    @State private var newHours = 1
    @State private var newMinutes = 0
    @State private var newSeconds = 0
    @State private var addError: String?
    @State private var isConfirmingReset = false

    private let hasBattery = PowerState.current.batteryLevel != nil

    var body: some View {
        Form {
            Section("General") {
                Toggle("Open at Login", isOn: Binding(
                    get: { opensAtLogin },
                    set: { LoginItem.set($0); opensAtLogin = LoginItem.isEnabled }))
                Toggle("Activate on Launch", isOn: $activatesOnLaunch)
                Toggle("Allow Display Sleep", isOn: $allowsDisplaySleep)
                Toggle("Quit When the Timer Ends", isOn: $quitsWhenTimerEnds)
            }

            Section {
                ForEach(durations.all, id: \.self) { seconds in
                    DurationRow(durations: durations, seconds: seconds)
                }
                HStack {
                    NumberField(title: "Hours", value: $newHours)
                    NumberField(title: "Minutes", value: $newMinutes)
                    NumberField(title: "Seconds", value: $newSeconds)
                    Spacer()
                    Button("Add", action: addDuration)
                }
                if let addError {
                    Text(addError).foregroundStyle(.red)
                }
                Button("Reset…") { isConfirmingReset = true }
                    .confirmationDialog("Put back the standard durations?", isPresented: $isConfirmingReset) {
                        Button("Reset", role: .destructive) { durations.reset() }
                    } message: {
                        Text("This removes the durations that you added.")
                    }
            } header: {
                Text("Durations")
            } footer: {
                Text("A click on the menu bar icon keeps the Mac awake for the default duration.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Stop at a Low Battery", isOn: $isBatteryCutOffEnabled)
                Slider(value: $batteryCutOffLevel, in: 10...90, step: 5) {
                    Text("Stop at \(Int(batteryCutOffLevel)) %")
                }
                .disabled(!isBatteryCutOffEnabled)
                Toggle("Stop in Low Power Mode", isOn: $isLowPowerModeCutOffEnabled)
            } header: {
                Text("Battery")
            } footer: {
                Text(hasBattery
                    ? "Night Watchman keeps the Mac awake also when the lid is closed. A closed Mac that stays awake in a bag can get hot. If you start below the battery level or in Low Power Mode, that limit does not apply until you start again."
                    : "This Mac has no battery.")
                    .foregroundStyle(.secondary)
            }
            .disabled(!hasBattery)
        }
        .formStyle(.grouped)
        // The form scrolls, because all the durations do not go on the screen of a small MacBook.
        .frame(width: 520, height: 600)
    }

    private func addDuration() {
        do {
            try durations.add(newHours * 3600 + newMinutes * 60 + newSeconds)
            addError = nil
        } catch {
            addError = switch error {
            case .notPositive: "Enter a duration of 1 second or more."
            case .alreadyInList: "This duration is already in the list."
            }
        }
    }
}

private struct DurationRow: View {
    let durations: ActivationDurations
    let seconds: Int

    var body: some View {
        HStack {
            Text(ActivationDurations.title(for: seconds))
            Spacer()
            if seconds == durations.defaultDuration {
                Text("Default").foregroundStyle(.secondary)
            } else {
                Button("Set Default") { durations.setDefault(seconds) }
            }
            Button("Remove", systemImage: "minus.circle") { durations.remove(seconds) }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .disabled(seconds == ActivationDurations.indefinite)
        }
    }
}

private struct NumberField: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        TextField(title, value: $value, format: .number)
            .labelsHidden()
            .frame(width: 44)
            .multilineTextAlignment(.trailing)
        Text(title)
    }
}
