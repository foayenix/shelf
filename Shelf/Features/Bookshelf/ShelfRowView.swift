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

    private var meta: String {
        let words = notes.reduce(0) { $0 + $1.wordCount }
        return "\(notes.count) notes · \(words.formatted()) words"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
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
}
