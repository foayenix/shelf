import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Token palette from docs/design-tokens.md. Ember is an accent only — touchable
/// elements and unread marks, never a surface fill.
enum ShelfPalette {
    static let ink = Color(hex: 0x241F19)
    static let paper = Color(hex: 0xFAF9F7)
    static let readerPaper = Color(hex: 0xFBF9F6)
    static let sepia = Color(hex: 0xF1E8D8)
    static let night = Color(hex: 0x1B1A18)
    static let boot = Color(hex: 0x141210)
    static let graphite = Color(hex: 0x8B857B)
    static let ember = Color(hex: 0xE8752C)
    static let faintGraphite = Color(hex: 0xB4AFA6)

    /// Book-spine neutrals, cycled per shelf position; unread spines use Ember.
    static let spineColors: [Color] = [
        Color(hex: 0x241F19), Color(hex: 0x5A544B),
        Color(hex: 0x7A736A), Color(hex: 0x38332D),
    ]
    static let spineLabel = Color(hex: 0xEDE8DF)
    static let spineLabelUnread = Color(hex: 0xFFF3EA)

    static let hairline = ink.opacity(0.10)
    static let cardBorder = ink.opacity(0.09)
}
