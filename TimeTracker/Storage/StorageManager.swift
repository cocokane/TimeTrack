import Foundation
import Yams

actor StorageManager {
    static let shared = StorageManager()

    private let fileManager = FileManager.default
    private let appSupportPath: URL
    private let sessionsPath: URL
    private let settingsPath: URL
    private let tagsPath: URL

    private let encoder: YAMLEncoder
    private let decoder: YAMLDecoder

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        appSupportPath = appSupport.appendingPathComponent("TimeTracker", isDirectory: true)
        sessionsPath = appSupportPath.appendingPathComponent("Sessions", isDirectory: true)
        settingsPath = appSupportPath.appendingPathComponent("settings.yaml")
        tagsPath = appSupportPath.appendingPathComponent("tags.yaml")

        encoder = YAMLEncoder()
        decoder = YAMLDecoder()

        // Ensure directories exist
        try? fileManager.createDirectory(at: appSupportPath, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: sessionsPath, withIntermediateDirectories: true)
    }

    // MARK: - Date Helpers

    private func dateString(for date: Date, resetHour: Int = 3) -> String {
        // Adjust for day reset time (default 3 AM)
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        var adjustedDate = date
        let hour = calendar.component(.hour, from: date)

        // If before reset hour, consider it part of previous day
        if hour < resetHour {
            adjustedDate = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: adjustedDate)
    }

    private func sessionFilePath(for dateString: String) -> URL {
        sessionsPath.appendingPathComponent("\(dateString).yaml")
    }

    // MARK: - Settings

    func loadSettings() -> AppSettings {
        guard fileManager.fileExists(atPath: settingsPath.path) else {
            let defaultSettings = AppSettings()
            try? saveSettings(defaultSettings)
            return defaultSettings
        }

        do {
            let data = try Data(contentsOf: settingsPath)
            let yaml = String(data: data, encoding: .utf8) ?? ""
            return try decoder.decode(AppSettings.self, from: yaml)
        } catch {
            print("Error loading settings: \(error)")
            return AppSettings()
        }
    }

    func saveSettings(_ settings: AppSettings) throws {
        let yaml = try encoder.encode(settings)
        try atomicWrite(yaml, to: settingsPath)
    }

    // MARK: - Tags

    func loadTags() -> [Tag] {
        guard fileManager.fileExists(atPath: tagsPath.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: tagsPath)
            let yaml = String(data: data, encoding: .utf8) ?? ""
            let tagsFile = try decoder.decode(TagsFile.self, from: yaml)
            return tagsFile.tags
        } catch {
            print("Error loading tags: \(error)")
            return []
        }
    }

    func saveTags(_ tags: [Tag]) throws {
        let tagsFile = TagsFile(tags: tags)
        let yaml = try encoder.encode(tagsFile)
        try atomicWrite(yaml, to: tagsPath)
    }

    // MARK: - Sessions

    func loadSessions(for date: Date, resetHour: Int = 3) -> [Session] {
        let dateStr = dateString(for: date, resetHour: resetHour)
        let filePath = sessionFilePath(for: dateStr)

        guard fileManager.fileExists(atPath: filePath.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: filePath)
            let yaml = String(data: data, encoding: .utf8) ?? ""
            return try decoder.decode([Session].self, from: yaml)
        } catch {
            print("Error loading sessions: \(error)")
            return []
        }
    }

    func saveSessions(_ sessions: [Session], for date: Date, resetHour: Int = 3) throws {
        let dateStr = dateString(for: date, resetHour: resetHour)
        let filePath = sessionFilePath(for: dateStr)

        let yaml = try encoder.encode(sessions)
        try atomicWrite(yaml, to: filePath)
    }

    func saveSession(_ session: Session, resetHour: Int = 3) throws {
        var sessions = loadSessions(for: session.start, resetHour: resetHour)

        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }

        // Sort by start time
        sessions.sort { $0.start < $1.start }

        try saveSessions(sessions, for: session.start, resetHour: resetHour)
    }

    func deleteSession(_ session: Session, resetHour: Int = 3) throws {
        var sessions = loadSessions(for: session.start, resetHour: resetHour)
        sessions.removeAll { $0.id == session.id }
        try saveSessions(sessions, for: session.start, resetHour: resetHour)
    }

    // MARK: - Atomic Write

    private func atomicWrite(_ content: String, to url: URL) throws {
        let tempURL = url.appendingPathExtension("tmp")
        let backupURL = url.appendingPathExtension("bak")

        // Write to temp file
        try content.write(to: tempURL, atomically: true, encoding: .utf8)

        // Create backup of existing file
        if fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: backupURL)
            try? fileManager.copyItem(at: url, to: backupURL)
        }

        // Replace original with temp
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        try fileManager.moveItem(at: tempURL, to: url)
    }

    // MARK: - Day Total

    func totalSecondsWorked(for date: Date, resetHour: Int = 3) -> Int {
        let sessions = loadSessions(for: date, resetHour: resetHour)
        return sessions.reduce(0) { total, session in
            if session.end != nil {
                return total + session.durationSeconds
            } else {
                // Active session - calculate current duration
                return total + Int(session.duration)
            }
        }
    }
}
