import SwiftUI
import ShelfKit

/// One shelf: name row, then the spines standing on a 3pt ink rule.
struct ShelfRowView: View {
    @Environment(ReadingProgressStore.self) private var progress

    let name: String
    let pinned: Bool
    let notes: [Note]
    let onOpenShelf: () -> Void
    let onOpenNote: (Note) -> Void
    /// Shelf management, from a long press on the name. The pinned Inbox is virtual
    /// — it can't be renamed, reordered or deleted — so it passes none.
    var actions: ShelfActions? = nil

    private var meta: String {
        let words = notes.reduce(0) { $0 + $1.wordCount }
        return "\(notes.count) notes · \(words.formatted()) words"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            // No menu at all on the Inbox — an empty one on long press reads as broken.
            if let actions {
                header.contextMenu { shelfMenu(actions) }
            } else {
                header
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(Array(notes.enumerated()), id: \.element.id) { position, note in
                        Button { onOpenNote(note) } label: {
                            BookSpineView(
                                note: note,
                                position: position,
                                unread: progress.isUnread(note.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .frame(minHeight: 98, alignment: .bottom)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(ShelfPalette.ink).frame(height: 3).offset(y: 3)
            }
            .padding(.bottom, 3)
        }
    }

    private var header: some View {
        Button(action: onOpenShelf) {
            HStack(alignment: .firstTextBaseline, spacing: Space.s) {
                Text(name)
                    .font(ShelfFont.display(23))
                    .foregroundStyle(ShelfPalette.ink)
                if pinned {
                    Circle().fill(ShelfPalette.ember).frame(width: 6, height: 6)
                }
                Spacer()
                Text(meta).metaCaps(size: 9)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func shelfMenu(_ actions: ShelfActions) -> some View {
        Button("Rename shelf", action: actions.rename)
        if actions.canMoveUp {
            Button("Move up") { actions.move(-1) }
        }
        if actions.canMoveDown {
            Button("Move down") { actions.move(1) }
        }
        Button("Delete shelf", role: .destructive, action: actions.delete)
    }
}

/// What can be done to a stored shelf. Passed as one value rather than four
/// optional closures — the ternaries that would build those are slow to type-check
/// inside a view body, and this keeps the Inbox's "no actions" case a single `nil`.
struct ShelfActions {
    let canMoveUp: Bool
    let canMoveDown: Bool
    let rename: () -> Void
    let delete: () -> Void
    let move: (Int) -> Void
}
