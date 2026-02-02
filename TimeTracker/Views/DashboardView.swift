import SwiftUI

enum DashboardTab: String, CaseIterable {
    case timeline = "Timeline"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .timeline:
            return "clock"
        case .settings:
            return "gearshape"
        }
    }
}

struct DashboardView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var selectedTab: DashboardTab = .timeline

    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailView
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(Color.darkBackground)
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(spacing: 0) {
            // App title
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.gold)
                Text("Time Tracker")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 20)

            Divider()
                .background(Color.gray.opacity(0.3))

            // Tabs
            VStack(spacing: 4) {
                ForEach(DashboardTab.allCases, id: \.self) { tab in
                    sidebarButton(for: tab)
                }
            }
            .padding(.top, 12)

            Spacer()

            // Current session with controls
            if viewModel.timerState != .idle, let session = viewModel.currentSession {
                currentSessionView(session: session)
            }

            // Daily progress
            dailyProgressView
        }
        .frame(width: 200)
        .background(Color.cardBackground)
    }

    private func sidebarButton(for tab: DashboardTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .frame(width: 20)
                Text(tab.rawValue)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(selectedTab == tab ? Color.gold.opacity(0.2) : Color.clear)
            .foregroundColor(selectedTab == tab ? .gold : .white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    // MARK: - Current Session View with Controls

    private func currentSessionView(session: Session) -> some View {
        VStack(spacing: 10) {
            Divider()
                .background(Color.gray.opacity(0.3))

            // Status indicator
            HStack {
                Circle()
                    .fill(viewModel.timerState == .paused ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)

                Text(viewModel.timerState == .paused ? "Paused" : "Working")
                    .font(.system(size: 11))
                    .foregroundColor(.secondaryText)
            }

            // Tag
            TagPillView(tagName: session.tag)

            // Timer
            Text(viewModel.formatSessionTime(viewModel.currentSessionElapsed))
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.white)

            // Control buttons
            HStack(spacing: 6) {
                if viewModel.timerState == .paused {
                    SidebarControlButton(title: "Resume", color: .green) {
                        viewModel.resumeSession()
                    }
                } else {
                    SidebarControlButton(title: "Pause", color: .orange) {
                        viewModel.pauseSession()
                    }
                }

                SidebarControlButton(title: "End", color: .red) {
                    viewModel.endSession()
                }

                SidebarControlButton(title: "Switch", color: .blue) {
                    viewModel.switchTask()
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 12)
    }

    private var dailyProgressView: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.gray.opacity(0.3))

            VStack(spacing: 4) {
                Text("Today")
                    .font(.system(size: 11))
                    .foregroundColor(.secondaryText)

                if viewModel.settings.timerMode == .targetTime {
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                            .frame(width: 50, height: 50)

                        Circle()
                            .trim(from: 0, to: progressAmount)
                            .stroke(viewModel.targetReached ? Color.gold : Color.blue, lineWidth: 4)
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))

                        if viewModel.targetReached {
                            Text("✓")
                                .font(.system(size: 20))
                                .foregroundColor(.gold)
                        } else {
                            Text(formatShortTime(viewModel.remainingSeconds))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    Text(formatShortTime(viewModel.todayTotalSeconds))
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 12)
        }
    }

    private var progressAmount: CGFloat {
        let progress = CGFloat(viewModel.todayTotalSeconds) / CGFloat(viewModel.settings.dailyTargetSeconds)
        return min(progress, 1.0)
    }

    private func formatShortTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }

    // MARK: - Detail View

    private var detailView: some View {
        Group {
            switch selectedTab {
            case .timeline:
                TimelineView(viewModel: viewModel)
            case .settings:
                SettingsView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sidebar Control Button

struct SidebarControlButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(color.opacity(0.7))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
