import Foundation

enum TimerMode: String, Codable, CaseIterable {
    case targetTime = "target_time"
    case stopwatch = "stopwatch"

    var displayName: String {
        switch self {
        case .targetTime:
            return "Target Time"
        case .stopwatch:
            return "Stopwatch"
        }
    }
}

struct AppSettings: Codable {
    var timerMode: TimerMode
    var dailyTargetSeconds: Int
    var dayResetHour: Int
    var dayResetMinute: Int
    var hotkeyEnabled: Bool

    init(
        timerMode: TimerMode = .targetTime,
        dailyTargetSeconds: Int = 3 * 3600, // 3 hours default
        dayResetHour: Int = 3,
        dayResetMinute: Int = 0,
        hotkeyEnabled: Bool = true
    ) {
        self.timerMode = timerMode
        self.dailyTargetSeconds = dailyTargetSeconds
        self.dayResetHour = dayResetHour
        self.dayResetMinute = dayResetMinute
        self.hotkeyEnabled = hotkeyEnabled
    }

    var dailyTargetFormatted: String {
        let hours = dailyTargetSeconds / 3600
        let minutes = (dailyTargetSeconds % 3600) / 60
        if minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(hours)h"
    }

    var resetTimeFormatted: String {
        String(format: "%d:%02d AM", dayResetHour, dayResetMinute)
    }

    enum CodingKeys: String, CodingKey {
        case timerMode = "timer_mode"
        case dailyTargetSeconds = "daily_target_seconds"
        case dayResetHour = "day_reset_hour"
        case dayResetMinute = "day_reset_minute"
        case hotkeyEnabled = "hotkey_enabled"
    }
}
