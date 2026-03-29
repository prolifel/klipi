import SwiftUI
import AppKit
import Carbon

// Shared ViewModel instance
class SharedViewModel {
    static let shared = ClipboardViewModel()
}

// Observable object to track permission state
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    @Published var hasPermission = false
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var viewModel: ClipboardViewModel = SharedViewModel.shared
    var isPopoverShown = false
    var eventTap: CFMachPort?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        PermissionManager.shared.hasPermission = setupKeyboardShortcut()
    }

    var needsOnboarding: Bool {
        return !PermissionManager.shared.hasPermission
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Klipi")
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(statusItemClicked(sender:))
        statusItem?.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc func statusItemClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent

        if event?.type == .rightMouseUp {
            // Show menu on right-click
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit Klipi", action: #selector(quitApp), keyEquivalent: "q"))
            statusItem?.popUpMenu(menu)
        } else {
            // Toggle popover on left-click
            togglePopover()
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    @discardableResult
    func setupKeyboardShortcut() -> Bool {
        // If already set up, return true
        if eventTap != nil {
            return true
        }

        // Use CGEventTap for more reliable global hotkey capture
        let eventMask = (1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon!).takeUnretainedValue()

                // Check for Alt+Cmd+. (period keyCode 47)
                let flags = event.flags
                let isCmd = flags.contains(.maskCommand)
                let isAlt = flags.contains(.maskAlternate)
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

                if isCmd && isAlt && keyCode == 47 {
                    DispatchQueue.main.async {
                        appDelegate.togglePopover()
                    }
                }

                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap - no Input Monitoring permission")
            return false
        }

        eventTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func retryPermission() -> Bool {
        let granted = setupKeyboardShortcut()
        PermissionManager.shared.hasPermission = granted
        return granted
    }

    @objc func togglePopover() {
        guard let statusItem = statusItem, let button = statusItem.button else {
            return
        }

        if isPopoverShown {
            closePopover()
        } else {
            // Activate the app first
            NSApplication.shared.activate(ignoringOtherApps: true)

            if popover == nil {
                popover = NSPopover()
                popover?.behavior = .transient
                popover?.contentSize = NSSize(width: 320, height: 400)
            }

            // Create hosting view with proper sizing
            let hostingView = NSHostingView(rootView: MenuBarView(
                viewModel: viewModel,
                onRetryPermission: { [weak self] in
                    return self?.retryPermission() ?? false
                },
                onClose: { [weak self] in
                    self?.closePopover()
                }
            ))
            hostingView.frame = NSRect(x: 0, y: 0, width: 320, height: 400)

            let viewController = NSViewController()
            viewController.view = hostingView

            popover?.contentViewController = viewController
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            isPopoverShown = true
        }
    }

    func closePopover() {
        popover?.performClose(nil)
        isPopoverShown = false
        // Hide the app to return focus to previous window
        NSApplication.shared.hide(nil)
    }
}

@main
struct KlipiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Hide dock icon - this is a menu bar app
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        // Empty scene - UI is handled by AppDelegate's NSStatusItem
        Settings {
            EmptyView()
                .onAppear {
                    // Close any windows that might appear
                    DispatchQueue.main.async {
                        NSApplication.shared.windows.forEach { window in
                            if window.contentView?.subviews.first is NSHostingView<EmptyView> {
                                window.close()
                            }
                        }
                    }
                }
        }
    }
}

// SwiftUI requires at least one Scene
struct EmptyView: View {
    var body: some View {
        Text("")
            .frame(width: 0, height: 0)
    }
}