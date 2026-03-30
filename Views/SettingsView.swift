import SwiftUI
import AppKit

struct SettingsView: View {
    @Binding var shortcut: KeyboardShortcut
    @State private var isRecording = false
    @State private var tempShortcut: KeyboardShortcut?
    @State private var localMonitor: Any?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Keyboard Shortcut")
                .font(.headline)

            Text("Press a keyboard shortcut to record it.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Current shortcut display
            HStack(spacing: 12) {
                Text("Current:")
                    .font(.body)
                Text(shortcut.displayName)
                    .font(.system(.title2, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(6)
            }

            // Recording area
            if isRecording {
                VStack(spacing: 8) {
                    if let temp = tempShortcut {
                        Text(temp.displayName)
                            .font(.system(.title, design: .monospaced))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.3))
                            .cornerRadius(8)
                    } else {
                        Text("Recording...")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        Text("Press a keyboard shortcut...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .focused($isFocused)
                .onAppear {
                    isFocused = true
                    startRecording()
                }
            } else {
                Button("Record New Shortcut") {
                    isRecording = true
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 12) {
                Button("Reset to Default") {
                    shortcut = .default
                    isRecording = false
                    tempShortcut = nil
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Done") {
                    stopRecording()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 320)
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        // Remove existing monitor if any
        stopRecording()

        // Add local monitor for key events (app is active when settings is open)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isRecording else { return event }

            let flags = event.modifierFlags
            let hasModifier = flags.contains(.command) ||
                              flags.contains(.option) ||
                              flags.contains(.control) ||
                              flags.contains(.shift)

            // Require at least one modifier
            guard hasModifier else {
                NSSound.beep()
                return event
            }

            // Don't allow modifier-only shortcuts
            let keyCode = event.keyCode
            let isModifierOnly = keyCode == 54 || keyCode == 55 || // left/right Command
                                  keyCode == 58 || keyCode == 61 || // left/right Option
                                  keyCode == 59 || keyCode == 62 || // left/right Control
                                  keyCode == 56 || keyCode == 60    // left/right Shift
            guard !isModifierOnly else {
                NSSound.beep()
                return event
            }

            let newShortcut = KeyboardShortcut(
                keyCode: Int64(keyCode),
                modifiers: KeyboardShortcut.Modifiers(
                    command: flags.contains(.command),
                    option: flags.contains(.option),
                    control: flags.contains(.control),
                    shift: flags.contains(.shift)
                )
            )

            // Update shortcut
            shortcut = newShortcut
            tempShortcut = newShortcut

            // Stop recording after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                stopRecording()
                isRecording = false
                tempShortcut = nil
            }

            return nil // Consume the event
        }
    }

    private func stopRecording() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
}