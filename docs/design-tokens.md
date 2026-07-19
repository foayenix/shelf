# Shelf — Design tokens (from Claude Design handoff)

Extracted from `Shelf.dc.html` (7-screen mockup set). This is the source of truth for
Phase 2 UI work. Concept line from the handoff:

> A shelf of chapters, not a chat log. The whole UI is set in the reading face; every
> note is drawn as a book spine whose width is its word count; orange appears only
> where you touch.

## Palette

| Token | Hex | Use |
|---|---|---|
| Ink | `#241F19` | text, shelf rules |
| Paper | `#FAF9F7` | app surfaces (`#FBF9F6` reader paper theme) |
| Sepia | `#F1E8D8` | reader sepia theme |
| Night | `#1B1A18` | reader night theme; boot screen bg `#141210` |
| Graphite | `#8B857B` | metadata, secondary text |
| Ember | `#E8752C` | accent **only** — touchable elements, unread marks; never a surface fill |

## Reader themes

| Theme | bg | ink | meta | bar | rule |
|---|---|---|---|---|---|
| paper | `#FBF9F6` | `#241F19` | `#8B857B` | `rgba(251,249,246,0.94)` | `rgba(36,31,25,0.14)` |
| sepia | `#F1E8D8` | `#3B3127` | `#8F8371` | `rgba(241,232,216,0.94)` | `rgba(59,49,39,0.16)` |
| night | `#1B1A18` | `#E7E2D9` | `#8B857B` | `rgba(27,26,24,0.94)` | `rgba(231,226,217,0.16)` |

## Type — 3 faces + wordmark

| Face | Role |
|---|---|
| Instrument Serif | Display — screen titles, collection names, reader title |
| Literata | Reading body + **all UI text** — no sans anywhere |
| IBM Plex Mono | Utility — dates, counts, metadata caps, boot text |
| Caveat (placeholder) | LazyLab wordmark only — replace with hand-drawn asset later |

All three product faces are open-licensed (OFL) and bundleable.
Note: the original brief said system New York — the design supersedes this pending
Felix's confirmation (gate question).

## Type scale (pt)

| pt | Role | Spec |
|---|---|---|
| 38 | Screen title | Instrument Serif 400 · lh 1.1 |
| 31 | Reader title | Instrument Serif 400 · lh 1.15 |
| 23 | Shelf name | Instrument Serif 400 |
| 19 | Reader body | Literata 400 · lh 1.62 · user-adjustable 17–23 |
| 15–17 | UI text, rows | Literata 400–600 |
| 9–11 | Metadata | Plex Mono 400 · caps · letter-spacing 0.1em |

## Spacing & radius

- Spacing scale: 4, 8, 12, 16, 24, 32, 48
- Radius: 12 (cards, swatches) · 24 (sheets, panda tile) · pill (buttons, chips)

## Signature element: the spine

Every note renders as a book spine on the Bookshelf:
- width ≈ `wordCount / 85`, clamped 11–34 pt
- height varies 76–96 pt (mockup used `76 + ((wordCount * 7) % 20)`)
- spine colours cycle Ink-family neutrals (`#241F19 #5A544B #7A736A #38332D`); unread = Ember with light label
- vertical mono label (lowercased title) when spine ≥ 17 pt wide
- shelf itself is a 3 pt Ink rule under the spines

## Screen notes (from mockups)

1. **Boot** — night bg, 12×10 pixel-grid panda (blinking eyes), Caveat wordmark, mono
   boot log lines ("mounting library … ok"), 12-block progress bar in Ember.
2. **Onboarding** — single screen, two steps: name your library (underline text field),
   pick your paper (3 mini page-preview swatches: paper/sepia/night). Pill CTA "Start
   reading" in Ink. Wordmark + tagline footer.
3. **Bookshelf** — date + search button top; library name 38 pt; "N SHELVES · N NOTES"
   meta; "Continue" card (last note, minutes left, Ember progress hairline); shelf rows
   with spines; Inbox pinned first with Ember dot; Ember FAB (+) bottom-right.
4. **Collection** — back chevron + "SHELF" breadcrumb; title 38 pt; "N NOTES · N WORDS ·
   N MIN" meta; note rows: title (Ember dot when unread), one-line italic preview,
   mono meta line (date · min · words); hairline dividers.
5. **Reader** — meta caps line (collection · saved date · read time), 31 pt title, short
   34 pt Ember rule, Literata body lh 1.62 with first-line indents after the first
   paragraph. Tap page toggles chrome: top bar (back, collection, position "3 / 8") and
   floating bottom pill (Aa−/Aa+, theme dots, "64% · 3 MIN"), both blurred bars.
6. **Capture sheet** — bottom sheet over blurred bookshelf: pasted text preview (3-line
   clamp + mono meta "PASTED · N WORDS · N MIN"), auto title (editable, underline),
   shelf chips (selected = Ink fill; "+ new" dashed), Ember pill CTA "Save to Inbox".
7. **Empty inbox** — pixel panda in a Night rounded tile, "Nothing on this shelf.",
   one graphite sentence, Ember pill "Paste your first note", mono tip line.

Motion: boot animation + one calm settle/fade transition into the Reader. Nothing else.
Copy voice: short and punchy, plain verbs, sentence case.
