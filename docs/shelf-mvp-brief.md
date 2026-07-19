# LazyLab — "Shelf" MVP Brief
*Working title. A personal reading library for saved Claude responses. Save what's worth keeping, read it later like a book — fully offline.*

**Hand this file to Claude Code. Read the whole brief before writing any code.**

---

## 1. Product summary

- iOS app (SwiftUI) + Share Extension.
- User captures Claude responses via the iOS share sheet or in-app paste.
- Saved responses become **Notes**, grouped into **Collections** (like chapters on a bookshelf).
- Reading experience is the core of the product: rendered markdown, book-quality typography, zero network dependency.
- All data is local, stored as plain `.md` files with a small metadata index. iCloud Drive sync via the app's documents container.

**Not building:** accounts, backend, API calls to Anthropic, Android, web. No analytics.

---

## 2. Tech decisions (fixed — do not deviate)

| Area | Decision |
|---|---|
| UI | SwiftUI, iOS 17+ |
| Capture | Share Extension (accepts plain text / markdown) + in-app paste |
| Storage | Plain `.md` files in app documents dir, one file per note |
| Metadata | Single `index.json` (id, title, collection, createdAt, source, wordCount, favourite) |
| Sync | iCloud Documents (ubiquity container) — file-based, no CloudKit schema |
| Markdown rendering | `swift-markdown-ui` (or AttributedString if it proves insufficient — flag before switching) |
| Persistence framework | None. No Core Data, no SwiftData. Files + JSON only. |

Rationale: portable, inspectable, survives the app being abandoned. The `.md` files must be readable by any other tool.

---

## 3. Data model

**Note** (one `.md` file + one index entry)
- `id` — UUID, also the filename (`{id}.md`)
- `title` — user-editable; default = first heading or first 8 words
- `body` — raw markdown, exactly as captured
- `collectionId` — nullable (uncategorised → "Inbox")
- `createdAt`, `updatedAt`
- `source` — enum: `shareExtension | paste | import`
- `favourite` — bool
- `wordCount` — computed on save

**Collection**
- `id`, `name`, `emoji` (optional), `sortOrder`

File layout:
```
Documents/
  Shelf/
    index.json
    notes/{uuid}.md
```

---

## 4. Screens

1. **Bookshelf (home)** — collections as shelf rows; "Inbox" pinned top. Word count + note count per collection. Search across all notes.
2. **Collection view** — note list: title, first line preview, date, reading-time estimate (200 wpm).
3. **Reader** — the hero screen. Rendered markdown. Serif type (New York), 1.5 line height, comfortable margins, adjustable text size, light/dark/sepia. Scroll position remembered per note. No chrome while reading — tap to toggle bars.
4. **Capture sheet** (in-app paste) — paste box → auto-title → pick collection → save. Three taps max.
5. **Settings** — theme, text size default, iCloud toggle, export-all (zip of the Shelf folder).

---

## 5. Share Extension flow

1. User selects text in the Claude app (or anywhere) → Share → **Save to Shelf**.
2. Extension shows a minimal sheet: detected title (editable), collection picker (defaults to Inbox / last used), Save.
3. Writes the `.md` file + index entry via an App Group container shared with the main app.
4. Confirmation haptic + dismiss. Under 3 seconds end-to-end.

Edge cases to handle: empty text, >100k characters (truncate with warning), extension launched with a URL instead of text (save URL as a one-line note).

---

## 6. LazyLab brand integration

- Primary colour: **#E8752C**. Panda mascot on empty states.
- First launch: retro boot animation → device-setup onboarding (name your library, pick theme) → straight to Bookshelf on return visits. Reuse the existing `lazylab_onboarded`-style flag pattern (UserDefaults, not localStorage).
- Copy style everywhere: short and punchy. No descriptive paragraphs.
- Tagline on about screen: *"We make things for human use."*

---

## 7. Build phases & verification gates

**Do not proceed past a gate without explicit confirmation from Felix.**

- **Phase 0 — Plan.** Produce a file map + list of every type and view you intend to create. ⛔ *Gate: approval before any code.*
- **Phase 1 — Storage layer.** Note/Collection models, file read/write, index.json, unit tests for save/load/edit/delete. ⛔ *Gate: demo tests passing.*
- **Phase 2 — Core UI.** Bookshelf, Collection view, Reader, in-app capture. ⛔ *Gate: run on device, review reading experience.*
- **Phase 3 — Share Extension.** App Group setup, extension target, capture flow. ⛔ *Gate: live capture from the Claude app works.*
- **Phase 4 — Polish.** Onboarding + boot animation, themes, search, iCloud, export.

If any requirement is ambiguous, **stop and ask** — do not guess.

---

## 8. Later (out of scope, don't scaffold for it)

- claude.ai export importer (backfill full history)
- macOS companion (Tauri or Catalyst)
- Tagging, highlights within notes
- App Store release prep
