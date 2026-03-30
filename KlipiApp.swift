import SwiftUI
import AppKit
import Carbon

class SharedViewModel {
    static let shared = ClipboardViewModel()
}

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

        // Close popover when app loses focus
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }

    @objc func applicationDidResignActive(_ notification: Notification) {
        if isPopoverShown {
            closePopover()
        }
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
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit Klipi", action: #selector(quitApp), keyEquivalent: "q"))
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            togglePopover()
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    @discardableResult
    func setupKeyboardShortcut() -> Bool {
        if eventTap != nil {
            return true
        }

        let eventMask = (1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon!).takeUnretainedValue()

                let flags = event.flags
                let isCmd = flags.contains(.maskCommand)
                let isAlt = flags.contains(.maskAlternate)
                let isCtrl = flags.contains(.maskControl)
                let isShift = flags.contains(.maskShift)
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

                // Get current shortcut from settings
                let shortcut = SettingsManager.shared.shortcut
                let modifiersMatch = (shortcut.modifiers.command == isCmd &&
                                       shortcut.modifiers.option == isAlt &&
                                       shortcut.modifiers.control == isCtrl &&
                                       shortcut.modifiers.shift == isShift)

                if modifiersMatch && keyCode == shortcut.keyCode {
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
            NSApplication.shared.activate(ignoringOtherApps: true)

            if popover == nil {
                popover = NSPopover()
                popover?.behavior = .transient
                popover?.contentSize = NSSize(width: 320, height: 400)
            }

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
        NSApplication.shared.hide(nil)
    }
}

@main
struct KlipiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        Settings {
            EmptyView()
                .onAppear {
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

struct EmptyView: View {
    var body: some View {
        Text("")
            .frame(width: 0, height: 0)
    }
}