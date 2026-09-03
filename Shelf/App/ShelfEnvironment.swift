import Foundation
import ShelfKit

/// Where Shelf's data lives. Canonical store is the App Group container so the
/// Share Extension can write directly (brief §5); the documents directory is the
/// fallback when the entitlement is missing (e.g. some CI/simulator setups).
enum ShelfEnvironment {
    static let appGroupId = "group.com.lazylab.shelf"

    /// UserDefaults keys shared between the app and the extension. Both targets
    /// compile this file, so the strings are declared once.
    enum Key {
        static let onboarded = "shelf_onboarded"
        static let libraryName = "shelf_library_name"
        static let theme = "shelf_default_theme"
        static let fontSize = "shelf_reader_font_size"
        static let lastCollection = "shelf_last_collection"
        static let iCloud = "shelf_icloud_enabled"
        static let readingProgress = "shelf_reading_progress"
    }

    /// Shared defaults so the extension sees the last-used shelf.
    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupId) ?? .standard
    }

    /// Which container a store was opened against. Anything but `.appGroup` is a
    /// degraded mode the user needs to be told about: the extension writes to the
    /// group container, and `.temporary` doesn't survive the session at all.
    enum Location: Equatable {
        case appGroup
        case documents
        case temporary
    }

    enum StoreError: Error {
        case sharedContainerUnavailable
    }

    /// Extension-side store: the App Group container or nothing. Falling back to a
    /// container the app can't read would swallow the capture silently, which is
    /// worse than telling the user the save failed.
    static func makeGroupStore() throws -> ShelfStore {
        guard let groupPaths = ShelfPaths.appGroup(id: appGroupId) else {
            throw StoreError.sharedContainerUnavailable
        }
        return try ShelfStore(paths: groupPaths)
    }

    static var documentsPaths: ShelfPaths {
        ShelfPaths(root: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0])
    }

    /// Opens the best container available, in order. Throws only when every
    /// candidate failed — the caller decides what to tell the user.
    static func makeStore() throws -> (store: ShelfStore, location: Location) {
        var candidates: [(ShelfPaths, Location)] = []
        if let groupPaths = ShelfPaths.appGroup(id: appGroupId) {
            // One-time move of any pre-App-Group data; never clobbers existing notes.
            try? ShelfMigrator.migrate(from: documentsPaths, to: groupPaths)
            candidates.append((groupPaths, .appGroup))
        }
        candidates.append((documentsPaths, .documents))
        candidates.append((ShelfPaths(root: FileManager.default.temporaryDirectory
            .appendingPathComponent("ShelfFallback", isDirectory: true)), .temporary))

        var lastError: Error?
        for (paths, location) in candidates {
            do {
                return (try ShelfStore(paths: paths), location)
            } catch let error as ShelfStoreError {
                // The container is fine, the data isn't. Falling through here would
                // hand the user a blank library on top of notes that still exist.
                throw error
            } catch {
                lastError = error
            }
        }
        throw lastError ?? ShelfStoreError.indexUnreadable
    }
}
