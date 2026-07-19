import SwiftUI

/// The three reader papers. The rest of the app stays on the light Paper surface;
/// only the Reader (and later the boot screen) go dark.
enum ReadingTheme: String, CaseIterable, Codable, Identifiable {
    case paper
    case sepia
    case night

    var id: String { rawValue }

    var background: Color {
        switch self {
        case .paper: ShelfPalette.readerPaper
        case .sepia: ShelfPalette.sepia
        case .night: ShelfPalette.night
        }
    }

    var ink: Color {
        switch self {
        case .paper: ShelfPalette.ink
        case .sepia: Color(hex: 0x3B3127)
        case .night: Color(hex: 0xE7E2D9)
        }
    }

    var meta: Color {
        switch self {
        case .paper, .night: ShelfPalette.graphite
        case .sepia: Color(hex: 0x8F8371)
        }
    }

    var barBackground: Color { background.opacity(0.94) }

    var rule: Color {
        switch self {
        case .paper: ShelfPalette.ink.opacity(0.14)
        case .sepia: Color(hex: 0x3B3127).opacity(0.16)
        case .night: Color(hex: 0xE7E2D9).opacity(0.16)
        }
    }

    var isDark: Bool { self == .night }

    var label: String {
        switch self {
        case .paper: "paper"
        case .sepia: "sepia"
        case .night: "night"
        }
    }
}
