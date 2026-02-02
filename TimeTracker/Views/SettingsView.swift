import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var selectedHours: Int = 3
    @State private var selectedMinutes: Int = 0
    @State private var resetHour: Int = 3
    @State private var resetMinute: Int = 0
    @State private var editingTag: Tag?
    @State private var newTagName: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Timer Mode
                settingsSection("Timer Mode") {
                    Picker("Mode", selection: $viewModel.settings.timerMode) {
                        ForEach(TimerMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.settings.timerMode) { _ in
                        viewModel.saveSettings()
                    }
                }

                // Daily Target
                settingsSection("Daily Target") {
                    HStack(spacing: 16) {
                        Picker("Hours", selection: $selectedHours) {
                            ForEach(0..<13) { hour in
                                Text("\(hour)h").tag(hour)
                            }
                        }
                        .frame(width: 80)

                        Picker("Minutes", selection: $selectedMinutes) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text("\(minute)m").tag(minute)
                            }
                        }
                        .frame(width: 80)

                        Spacer()

                        Button("Apply") {
                            viewModel.settings.dailyTargetSeconds = (selectedHours * 3600) + (selectedMinutes * 60)
                            viewModel.saveSettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.gold)
                    }
                }

                // Day Reset Time
                settingsSection("Day Reset Time") {
                    HStack(spacing: 16) {
                        Picker("Hour", selection: $resetHour) {
                            ForEach(0..<24) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .frame(width: 100)

                        Picker("Minute", selection: $resetMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text(String(format: ":%02d", minute)).tag(minute)
                            }
                        }
                        .frame(width: 80)

                        Spacer()

                        Button("Apply") {
                            viewModel.settings.dayResetHour = resetHour
                            viewModel.settings.dayResetMinute = resetMinute
                            viewModel.saveSettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.gold)
                    }

                    Text("Sessions before this time count toward the previous day")
                        .font(.system(size: 11))
                        .foregroundColor(.secondaryText)
                }

                // Global Hotkey
                settingsSection("Global Hotkey") {
                    Toggle("Enable ⌥⌘A to toggle popover", isOn: $viewModel.settings.hotkeyEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: viewModel.settings.hotkeyEnabled) { _ in
                            viewModel.saveSettings()
                            NotificationCenter.default.post(name: .hotkeySettingChanged, object: nil)
                        }
                }

                Divider()
                    .background(Color.gray.opacity(0.3))

                // Tag Management
                settingsSection("Manage Tags") {
                    if viewModel.tags.isEmpty {
                        Text("No tags yet. Create one from the popover.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondaryText)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(viewModel.tags.sorted { $0.lastUsed > $1.lastUsed }) { tag in
                                tagRow(tag)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(Color.darkBackground)
        .onAppear {
            // Initialize pickers with current values
            selectedHours = viewModel.settings.dailyTargetSeconds / 3600
            selectedMinutes = (viewModel.settings.dailyTargetSeconds % 3600) / 60
            resetHour = viewModel.settings.dayResetHour
            resetMinute = viewModel.settings.dayResetMinute
        }
    }

    // MARK: - Helpers

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            content()
        }
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 {
            return "12 AM"
        } else if hour < 12 {
            return "\(hour) AM"
        } else if hour == 12 {
            return "12 PM"
        } else {
            return "\(hour - 12) PM"
        }
    }

    private func tagRow(_ tag: Tag) -> some View {
        HStack {
            if editingTag?.id == tag.id {
                TextField("Tag name", text: $newTagName)
                    .textFieldStyle(.plain)
                    .padding(6)
                    .background(Color.cardBackground)
                    .cornerRadius(6)
                    .onSubmit {
                        viewModel.renameTag(from: tag.name, to: newTagName)
                        editingTag = nil
                    }

                Button("Save") {
                    viewModel.renameTag(from: tag.name, to: newTagName)
                    editingTag = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(.gold)

                Button("Cancel") {
                    editingTag = nil
                }
                .buttonStyle(.bordered)
            } else {
                TagPillView(tagName: tag.name)

                Spacer()

                Button {
                    newTagName = tag.name
                    editingTag = tag
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(.secondaryText)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.deleteTag(tag)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let hotkeySettingChanged = Notification.Name("hotkeySettingChanged")
}
