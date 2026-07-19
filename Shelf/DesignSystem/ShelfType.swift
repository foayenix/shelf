import SwiftUI
import UIKit

/// The three faces from the token sheet. Font names vary between the family name
/// and the PostScript name depending on how iOS registers the file, so each face
/// resolves against a candidate list once at startup.
enum ShelfFont {
    private static func resolve(_ candidates: [String]) -> String {
        for name in candidates where UIFont(name: name, size: 12) != nil {
            return name
        }
        assertionFailure("None of \(candidates) resolved — check UIAppFonts and bundle resources")
        return candidates[0]
    }

    /// Resolved names are exposed for MarkdownUI's FontFamily, which needs the
    /// string rather than a SwiftUI Font.
    static let displayName = resolve(["InstrumentSerif-Regular", "Instrument Serif"])
    static let readingName = resolve(["Literata", "Literata-Regular"])
    static let monoName = resolve(["IBMPlexMono", "IBM Plex Mono", "IBMPlexMono-Regular"])
    static let monoMediumName = resolve(["IBMPlexMono-Medium", "IBM Plex Mono Medium"])

    /// Instrument Serif — screen titles, shelf names, reader titles.
    static func display(_ size: CGFloat) -> Font { .custom(displayName, size: size) }
    /// Literata — reading body and all UI text. No sans anywhere.
    static func reading(_ size: CGFloat) -> Font { .custom(readingName, size: size) }
    /// IBM Plex Mono — dates, counts, metadata.
    static func mono(_ size: CGFloat) -> Font { .custom(monoName, size: size) }
    static func monoMedium(_ size: CGFloat) -> Font { .custom(monoMediumName, size: size) }
}

/// Uppercase Plex Mono metadata line — the "9–11pt caps, tracked" token.
struct MetaCapsStyle: ViewModifier {
    var size: CGFloat = 10
    var color: Color = ShelfPalette.graphite

    func body(content: Content) -> some View {
        content
            .font(ShelfFont.mono(size))
            .textCase(.uppercase)
            .kerning(1.2)
            .foregroundStyle(color)
    }
}

extension View {
    func metaCaps(size: CGFloat = 10, color: Color = ShelfPalette.graphite) -> some View {
        modifier(MetaCapsStyle(size: size, color: color))
    }
}
