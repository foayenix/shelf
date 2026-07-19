import Foundation
import XCTest
@testable import ShelfKit

/// Every test gets a fresh temp-directory shelf, mirroring how the app injects the
/// App Group container.
class ShelfKitTestCase: XCTestCase {
    var root: URL!
    var paths: ShelfPaths!
    var store: ShelfStore!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ShelfKitTests-\(UUID().uuidString)", isDirectory: true)
        paths = ShelfPaths(root: root)
        store = try ShelfStore(paths: paths)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    /// A second store on the same root — simulates the share extension process.
    func freshStore() throws -> ShelfStore {
        try ShelfStore(paths: paths)
    }
}

let sampleMarkdown = """
# A short history of the semicolon

The semicolon was born in Venice in 1494, in the print shop of **Aldus Manutius**.

- It sat between the comma and the colon.
- Nobody agreed on what it was for.

```swift
let mark = ";"
```

> It holds two ideas at arm's length and insists they look at each other.
"""
