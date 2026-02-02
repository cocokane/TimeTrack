# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
# Build and create app bundle (RECOMMENDED)
./build-app.sh

# Run the app (after building)
open TimeTracker.app

# Install to Applications folder (optional)
cp -r TimeTracker.app /Applications/

# Kill running instances
pkill -9 -f "TimeTracker"
```

**Important:** Do NOT use `swift run` for this app. It must be run as a proper `.app` bundle for text input and focus handling to work correctly. Always use `./build-app.sh` then `open TimeTracker.app`.

### Development Commands

```bash
# Quick compile check (no app bundle)
swift build

# Clean build artifacts
swift package clean
```

## Architecture Overview

This is a native macOS menu bar app built with Swift and SwiftUI. It uses Swift Package Manager with two dependencies: **Yams** (YAML serialization) and **HotKey** (global keyboard shortcuts).

### Key Components

**AppDelegate** (`AppDelegate.swift`) - The hub of the application. Manages:
- NSStatusItem (menu bar presence)
- NSPopover (click-to-open UI)
- NSWindow (dashboard/main window)
- Global hotkey registration via HotkeyManager

**TimerViewModel** (`ViewModels/TimerViewModel.swift`) - Central state manager using `@MainActor`. Owns:
- Timer state (idle/running/paused)
- Current session tracking
- Tag management
- All persistence operations via StorageManager

**StorageManager** (`Storage/StorageManager.swift`) - Actor-based YAML persistence. Handles:
- Atomic file writes with `.bak` backups
- Day-boundary logic (configurable reset hour, default 3 AM)
- Session files stored by date: `~/Library/Application Support/TimeTracker/Sessions/YYYY-MM-DD.yaml`

### Data Flow

1. User interacts with PopoverView or DashboardView
2. Views call methods on TimerViewModel (passed as `@ObservedObject`)
3. TimerViewModel updates state and calls StorageManager for persistence
4. AppDelegate observes `@Published` properties via Combine to update menu bar text

### UI Hierarchy

- **PopoverView** - Translucent interface shown on menu bar click (tag selection, timer controls)
- **DashboardView** - Main window with NavigationSplitView sidebar (Timeline + Settings tabs)
- **TimelineView** - Chronological session list with inline editing (uses AppKit wrappers for text input)
- **SettingsView** - Timer mode, daily target, reset time, tag management

### Text Input Note

Text fields in the main window use `EditableTextField` and `EditableTextView` (NSViewRepresentable wrappers in TimelineView.swift) instead of SwiftUI TextField/TextEditor. This is required for proper focus handling in the NSWindow context.

## Design Constraints

- **LSUIElement = true** - App has no dock icon, lives only in menu bar
- **Dark theme with translucent popover** - Uses `.ultraThinMaterial` for popover background
- **Subtle colors in popover** - White/translucent buttons, gold accent in dashboard only
- **Monospaced digits** for timer display stability
- **macOS 13+** minimum deployment target
