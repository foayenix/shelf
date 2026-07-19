# Shelf

A personal reading library for saved Claude responses, by LazyLab. Save what's
worth keeping, read it later like a book — fully offline.

- Notes are plain `.md` files plus one `index.json`; readable by any tool, no
  database. See `docs/shelf-mvp-brief.md`.
- `ShelfKit/` holds all storage and capture logic as a Swift package with a
  platform-independent test suite (`swift test --package-path ShelfKit`).
- `Shelf/` is the SwiftUI app (iOS 17+). Design tokens in `docs/design-tokens.md`.

## Building

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen            # produces Shelf.xcodeproj from project.yml
open Shelf.xcodeproj
```

Set your development team on **both** targets (Shelf and ShareExtension) under
Signing & Capabilities the first time you run on device — the App Group
`group.com.lazylab.shelf` is provisioned automatically. Fonts (Literata,
Instrument Serif, IBM Plex Mono — all OFL, licenses alongside the files) are
bundled in `Shelf/Resources/Fonts`.

To test capture: select text in any app (e.g. the Claude app) → Share →
**Save to Shelf**. Notes land in the shared container and appear in the app the
next time it comes to the foreground.

## CI

- `ShelfKit tests` — `swift test` on Linux in the `swift:6.1` container.
- `App build` — XcodeGen + `xcodebuild` for iOS Simulator on a macOS runner.
