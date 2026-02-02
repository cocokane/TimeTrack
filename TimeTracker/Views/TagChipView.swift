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
                .background(isSelected ? Color.gold : Color.gray.opacity(0.3))
                .foregroundColor(isSelected ? .black : .white)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct TagPillView: View {
    let tagName: String
    var isLarge: Bool = false

    var body: some View {
        Text(tagName)
            .font(.system(size: isLarge ? 14 : 11, weight: .medium))
            .padding(.horizontal, isLarge ? 14 : 10)
            .padding(.vertical, isLarge ? 6 : 4)
            .background(Color.gold)
            .foregroundColor(.black)
            .cornerRadius(isLarge ? 14 : 10)
    }
}

// MARK: - Color Extension

extension Color {
    static let gold = Color(red: 1.0, green: 215/255, blue: 0)
    static let darkBackground = Color(red: 30/255, green: 30/255, blue: 32/255)
    static let cardBackground = Color(red: 44/255, green: 44/255, blue: 46/255)
    static let secondaryText = Color(red: 142/255, green: 142/255, blue: 147/255)
}
