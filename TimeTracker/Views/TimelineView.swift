import SwiftUI

struct TimelineView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var expandedSessionId: UUID?
    @State private var editingDescription: String = ""
    @State private var editingRemarks: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header with date navigation
            headerView

            Divider()
                .background(Color.gray.opacity(0.3))

            // Sessions list
            if viewModel.todaySessions.isEmpty {
                emptyStateView
            } else {
                sessionsListView
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // Previous day
            Button(action: navigateToPreviousDay) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.gold)
            }
            .buttonStyle(.plain)

            Spacer()

            // Date and stats
            VStack(spacing: 4) {
                Text(formattedDate)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(summaryText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondaryText)
            }

            Spacer()

            // Next day
            Button(action: navigateToNextDay) {
                Image(systemName: "chevron.right")
                    .foregroundColor(isToday ? .gray.opacity(0.5) : .gold)
            }
            .buttonStyle(.plain)
            .disabled(isToday)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.cardBackground)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: viewModel.selectedDate)
    }

    private var summaryText: String {
        let count = viewModel.todaySessions.count
        let total = viewModel.todaySessions.reduce(0) { $0 + $1.durationSeconds }
        let hours = total / 3600
        let minutes = (total % 3600) / 60

        let sessionWord = count == 1 ? "session" : "sessions"
        if hours > 0 {
            return "\(count) \(sessionWord), \(hours)h \(minutes)m total"
        } else {
            return "\(count) \(sessionWord), \(minutes)m total"
        }
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(viewModel.selectedDate)
    }

    // MARK: - Navigation

    private func navigateToPreviousDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.selectedDate) {
            viewModel.loadSessionsForDate(newDate)
        }
    }

    private func navigateToNextDay() {
        guard !isToday else { return }
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.selectedDate) {
            viewModel.loadSessionsForDate(newDate)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No sessions")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondaryText)

            Text("Start tracking from the menu bar")
                .font(.system(size: 12))
                .foregroundColor(.secondaryText.opacity(0.7))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.darkBackground)
    }

    // MARK: - Sessions List

    private var sessionsListView: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(viewModel.todaySessions) { session in
                    SessionRowView(
                        session: session,
                        isExpanded: expandedSessionId == session.id,
                        editingDescription: $editingDescription,
                        editingRemarks: $editingRemarks,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedSessionId == session.id {
                                    expandedSessionId = nil
                                } else {
                                    expandedSessionId = session.id
                                    editingDescription = session.description
                                    editingRemarks = session.remarks
                                }
                            }
                        },
                        onSave: {
                            var updated = session
                            updated.description = String(editingDescription.prefix(140))
                            updated.remarks = editingRemarks
                            updated.updatedAt = Date()
                            viewModel.updateSession(updated)
                            expandedSessionId = nil
                        },
                        onCancel: {
                            expandedSessionId = nil
                        },
                        onDelete: {
                            viewModel.deleteSession(session)
                            expandedSessionId = nil
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color.darkBackground)
    }
}

// MARK: - Session Row

struct SessionRowView: View {
    let session: Session
    let isExpanded: Bool
    @Binding var editingDescription: String
    @Binding var editingRemarks: String
    let onTap: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                // Time range
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.timeRange)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)

                    Text(session.formattedDuration)
                        .font(.system(size: 11))
                        .foregroundColor(.secondaryText)
                }

                Spacer()

                // Tag pill
                TagPillView(tagName: session.tag)

                // Expand indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            // Expanded content
            if isExpanded {
                expandedContent
            }
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Description
            VStack(alignment: .leading, spacing: 4) {
                Text("Description")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondaryText)

                TextField("Brief summary (140 chars max)", text: $editingDescription)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color.darkBackground)
                    .cornerRadius(6)
            }

            // Remarks
            VStack(alignment: .leading, spacing: 4) {
                Text("Remarks")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondaryText)

                TextEditor(text: $editingRemarks)
                    .font(.system(size: 12))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color.darkBackground)
                    .cornerRadius(6)
                    .frame(minHeight: 60, maxHeight: 120)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button("Save") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .tint(.gold)

                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(Color.cardBackground.opacity(0.8))
    }
}
