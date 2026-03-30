import Foundation

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let shortcutKey = "keyboardShortcut"

    @Published var shortcut: KeyboardShortcut {
        didSet {
            saveShortcut()
        }
    }

    private init() {
        // Initialize with default first, then load from storage
        let loaded = Self.loadShortcut()
        shortcut = loaded
    }

    private static func loadShortcut() -> KeyboardShortcut {
        guard let data = UserDefaults.standard.data(forKey: "keyboardShortcut"),
              let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: data) else {
            return .default
        }
        return decoded
    }

    private func saveShortcut() {
        guard let encoded = try? JSONEncoder().encode(shortcut) else { return }
        UserDefaults.standard.set(encoded, forKey: shortcutKey)
    }

    func resetToDefault() {
        shortcut = .default
    }
}