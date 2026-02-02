import Foundation
import SwiftUI
import Combine

enum TimerState: Equatable {
    case idle
    case running
    case paused
}

@MainActor
class TimerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var timerState: TimerState = .idle
    @Published var currentSession: Session?
    @Published var settings: AppSettings = AppSettings()
    @Published var tags: [Tag] = []
    @Published var todaySessions: [Session] = []
    @Published var selectedDate: Date = Date()

    @Published var menuBarText: String = "0:00"
    @Published var currentSessionElapsed: TimeInterval = 0
    @Published var todayTotalSeconds: Int = 0

    @Published var tagInput: String = ""
    @Published var showingDashboard: Bool = false
    @Published var showingEndSessionSheet: Bool = false
    @Published var sessionToEnd: Session?

    // MARK: - Private Properties

    private var timer: Timer?
    private var pausedDuration: TimeInterval = 0
    private var pauseStartTime: Date?
    private let storage = StorageManager.shared

    // MARK: - Computed Properties

    var recentTags: [Tag] {
        Array(tags.sorted { $0.lastUsed > $1.lastUsed }.prefix(10))
    }

    var filteredTags: [Tag] {
        if tagInput.isEmpty {
            return recentTags
        }
        return tags.filter { $0.name.localizedCaseInsensitiveContains(tagInput) }
    }

    var targetReached: Bool {
        todayTotalSeconds >= settings.dailyTargetSeconds
    }

    var overtimeSeconds: Int {
        max(0, todayTotalSeconds - settings.dailyTargetSeconds)
    }

    var remainingSeconds: Int {
        max(0, settings.dailyTargetSeconds - todayTotalSeconds)
    }

    // MARK: - Initialization

    init() {
        loadData()
        startMenuBarTimer()
    }

    // MARK: - Data Loading

    func loadData() {
        Task {
            let loadedSettings = await storage.loadSettings()
            let loadedTags = await storage.loadTags()
            let loadedSessions = await storage.loadSessions(for: Date(), resetHour: loadedSettings.dayResetHour)

            await MainActor.run {
                self.settings = loadedSettings
                self.tags = loadedTags
                self.todaySessions = loadedSessions
                self.updateTodayTotal()
                self.updateMenuBarText()

                // Check for any active session
                if let activeSession = loadedSessions.first(where: { $0.end == nil }) {
                    self.currentSession = activeSession
                    self.timerState = .running
                }
            }
        }
    }

    func loadSessionsForDate(_ date: Date) {
        Task {
            let sessions = await storage.loadSessions(for: date, resetHour: settings.dayResetHour)
            await MainActor.run {
                self.selectedDate = date
                self.todaySessions = sessions
            }
        }
    }

    // MARK: - Timer Control

    func startSession(with tagName: String) {
        let trimmedTag = String(tagName.prefix(30)).trimmingCharacters(in: .whitespaces)
        guard !trimmedTag.isEmpty else { return }

        // Create or update tag
        updateTag(trimmedTag)

        // Create new session
        let session = Session(tag: trimmedTag)
        currentSession = session
        timerState = .running
        pausedDuration = 0
        tagInput = ""

        // Save session
        Task {
            try? await storage.saveSession(session, resetHour: settings.dayResetHour)
            await loadSessionsForToday()
        }
    }

    func pauseSession() {
        guard timerState == .running else { return }
        timerState = .paused
        pauseStartTime = Date()
    }

    func resumeSession() {
        guard timerState == .paused, let pauseStart = pauseStartTime else { return }
        pausedDuration += Date().timeIntervalSince(pauseStart)
        pauseStartTime = nil
        timerState = .running
    }

    func togglePause() {
        switch timerState {
        case .running:
            pauseSession()
        case .paused:
            resumeSession()
        case .idle:
            break
        }
    }

    func endSession(description: String = "", remarks: String = "") {
        guard var session = currentSession else { return }

        let endTime = Date()
        session.end = endTime
        session.durationSeconds = Int(session.duration) - Int(pausedDuration)
        session.description = String(description.prefix(140))
        session.remarks = remarks
        session.updatedAt = Date()

        timerState = .idle
        currentSession = nil
        pausedDuration = 0
        pauseStartTime = nil

        Task {
            try? await storage.saveSession(session, resetHour: settings.dayResetHour)
            await loadSessionsForToday()
        }
    }

    func switchTask() {
        // End current session first
        endSession()
        // Dashboard will open to allow new tag selection
        showingDashboard = true
    }

    // MARK: - Tag Management

    private func updateTag(_ name: String) {
        if let index = tags.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
            tags[index].lastUsed = Date()
        } else {
            let newTag = Tag(name: name, sortOrder: tags.count)
            tags.append(newTag)
        }

        Task {
            try? await storage.saveTags(tags)
        }
    }

    func renameTag(from oldName: String, to newName: String) {
        let trimmedNew = String(newName.prefix(30)).trimmingCharacters(in: .whitespaces)
        guard !trimmedNew.isEmpty else { return }

        if let index = tags.firstIndex(where: { $0.name == oldName }) {
            tags[index].name = trimmedNew
            Task {
                try? await storage.saveTags(tags)
            }
        }
    }

    func deleteTag(_ tag: Tag) {
        tags.removeAll { $0.id == tag.id }
        Task {
            try? await storage.saveTags(tags)
        }
    }

    // MARK: - Session Management

    func updateSession(_ session: Session) {
        Task {
            try? await storage.saveSession(session, resetHour: settings.dayResetHour)
            await loadSessionsForToday()
        }
    }

    func deleteSession(_ session: Session) {
        Task {
            try? await storage.deleteSession(session, resetHour: settings.dayResetHour)
            await loadSessionsForToday()
        }
    }

    // MARK: - Settings

    func saveSettings() {
        Task {
            try? await storage.saveSettings(settings)
            updateMenuBarText()
        }
    }

    // MARK: - Private Helpers

    private func loadSessionsForToday() async {
        let sessions = await storage.loadSessions(for: Date(), resetHour: settings.dayResetHour)
        await MainActor.run {
            self.todaySessions = sessions
            self.updateTodayTotal()
        }
    }

    private func updateTodayTotal() {
        todayTotalSeconds = todaySessions.reduce(0) { total, session in
            if let _ = session.end {
                return total + session.durationSeconds
            } else {
                // Active session
                return total + Int(session.duration) - Int(pausedDuration)
            }
        }
    }

    private func startMenuBarTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func tick() {
        // Update current session elapsed time
        if let session = currentSession, timerState == .running {
            currentSessionElapsed = session.duration - pausedDuration
        } else if timerState == .paused, let session = currentSession {
            // Keep showing elapsed time while paused
            if let pauseStart = pauseStartTime {
                currentSessionElapsed = session.duration - pausedDuration - Date().timeIntervalSince(pauseStart)
            }
        }

        updateTodayTotal()
        updateMenuBarText()
    }

    private func updateMenuBarText() {
        switch settings.timerMode {
        case .targetTime:
            if targetReached {
                if overtimeSeconds == 0 {
                    menuBarText = "✓"
                } else {
                    menuBarText = "+\(formatTime(overtimeSeconds))"
                }
            } else {
                menuBarText = formatTime(remainingSeconds)
            }
        case .stopwatch:
            menuBarText = formatTime(todayTotalSeconds)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return String(format: "0:%02d", minutes)
        }
    }

    func formatSessionTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}
