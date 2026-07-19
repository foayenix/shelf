import SwiftUI

/// The LazyLab panda as a 12×10 pixel grid, from the design handoff. Used on the
/// empty state now and the boot screen in Phase 4.
struct PandaPixelView: View {
    var cellSize: CGFloat = 6

    private static let map = [
        ".BB......BB.",
        "BBBB....BBBB",
        "BBWWWWWWWWBB",
        ".WWWWWWWWWW.",
        "WWWWWWWWWWWW",
        "WWEEWWWWEEWW",
        "WWEEWWWWEEWW",
        "WWWWWNNWWWWW",
        ".WWWWWWWWWW.",
        "..WWWWWWWW..",
    ]

    private func color(for character: Character) -> Color? {
        switch character {
        case "W": Color(hex: 0xF2EDE4)
        case "B": Color(hex: 0x4A443A)
        case "E", "N": ShelfPalette.boot
        default: nil
        }
    }

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(Array(Self.map.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, character in
                        Rectangle()
                            .fill(color(for: character) ?? .clear)
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}
