import Foundation
import HotKey
import Carbon

class HotkeyManager {
    static let shared = HotkeyManager()

    private var togglePopoverHotkey: HotKey?
    private var togglePauseHotkey: HotKey?

    var onTogglePopover: (() -> Void)?
    var onTogglePause: (() -> Void)?

    private init() {}

    func setupHotkeys(enabled: Bool) {
        // Clear existing hotkeys
        togglePopoverHotkey = nil
        togglePauseHotkey = nil

        guard enabled else { return }

        // ⌥⌘A - Toggle popover
        togglePopoverHotkey = HotKey(key: .a, modifiers: [.option, .command])
        togglePopoverHotkey?.keyDownHandler = { [weak self] in
            self?.onTogglePopover?()
        }

        // ⌥⌘P - Toggle pause
        togglePauseHotkey = HotKey(key: .p, modifiers: [.option, .command])
        togglePauseHotkey?.keyDownHandler = { [weak self] in
            self?.onTogglePause?()
        }
    }

    func disable() {
        togglePopoverHotkey = nil
        togglePauseHotkey = nil
    }
}
