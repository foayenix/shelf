import SwiftUI
import ShelfKit

/// The hero screen. Full-bleed markdown, tap the page to toggle chrome, scroll
/// position remembered per note, three papers, adjustable size.
struct ReaderView: View {
    @Environment(LibraryModel.self) private var library
    @Environment(AppSettings.self) private var settings
    @Environment(ReadingProgressStore.self) private var progressStore
    @Environment(\.dismiss) private var dismiss

    let noteId: UUID

    @State private var theme: ReadingTheme = .paper
    @State private var fontSize: Double = 19
    @State private var barsVisible = true
    @State private var blocks: [String] = []
    @State private var topBlockIndex: Int?
    @State private var loaded = false

    private var note: Note? { library.note(id: noteId) }

    private var progress: Double {
        guard blocks.count > 1, let top = topBlockIndex, top >= 0 else { return 0 }
        return Double(top) / Double(blocks.count - 1)
    }

    private var progressLabel: String {
        guard let note else { return "" }
        let minutesLeft = max(1, Int((Double(note.wordCount) * (1 - progress) / 200).rounded()))
        return "\(Int((progress * 100).rounded()))% · \(minutesLeft) min"
    }

    private var positionLabel: String {
        guard let note else { return "" }
        let siblings = library.notes(in: note.collectionId)
        guard let index = siblings.firstIndex(where: { $0.id == note.id }) else { return "" }
        return "\(index + 1) / \(siblings.count)"
    }

    private var metaLine: String {
        guard let note else { return "" }
        let saved = note.createdAt.formatted(.dateTime.day().month(.abbreviated))
        let minutes = max(1, Int((Double(note.wordCount) / 200).rounded()))
        return "\(library.collectionName(id: note.collectionId)) · saved \(saved) · \(minutes) min read"
    }

    var body: some View {
        ZStack(alignment: .top) {
            theme.background.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: fontSize * 0.45) {
                    header.id(-1)
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        MarkdownBodyView(markdown: block, theme: theme, fontSize: fontSize)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 32)
                .padding(.top, 70)
                .padding(.bottom, 130)
            }
            .scrollPosition(id: $topBlockIndex, anchor: .top)
            .scrollIndicators(.hidden)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.35)) { barsVisible.toggle() }
            }

            ReaderTopBar(
                theme: theme,
                collectionName: library.collectionName(id: note?.collectionId ?? nil),
                position: positionLabel,
                onBack: { dismiss() }
            )
            .opacity(barsVisible ? 1 : 0)
            .allowsHitTesting(barsVisible)
        }
        .overlay(alignment: .bottom) {
            ReaderControlsBar(
                theme: theme,
                progressLabel: progressLabel,
                onSmaller: { fontSize = max(AppSettings.fontSizeRange.lowerBound, fontSize - 1) },
                onLarger: { fontSize = min(AppSettings.fontSizeRange.upperBound, fontSize + 1) },
                onTheme: { theme = $0 }
            )
            .padding(.bottom, Space.l)
            .opacity(barsVisible ? 1 : 0)
            .allowsHitTesting(barsVisible)
        }
        .statusBarHidden(!barsVisible)
        .navigationBarHidden(true)
        .task { await load() }
        .onDisappear(perform: save)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(metaLine).metaCaps(size: 9, color: theme.meta)
            Text(note?.title ?? "")
                .font(ShelfFont.display(31))
                .foregroundStyle(theme.ink)
                .padding(.top, Space.m)
            Rectangle()
                .fill(ShelfPalette.ember)
                .frame(width: 34, height: 2)
                .padding(.top, 22)
                .padding(.bottom, Space.s)
        }
    }

    private func load() async {
        guard !loaded else { return }
        loaded = true
        theme = settings.defaultTheme
        fontSize = settings.readerFontSize
        blocks = MarkdownBlocks.split(await library.body(of: noteId))

        let existing = progressStore.entry(for: noteId)
        if let existing, existing.blockIndex > 0, existing.blockIndex < blocks.count {
            // `scrollPosition` only takes effect once the blocks it addresses have
            // been laid out, so restore on the turn after they land.
            await Task.yield()
            topBlockIndex = existing.blockIndex
        }
        // Opening a note marks it read (clears the unread dot / spine colour).
        progressStore.record(
            noteId: noteId,
            blockIndex: existing?.blockIndex ?? 0,
            progress: max(existing?.progress ?? 0, ReadingProgress.openedThreshold)
        )
    }

    private func save() {
        guard loaded, note != nil else { return }
        progressStore.record(
            noteId: noteId,
            blockIndex: max(topBlockIndex ?? 0, 0),
            progress: max(progress, progressStore.entry(for: noteId)?.progress ?? 0)
        )
        // Both reader controls persist: changing them mid-note shouldn't reset
        // the next time a note is opened.
        settings.readerFontSize = fontSize
        settings.defaultTheme = theme
    }
}
