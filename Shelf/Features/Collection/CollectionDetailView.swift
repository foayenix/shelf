import SwiftUI
import ShelfKit

struct CollectionDetailView: View {
    @Environment(LibraryModel.self) private var library
    @Environment(\.dismiss) private var dismiss

    let collectionId: UUID?
    let onOpenNote: (Note) -> Void

    private var name: String { library.collectionName(id: collectionId) }
    private var notes: [Note] { library.notes(in: collectionId) }

    private var meta: String {
        let words = notes.reduce(0) { $0 + $1.wordCount }
        let minutes = max(notes.isEmpty ? 0 : 1, Int((Double(words) / 200).rounded()))
        return "\(notes.count) notes · \(words.formatted()) words · \(minutes) min"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    HStack(spacing: Space.s) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(ShelfPalette.ink)
                        Text("Shelf").metaCaps()
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, Space.l)

                Text(name)
                    .font(ShelfFont.display(38))
                    .foregroundStyle(ShelfPalette.ink)
                    .padding(.top, 14)
                Text(meta).metaCaps()
                    .padding(.top, Space.xs)

                if notes.isEmpty {
                    EmptyShelfView(shelfName: name, onCapture: nil)
                        .padding(.top, Space.xl)
                } else {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(notes) { note in
                            Button { onOpenNote(note) } label: {
                                NoteRowView(note: note)
                            }
                            .buttonStyle(.plain)
                            .contextMenu { contextMenu(for: note) }
                            Divider().overlay(ShelfPalette.hairline)
                        }
                    }
                    .padding(.top, Space.s)
                }
            }
            .padding(.horizontal, Space.xl)
            .padding(.bottom, Space.xxxl)
        }
        .background(ShelfPalette.paper.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func contextMenu(for note: Note) -> some View {
        Section("Move to") {
            if note.collectionId != nil {
                Button("Inbox") { library.moveNote(note.id, to: nil) }
            }
            ForEach(library.collections.filter { $0.id != note.collectionId }) { collection in
                Button(collection.name) { library.moveNote(note.id, to: collection.id) }
            }
        }
        Button(note.favourite ? "Unfavourite" : "Favourite") {
            library.setFavourite(!note.favourite, for: note.id)
        }
        Button("Delete", role: .destructive) {
            library.deleteNote(note.id)
        }
    }
}
