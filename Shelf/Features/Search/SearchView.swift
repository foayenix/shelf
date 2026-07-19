import SwiftUI
import ShelfKit

/// Title search across all notes. Full-text search over bodies lands with the
/// Phase 4 polish pass.
struct SearchView: View {
    @Environment(LibraryModel.self) private var library
    @Environment(\.dismiss) private var dismiss

    let onOpenNote: (Note) -> Void

    @State private var query = ""

    private var results: [Note] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        return library.notes
            .filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
            .sorted { $0.createdAt > $1.createdAt }
    }

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
                Text("No titles match.")
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
    }
}
