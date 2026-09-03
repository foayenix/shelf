import Foundation
import UIKit
import ShelfKit

/// File-based iCloud mirror, per the brief: no CloudKit schema, just the Shelf
/// folder copied into the ubiquity container's Documents. Newest file wins by
/// modification date; notes that only exist in the cloud are pulled down and
/// adopted into the index.
///
/// Requires the iCloud Documents capability on the Shelf target (add it in
/// Signing & Capabilities). Without the entitlement or an iCloud account,
/// `isAvailable` is false and everything is a no-op.
enum CloudMirror {
    static var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    /// Scene-phase variant. Held open with a background task assertion — without
    /// one, iOS suspends the app on the way out and the mirror stops mid-copy.
    @MainActor
    static func syncInBackground(paths: ShelfPaths) {
        let application = UIApplication.shared
        let token = BackgroundTaskToken()
        token.identifier = application.beginBackgroundTask(withName: "ShelfCloudMirror") {
            token.end(with: application)
        }
        Task {
            await sync(paths: paths)
            token.end(with: application)
        }
    }

    static func sync(paths: ShelfPaths) async {
        let work = Task.detached(priority: .utility) { () -> Bool in
            guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
                return false
            }
            let cloud = ShelfPaths(
                root: container.appendingPathComponent("Documents", isDirectory: true)
            )
            do {
                return try mirror(local: paths, cloud: cloud)
            } catch {
                return false
            }
        }
        _ = await work.value
    }

    /// Returns true when anything was pulled into the local store.
    private static func mirror(local: ShelfPaths, cloud: ShelfPaths) throws -> Bool {
        let fm = FileManager.default
        try fm.createDirectory(at: cloud.notesDirectory, withIntermediateDirectories: true)

        var pulledSomething = false

        // Pull: cloud notes that are missing locally or newer than the local copy.
        for file in (try? fm.contentsOfDirectory(at: cloud.notesDirectory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? [] {
            if file.lastPathComponent.hasSuffix(".icloud") {
                // Placeholder that hasn't downloaded yet — request it, pick it up next sync.
                try? fm.startDownloadingUbiquitousItem(at: file)
                continue
            }
            guard file.pathExtension == "md" else { continue }
            let localFile = local.notesDirectory.appendingPathComponent(file.lastPathComponent)
            if shouldCopy(from: file, over: localFile) {
                try replace(localFile, withCopyOf: file)
                pulledSomething = true
            }
        }

        if pulledSomething {
            // Own store instance: this runs off the main actor.
            let store = try ShelfStore(paths: local)
            _ = try? store.adoptOrphanNotes()
        }

        // Push: local notes that are missing in the cloud or newer, plus the index.
        for file in (try? fm.contentsOfDirectory(at: local.notesDirectory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        where file.pathExtension == "md" {
            let cloudFile = cloud.notesDirectory.appendingPathComponent(file.lastPathComponent)
            if shouldCopy(from: file, over: cloudFile) {
                try replace(cloudFile, withCopyOf: file)
            }
        }
        if fm.fileExists(atPath: local.indexFile.path) {
            try replace(cloud.indexFile, withCopyOf: local.indexFile)
        }
        return pulledSomething
    }

    /// Copy that is never observable half-written: stage next to the destination,
    /// then swap it in. A plain remove-then-copy leaves a window where the file is
    /// missing or truncated — and on the index, that window is the whole library.
    private static func replace(_ destination: URL, withCopyOf source: URL) throws {
        let fm = FileManager.default
        let staged = destination
            .deletingLastPathComponent()
            .appendingPathComponent(".\(destination.lastPathComponent).\(UUID().uuidString).tmp")
        try? fm.removeItem(at: staged)
        try fm.copyItem(at: source, to: staged)
        do {
            if fm.fileExists(atPath: destination.path) {
                _ = try fm.replaceItemAt(destination, withItemAt: staged)
            } else {
                try fm.moveItem(at: staged, to: destination)
            }
        } catch {
            try? fm.removeItem(at: staged)
            throw error
        }
    }

    private static func shouldCopy(from source: URL, over destination: URL) -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: destination.path) else { return true }
        let sourceDate = (try? source.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        let destinationDate = (try? destination.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        guard let sourceDate, let destinationDate else { return false }
        // One-second slack: cloud round-trips don't preserve exact timestamps.
        return sourceDate.timeIntervalSince(destinationDate) > 1
    }
}

/// Holds the background task id so both the completion and the expiration handler
/// can end it exactly once.
@MainActor
private final class BackgroundTaskToken {
    var identifier: UIBackgroundTaskIdentifier = .invalid

    func end(with application: UIApplication) {
        guard identifier != .invalid else { return }
        application.endBackgroundTask(identifier)
        identifier = .invalid
    }
}
