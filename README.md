# Shelf

A personal reading library for saved Claude responses, by LazyLab. Save what's
worth keeping, read it later like a book — fully offline.

- Notes are plain `.md` files plus one `index.json`; readable by any tool, no
  database. See `docs/shelf-mvp-brief.md`. The `.md` files are the source of
  truth: an index that can't be read is set aside as `index-corrupt-<stamp>.json`
  and rebuilt from them, so nothing is overwritten on the way to recovery.
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

**iCloud mirror** (optional, off by default): add the *iCloud Documents*
capability to the Shelf target in Signing & Capabilities (requires a paid
developer account), then flip the toggle in Settings. The mirror is file-based —
the Shelf folder copied to iCloud Drive, newest file wins — with no CloudKit
schema. The toggle stays disabled when the capability or an iCloud account is
missing.

## Shipping to the App Store

In the repo, and checked on every build by the *App Store requirements* CI step:

- **App icon** — `Shelf/Resources/Assets.xcassets/AppIcon.appiconset`, a single
  1024×1024 with no alpha. Regenerate with `tools/make-icon.py`.
- **Privacy manifests** — `Shelf/Resources/PrivacyInfo.xcprivacy` and
  `ShareExtension/PrivacyInfo.xcprivacy`, declaring the two required-reason APIs
  Shelf touches: UserDefaults (`CA92.1`, `1C8F.1`) and file timestamps (`C617.1`).
  Nothing is collected and nothing is tracked.
- **Versions** — both targets take `CFBundleShortVersionString` /
  `CFBundleVersion` from `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in
  `project.yml`. Bump them there; the app and extension must never disagree.
- **Export compliance** — `ITSAppUsesNonExemptEncryption: false`.

What still needs a human, none of which lives in the repo:

1. A paid Apple Developer account, with `com.lazylab.shelf` and the App Group
   `group.com.lazylab.shelf` registered to your team, and the team set on both
   targets.
2. In App Store Connect: name, subtitle, description, keywords, age rating,
   screenshots for the required iPhone sizes, and a support URL.
3. A **privacy policy URL** — required for every app, even one that collects
   nothing. Answer the privacy questionnaire as *Data Not Collected*.
4. Archive against a real device destination (`xcodebuild archive` or Xcode →
   Product → Archive) and upload. The CI job builds for the simulator and does
   not sign, so it proves the bundle is well-formed, not that it is signable.

## CI

- `ShelfKit tests` — `swift test` on Linux in the `swift:6.1` container.
- `App build` — XcodeGen + `xcodebuild` for iOS Simulator on a macOS runner,
  then an App Store preflight over the built bundle: icon wired up
  (`CFBundleIconName`), both privacy manifests present, app and extension
  versions matching `project.yml`.
