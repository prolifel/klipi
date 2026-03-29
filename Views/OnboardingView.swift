import SwiftUI

struct OnboardingView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Enable Keyboard Shortcut")
                .font(.title2)
                .fontWeight(.bold)

            Text("To use Alt+Cmd+. for quick clipboard access, Klipi needs Input Monitoring permission.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                StepView(number: "1", text: "Open System Settings → Privacy & Security → Input Monitoring")
                StepView(number: "2", text: "Click the + button and add Klipi")
                StepView(number: "3", text: "Make sure Klipi is enabled")
            }
            .padding(.vertical, 8)

            Button(action: {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
            }) {
                Text("Open System Settings")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("I've enabled it, continue") {
                onContinue()
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(width: 360)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct StepView: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
            Text(text)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}