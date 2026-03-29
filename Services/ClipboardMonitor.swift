import AppKit
import Combine

class ClipboardMonitor: ObservableObject {
    @Published var lastChangeCount: Int
    private var timer: Timer?
    private var isCopyingFromHistory = false

    let onNewContent: (String) -> Void

    init(onNewContent: @escaping (String) -> Void) {
        self.onNewContent = onNewContent
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        guard !isCopyingFromHistory else { return }

        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount

            if let content = pasteboard.string(forType: .string), !content.isEmpty {
                onNewContent(content)
            }
        }
    }

    func copyToClipboard(_ content: String) {
        isCopyingFromHistory = true
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        lastChangeCount = pasteboard.changeCount

        // Reset flag after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.isCopyingFromHistory = false
        }
    }
}