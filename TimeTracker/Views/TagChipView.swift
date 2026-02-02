import SwiftUI

struct TagChipView: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag.name)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                .foregroundColor(.white)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct TagPillView: View {
    let tagName: String
    var isLarge: Bool = false
    var style: TagPillStyle = .accent

    enum TagPillStyle {
        case accent      // Gold for dashboard/timeline
        case subtle      // White/translucent for popover
    }

    var body: some View {
        Text(tagName)
            .font(.system(size: isLarge ? 14 : 11, weight: .medium))
            .padding(.horizontal, isLarge ? 14 : 10)
            .padding(.vertical, isLarge ? 6 : 4)
            .background(pillBackground)
            .foregroundColor(pillForeground)
            .cornerRadius(isLarge ? 14 : 10)
    }

    private var pillBackground: Color {
        switch style {
        case .accent:
            return .gold
        case .subtle:
            return .white.opacity(0.2)
        }
    }

    private var pillForeground: Color {
        switch style {
        case .accent:
            return .black
        case .subtle:
            return .white
        }
    }
}

// MARK: - Color Extension

extension Color {
    static let gold = Color(red: 1.0, green: 215/255, blue: 0)
    static let darkBackground = Color(red: 30/255, green: 30/255, blue: 32/255)
    static let cardBackground = Color(red: 44/255, green: 44/255, blue: 46/255)
    static let secondaryText = Color(red: 142/255, green: 142/255, blue: 147/255)

    // Translucent button colors for popover
    static let popoverButton = Color.white.opacity(0.15)
    static let popoverButtonEnd = Color.red.opacity(0.25)
}
