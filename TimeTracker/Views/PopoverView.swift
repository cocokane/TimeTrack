import SwiftUI

struct PopoverView: View {
    @ObservedObject var viewModel: TimerViewModel
    @FocusState private var isTagFieldFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            switch viewModel.timerState {
            case .idle:
                idleView
            case .running:
                runningView
            case .paused:
                pausedView
            }

            Divider()
                .background(Color.gray.opacity(0.3))

            Button("Open Dashboard") {
                viewModel.showingDashboard = true
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.plain)
            .foregroundColor(.gold)
            .font(.system(size: 12, weight: .medium))
        }
        .padding(16)
        .frame(width: 280)
        .background(Color.darkBackground)
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: 12) {
            Text("Start a session")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            // Tag chips
            if !viewModel.recentTags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.filteredTags.prefix(8)) { tag in
                        TagChipView(tag: tag, isSelected: false) {
                            viewModel.startSession(with: tag.name)
                        }
                    }
                }
            }

            // Tag input field
            HStack {
                TextField("Enter tag...", text: $viewModel.tagInput)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color.cardBackground)
                    .cornerRadius(8)
                    .focused($isTagFieldFocused)
                    .onSubmit {
                        if !viewModel.tagInput.isEmpty {
                            viewModel.startSession(with: viewModel.tagInput)
                        }
                    }
            }
        }
    }

    // MARK: - Running View

    private var runningView: some View {
        VStack(spacing: 16) {
            // Current tag
            if let session = viewModel.currentSession {
                TagPillView(tagName: session.tag, isLarge: true)
            }

            // Elapsed time
            Text(viewModel.formatSessionTime(viewModel.currentSessionElapsed))
                .font(.system(size: 32, weight: .light, design: .monospaced))
                .foregroundColor(.white)

            // Action buttons
            HStack(spacing: 12) {
                ActionButton(title: "Pause", color: .orange) {
                    viewModel.pauseSession()
                }

                ActionButton(title: "End", color: .red) {
                    viewModel.endSession()
                    viewModel.showingDashboard = true
                }

                ActionButton(title: "Switch", color: .blue) {
                    viewModel.switchTask()
                }
            }
        }
    }

    // MARK: - Paused View

    private var pausedView: some View {
        VStack(spacing: 16) {
            // Paused indicator
            HStack(spacing: 8) {
                Image(systemName: "pause.circle.fill")
                    .foregroundColor(.orange)
                Text("Paused")
                    .foregroundColor(.orange)
                    .font(.system(size: 14, weight: .semibold))
            }

            // Current tag
            if let session = viewModel.currentSession {
                TagPillView(tagName: session.tag, isLarge: true)
            }

            // Elapsed time (frozen)
            Text(viewModel.formatSessionTime(viewModel.currentSessionElapsed))
                .font(.system(size: 32, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))

            // Action buttons
            HStack(spacing: 12) {
                ActionButton(title: "Resume", color: .green) {
                    viewModel.resumeSession()
                }

                ActionButton(title: "End", color: .red) {
                    viewModel.endSession()
                    viewModel.showingDashboard = true
                }

                ActionButton(title: "Switch", color: .blue) {
                    viewModel.switchTask()
                }
            }
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(color.opacity(0.8))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.width ?? 0,
            spacing: spacing,
            subviews: subviews
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            spacing: spacing,
            subviews: subviews
        )

        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: point, proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
