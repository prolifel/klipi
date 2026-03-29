import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var viewModel: ClipboardViewModel
    @ObservedObject var permissionManager = PermissionManager.shared
    var onRetryPermission: () -> Bool
    var onClose: () -> Void
    @State private var selectedIndex: Int?
    @State private var showCopiedOverlay = false
    @State private var showOnboarding: Bool?

    var body: some View {
        ZStack {
            if showOnboarding ?? !permissionManager.hasPermission {
                OnboardingView(onContinue: {
                    _ = onRetryPermission()
                    onClose()
                })
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Clipboard History")
                            .font(.headline)
                        Spacer()
                        Button(action: { viewModel.clearHistory() }) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .help("Clear all")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    Divider()

                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search...", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .id("searchField")
                        if !viewModel.searchText.isEmpty {
                            Button(action: { viewModel.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))

                    Divider()

                    // History List
                    if viewModel.filteredHistory.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "clipboard")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text(viewModel.searchText.isEmpty ? "No clipboard history" : "No matching items")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 320, height: 200)
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 4) {
                                    ForEach(Array(viewModel.filteredHistory.enumerated()), id: \.element.id) { index, item in
                                        ClipboardRowView(
                                            item: item,
                                            onCopy: {
                                                viewModel.copyItem(item)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    onClose()
                                                }
                                            },
                                            onDelete: {
                                                viewModel.removeItem(item)
                                            },
                                            isSelected: selectedIndex == index
                                        )
                                        .id(item.id)
                                        .contextMenu {
                                            Button("Copy") {
                                                viewModel.copyItem(item)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    onClose()
                                                }
                                            }
                                            Button("Delete", role: .destructive) {
                                                viewModel.removeItem(item)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .frame(width: 320)
                            .frame(maxHeight: 400)
                            .onChange(of: selectedIndex) { newValue in
                                if let index = newValue, index < viewModel.filteredHistory.count {
                                    let item = viewModel.filteredHistory[index]
                                    withAnimation {
                                        proxy.scrollTo(item.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }
                .background(Color(NSColor.windowBackgroundColor))

                // Copied overlay
                if showCopiedOverlay {
                    VStack {
                        Text("Copied!")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .cornerRadius(8)
                    }
                    .frame(width: 320, height: 400)
                    .background(Color.black.opacity(0.3))
                }
            }
        }
        .onAppear {
            selectedIndex = nil
            setupKeyboardMonitor()
        }
    }

    private func setupKeyboardMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyPress(event: event)
            return event
        }
    }

    private func handleKeyPress(event: NSEvent) {
        guard permissionManager.hasPermission else { return }

        let items = viewModel.filteredHistory

        switch event.keyCode {
        case 125: // Down arrow
            if items.isEmpty { return }
            if let current = selectedIndex {
                selectedIndex = current < items.count - 1 ? current + 1 : 0
            } else {
                selectedIndex = 0
            }
        case 126: // Up arrow
            if items.isEmpty { return }
            if let current = selectedIndex {
                selectedIndex = current > 0 ? current - 1 : items.count - 1
            } else {
                selectedIndex = 0
            }
        case 36: // Return
            if let index = selectedIndex, index < items.count {
                viewModel.copyItem(items[index])
                // Show copied overlay briefly before closing
                withAnimation {
                    showCopiedOverlay = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onClose()
                }
            }
        case 53: // Escape
            onClose()
        default:
            break
        }
    }
}