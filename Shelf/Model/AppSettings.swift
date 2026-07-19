import Foundation
import Observation

/// User preferences, persisted in UserDefaults. `shelf_onboarded` follows the
/// LazyLab `lazylab_onboarded` flag pattern from the brief.
@Observable
final class AppSettings {
    private static let onboardedKey = "shelf_onboarded"
    private static let libraryNameKey = "shelf_library_name"
    private static let themeKey = "shelf_default_theme"
    private static let fontSizeKey = "shelf_reader_font_size"
    private static let lastCollectionKey = "shelf_last_collection"
    private static let iCloudKey = "shelf_icloud_enabled"

    static let fontSizeRange: ClosedRange<Double> = 17...23

    private let defaults: UserDefaults

    var onboarded: Bool { didSet { defaults.set(onboarded, forKey: Self.onboardedKey) } }
    var libraryName: String { didSet { defaults.set(libraryName, forKey: Self.libraryNameKey) } }
    var defaultTheme: ReadingTheme { didSet { defaults.set(defaultTheme.rawValue, forKey: Self.themeKey) } }
    var readerFontSize: Double {
        didSet {
            readerFontSize = readerFontSize.clamped(to: Self.fontSizeRange)
            defaults.set(readerFontSize, forKey: Self.fontSizeKey)
        }
    }
    /// Capture defaults to the last shelf the user saved to (brief §5).
    var lastUsedCollectionId: UUID? {
        didSet { defaults.set(lastUsedCollectionId?.uuidString, forKey: Self.lastCollectionKey) }
    }
    var iCloudEnabled: Bool { didSet { defaults.set(iCloudEnabled, forKey: Self.iCloudKey) } }

    init(defaults: UserDefaults = ShelfEnvironment.sharedDefaults) {
        self.defaults = defaults
        onboarded = defaults.bool(forKey: Self.onboardedKey)
        libraryName = defaults.string(forKey: Self.libraryNameKey) ?? "My library"
        defaultTheme = ReadingTheme(rawValue: defaults.string(forKey: Self.themeKey) ?? "") ?? .paper
        let size = defaults.double(forKey: Self.fontSizeKey)
        readerFontSize = size == 0 ? 19 : size.clamped(to: Self.fontSizeRange)
        lastUsedCollectionId = defaults.string(forKey: Self.lastCollectionKey).flatMap(UUID.init)
        iCloudEnabled = defaults.bool(forKey: Self.iCloudKey)
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
