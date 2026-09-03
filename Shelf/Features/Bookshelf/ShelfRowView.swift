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
    /// — it can't be renamed, reordered or deleted — so it passes none of these.
    var onRename: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil

    private var isManageable: Bool {
        onRename != nil || onDelete != nil || onMoveUp != nil || onMoveDown != nil
    }

    private var meta: String {
        let words = notes.reduce(0) { $0 + $1.wordCount }
        return "\(notes.count) notes · \(words.formatted()) words"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            // No menu at all on the Inbox — an empty one on long press reads as broken.
            if isManageable {
                header.contextMenu { shelfMenu }
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
    private var shelfMenu: some View {
        if let onRename {
            Button("Rename shelf", action: onRename)
        }
        if let onMoveUp {
            Button("Move up", action: onMoveUp)
        }
        if let onMoveDown {
            Button("Move down", action: onMoveDown)
        }
        if let onDelete {
            Button("Delete shelf", role: .destructive, action: onDelete)
        }
    }
}
