import Foundation
import Observation

/// User preferences, persisted in UserDefaults. `shelf_onboarded` follows the
/// LazyLab `lazylab_onboarded` flag pattern from the brief.
@Observable
final class AppSettings {
    private typealias Key = ShelfEnvironment.Key

    static let fontSizeRange: ClosedRange<Double> = 17...23

    private let defaults: UserDefaults

    var onboarded: Bool { didSet { defaults.set(onboarded, forKey: Key.onboarded) } }
    var libraryName: String { didSet { defaults.set(libraryName, forKey: Key.libraryName) } }
    var defaultTheme: ReadingTheme { didSet { defaults.set(defaultTheme.rawValue, forKey: Key.theme) } }
    var readerFontSize: Double {
        didSet {
            readerFontSize = readerFontSize.clamped(to: Self.fontSizeRange)
            defaults.set(readerFontSize, forKey: Key.fontSize)
        }
    }
    /// Capture defaults to the last shelf the user saved to (brief §5).
    var lastUsedCollectionId: UUID? {
        didSet { defaults.set(lastUsedCollectionId?.uuidString, forKey: Key.lastCollection) }
    }
    var iCloudEnabled: Bool { didSet { defaults.set(iCloudEnabled, forKey: Key.iCloud) } }

    init(defaults: UserDefaults = ShelfEnvironment.sharedDefaults) {
        self.defaults = defaults
        onboarded = defaults.bool(forKey: Key.onboarded)
        libraryName = defaults.string(forKey: Key.libraryName) ?? "My library"
        defaultTheme = ReadingTheme(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .paper
        let size = defaults.double(forKey: Key.fontSize)
        readerFontSize = size == 0 ? 19 : size.clamped(to: Self.fontSizeRange)
        lastUsedCollectionId = defaults.string(forKey: Key.lastCollection).flatMap(UUID.init)
        iCloudEnabled = defaults.bool(forKey: Key.iCloud)
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
