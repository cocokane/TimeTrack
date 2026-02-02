import AppKit
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var dashboardWindow: NSWindow?

    private var viewModel: TimerViewModel!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize view model
        viewModel = TimerViewModel()

        // Setup menu bar
        setupStatusItem()

        // Setup popover
        setupPopover()

        // Setup global hotkeys
        setupHotkeys()

        // Observe settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotkeySettingChanged),
            name: .hotkeySettingChanged,
            object: nil
        )

        // Observe dashboard show requests
        viewModel.$showingDashboard
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
                if show {
                    Task { @MainActor in
                        self?.showDashboard()
                        self?.viewModel.showingDashboard = false
                    }
                }
            }
            .store(in: &cancellables)

        // Update menu bar text
        viewModel.$menuBarText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.updateMenuBarText(text)
            }
            .store(in: &cancellables)
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = viewModel.menuBarText
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
    }

    private func updateMenuBarText(_ text: String) {
        statusItem.button?.title = text
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Open Dashboard", action: #selector(openDashboard), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Time Tracker", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openDashboard() {
        showDashboard()
    }

    @objc private func openSettings() {
        showDashboard()
        // Settings will be accessible from dashboard sidebar
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 250)
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: PopoverView(viewModel: viewModel))
    }

    func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    // MARK: - Dashboard Window

    func showDashboard() {
        closePopover()

        if dashboardWindow == nil {
            let contentView = DashboardView(viewModel: viewModel)

            dashboardWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )

            dashboardWindow?.title = "Time Tracker"
            dashboardWindow?.contentView = NSHostingView(rootView: contentView)
            dashboardWindow?.center()
            dashboardWindow?.setFrameAutosaveName("Dashboard")
            dashboardWindow?.isReleasedWhenClosed = false

            // Dark appearance
            dashboardWindow?.appearance = NSAppearance(named: .darkAqua)
            dashboardWindow?.backgroundColor = NSColor(Color.darkBackground)
        }

        dashboardWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePopover() {
        if popover.isShown {
            popover.performClose(nil)
        }
    }

    // MARK: - Hotkeys

    private func setupHotkeys() {
        let hotkeyManager = HotkeyManager.shared

        hotkeyManager.onTogglePopover = { [weak self] in
            Task { @MainActor in
                self?.togglePopover()
            }
        }

        hotkeyManager.onTogglePause = { [weak self] in
            Task { @MainActor in
                self?.viewModel.togglePause()
            }
        }

        hotkeyManager.setupHotkeys(enabled: viewModel.settings.hotkeyEnabled)
    }

    @objc private func hotkeySettingChanged() {
        HotkeyManager.shared.setupHotkeys(enabled: viewModel.settings.hotkeyEnabled)
    }

    // MARK: - NSPopoverDelegate

    nonisolated func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return false
    }
}
