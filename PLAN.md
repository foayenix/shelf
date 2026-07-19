# Shelf — Phase 0 Plan

File map + every type and view, per the brief (`docs/shelf-mvp-brief.md`) and the design
handoff (`docs/design-tokens.md`). **Gate: no code until this plan is approved.**

## Architecture in one paragraph

All storage and capture logic lives in **ShelfKit**, a local Swift package with no UI
and no app-only dependencies. The app target, the Share Extension target, and the test
suite all import it. This keeps the extension thin (brief §5), makes Phase 1 fully
unit-testable (`swift test` runs without a simulator, so the storage gate can be
demonstrated before any Xcode work), and enforces the "files + JSON only" rule in one
place. The app is pure SwiftUI on top: an `@Observable` `LibraryModel` wraps the
ShelfKit store and feeds the views. Data is canonical in the App Group container so the
extension can write directly; iCloud mirroring is layered on in Phase 4.

## File map

```
shelf/
├── PLAN.md                                  ← this file
├── README.md                                — one-pager: what Shelf is, how to build
├── project.yml                              — XcodeGen spec: Shelf app + ShareExtension
│                                              targets, App Group, iCloud entitlements
├── docs/
│   ├── shelf-mvp-brief.md                   — the brief (committed for reference)
│   └── design-tokens.md                     — extracted design handoff
│
├── ShelfKit/                                — local SPM package (logic, no UI)
│   ├── Package.swift
│   ├── Sources/ShelfKit/
│   │   ├── Note.swift                       — Note struct + NoteSource enum
│   │   ├── NoteCollection.swift             — collection struct + Inbox constant
│   │   ├── ShelfIndex.swift                 — index.json document (schemaVersion,
│   │   │                                      notes, collections)
│   │   ├── ShelfPaths.swift                 — resolves Shelf/, notes/, index.json
│   │   │                                      under an injectable root URL
│   │   ├── ShelfStore.swift                 — CRUD: save/load/edit/delete notes &
│   │   │                                      collections, atomic index writes,
│   │   │                                      NSFileCoordinator around index.json,
│   │   │                                      index rebuild from .md files on corruption
│   │   ├── CaptureProcessor.swift           — capture pipeline: empty-text rejection,
│   │   │                                      >100k truncation (with flag), URL→one-line
│   │   │                                      note, title detection, word count
│   │   ├── TitleDetector.swift              — first heading, else first 8 words
│   │   ├── WordCount.swift                  — word counting + 200 wpm reading time
│   │   └── ShelfStoreError.swift            — typed errors
│   └── Tests/ShelfKitTests/
│       ├── ShelfStoreTests.swift            — save/load/edit/delete round-trips,
│       │                                      atomicity, index rebuild
│       ├── CaptureProcessorTests.swift      — empty, truncation, URL, markdown intact
│       ├── TitleDetectorTests.swift
│       ├── WordCountTests.swift
│       └── CollectionTests.swift            — CRUD, delete→notes fall back to Inbox
│
├── Shelf/                                   — app target (SwiftUI, iOS 17)
│   ├── App/
│   │   ├── ShelfApp.swift                   — @main; builds LibraryModel + AppSettings
│   │   └── RootView.swift                   — routes boot → onboarding → Bookshelf
│   │                                          (returns straight to Bookshelf when
│   │                                          `shelf_onboarded` is set)
│   ├── Model/
│   │   ├── LibraryModel.swift               — @Observable wrapper over ShelfStore:
│   │   │                                      published notes/collections, search,
│   │   │                                      reload on foreground/darwin notify
│   │   ├── AppSettings.swift                — UserDefaults (App Group): onboarded flag,
│   │   │                                      library name, default theme & text size,
│   │   │                                      iCloud toggle, last-used collection
│   │   └── ReadingProgressStore.swift       — per-note scroll position + read state
│   │                                          (UserDefaults, device-local; not in
│   │                                          index.json — see open question 5)
│   ├── DesignSystem/
│   │   ├── ShelfPalette.swift               — Ink/Paper/Sepia/Night/Graphite/Ember
│   │   ├── ShelfType.swift                  — font helpers + type scale per tokens
│   │   ├── ReadingTheme.swift               — paper/sepia/night colour sets
│   │   └── Spacing.swift                    — 4/8/12/16/24/32/48 + radii
│   ├── Features/
│   │   ├── Boot/
│   │   │   ├── BootView.swift               — retro boot: log lines, progress blocks
│   │   │   └── PandaPixelView.swift         — pixel-grid panda (shared w/ empty state)
│   │   ├── Onboarding/
│   │   │   └── OnboardingView.swift         — name library + pick paper, one screen
│   │   ├── Bookshelf/
│   │   │   ├── BookshelfView.swift          — home: header, continue card, shelf rows,
│   │   │   │                                  Ember FAB, search entry
│   │   │   ├── ShelfRowView.swift           — collection name + meta + spine row
│   │   │   ├── BookSpineView.swift          — the signature spine (width ≈ wc/85)
│   │   │   └── ContinueReadingCard.swift    — last-open note + progress hairline
│   │   ├── Collection/
│   │   │   ├── CollectionDetailView.swift   — note list for one collection
│   │   │   └── NoteRowView.swift            — title, italic preview, mono meta
│   │   ├── Reader/
│   │   │   ├── ReaderView.swift             — hero screen: markdown body, tap-to-toggle
│   │   │   │                                  chrome, scroll position restore
│   │   │   ├── ReaderTopBar.swift           — back, collection, position
│   │   │   ├── ReaderControlsBar.swift      — Aa−/Aa+, theme dots, progress pill
│   │   │   └── MarkdownBodyView.swift       — swift-markdown-ui wrapped + themed
│   │   ├── Capture/
│   │   │   ├── CaptureSheetView.swift       — paste → title → shelf chips → save
│   │   │   └── CollectionChipsView.swift    — picker chips incl. "+ new" (shared
│   │   │                                      with the Share Extension UI)
│   │   ├── Search/
│   │   │   └── SearchView.swift             — all-notes search (Phase 4)
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift           — theme, text size, iCloud, export-all
│   │   │   └── AboutView.swift              — wordmark + "We make things for human use."
│   │   └── Shared/
│   │       └── EmptyShelfView.swift         — panda tile + "Nothing on this shelf."
│   ├── Sync/
│   │   └── CloudMirror.swift                — Phase 4: mirror App Group Shelf/ ↔
│   │                                          ubiquity container, newest-wins by
│   │                                          updatedAt, NSFileCoordinator
│   ├── Export/
│   │   └── ShelfExporter.swift              — Phase 4: zip Shelf/ for share sheet
│   └── Resources/
│       ├── Fonts/                           — Literata, Instrument Serif, IBM Plex Mono
│       ├── Assets.xcassets                  — colours, app icon
│       ├── Info.plist
│       └── Shelf.entitlements               — App Group + iCloud Documents
│
└── ShareExtension/                          — Phase 3 target
    ├── ShareViewController.swift            — UIHostingController shell; reads
    │                                          NSExtensionItem (text or URL)
    ├── ShareCaptureView.swift               — minimal sheet: title, collection, Save;
    │                                          uses ShelfKit CaptureProcessor+ShelfStore
    ├── Info.plist                           — NSExtensionActivationRule: text + URL
    └── ShareExtension.entitlements          — same App Group
```

## Every type (non-view)

| Type | Kind | Home | Notes |
|---|---|---|---|
| `Note` | struct, Codable | ShelfKit | id, title, collectionId?, createdAt, updatedAt, source, favourite, wordCount; body handled as file content, not in index |
| `NoteSource` | enum, Codable | ShelfKit | `shareExtension` / `paste` / `import` |
| `NoteCollection` | struct, Codable | ShelfKit | id, name, emoji?, sortOrder ("Collection" clashes with stdlib) |
| `ShelfIndex` | struct, Codable | ShelfKit | schemaVersion, notes, collections |
| `ShelfPaths` | struct | ShelfKit | injectable root → testable with temp dirs |
| `ShelfStore` | final class | ShelfKit | all file + index I/O; the only writer |
| `CaptureProcessor` | struct | ShelfKit | raw input → validated draft note |
| `TitleDetector` | enum (static) | ShelfKit | first `#` heading, else first 8 words |
| `WordCount` | enum (static) | ShelfKit | count + reading time (200 wpm) |
| `ShelfStoreError` | enum, Error | ShelfKit | notFound, corruptIndex, io, emptyCapture… |
| `LibraryModel` | @Observable class | app | UI-facing state over ShelfStore |
| `AppSettings` | @Observable class | app | App Group UserDefaults wrapper |
| `ReadingProgressStore` | struct | app | scroll offset + last-read per note id |
| `ReadingTheme` | enum | app | paper / sepia / night colour sets |
| `ShelfPalette`, `ShelfType`, `Spacing` | enums (static tokens) | app | design tokens |
| `CloudMirror` | class | app (Phase 4) | ubiquity mirroring |
| `ShelfExporter` | struct | app (Phase 4) | zip export |

## Every view

`RootView`, `BootView`, `PandaPixelView`, `OnboardingView`, `BookshelfView`,
`ShelfRowView`, `BookSpineView`, `ContinueReadingCard`, `CollectionDetailView`,
`NoteRowView`, `ReaderView`, `ReaderTopBar`, `ReaderControlsBar`, `MarkdownBodyView`,
`CaptureSheetView`, `CollectionChipsView`, `SearchView`, `SettingsView`, `AboutView`,
`EmptyShelfView`, `ShareCaptureView` (+ `ShareViewController` shell in the extension).

## Storage & concurrency decisions

- **Canonical data location: App Group container** `group.<bundle-id>/Shelf/` — both app
  and extension read/write it directly, matching brief §5. `ShelfPaths` takes the root
  as a parameter so tests use temp directories.
- **index.json integrity**: writes are atomic (temp file + replace) and wrapped in
  `NSFileCoordinator` so app and extension never clobber each other. The extension posts
  a darwin notification after saving; the app reloads the index on receipt and on
  foreground. If index.json is missing/corrupt, `ShelfStore` rebuilds it by scanning
  `notes/*.md` (titles re-detected, collections default to Inbox) — the .md files stay
  the source of truth, per the brief's portability rationale.
- **Inbox** is a virtual collection (`collectionId == nil`), pinned first — no stored
  collection row, nothing to rename or delete.
- **iCloud (Phase 4)**: toggle mirrors `Shelf/` to the ubiquity Documents container,
  newest-wins by `updatedAt`. File-based only, no CloudKit, per the brief.

## Phase mapping (unchanged from brief)

- **Phase 1**: ShelfKit package + full test suite. Tests run headless via `swift test`
  — the gate demo is the passing suite.
- **Phase 2**: DesignSystem + Bookshelf, Collection, Reader, Capture sheet, RootView
  (onboarding stubbed to a flag), swift-markdown-ui dependency. Gate: on-device review.
- **Phase 3**: XcodeGen project gains the ShareExtension target + App Group; capture
  flow. Gate: live capture from the Claude app.
- **Phase 4**: Boot animation, OnboardingView, themes polish, SearchView, CloudMirror,
  ShelfExporter, empty states.

## Open questions for the gate

1. **Fonts** — brief says system New York; the design handoff specifies Literata +
   Instrument Serif + IBM Plex Mono (all OFL, bundleable). Recommendation: follow the
   design and bundle the three faces.
2. **Xcode project** — recommendation: XcodeGen (`project.yml` committed; you run
   `xcodegen` once locally — `brew install xcodegen`). Alternative: I hand-maintain a
   `.pbxproj`, which works without tooling but is uglier to diff and riskier to edit.
3. **Bundle IDs** — proposing `com.lazylab.shelf`, extension
   `com.lazylab.shelf.share-extension`, App Group `group.com.lazylab.shelf`. Confirm
   prefix/team.
4. **"Continue reading" card** — in the mockups but not the brief. Recommendation:
   include in Phase 2 (cheap: last-opened note + progress).
5. **Scroll position storage** — brief keeps the `index.json` schema minimal, so I plan
   to store per-note scroll position in device-local UserDefaults rather than adding a
   field to the index. Confirm.
