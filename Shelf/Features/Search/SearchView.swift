import SwiftUI
import ShelfKit

/// Full-text search across all notes — titles and bodies.
struct SearchView: View {
    @Environment(LibraryModel.self) private var library
    @Environment(\.dismiss) private var dismiss

    let onOpenNote: (Note) -> Void

    @State private var query = ""
    @State private var results: [Note] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                TextField("Search your shelf", text: $query)
                    .font(ShelfFont.reading(17))
                    .foregroundStyle(ShelfPalette.ink)
                    .submitLabel(.search)
                Button("Close") { dismiss() }
                    .font(ShelfFont.reading(15))
                    .foregroundStyle(ShelfPalette.graphite)
            }
            .padding(.vertical, Space.l)
            .overlay(alignment: .bottom) {
                Rectangle().fill(ShelfPalette.ink).frame(height: 1.5)
            }
            .padding(.top, Space.l)

            if results.isEmpty && !query.isEmpty {
                Text("No notes match.")
                    .font(ShelfFont.reading(15))
                    .foregroundStyle(ShelfPalette.graphite)
                    .padding(.top, Space.xl)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(results) { note in
                        Button { onOpenNote(note) } label: {
                            NoteRowView(note: note)
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(ShelfPalette.hairline)
                    }
                }
            }
        }
        .padding(.horizontal, Space.xl)
        .background(ShelfPalette.paper.ignoresSafeArea())
        .task(id: query) {
            // Small debounce so bodies aren't scanned on every keystroke.
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            results = await library.search(query)
        }
    }
}
