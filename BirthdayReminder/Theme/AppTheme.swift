import SwiftUI

enum AppTheme {
    static let background  = Color(hex: "F5F4F0")
    static let surface     = Color.white
    static let primary     = Color(hex: "1A1A1A")
    static let secondary   = Color(hex: "8A8A8A")
    static let accent      = Color(hex: "6B8F71")
    static let divider     = Color(hex: "E8E6E1")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

extension Color {
    static func avatar(_ color: AvatarColor) -> Color {
        Color(hex: color.rawValue)
    }
}

// MARK: - Reusable section header style
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(AppTheme.secondary)
            .textCase(.uppercase)
            .tracking(1.2)
    }
}

// MARK: - Avatar view
struct AvatarView: View {
    let friend: Friend
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.avatar(friend.avatarColor))
                .frame(width: size, height: size)
            Text(friend.initials)
                .font(.system(size: size * 0.35, weight: .medium))
                .foregroundColor(.white)
        }
    }
}
