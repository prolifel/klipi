import Foundation
import Combine

class ClipboardViewModel: ObservableObject {
    @Published var history: [ClipboardItem] = []
    @Published var searchText: String = ""

    let settingsManager = SettingsManager.shared

    private let maxItems = 50
    private let storageKey = "clipboardHistory"

    private var monitor: ClipboardMonitor?

    var filteredHistory: [ClipboardItem] {
        if searchText.isEmpty {
            return history
        }
        return history.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    init() {
        loadHistory()
        setupMonitor()
    }

    private func setupMonitor() {
        monitor = ClipboardMonitor { [weak self] content in
            self?.addItem(content)
        }
        monitor?.startMonitoring()
    }

    func addItem(_ content: String) {
        // Remove existing item if present, then add at top
        history.removeAll { $0.content == content }

        let item = ClipboardItem(content: content)
        history.insert(item, at: 0)

        // Remove oldest if over limit
        if history.count > maxItems {
            history.removeLast()
        }

        saveHistory()
    }

    func removeItem(_ item: ClipboardItem) {
        history.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    func copyItem(_ item: ClipboardItem) {
        print("[DEBUG] copyItem called with: \(item.content)")
        // Just copy to clipboard, history will be updated by monitor when pasting elsewhere
        monitor?.copyToClipboard(item.content)
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            history = decoded
        }
    }
}