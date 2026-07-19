import Foundation
import SwiftUI
import UIKit
import ShelfKit

/// Export-all: zips the Shelf folder (index.json + notes/*.md) for the share
/// sheet. Uses NSFileCoordinator's `.forUploading`, which produces a zip without
/// any archive dependency.
enum ShelfExporter {
    static func exportZip(of paths: ShelfPaths) throws -> URL {
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var result: Result<URL, Error> = .failure(CocoaError(.fileNoSuchFile))

        coordinator.coordinate(
            readingItemAt: paths.shelfDirectory,
            options: .forUploading,
            error: &coordinationError
        ) { zippedURL in
            let stamp = Date().formatted(.iso8601.year().month().day())
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("Shelf-\(stamp).zip")
            do {
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.copyItem(at: zippedURL, to: destination)
                result = .success(destination)
            } catch {
                result = .failure(error)
            }
        }

        if let coordinationError { throw coordinationError }
        return try result.get()
    }
}

/// UIActivityViewController wrapper for presenting the zip in a share sheet.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
